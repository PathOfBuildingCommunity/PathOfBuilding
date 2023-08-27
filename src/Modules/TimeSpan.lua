--- # TimeSpan
--- Represents the difference between two points in time.
--- ## Summary
--- All constructors and getters are implemented for the time measures
--- - `us`: microseconds
--- - `ms`: milliseconds
--- - `sec`: seconds
--- - `min`: minutes
--- - `hours`: hours
--- - `days`: days
--- ## Constructors
--- Create a `TimeSpan` with the specified number value in the measure by calling the `TimeSpan.from*` function for the measure.
--- ## Getters
--- ### Relative time values
--- Get the integer value of time measures are by calling the `TimeSpan:get*` function for the measure.
--- Returns the number of the measure in the next higher measure.
--- #### Example 
--- ```lua
--- local ts = TimeSpan.fromSec(65)
--- print(ts:getMin()) -- 1
--- print(ts:getSec()) -- 5
--- ```
--- ### Full time values
--- Get the floating full time measures are by calling the `TimeSpan:get*F` function for the measure.
--- They return the value of the `TimeSpan` in the measure specified by the function name.
--- #### Example
--- ```lua
--- local ts = TimeSpan.fromSec(65)
--- print(ts:getMinF()) -- 1.0833333333333
--- print(ts:getSecF()) -- 65
--- ```
--- ## Functions
--- 
--- - `TimeSpan:min(TimeSpan) -> TimeSpan`: Returns the smaller TimeSpan of the current TimeSpan and the given TimeSpan.
--- - `TimeSpan:max(TimeSpan) -> TimeSpan`: Returns the larger TimeSpan of the current TimeSpan and the given TimeSpan.
--- - `TimeSpan:clamp(TimeSpan, TimeSpan) -> TimeSpan`: Clamps the current TimeSpan between the given TimeSpans.
--- - `TimeSpan:floor(TimeSpan) -> TimeSpan`: Rounds the current TimeSpan down to the given TimeSpan.
--- - `TimeSpan:ceil(TimeSpan) -> TimeSpan`: Rounds the current TimeSpan up to the given TimeSpan.
--- - `TimeSpan:toIso() -> string`: Returns the current TimeSpan in the ISO 8601 format `d.hh:mm:ss.f`.
--- - `TimeSpan:toMinSecMs() -> string`: Returns the current TimeSpan in the format `mm:ss.ms`.
--- - `TimeSpan:toSecMs() -> string`: Returns the current TimeSpan in the format `ss.ms`.
---
--- ## Operators
--- The following operators are implemented for `TimeSpan`:
--- - `-TimeSpan`: Negation
--- - `TimeSpan + TimeSpan -> TimeSpan`: Addition
--- - `TimeSpan - TimeSpan -> TimeSpan`: Subtraction
--- - `TimeSpan * TimeSpan -> TimeSpan`: Multiplication
--- - `TimeSpan * number -> TimeSpan`: Scalar multiplication
--- - `TimeSpan / TimeSpan -> number`: Division
--- - `TimeSpan / number -> TimeSpan`: Scalar division
--- - `TimeSpan % TimeSpan -> TimeSpan`: Modulo
--- - `TimeSpan == TimeSpan -> boolean`: Equality
--- - `TimeSpan < TimeSpan -> boolean`: Comparison
--- - `TimeSpan <= TimeSpan -> boolean`: Comparison
---
--- @class TimeSpan
TimeSpan = { 
  --- # TimeSpan.ticks
  --- ## Summary
  --- The number of ticks of the `TimeSpan`.
  --- ## Remarks
  --- The number of ticks is stored as an integer inside the mantissa of a double precision floating point number.
  --- The value must always be an integer between `TimeSpan.MIN` and `TimeSpan.MAX`.
  --- @type integer
  ticks = 0
}
TimeSpan.__index = TimeSpan

--- # TimeSpan.MAX_VALUE
--- ## Summary
--- The maximum value of a `TimeSpan`.
--- ## Remarks
--- Lua stores numbers as double precision floating point numbers.
--- The value of a `TimeSpan` is stored as an integer inside the mantiassa of the double precision floating point number.
--- The maximum value of the mantissa is 2^53 - 1 = 9007199254740991 = 10424:23:58:45.4740991
--- @type TimeSpan
TimeSpan.MAX_VALUE = { ticks = 9007199254740991 }

--- # TimeSpan.MIN_VALUE
--- ## Summary
--- The minimum value of a `TimeSpan`.
--- ## Remarks
--- Lua stores numbers as double precision floating point numbers.
--- The value of a `TimeSpan` is stored as an integer inside the mantiassa of the double precision floating point number.
--- The minimum value of the mantissa is -2^53 + 1 = -9007199254740991 = -10424:23:58:45.4740991
--- @type TimeSpan
TimeSpan.MIN_VALUE = { ticks = -9007199254740991 }

