-- Path of Building
--
-- Module: Parallel Runner
-- Worker pool for running batched calculations on background threads.
-- Each worker is an isolated Lua VM started via the engine's LaunchSubScript;
-- work is described by a mode string plus JSON payloads, and results come back
-- as a single JSON string per worker. If a worker fails, or its results diverge
-- from the main thread's baseline, the whole job fails and the caller falls
-- back to the single-core code path.
--
local dkjson = require "dkjson"

local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local m_abs = math.abs
local m_max = math.max
local m_min = math.min
local m_floor = math.floor
local s_format = string.format

local ParallelRunner = {
	jobCount = 0,
	activeJobs = { },
	-- Set after a worker error or baseline mismatch so we don't repeatedly pay
	-- worker bootstrap costs for a broken configuration. Cleared on restart or
	-- when the user changes the computation mode in Options.
	disabledThisSession = false,
}

-- In dev mode, mirror job lifecycle events to a log file so worker problems
-- can be diagnosed without console access
local function logEvent(fmt, ...)
	if not (launch and launch.devMode) then
		return
	end
	local file = io.open(GetScriptPath().."/parallel_log.txt", "a")
	if file then
		file:write(os.date("%H:%M:%S"), " ", s_format(fmt, ...), "\n")
		file:close()
	end
end

local jobClass = { }
jobClass.__index = jobClass

-- Cancel all outstanding workers of this job; late finish/error events for
-- aborted subscripts are ignored (nil-guarded in launch:OnSubFinished/OnSubError)
function jobClass:Cancel()
	if self.cancelled then
		return
	end
	self.cancelled = true
	for i, id in pairs(self.workers) do
		AbortSubScript(id)
		launch.subScripts[id] = nil
		self.workers[i] = nil
	end
	ParallelRunner.activeJobs[self.id] = nil
end

function ParallelRunner:IsAvailable()
	-- LaunchSubScript is engine-provided; headless mode stubs it to return nil,
	-- and forks without it should transparently stay on the single-core path
	if type(LaunchSubScript) ~= "function" then
		return false
	end
	if self.disabledThisSession then
		return false
	end
	return not main or main.computationMode ~= "SINGLE"
end

function ParallelRunner:GetWorkerCount()
	local count = main and main.workerCount or 0
	if count == 0 then
		-- Auto: leave one core for the UI thread
		local detected = tonumber(os.getenv("NUMBER_OF_PROCESSORS") or "") or 2
		return m_max(1, m_min(detected - 1, 8))
	end
	return m_max(1, m_min(count, 16))
end

-- Decide whether a job is big enough to be worth the per-worker bootstrap cost.
-- weight is a relative estimate of per-candidate cost (1 = one cached calcFunc call)
function ParallelRunner:ShouldParallelize(candidateCount, weight)
	if not self:IsAvailable() then
		return false
	end
	return candidateCount * (weight or 1) >= 300
end

