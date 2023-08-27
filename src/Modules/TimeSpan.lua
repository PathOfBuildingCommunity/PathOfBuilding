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
--- local ts = TimeSpan:fromSec(65)
--- print(ts.getMin()) -- 1
--- print(ts.getSec()) -- 5
--- ```
--- ### Full time values
--- Get the floating full time measures are by calling the `TimeSpan:get*F` functions.
--- They return the value of the `TimeSpan` in the measure specified by the function name.
--- #### Example
--- ```lua
--- local ts = TimeSpan:fromSec(65)
--- print(ts.getMinF()) -- 1.0833333333333
--- print(ts.getSecF()) -- 65
--- ```
--- ## Operators
--- The following operators are implemented for `TimeSpan`:
--- - `+`: Addition
--- - `-`: Subtraction
--- - `*`: Multiplication
--- - `/`: Division
--- - `%`: Modulo
--- - `==`: Equality
--- - `<`: Comparison
--- - `<=`: Comparison
--- ## Parameters
--- ### `ticks`
--- The number of ticks to create the TimeSpan from.
--- ## Remarks
--- Ensures that the ticks value is an integer and smaller than 2^51.
--- @return TimeSpan
--- @param ticks integer
function TimeSpan(ticks)
  if (math.type(ticks) ~= "integer") then
    error(string.format("Invalid ticks value %d, TimeSpan.ticks must always be an integer. Ensure no fraction is used and the absolute number is smaller than 2^51", ticks), 2)
  end

  local self = { ticks = ticks }

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
  function self.divUp(rhs)
    return TimeSpan(math.ceil(self.ticks / rhs.ticks))
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
  function self.min(rhs)
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
  function self.max(rhs)
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
  function self.floor(base)
    return base.mul(self.div(base))
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
  function self.ceil(base)
    return base.mul(self.divUp(base))
  end
  --- # TimeSpan:getUsF
  --- ## Summary
  --- Returns the total number of microseconds of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of microseconds of the current `TimeSpan` as a floating point number.
  function self.getUsF()
    return self.ticks / 10
  end
  --- # TimeSpan:getUs
  --- ## Summary
  --- Returns the number of microseconds in the millisecond of the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  --- The number of microseconds in the millisecond of the current `TimeSpan`.
  function self.getUs()
    return math.floor(self.getUsF() % 1000)
  end
  --- # TimeSpan:getMsF
  --- ## Summary
  --- Returns the total number of milliseconds of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of milliseconds of the current `TimeSpan` as a floating point number.
  function self.getMsF()
    return self.ticks / 10000
  end
  --- # TimeSpan:getMs
  --- ## Summary
  --- Returns the number of milliseconds in the second of the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  --- The number of milliseconds in the second of the current `TimeSpan`.
  function self.getMs()
    return math.floor(self.getMsF() % 1000)
  end
  --- # TimeSpan:getSecF
  --- ## Summary
  --- Returns the total number of seconds of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of seconds of the current `TimeSpan` as a floating point number.
  function self.getSecF()
    return self.ticks / 10000000
  end
  --- # TimeSpan:getSec
  --- ## Summary
  --- Returns the number of seconds in the minute of the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  function self.getSec()
    return math.floor(self.getSecF() % 60)
  end
  --- # TimeSpan:getMinF
  --- ## Summary
  --- Returns the total number of minutes of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of minutes of the current `TimeSpan` as a floating point number.
  function self.getMinF()
    return self.ticks / 600000000
  end
  --- # TimeSpan:getMin
  --- ## Summary
  --- Returns the number of minutes in the hour of the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  function self.getMin()
    return math.floor(self.getMinF() % 60)
  end
  --- # TimeSpan:getHoursF
  --- ## Summary
  --- Returns the total number of hours of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of hours of the current `TimeSpan` as a floating point number.
  function self.getHoursF()
    return self.ticks / 36000000000
  end
  --- # TimeSpan:getHours
  --- ## Summary
  --- Returns the number of hours in the day of the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  --- The number of hours in the day of the current `TimeSpan`.
  function self.getHours()
    return math.floor(self.getHoursF() % 24)
  end
  --- # TimeSpan:getDaysF
  --- ## Summary
  --- Returns the total number of days of the current `TimeSpan` as a floating point number.
  --- ## Returns
  --- @return number
  --- The total number of days of the current `TimeSpan` as a floating point number.
  function self.getDaysF()
    return self.ticks / 864000000000
  end
  --- # TimeSpan:getDays
  --- ## Summary
  --- Returns the number of days in the current `TimeSpan`.
  --- ## Returns
  --- @return integer
  --- The number of days in the current `TimeSpan` without hours, minutes, etc.
  function self.getDays()
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
  function self.getFraction()
    return math.floor(self.ticks % 10000000)
  end
  --- # TimeSpan:toIso
  --- ## Summary
  --- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
  --- ## Returns
  --- @return string
  --- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
  function self.toIso()
    return string.format("%02d.%02d:%02d:%02d.%d", self.getDays(), self.getHours(), self.getMin(), self.getSec(), self.getFraction())
  end
  --- # TimeSpan:toMinSecMs
  --- ## Summary
  --- Returns the current `TimeSpan` in the format `mm:ss.ms`.
  --- ## Returns
  --- @return string
  --- The current `TimeSpan` in the format `mm:ss.ms`.
  function self.toMinSecMs()
    return string.format("%02d:%02d.%d", math.floor(self.min()), self.getSec(), self.getMs())
  end
  --- # TimeSpan:toSecMs
  --- ## Summary
  --- Returns the current `TimeSpan` in the format `ss.ms`.
  --- ## Returns
  --- @return string
  --- The current `TimeSpan` in the format `ss.ms`.
  function self.toSecMs()
    return string.format("%02d.%d", math.floor(self.getSecF()), self.getMs())
  end
  setmetatable(self, {
    --- # TimeSpan:__tostring
    --- ## Summary
    --- Returns the current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
    --- ## Returns
    --- @return string
    --- The current `TimeSpan` in the ISO 8601 format `d.hh:mm:ss.fff*`.
    __tostring = function()
      return self.toIso()
    end,
    --- # TimeSpan:unm
    --- ## Summary
    --- Returns the negated value of the TimeSpan.
    --- ## Returns
    --- A new TimeSpan object with the negated value.
    --- @return TimeSpan
    __unm = function()
      return TimeSpan(-self.ticks)
    end,
    --- # TimeSpan:add
    --- ## Summary
    --- Adds the given TimeSpan to the current TimeSpan.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The TimeSpan to add to the current TimeSpan.
    --- ## Returns
    --- @return TimeSpan
    --- A new TimeSpan object with the added value.
    __add = function(_, rhs)
      return TimeSpan(math.floor(self.ticks + rhs.ticks))
    end,
    --- # TimeSpan:sub
    --- ## Summary
    --- Subtracts the given TimeSpan from the current TimeSpan.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The TimeSpan to subtract from the current TimeSpan.
    --- ## Returns
    --- @return TimeSpan
    --- A new TimeSpan object with the subtracted value.
    __sub = function(_, rhs)
      return TimeSpan(math.floor(self.ticks - rhs.ticks))
    end,
    --- # TimeSpan:mul
    --- ## Summary
    --- Multiplies the current TimeSpan with the given TimeSpan.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The TimeSpan to multiply the current TimeSpan with.
    --- ## Returns
    --- @return TimeSpan
    --- A new TimeSpan object with the multiplied value.
    __mul = function(_, rhs)
      return TimeSpan(math.floor(self.ticks * rhs))
    end,
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
    __div = function(rhs)
      return TimeSpan(self.ticks // rhs.ticks)
    end,    
    --- # TimeSpan:mod
    --- ## Summary
    --- Calculates the modulo of the current `TimeSpan` by the given `TimeSpan`.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The `TimeSpan` to calculate the modulo of the current `TimeSpan` by.
    --- ## Returns
    --- @return TimeSpan
    --- A new `TimeSpan` object with the modulo value.
    __mod = function(_, rhs)
      return TimeSpan(math.floor(self.ticks % rhs.ticks))
    end,
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
    __eq = function(_, rhs)
      return self.ticks == rhs.ticks
    end,
    --- # TimeSpan:lt
    --- ## Summary
    --- Checks if the current `TimeSpan` is less than the given `TimeSpan`.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The TimeSpan to check for less than.
    --- ## Returns
    --- @return boolean
    --- `true` if the current `TimeSpan` is less than the given `TimeSpan`, `false` otherwise.
    __lt = function(_, rhs)
      return self.ticks < rhs.ticks
    end,
    --- # TimeSpan:le
    --- ## Summary
    --- Checks if the current `TimeSpan` is less than or equal to the given `TimeSpan`.
    --- ## Parameters
    --- @param rhs TimeSpan
    --- - `rhs`: The TimeSpan to check for less than or equal to.
    --- ## Returns
    --- @return boolean
    --- `true` if the current `TimeSpan` is less than or equal to the given `TimeSpan`, `false` otherwise.
    __le = function(_, rhs)
      return self.ticks <= rhs.ticks
    end
  })

  return self;
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
function TimeSpanFromUs(us)
  return TimeSpan(math.floor(us * 10))
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
function TimeSpanFromMs(ms)
  return TimeSpan(math.floor(ms * 10000))
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
function TimeSpanFromSec(sec)
  return TimeSpan(math.floor(sec * 10000000))
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
function TimeSpanFromMin(min)
  return TimeSpan(math.floor(min * 600000000))
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
function TimeSpanFromHours(hours)
  return TimeSpan(math.floor(hours * 36000000000))
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
function TimeSpanFromDays(days)
  return TimeSpan(math.floor(days * 864000000000))
end