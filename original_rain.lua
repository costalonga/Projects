-- adapted on: https://github.com/cairobatista/love2d-rain_drop_lst

rain_drop_lst = {}

local ww = love.graphics.getWidth()
local wh = love.graphics.getHeight()

function newRainDrop()

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

function love.load()

  love.graphics.setBackgroundColor(0, 0, 0)

  for i = 0, 1000 do
    table.insert(rain_drop_lst, newRainDrop())
  end
end


function love.draw()
  -- local g = love.graphics

  for k, v in ipairs(rain_drop_lst) do
    love.graphics.setColor(28, 93, 155, v.prof)
    love.graphics.line(v.p1.x, v.p1.y, v.p2.x, v.p2.y)
  end
end

function love.update(dt)
  for k, v in ipairs(rain_drop_lst) do
    v.p1.y = v.p1.y + 20 * (v.prof / 255)
    v.p2.y = v.p2.y + 20 * (v.prof / 255)
    if v.p1.y >= wh + 20 then
      rain_drop_lst[k] = newRainDrop()
    end
  end
end
