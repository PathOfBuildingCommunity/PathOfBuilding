#Requires -Version 5.1
<#
.SYNOPSIS
    Syncs this fork's local `dev` branch with upstream PathOfBuildingCommunity/PathOfBuilding.

.DESCRIPTION
    Follows CONTRIBUTING.md "Keeping your fork up to date":
      1. Ensure the `upstream` remote exists
      2. Fetch upstream
      3. Check out `dev`
      4. Rebase onto upstream/dev
      5. Optionally push to origin (use -Push)

.PARAMETER Push
    After a successful rebase, force-push the updated `dev` branch to origin.
    Required when the rebase rewrites history relative to origin/dev.

.PARAMETER Branch
    Local branch to update. Defaults to `dev`.

.EXAMPLE
    .\Sync-Upstream.ps1

.EXAMPLE
    .\Sync-Upstream.ps1 -Push
#>
[CmdletBinding()]
param(
    [switch]$Push,
    [string]$Branch = "dev"
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$UpstreamUrl = "https://github.com/PathOfBuildingCommunity/PathOfBuilding.git"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-GitRepo {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a git repository: $PSScriptRoot"
    }
}

function Get-Remotes {
    git remote 2>$null
}

Assert-GitRepo

# Block on modified/staged tracked files only; untracked files are fine.
$dirty = git status --porcelain --untracked-files=no
if ($dirty) {
    throw @"
Working tree has uncommitted changes to tracked files. Commit, stash, or discard them first:

$dirty
"@
}

Write-Step "Ensuring upstream remote"
$remotes = @(Get-Remotes)
if ($remotes -notcontains "upstream") {
    Write-Host "Adding upstream -> $UpstreamUrl"
    git remote add upstream $UpstreamUrl
    if ($LASTEXITCODE -ne 0) { throw "Failed to add upstream remote." }
} else {
    $currentUrl = (git remote get-url upstream).Trim()
    Write-Host "upstream already configured: $currentUrl"
}

Write-Step "Fetching from upstream"
git fetch upstream
if ($LASTEXITCODE -ne 0) { throw "git fetch upstream failed." }

$upstreamRef = "upstream/$Branch"
git rev-parse --verify "$upstreamRef^{commit}" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Upstream branch '$upstreamRef' not found after fetch."
}

Write-Step "Checking out $Branch"
git checkout $Branch
if ($LASTEXITCODE -ne 0) { throw "Failed to check out '$Branch'." }

$before = (git rev-parse HEAD).Trim()
$upstreamTip = (git rev-parse $upstreamRef).Trim()

if ($before -eq $upstreamTip) {
    Write-Host "`nAlready up to date with $upstreamRef." -ForegroundColor Green
} else {
    $behind = (git rev-list --count "HEAD..$upstreamRef").Trim()
    $ahead = (git rev-list --count "$upstreamRef..HEAD").Trim()
    Write-Host "Local $Branch is $behind commit(s) behind and $ahead commit(s) ahead of $upstreamRef."

    Write-Step "Rebasing $Branch onto $upstreamRef"
    git rebase $upstreamRef
    if ($LASTEXITCODE -ne 0) {
        Write-Host @"

Rebase failed (likely conflicts). Resolve them, then run:
  git add <resolved-files>
  git rebase --continue

Or abort with:
  git rebase --abort
"@ -ForegroundColor Yellow
        exit 1
    }

    $after = (git rev-parse HEAD).Trim()
    Write-Host "`nRebase complete: $before -> $after" -ForegroundColor Green
}

if ($Push) {
    Write-Step "Force-pushing $Branch to origin"
    git push -f origin $Branch
    if ($LASTEXITCODE -ne 0) { throw "git push -f origin $Branch failed." }
    Write-Host "Pushed origin/$Branch." -ForegroundColor Green
} else {
    $localTip = (git rev-parse HEAD).Trim()
    $originTip = $null
    git rev-parse --verify "origin/$Branch^{commit}" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $originTip = (git rev-parse "origin/$Branch").Trim()
    }

    if ($originTip -and $localTip -ne $originTip) {
        Write-Host @"

Local $Branch differs from origin/$Branch.
To update your fork on GitHub, re-run with -Push:
  .\Sync-Upstream.ps1 -Push
"@ -ForegroundColor Yellow
    } else {
        Write-Host "`nDone. Use -Push if you also want to update origin/$Branch." -ForegroundColor Green
    }
}