--- # TimeSpan.ZERO
--- ## Summary
--- The zero value of a `TimeSpan`.
--- @type TimeSpan
TimeSpan.ZERO = { ticks = 0 }

--- TimeSpan.US
--- ## Summary
--- The `TimeSpan` of one microsecond.
--- @type TimeSpan
TimeSpan.US = { ticks = 10 }

--- # TimeSpan.MS
--- ## Summary
--- The `TimeSpan` of one millisecond.
--- @type TimeSpan
TimeSpan.MS = { ticks = 10000 }

--- # TimeSpan.SEC
--- ## Summary
--- The `TimeSpan` of one second.
--- @type TimeSpan
TimeSpan.SEC = { ticks = 10000000 }

--- # TimeSpan.MIN
--- ## Summary
--- The `TimeSpan` of one minute.
--- @type TimeSpan
TimeSpan.MIN = { ticks = 600000000 }

--- # TimeSpan.HOUR
--- ## Summary
--- The `TimeSpan` of one hour.
--- @type TimeSpan
TimeSpan.HOUR = { ticks = 36000000000 }

--- # TimeSpan.DAY
--- ## Summary
--- The `TimeSpan` of one day.
--- @type TimeSpan
TimeSpan.DAY = { ticks = 864000000000 }

--- # TimeSpan.fromTicks
--- ## Summary
--- Creates a new `TimeSpan` from the given number of ticks.
--- ## Parameters
--- @param ticks number
--- - `ticks`: The number of ticks to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of ticks.
function TimeSpan.fromTicks(ticks)
  if (type(ticks) ~= "number") then
    error(string.format("Invalid ticks value, TimeSpan.ticks must always be a number. Ensure a number is used"), 2)
    end
  if (ticks < TimeSpan.MIN_VALUE.ticks or ticks > TimeSpan.MAX_VALUE.ticks) then
    error(string.format("Invalid ticks value %d, Ensure the number is an integer between than `TimeSpan.MAX` and `TimeSpan.MIN`", ticks), 2)
  end

  return setmetatable({ ticks = math.floor(ticks) }, TimeSpan);
end
--- # TimeSpan.fromUs
--- ## Summary
--- Creates a new `TimeSpan` from the given number of microseconds.
--- ## Parameters
--- @param us number
--- - `us`: The number of microseconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of microseconds.
function TimeSpan.fromUs(us)
  return TimeSpan.fromTicks(us * TimeSpan.US.ticks)
end
--- # TimeSpan.fromMs
--- ## Summary
--- Creates a new `TimeSpan` from the given number of milliseconds.
--- ## Parameters
--- @param ms number
--- - `ms`: The number of milliseconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of milliseconds.
function TimeSpan.fromMs(ms)
  return TimeSpan.fromTicks(ms * TimeSpan.MS.ticks)
end
--- # TimeSpan.fromSec
--- ## Summary
--- Creates a new `TimeSpan` from the given number of seconds.
--- ## Parameters
--- @param sec number
--- - `sec`: The number of seconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of seconds.
function TimeSpan.fromSec(sec)
  return TimeSpan.fromTicks(sec * TimeSpan.SEC.ticks)
end
--- # TimeSpan.fromMin
--- ## Summary
--- Creates a new `TimeSpan` from the given number of minutes.
--- ## Parameters
--- @param min number
--- - `min`: The number of minutes to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of minutes.
function TimeSpan.fromMin(min)
  return TimeSpan.fromTicks(min * TimeSpan.MIN.ticks)
end
--- # TimeSpan.fromHours
--- ## Summary
--- Creates a new `TimeSpan` from the given number of hours.
--- ## Parameters
--- @param hours number
--- - `hours`: The number of hours to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of hours.
function TimeSpan.fromHours(hours)
  return TimeSpan.fromTicks(hours * TimeSpan.HOUR.ticks)
end
--- # TimeSpan.fromDays
--- ## Summary
--- Creates a new `TimeSpan` from the given number of days.
--- ## Parameters
--- @param days number
--- - `days`: The number of days to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of days.
function TimeSpan.fromDays(days)
  return TimeSpan.fromTicks(days * TimeSpan.DAY.ticks)
end

--- # TimeSpan:min
--- ## Summary
--- Returns the smaller `TimeSpan` of the current `TimeSpan` and the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to compare the current `TimeSpan` to.
--- ## Returns
--- @return TimeSpan
--- The smaller TimeSpan of the two.
function TimeSpan:min(rhs)
  if self.ticks <= rhs.ticks then
    return self
  end
  return rhs
end
--- # TimeSpan:max
--- ## Summary
--- Returns the larger `TimeSpan` of the current `TimeSpan` and the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The `TimeSpan` to compare the current `TimeSpan` to.
--- ## Returns
--- @return TimeSpan
--- The larger TimeSpan of the two.
function TimeSpan:max(rhs)
  if self.ticks >= rhs.ticks then
    return self
  end
  return rhs
