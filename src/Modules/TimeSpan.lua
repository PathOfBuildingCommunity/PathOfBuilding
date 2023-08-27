--- # TimeSpan
--- Represents the difference between two points in time.
--- All constructors and getters are implemented for the time measures
--- - `us`: microseconds
--- - `ms`: milliseconds
--- - `sec`: seconds
--- - `min`: minutes
--- - `hours`: hours
--- - `days`: days
--- ## Constructors
--- Create a `TimeSpan` with the specified value in the measure by calling the `TimeSpan:from*` functions.
--- ## Getters
--- ### Relative time values
--- Get the integer value of time measures are by calling the `TimeSpan:get*` functions.
--- Returns the number of the measure in the next higher measure.
--- #### Example 
--- ```lua
--- local ts = TimeSpan.fromSec(65)
--- print(ts:getMin()) -- 1
--- print(ts:getSec()) -- 5
--- ```
--- ### Full time values
--- Get the floating full time measures are by calling the `TimeSpan:get*F` functions.
--- They return the value of the `TimeSpan` in the measure specified by the function name.
--- #### Example
--- ```lua
--- local ts = TimeSpan.fromSec(65)
--- print(ts:getMinF()) -- 1.0833333333333
--- print(ts:getSecF()) -- 65
--- ```
--- ## Operators
--- The following operators are implemented for `TimeSpan`:
--- - `+`: AdditionF
--- - `-`: Subtraction
--- - `*`: Multiplication
--- - `/`: Division
--- - `%`: Modulo
--- - `==`: Equality
--- - `<`: Comparison
--- - `<=`: Comparison
--- @class TimeSpan
TimeSpan = { ticks = 0 }
TimeSpan.__index = TimeSpan

--- @return TimeSpan
--- @param ticks integer
function TimeSpan.fromTicks(ticks)
  if (type(ticks) ~= "number") then
    error(string.format("Invalid ticks value, TimeSpan.ticks must always be a number. Ensure a number is used"), 2)
    end
  if (math.type(ticks) ~= "integer") then
    error(string.format("Invalid ticks value %d, TimeSpan.ticks must always be an integer. Ensure no fraction is used and the absolute number is smaller than 2^51", ticks), 2)
  end

  local ts = { ticks = ticks }
  setmetatable(ts, TimeSpan)

  return ts;
end
--- # TimeSpan:fromUs
--- ## Summary
--- Creates a new `TimeSpan` from the given number of microseconds.
--- ## Parameters
--- @param us number
--- - `us`: The number of microseconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of microseconds.
function TimeSpan.fromUs(us)
  return TimeSpan.fromTicks(math.floor(us * 10))
end
--- # TimeSpan:fromMs
--- ## Summary
--- Creates a new `TimeSpan` from the given number of milliseconds.
--- ## Parameters
--- @param ms number
--- - `ms`: The number of milliseconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of milliseconds.
function TimeSpan.fromMs(ms)
  return TimeSpan.fromTicks(math.floor(ms * 10000))
end
--- # TimeSpan:fromSec
--- ## Summary
--- Creates a new `TimeSpan` from the given number of seconds.
--- ## Parameters
--- @param sec number
--- - `sec`: The number of seconds to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of seconds.
function TimeSpan.fromSec(sec)
  return TimeSpan.fromTicks(math.floor(sec * 10000000))
end
--- # TimeSpan:fromMin
--- ## Summary
--- Creates a new `TimeSpan` from the given number of minutes.
--- ## Parameters
--- @param min number
--- - `min`: The number of minutes to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of minutes.
function TimeSpan.fromMin(min)
  return TimeSpan.fromTicks(math.floor(min * 600000000))
end
--- # TimeSpan:fromHours
--- ## Summary
--- Creates a new `TimeSpan` from the given number of hours.
--- ## Parameters
--- @param hours number
--- - `hours`: The number of hours to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of hours.
function TimeSpan.fromHours(hours)
  return TimeSpan.fromTicks(math.floor(hours * 36000000000))
end
--- # TimeSpan:fromDays
--- ## Summary
--- Creates a new `TimeSpan` from the given number of days.
--- ## Parameters
--- @param days number
--- - `days`: The number of days to create the `TimeSpan` from.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the given number of days.
function TimeSpan.fromDays(days)
  return TimeSpan.fromTicks(math.floor(days * 864000000000))
end

