local ITEMS = {}

--                                                                     -- Items
function ITEMS.newItem (sel, existence, iniX1, iniY1, iniX2, iniY2)
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

  local posX1 = iniX1
  local posY1 = iniY1
  local posX2 = iniX2
  local posY2 = iniY2

  local caught = false
  local effect_value = 0

  local function gotcha (posX1, posY1, posX2, posY2)
    if posX1 < x and posX2 > x then
      if posY1 < y and posY2 > y then
        active = false

        -- TODO: change effects inc to real value but wait untill test finishes
        if mode == "inc_speed" then
          -- effect_value = 0.55
          effect_value = 1.55

        elseif mode == "inc_fire_rate" then
          -- effect_value = -0.1
          effect_value = -0.55

        elseif mode == "dec_fire_rate" then
          -- effect_value = 0.1
          effect_value = 0.25

        elseif mode == "dec_speed" then
          -- effect_value = -0.3
          effect_value = -0.55
        end
        caught = true
      end
    end
  end

  local wait = function (seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end

  local function stay()
    while (created+existence) > love.timer.getTime() do
      -- make it blink
      blink = bit.band(1,blink+1) -- bitwise: 1 & blink+1

      gotcha(posX1, posY1, posX2, posY2)
      if caught then
        active = false
        break
      end
      wait(clock) -- blink frequency
    end
  end

  local function exists ()

    local wrapping = coroutine.create(stay)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = exists(),
    getInactiveTime = function () return inactiveTime end,

    setX1 = function (pos) posX1 = pos end,
    setY1 = function (pos) posY1 = pos end,
    setX2 = function (pos) posX2 = pos end,
    setY2 = function (pos) posY2 = pos end,

    getEffectType = function () return mode end,
    getEffectValue = function () return effect_value end,
    CaughtIt = function () return caught end,

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
function ITEMS.newItemGenerator (iniX1, iniY1, iniX2, iniY2)
  local lst = {}
  -- local item_respawn = love.math.random(6,8) -- TODO
  local item_respawn = love.math.random(2,3)
  local await_time = love.timer.getTime() + item_respawn -- game starts without items

  local posX1 = iniX1
  local posY1 = iniY1
  local posX2 = iniX2
  local posY2 = iniY2

  local wait = function (seg)
    await_time = love.timer.getTime() + seg
    -- item_respawn = love.math.random(4,20) -- TODO
    item_respawn = love.math.random(4,7)

    coroutine.yield()
  end
  local function generate_item()
    while true do
      local sel = love.math.random(1,4)
      local duration = love.math.random(5,15) -- time item will exists
      table.insert(lst, ITEMS.newItem(sel, duration, posX1, posY1, posX2, posY2))
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

    setX1 = function (pos) posX1 = pos end,
    setY1 = function (pos) posY1 = pos end,
    setX2 = function (pos) posX2 = pos end,
    setY2 = function (pos) posY2 = pos end,

    getWaitTime = function () return await_time end,
    getItemsList = function () return lst end,
    removeItem = function (i) table.remove(lst,i) end,
  }
end

return (ITEMS)
