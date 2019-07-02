RAIN = {}

rain_drop_lst = {}


function RAIN.newRainDrop()
  local spread = math.random(50, 255)
  -- local cor = 50
  local size = spread / 255 * 40
  local x = math.random(-20, width + 20)
  local y = -50
  local rainDrop = {
    p1 = {x = x, y = y},
    p2 = {x = x, y = y + size},
    prof = spread,
  }
  return rainDrop
end

function RAIN.draw()
  for k, v in ipairs(rain_drop_lst) do
    love.graphics.setColor(28, 93, 155, v.prof)
    love.graphics.line(v.p1.x, v.p1.y, v.p2.x, v.p2.y)
  end
end

function RAIN.update()
  for k, v in ipairs(rain_drop_lst) do
    v.p1.y = v.p1.y + 20 * (v.prof / 255)
    v.p2.y = v.p2.y + 20 * (v.prof / 255)
    if v.p1.y >= height + 20 then
      rain_drop_lst[k] = RAIN.newRainDrop()
    end
  end
end


function RAIN.startRain(N)
  for i = 1, N do
    table.insert(rain_drop_lst, RAIN.newRainDrop())
  end
end

function RAIN.stopRain()
  for i = 1, #rain_drop_lst  do
    table.remove(rain_drop_lst, i)
  end
end

return (RAIN)
