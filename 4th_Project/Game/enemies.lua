local ENEMIES = {}
local curr_directory = "Game/"

--                                                                      -- Blip
function ENEMIES.newBlip (life)
  local square_size = 20
  local width, height = love.graphics.getDimensions( )
  local x = love.math.random(0, width)
  local Yrows = {0, 25, 50, 75, 100}
  local y = Yrows[love.math.random(1, 5)]
  local inactiveTime = 0
  local clock = love.math.random(2, 4) / love.math.random(4, 6)
  local step = love.math.random(5, 12)
  local health = life

  local blipImg = love.graphics.newImage(curr_directory .. "Images/blips.jpg")
  local size = 0.25 -- blip.getBulletSize()0.25
  local rect_height = (blipImg:getHeight())*size
  local rect_width = (blipImg:getWidth())*size

  local wait = function (seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end

  local function up()
    while true do
      if y % 2 == 0 then -- If blip is in row 0, 50 or 100 : Left To Right direction
        x = x + step
        if x+square_size > width then
          x = 0
        end
      else -- Else Right To Left direction
        x = x - step
        if x-square_size < 0 then
          x = width
        end
      end
      wait(clock)
    end
  end
  return {
    update = coroutine.wrap(up),
    affected = function (posX, posY, radius)
      if (posX + radius) >= x and (posX - radius) <= x+square_size then
        if (posY + radius) >= y and (posY - radius) <= y+square_size then
          --          "pegou" o blip
          return true
        end
      else
        return false
      end
    end,
    getXM = function () return x + square_size/2 end, -- Mid X
    getYL = function () return y + square_size end, -- Lower Y
    getHp = function () return health end,
    setHp = function (hp) health = health + hp end,
    getInactiveTime = function () return inactiveTime end,

    draw = function ()
      -- love.graphics.draw(blipImg, x, y, 0, size, size, radius, radius)
--      love.graphics.draw(blipImg, x+(rect_width/3), y, 0, size, size, rect_width/2, 0)
      love.graphics.rectangle("fill", x, y, rect_width, rect_width)
    end
  }
end


--                                                                    -- Attack
function ENEMIES.newAttack (blipXM, blipYL)
  local x = blipXM
  local y = blipYL
  local step = love.math.random(4,6)
  local speed_list = {0.025, 0.03, 0.035, 0.04, 0.045, 0.05}
  local random_speed = love.math.random(1, #speed_list)
  local speed = speed_list[random_speed]
  local status = true
  local attack_wait = 0
  local width, height = love.graphics.getDimensions()
  local playerDamadge = -1
  local blipShotImg = love.graphics.newImage(curr_directory .. "Images/blipshot.png")
  local size = 1 -- blip.getBulletSize()
  local radius = (blipShotImg:getHeight()/2)*size

  local wait = function (seg)
    attack_wait = love.timer.getTime() + seg
    coroutine.yield()
  end

  local collision = function()
    local px = player.getX()
    local py = player.getY()
    local px2 = player.getXR()
    local py2 = player.getYL()
    if (x+radius) >= px and (x-radius) <= px2 then
      if (y+radius) >= py and (y-radius) <=py2 then
        --          "pegou" no player
        player.setHp(playerDamadge)
        return true
      end
    end
    return false
  end

  local function down()
    while status  do
      y = y + step
      if collision() then
        status = false
      end
      if y >= height then
        status = false
      end
      wait(speed)
    end
  end
  local function move ()
    local wrapping = coroutine.create(down)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = move(),
    getX = function () return x end,
    getY = function () return y end,
    setX = function (xi) x = xi end,
    setY = function (yi) y = yi end,
    getWaitTime = function () return attack_wait end,
    setStatus = function (st) status = st end,

    draw = function ()
      if status then
        love.graphics.draw(blipShotImg, x, y, 0, size, size, radius, radius)
      end
    end
  }
end


--                                                          -- Enemy Fire List
function ENEMIES.newAttackList (listabls)
  local lst = {}
  local shot_cooldown = 2.5 -- Time between blips shots!
  local attack_wait = 0

  local wait = function (seg)
    attack_wait = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function start_attack()
    while #listabls >= 1 do
      for i=1,#listabls do
        local blpXM = listabls[i].getXM()
        local blpYL = listabls[i].getYL()
        table.insert(lst, ENEMIES.newAttack(blpXM, blpYL))
      end
      wait(shot_cooldown)
    end
  end
  local function move ()
    local wrapping = coroutine.create(start_attack)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = move(),
    getWaitTime = function () return attack_wait end,
    getEnemyFireList = function () return lst end,
    removeEnemyFireList = function (i) table.remove(lst,i) end,
  }
end

return (ENEMIES)
