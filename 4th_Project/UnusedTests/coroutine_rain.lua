-- adapted from: https://github.com/cairobatista/love2d-rain_drop_lst
RAIN = {}

function newRainDrop()
  local ww = love.graphics.getWidth()
  local spread = math.random(50, 255)
  local x = math.random(-20, ww + 20)
  local y = -50
  local size = spread / 255 * 40
  local await_time = 0
  local clock = 10.5
  local rainDrop = {
    p1 = {x = x, y = y},
    p2 = {x = x, y = y + size},
    prof = spread,
  }
  local itsRaining = true -- hallelujah

  local wait = function (seg)
    await_time = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function makeItRain()
    while itsRaining do
      for k, v in ipairs(rain_drop_lst) do
        v.p1.y = v.p1.y + 20 * (v.prof / 255)
        v.p2.y = v.p2.y + 20 * (v.prof / 255)
        if v.p1.y >= wh then
          -- rain_drop_lst[k] = newRainDrop()
          v.p1.y = 0
        end
      end
      wait(clock)
    end
  end

  return {
    update = makeItRain(), -- money to blow
    draw = function ()
      for k, v in ipairs(rain_drop_lst) do
        love.graphics.setColor(28, 93, 155, v.prof)
        love.graphics.line(v.p1.x, v.p1.y, v.p2.x, v.p2.y)
      end
    end
  }
end

--    LOAD
function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)
  rain_drop_lst = {}
  for i = 1, 5 do
    table.insert(rain_drop_lst, newRainDrop())
  end
  love.timer.step()
end

--      DRAW
function love.draw()
  for i = 1,#rain_drop_lst do
    rain_drop_lst[i].draw()
  end
end

--    LOVE UPDATE
function love.update(dt)
  local nowTime = love.timer.getTime()

  for i = 1,#rain_drop_lst do
    if rain_drop_lst[i].getInactiveTime() <= nowTime then
      rain_drop_lst[i].update()
    end
  end
end