--- # TimeSpan:divUp
--- ## Summary
--- Divides the current TimeSpan by the given TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to divide the current TimeSpan by.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the divided value.
--- ## Remarks
--- The integer division result is rounded up.
function TimeSpan:divUp(rhs)
  return TimeSpan.fromTicks(math.ceil(self.ticks / rhs.ticks))
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
  return base.mul(self:div(base))
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
  return base.mul(self:divUp(base))
end
--- # TimeSpan:getUsF
--- ## Summary
--- Returns the total number of microseconds of the current `TimeSpan` as a floating point number.
--- ## Returns
--- @return number
--- The total number of microseconds of the current `TimeSpan` as a floating point number.
function TimeSpan:getUsF()
  return self.ticks / 10
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
  return self.ticks / 10000
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
  return self.ticks / 10000000
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
  return self.ticks / 600000000
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
  return self.ticks / 36000000000
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
  return self.ticks / 864000000000
end
--- # TimeSpan:getDays
--- ## Summary
--- Returns the number of days in the current `TimeSpan`.
--- ## Returns
--- @return integer
--- The number of days in the current `TimeSpan` without hours, minutes, etc.
function TimeSpan:getDays()
  return self.ticks // 864000000000
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
  return math.floor(self.ticks % 10000000)
end
--- # TimeSpan:toIso
--- ## Summary
--- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
function TimeSpan:toIso()
  return string.format("%02d.%02d:%02d:%02d.%09d", self:getDays(), self:getHours(), self:getMin(), self:getSec(), self:getFraction())
end
--- # TimeSpan:toMinSecMs
--- ## Summary
--- Returns the current `TimeSpan` in the format `mm:ss.ms`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the format `mm:ss.ms`.
function TimeSpan:toMinSecMs()
  return string.format("%02d:%02d.%04d", math.floor(self:min()), self:getSec(), self:getMs())
end
--- # TimeSpan:toSecMs
--- ## Summary
--- Returns the current `TimeSpan` in the format `ss.ms`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the format `ss.ms`.
function TimeSpan:toSecMs()
  return string.format("%02d.%04d", math.floor(self:getSecF()), self:getMs())
end





--- # TimeSpan:__tostring
--- ## Summary
--- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
--- ## Returns
--- @return string
--- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
function TimeSpan:__tostring()
  return self:toIso()
end
--- # TimeSpan:unm
--- ## Summary
--- Returns the negated value of the TimeSpan.
--- ## Returns
--- A new TimeSpan object with the negated value.
--- @return TimeSpan
function TimeSpan:__unm()
  return TimeSpan.fromTicks(-self.ticks)
end
--- # TimeSpan:add
--- ## Summary
--- Adds the given TimeSpan to the current TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to add to the current TimeSpan.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the added value.
function TimeSpan:__add(rhs)
  return TimeSpan.fromTicks(math.floor(self.ticks + rhs.ticks))
end
--- # TimeSpan:sub
--- ## Summary
--- Subtracts the given TimeSpan from the current TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to subtract from the current TimeSpan.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the subtracted value.
function TimeSpan:__sub(rhs)
  return TimeSpan.fromTicks(math.floor(self.ticks - rhs.ticks))
end
--- # TimeSpan:mul
--- ## Summary
--- Multiplies the current TimeSpan with the given TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to multiply the current TimeSpan with.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the multiplied value.
function TimeSpan:__mul(rhs)
  return TimeSpan.fromTicks(math.floor(self.ticks * rhs))
end
--- # TimeSpan:div
--- ## Summary
--- Divides the current TimeSpan by the given TimeSpan.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The TimeSpan to divide the current TimeSpan by.
--- ## Returns
--- @return TimeSpan
--- A new TimeSpan object with the divided value.
--- ## Remarks
--- The integer division result is rounded down.
function TimeSpan:__div(rhs)
  return TimeSpan.fromTicks(self.ticks // rhs.ticks)
end
--- # TimeSpan:mod
--- ## Summary
--- Calculates the modulo of the current `TimeSpan` by the given `TimeSpan`.
--- ## Parameters
--- @param rhs TimeSpan
--- - `rhs`: The `TimeSpan` to calculate the modulo of the current `TimeSpan` by.
--- ## Returns
--- @return TimeSpan
--- A new `TimeSpan` object with the modulo value.
function TimeSpan:__mod(rhs)
  return TimeSpan.fromTicks(math.floor(self.ticks % rhs.ticks))
end
--- # TimeSpan:equals
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
--- # TimeSpan:lt
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
--- # TimeSpan:le
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