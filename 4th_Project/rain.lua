-- adapted from: https://github.com/cairobatista/love2d-rain_drop_lst
RAIN = {}

function RAIN.newRainDrop()
  local ww = love.graphics.getWidth()
  local spread = math.random(50, 255)
  -- local cor = 50
  local size = spread / 255 * 40
  local x = math.random(-20, ww + 20)
  local y = -50
  local rainDrop = {
    p1 = {x = x, y = y},
    p2 = {x = x, y = y + size},
    prof = spread,
  }
  return rainDrop
end


function RAIN.makeItRain (N) -- money to blow
  local rain_drop_lst = {}
  local await_time = 0
  local clock = 0.5
  -- N == 1000 - heavy rain
  for i = 0, N do
    table.insert(rain_drop_lst, RAIN.newRainDrop())
  end

  local wait = function (seg)
    await_time = love.timer.getTime() + seg
    coroutine.yield()
  end

  local function wetItUp()
    while #listabls >= 1 do
      for i=1,#listabls do
        local blpXM = listabls[i].getXM()
        local blpYL = listabls[i].getYL()
        table.insert(lst, newAttack(blpXM, blpYL))
      end
      wait(clock)
    end
  end
  local function itsRaining ()
    local wrapping = coroutine.create(start_attack)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = itsRaining(), -- hallelujah
    draw = function ()
      for k, v in ipairs(rain_drop_lst) do
        love.graphics.setColor(28, 93, 155, v.prof)
        love.graphics.line(v.p1.x, v.p1.y, v.p2.x, v.p2.y)
      end
    end
  }
end


function love.update(dt)
  for k, v in ipairs(rain_drop_lst) do
    v.p1.y = v.p1.y + 20 * (v.prof / 255)
    v.p2.y = v.p2.y + 20 * (v.prof / 255)
    local wh = love.graphics.getHeight()
    if v.p1.y >= wh + 20 then
      rain_drop_lst[k] = newRainDrop()
    end
  end
end
