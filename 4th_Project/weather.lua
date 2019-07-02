local snow = require("snow")
local rain = require("rain")

local WC = {}

function WC.newWeatherControl ()
  local weather = "clear"
  local dayTime = "day"
  local clarity = "normal"
  local isRaining = false
  local isSnowing = false
  local inactiveTime = 0
  local clock = 0.05

  local wait = function(seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function control()
    while true do
      if isRaining then
        rain.update()
      elseif isSnowing then
        snow:update()
      end
      wait(clock)
    end
  end
  return {
    update = coroutine.wrap(control),
    getInactiveTime = function () return inactiveTime end,
    setWeather = function (w)
      weather = w
      if weather == "raining" then
        if not isRaining then
          rain.startRain(350)
          isRaining = true
          isSnowing = false
        end
      else
        if isRaining then
          rain.stopRain()
          isRaining = false
        end
        if weather == "snowing" then
          if not isSnowing then
            snow:load(width, height, 30)
            isSnowing = true
          end
        elseif weather == "clear" then
          isSnowing = false
          isRaining = false
        end
      end
    end,

    getWeather = function () return weather end,
    getDayTime = function () return dayTime end,
    getClarity = function () return clarity end,
    setDayTime = function (d) dayTime = d end,
    setClarity = function (c) clarity = c end,

    reset = function ()
      newWeather = nil
      newDayTime = nil
      newClarity = nil
    end,

    draw = function ()
      if isRaining then
        rain.draw()
      elseif isSnowing then
        snow.draw()
      end
    end
  }
end

return (WC)