-- Split a flat list into up to numBatches round-robin slices
function ParallelRunner:PartitionList(list, numBatches)
	local batches = { }
	local n = m_min(numBatches, #list)
	for i = 1, n do
		batches[i] = { }
	end
	for i, item in ipairs(list) do
		t_insert(batches[((i - 1) % n) + 1], item)
	end
	return batches
end

-- Compare the baseline stats computed by a worker against the main thread's.
-- Any disagreement means the build didn't survive the XML round trip intact,
-- so per-candidate results can't be trusted. Returns a description of the
-- first mismatch, or nil if everything agrees.
local function validateBaseline(got, expected)
	if type(got) ~= "table" then
		return "no baseline returned"
	end
	for stat, value in pairs(expected) do
		local workerValue = got[stat]
		if type(workerValue) ~= "number" then
			return s_format("stat %s missing", stat)
		end
		if m_abs(workerValue - value) > m_max(1e-6, 1e-3 * m_max(m_abs(workerValue), m_abs(value))) then
			return s_format("stat %s: worker %g vs main %g", stat, workerValue, value)
		end
	end
end

-- Launch a job:
-- desc = {
--   mode = "probe"/"nodePower"/"compare"/"notable"/"itemdb",
--   buildXML = <build snapshot from buildMode:SaveDB()>,
--   auxText = <mode-specific extra text, e.g. compare build XML or item raw>,
--   common = <table of settings shared by all batches>,
--   batches = <array of per-worker batch tables>,
--   total = <total candidate count, for progress reporting>,
--   expectedBaseline = <stat name -> number, validated against each worker>,
--   onProgress = function(percent),
--   onComplete = function(payloads),  -- array of decoded worker payloads
--   onError = function(errMsg),       -- called at most once; caller should fall back
-- }
-- Returns the job (with job:Cancel()), or nil + error message if workers
-- could not be launched at all (caller should fall back synchronously).
function ParallelRunner:LaunchJob(desc)
	local scriptText, errMsg = self:GetWorkerScript()
	if not scriptText then
		return nil, errMsg
	end
	self.jobCount = self.jobCount + 1
	local job = setmetatable({
		id = self.jobCount,
		desc = desc,
		workers = { },
		payloads = { },
		progress = { },
		pending = 0,
		lastPercent = -1,
	}, jobClass)
	for i, batch in ipairs(desc.batches) do
		local specJSON = dkjson.encode({ common = desc.common, batch = batch })
		local id = LaunchSubScript(scriptText,
			"GetScriptPath,GetRuntimePath,GetWorkDir,MakeDir,GetUserPath",
			"ConPrintf,ParallelWorkerProgress",
			job.id, i, GetScriptPath(), desc.mode, desc.buildXML or "", desc.auxText or "", specJSON)
		if not id then
			job:Cancel()
			return nil, "Unable to launch background worker"
		end
		job.workers[i] = id
		job.pending = job.pending + 1
		launch:RegisterSubScript(id, function(resultJSON, workerErrMsg)
			self:OnWorkerDone(job, i, resultJSON, workerErrMsg)
		end)
	end
	if job.pending == 0 then
		return nil, "No work to distribute"
	end
	self.activeJobs[job.id] = job
	logEvent("job %d launched: mode=%s workers=%d total=%s buildXML=%dB", job.id, desc.mode, job.pending, tostring(desc.total), #(desc.buildXML or ""))
	return job
end

function ParallelRunner:OnWorkerDone(job, workerIdx, resultJSON, errMsg)
	if job.cancelled or job.failed then
		return
	end
	job.workers[workerIdx] = nil
	if errMsg or not resultJSON then
		self:FailJob(job, errMsg or "worker returned no result")
		return
	end
	local payload, _, decodeErr = dkjson.decode(resultJSON)
	if type(payload) ~= "table" then
		self:FailJob(job, "malformed worker result: "..tostring(decodeErr))
		return
	end
	if payload.error then
		self:FailJob(job, payload.error, payload)
		return
	end
	if job.desc.expectedBaseline then
		local mismatch = validateBaseline(payload.baseline, job.desc.expectedBaseline)
		if mismatch then
			self:FailJob(job, "worker results diverged from main thread ("..mismatch..")")
			return
		end
	end
	job.payloads[workerIdx] = payload
	job.pending = job.pending - 1
	logEvent("job %d worker %d done: %dB result, %d pending", job.id, workerIdx, #resultJSON, job.pending)
	if job.pending == 0 then
		self.activeJobs[job.id] = nil
		if job.desc.onComplete then
			logEvent("job %d complete, merging", job.id)
			job.desc.onComplete(job.payloads)
		end
	end
end

function ParallelRunner:FailJob(job, errMsg, payload)
	job.failed = true
	job:Cancel()
	self.disabledThisSession = true
	ConPrintf("Parallel computation failed, falling back to single-core: %s", tostring(errMsg))
	logEvent("job %d FAILED: %s", job.id, tostring(errMsg))
	if job.desc.onError then
		job.desc.onError(errMsg, payload)
	end
end

function ParallelRunner:CancelAll()
	for _, job in pairs(self.activeJobs) do
		job:Cancel()
	end
end

-- Public wrapper so call sites can add their own entries to the dev log
function ParallelRunner:Log(fmt, ...)
	logEvent(fmt, ...)
end

function ParallelRunner:GetWorkerScript()
	if not self.workerScript then
		local file = io.open("CalcWorker.lua", "r")
		if not file then
			file = io.open(GetScriptPath().."/CalcWorker.lua", "r")
		end
		if not file then
			return nil, "CalcWorker.lua not found"
		end
		self.workerScript = file:read("*a")
		file:close()
	end
	return self.workerScript
end

-- Dev-mode probe: launches a single worker that bootstraps a headless program,
-- reloads the given build from XML, and reports facts about the worker VM
-- (injected functions, timings, baseline agreement). Results go to the console
-- and to probe_report.txt next to the scripts.
function ParallelRunner:RunProbe(build)
	local reportLines = { }
	local function report(fmt, ...)
		local line = s_format(fmt, ...)
		ConPrintf("%s", line)
		t_insert(reportLines, line)
	end
	local function writeReport()
		local file = io.open(GetScriptPath().."/probe_report.txt", "w")
		if file then
			file:write(table.concat(reportLines, "\n"), "\n")
			file:close()
		end
	end
	local buildXML = build:SaveDB("probe")
	if not buildXML then
		report("Probe: unable to serialize build")
		writeReport()
		return
	end
	local expectedBaseline
	if build.calcsTab and build.calcsTab.miscCalculator then
		local calcFunc, calcBase = build.calcsTab:GetMiscCalculator()
		expectedBaseline = PowerCalcTasks.extractBaseline(calcBase, nil, false)
	end
	local startTime = GetTime()
	report("Probe: launching worker (build XML: %d bytes)...", #buildXML)
	local job, errMsg = self:LaunchJob({
		mode = "probe",
		buildXML = buildXML,
		common = { },
		batches = { { } },
		total = 1,
		-- Baselines are compared manually below so the probe can report every
		-- stat instead of failing on the first mismatch
		onComplete = function(payloads)
			local payload = payloads[1]
			report("Probe: completed in %d ms (wall)", GetTime() - startTime)
			for key, value in pairs(payload.probe or { }) do
				report("Probe:   %s = %s", key, tostring(value))
			end
			for key, value in pairs(payload.timing or { }) do
				report("Probe:   timing.%s = %s", key, tostring(value))
			end
			local mismatches = 0
			for stat, value in pairs(expectedBaseline or { }) do
				local workerValue = payload.baseline and payload.baseline[stat]
				if type(workerValue) ~= "number" then
					report("Probe: BASELINE %s: main %.6g, worker MISSING", stat, value)
					mismatches = mismatches + 1
				elseif m_abs(workerValue - value) > m_max(1e-6, 1e-3 * m_max(m_abs(workerValue), m_abs(value))) then
					report("Probe: BASELINE %s: main %.6g, worker %.6g (%+.3f%%)", stat, value, workerValue, (workerValue - value) / value * 100)
					mismatches = mismatches + 1
				else
					report("Probe: baseline %s: main %.6g, worker %.6g OK", stat, value, workerValue)
				end
			end
			if mismatches == 0 then
				report("Probe: baseline validated OK against main thread")
				-- A successful probe proves the environment works; re-enable if a
				-- previous failure had disabled parallel mode
				self.disabledThisSession = false
			else
				report("Probe: %d baseline stats DIVERGED", mismatches)
			end
			writeReport()
		end,
		onError = function(probeErrMsg, payload)
			report("Probe: FAILED: %s", tostring(probeErrMsg))
			if payload and payload.probe then
				for key, value in pairs(payload.probe) do
					report("Probe:   env.%s = %s", key, tostring(value))
				end
			end
			writeReport()
		end,
	})
	if not job then
		report("Probe: could not launch worker: %s", tostring(errMsg))
		writeReport()
	end
end

-- Called from worker threads via launch:OnSubCall; aggregates per-worker
-- progress counters into one percentage for the job's progress callback
function ParallelWorkerProgress(jobId, workerIdx, done, total)
	local job = ParallelRunner.activeJobs[jobId]
	if not job or job.cancelled or job.failed then
		return
	end
	job.progress[workerIdx] = done
	if job.desc.onProgress and job.desc.total and job.desc.total > 0 then
		local doneSum = 0
		for _, workerDone in pairs(job.progress) do
			doneSum = doneSum + workerDone
		end
		local percent = m_min(m_floor(doneSum / job.desc.total * 100), 100)
		if percent ~= job.lastPercent then
			job.lastPercent = percent
			job.desc.onProgress(percent)
		end
	end
end

return ParallelRunner
