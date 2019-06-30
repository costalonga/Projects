local ITEMS = {}

--                                                                     -- Items
function ITEMS.newItem (sel, existence)
  local width, height = love.graphics.getDimensions()
  local radius = 7.5
  local x = love.math.random(radius*4, width - 4*radius)
  local y = love.math.random(height/5, height - 4*radius)
  local clock = 0.25
  local inactiveTime = 0
  local modes = { "inc_speed", "inc_fire_rate", "dec_fire_rate", "dec_speed"}
  local mode = modes[sel]
  local blink_mode = {"fill","line"}
  local blink = 0
  local active = true
  local created = love.timer.getTime()

  local function gotcha (posX1, posY1, posX2, posY2)
    if posX1 < x and posX2 > x then
      if posY1 < y and posY2 > y then
        active = false

        if mode == "inc_speed" then player.incSpeed(0.55)
        elseif mode == "inc_fire_rate" then
          if player.getFireRate() >= 0.1 then player.incFireRate(-0.1) end
        elseif mode == "dec_fire_rate" then player.incFireRate(0.1)
        elseif mode == "dec_speed" then player.incSpeed(-0.3) end

        -- if mode == "inc_speed" then return 0.55

        return true
      end
      return false
    end
  end

  local wait = function (seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end

  local function stay(posX1, posY1, posX2, posY2)
    while (created+existence) > love.timer.getTime() do
      -- make it blink
      blink = bit.band(1,blink+1) -- bitwise: 1 & blink+1
      local posX1 = player.getX()
      local posY1 = player.getY()
      local posX2 = player.getXR()
      local posY2 = player.getYL()
      -- Check if player caught item
      if gotcha(posX1, posY1, posX2, posY2) then
        active = false
        break
      end
      wait(clock) -- blink frequency
    end
  end

  local function exists (posX1, posY1, posX2, posY2)
    local wrapping = coroutine.create(stay(posX1, posY1, posX2, posY2))
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = exists(),
    getInactiveTime = function () return inactiveTime end,
    draw = function ()
      if active then
        if mode == "inc_speed" then
          love.graphics.arc(blink_mode[blink+1], x, y, radius, 0, math.pi*2)
        elseif mode == "inc_fire_rate" then
          love.graphics.arc(blink_mode[blink+1], x, y, radius+2.5, math.pi/2, math.pi*2)
        elseif mode == "dec_fire_rate" then
          love.graphics.arc(blink_mode[blink+1], x, y, radius+2.5, math.pi/2, 3*math.pi/2)
        elseif mode == "dec_speed" then
          love.graphics.arc(blink_mode[blink+1], x, y, radius+2.5, 0, math.pi)
        end
      end
    end
  }
end

--                                                       -- Item Generator List
function ITEMS.newItemGenerator ()
  local lst = {}
  local item_respawn = love.math.random(6,8)
  local await_time = love.timer.getTime() + item_respawn -- game starts without items

  local wait = function (seg)
    await_time = love.timer.getTime() + seg
    item_respawn = love.math.random(4,20)
    coroutine.yield()
  end
  local function generate_item()
    while true do
      local sel = love.math.random(1,4)
      local duration = love.math.random(5,15) -- time item will exists
      table.insert(lst, ENEMIES.newItem(sel, duration))
      wait(item_respawn)
    end
  end
  local function startUpdate ()
    local wrapping = coroutine.create(generate_item)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = startUpdate(),
    getWaitTime = function () return await_time end,
    getItemsList = function () return lst end,
    removeItem = function (i) table.remove(lst,i) end,
  }
end

return (ITEMS)