end

--- # TimeSpan:clamp
--- ## Summary
--- Clamps the current `TimeSpan` between the given `TimeSpan`s.
--- ## Parameters
--- @param min TimeSpan
--- - `min`: The minimum `TimeSpan` to clamp the current `TimeSpan` to.
--- @param max TimeSpan
--- - `max`: The maximum `TimeSpan` to clamp the current `TimeSpan` to.
--- ## Returns
--- @return TimeSpan
--- The clamped `TimeSpan`.
function TimeSpan:clamp(min, max)
  return self:max(min):min(max)
end

--- # TimeSpan:floor
--- ## Summary
--- Rounds the current `TimeSpan` down to the given `TimeSpan`.
--- ## Parameters
--- @param base TimeSpan
--- - `base`: The `TimeSpan` to round the current `TimeSpan` down to.
--- ## Returns
--- @return TimeSpan
--- The `TimeSpan` rounded down to the given `base`.
function TimeSpan:floor(base)
  return TimeSpan.fromTicks(base.ticks * math.floor(self.ticks / base.ticks))
end

--- # TimeSpan:ceil
--- ## Summary
--- Rounds the current `TimeSpan` up to the given `TimeSpan`.
--- ## Parameters
--- @param base TimeSpan
--- - `base`: The `TimeSpan` to round the current `TimeSpan` up to.
--- ## Returns
--- @return TimeSpan
--- The `TimeSpan` rounded up to the given `base`.
function TimeSpan:ceil(base)
  return TimeSpan.fromTicks(base.ticks * math.ceil(self.ticks / base.ticks))
end
--- # TimeSpan:getUsF
--- ## Summary
--- Returns the total number of microseconds of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of microseconds of the current `TimeSpan` as a floating point number.
function TimeSpan:getUsF()
  return self.ticks / TimeSpan.US.ticks
end
--- # TimeSpan:getUs
--- ## Summary
--- Returns the number of microseconds in the millisecond of the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of microseconds in the millisecond of the current `TimeSpan`.
function TimeSpan:getUs()
  return math.floor(self:getUsF() % 1000)
end
--- # TimeSpan:getMsF
--- ## Summary
--- Returns the total number of milliseconds of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of milliseconds of the current `TimeSpan` as a floating point number.
function TimeSpan:getMsF()
  return self.ticks / TimeSpan.MS.ticks
end
--- # TimeSpan:getMs
--- ## Summary
--- Returns the number of milliseconds in the second of the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of milliseconds in the second of the current `TimeSpan`.
function TimeSpan:getMs()
  return math.floor(self:getMsF() % 1000)
end
--- # TimeSpan:getSecF
--- ## Summary
--- Returns the total number of seconds of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of seconds of the current `TimeSpan` as a floating point number.
function TimeSpan:getSecF()
  return self.ticks / TimeSpan.SEC.ticks
end
--- # TimeSpan:getSec
--- ## Summary
--- Returns the number of seconds in the minute of the current `TimeSpan`.
--- ## Returns
--- @return integer
function TimeSpan:getSec()
  return math.floor(self:getSecF() % 60)
end
--- # TimeSpan:getMinF
--- ## Summary
--- Returns the total number of minutes of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of minutes of the current `TimeSpan` as a floating point number.
function TimeSpan:getMinF()
  return self.ticks / TimeSpan.MIN.ticks
end
--- # TimeSpan:getMin
--- ## Summary
--- Returns the number of minutes in the hour of the current `TimeSpan`.
--- ## Returns
--- @return integer
function TimeSpan:getMin()
  return math.floor(self:getMinF() % 60)
end
--- # TimeSpan:getHoursF
--- ## Summary
--- Returns the total number of hours of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of hours of the current `TimeSpan` as a floating point number.
function TimeSpan:getHoursF()
  return self.ticks / TimeSpan.HOUR.ticks
end
--- # TimeSpan:getHours
--- ## Summary
--- Returns the number of hours in the day of the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of hours in the day of the current `TimeSpan`.
function TimeSpan:getHours()
  return math.floor(self:getHoursF() % 24)
end
--- # TimeSpan:getDaysF
--- ## Summary
--- Returns the total number of days of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of days of the current `TimeSpan` as a floating point number.
function TimeSpan:getDaysF()
  return self.ticks / TimeSpan.DAY.ticks
end
--- # TimeSpan:getDays
--- ## Summary
--- Returns the number of days in the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of days in the current `TimeSpan` without hours, minutes, etc.
function TimeSpan:getDays()
  return self.ticks // TimeSpan.DAY.ticks
end
--- # TimeSpan:getFraction
--- ## Summary
--- Returns the number of ticks in the second of the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of ticks in the second of the current `TimeSpan`.
--- ## Remarks
--- Used for the ISO 8601 format.
function TimeSpan:getFraction()
  return math.floor(self.ticks % TimeSpan.SEC.ticks)
end
--- # TimeSpan:toIso
--- ## Summary
--- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.f`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.f`.
function TimeSpan:toIso()
  return string.format("%d.%02d:%02d:%02d.%09d", self:getDays(), self:getHours(), self:getMin(), self:getSec(), self:getFraction())
end
--- # TimeSpan:toMinSecMs
--- ## Summary
--- Returns the current `TimeSpan` in the format `m:ss.ms`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the format `m:ss.ms`.
function TimeSpan:toMinSecMs()
  return string.format("%d:%02d.%04d", math.floor(self:min()), self:getSec(), self:getMs())
end
--- # TimeSpan:toSecMs
--- ## Summary
--- Returns the current `TimeSpan` in the format `s.ms`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the format `s.ms`.
function TimeSpan:toSecMs()
  return string.format("%d.%04d", math.floor(self:getSecF()), self:getMs())
end

--- # TimeSpan:__tostring
--- ## Summary
--- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.f`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.f`.
function TimeSpan:__tostring()
  return self:toIso()
end
--- # TimeSpan:__unm
--- ## Summary
--- Returns the negated value of the TimeSpan.
--- ## Returns
--- A new TimeSpan object with the negated value.
--- @return TimeSpan
function TimeSpan:__unm()
  return TimeSpan.fromTicks(-self.ticks)
end
--- # TimeSpan:__add
--- ## Summary
--- Adds the given TimeSpan to the current TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to add to the current TimeSpan.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the added value.
function TimeSpan:__add(rhs)
  return TimeSpan.fromTicks(self.ticks + rhs.ticks)
end
--- # TimeSpan:__sub
--- ## Summary
--- Subtracts the given TimeSpan from the current TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to subtract from the current TimeSpan.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the subtracted value.
function TimeSpan:__sub(rhs)
  return TimeSpan.fromTicks(self.ticks - rhs.ticks)
end
--- # TimeSpan:__mul
--- ## Summary
--- Multiplies the current TimeSpan with the given TimeSpan or scalar.
--- ## Parameters
--- @param rhs TimeSpan | number
--- - `rhs`: The TimeSpan or number to multiply the current TimeSpan with.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the multiplied value.
function TimeSpan:__mul(rhs)
  if (type(rhs) == "number") then
    return TimeSpan.fromTicks(self.ticks * rhs)
  else
    return TimeSpan.fromTicks(self.ticks * rhs.ticks)
  end
end
--- # TimeSpan:__div
--- ## Summary
--- Divides the current TimeSpan by the given TimeSpan or scalar.
--- ## Parameters
--- @param rhs TimeSpan | number
--- - `rhs`: The TimeSpan or number to divide the current TimeSpan by.
--- ## Returns
--- @return TimeSpan | number
--- A new TimeSpan object with the divided value if the `rhs` is a scalar, the division result otherwise.
--- ## Remarks
--- The integer division result is rounded down.
function TimeSpan:__div(rhs)
  if (type(rhs) == "number") then
    return TimeSpan.fromTicks(self.ticks / rhs)
  else
    return self.ticks / rhs.ticks
  end
end
--- # TimeSpan:__mod
--- ## Summary
--- Calculates the modulo of the current `TimeSpan` by the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The `TimeSpan` to calculate the modulo of the current `TimeSpan` by.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the modulo value.
function TimeSpan:__mod(rhs)
  return TimeSpan.fromTicks(self.ticks % rhs.ticks)
end
--- # TimeSpan:__eq
--- ## Summary
--- Checks if the current `TimeSpan` is equal to the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to check for equality.
--- ## Returns
--- @return boolean
--- `true` if the `TimeSpan`s are equal, `false` otherwise.
--- ## Remarks
--- The `TimeSpan`s are considered equal if their ticks values are equal.
function TimeSpan:__eq(rhs)
  return self.ticks == rhs.ticks
end
--- # TimeSpan:__lt
--- ## Summary
--- Checks if the current `TimeSpan` is less than the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to check for less than.
--- ## Returns
--- @return boolean
--- `true` if the current `TimeSpan` is less than the given `TimeSpan`, `false` otherwise.
function TimeSpan:__lt(rhs)
  return self.ticks < rhs.ticks
end
--- # TimeSpan:__le
--- ## Summary
--- Checks if the current `TimeSpan` is less than or equal to the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to check for less than or equal to.
--- ## Returns
--- @return boolean
--- `true` if the current `TimeSpan` is less than or equal to the given `TimeSpan`, `false` otherwise.
function TimeSpan:__le(rhs)
  return self.ticks <= rhs.ticks
end