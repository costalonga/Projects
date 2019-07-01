local BOSS = {}
local curr_directory = "Game/"

--                                                                      -- Boss
function BOSS.newBoss ()
  local width, height = love.graphics.getDimensions( )
  local x = love.math.random(0, width)
  local y = 5
  local inactiveTime = 0
  local clock = love.math.random(1, 2) / love.math.random(4, 6)
  local step = love.math.random(5, 15)

  local health = love.math.random(75, 125)

  local change_dir = false
  local div_list = {5, 10, 15, 20, 25, 30}
  local random_div = love.math.random(1, #div_list)
  local divN = div_list[random_div]

  -- local blipImg = love.graphics.newImage(curr_directory .. "Images/blips.jpg")
  local size = 2.25 -- blip.getBulletSize()0.25

  -- TODO LATER
  -- local rect_height = love.math.random(75, 150)
  -- local rect_width = love.math.random(100, 200)

  local square_size = love.math.random(75, 200)

  local wait = function (seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end

  local function up()
    while true do
      step = love.math.random(0, 20)
      if (x + step + square_size >= width) then
        change_dir = false
      elseif (x - step <= 0) then
        change_dir = true
      end
      if change_dir then
        x = x + step
      else
        x = x - step
      end

      random_div = love.math.random(1, #div_list)
      divN = div_list[random_div]
      clock = love.math.random(1, 2) / divN
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
      love.graphics.rectangle("fill", x, y, square_size, square_size)
    end
  }
end


--                                                                    -- Attack
function BOSS.newAttack (blipXM, blipYL)
  local x = blipXM
  local y = blipYL
  local step = love.math.random(2,6)
  local speed_list = {0.001, 0.0025, 0.04, 0.06, 0.15, 0.2}
  local random_speed = love.math.random(1, #speed_list)
  local speed = speed_list[random_speed]
  local status = true
  local attack_wait = 0
  local width, height = love.graphics.getDimensions()
  local playerDamadge = -1
  -- local blipShotImg = love.graphics.newImage(curr_directory .. "Images/boss_atack.png")
  local blipShotImg = love.graphics.newImage(curr_directory .. "Images/blipshot.png")

  local size = 4 -- blip.getBulletSize()
  local radius = (blipShotImg:getHeight()/2)*1

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
      random_speed = love.math.random(1, #speed_list)
      speed = speed_list[random_speed]
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
function BOSS.newAttackList (listabls)
  local lst = {}
  local speed_list = {0.0125, 0.025, 0.075, 0.25, 0.5}
  local random_speed = love.math.random(1, #speed_list)
  local shot_cooldown = speed_list[random_speed] -- Time between boss shots!
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
        table.insert(lst, BOSS.newAttack(blpXM, blpYL))
      end
      random_speed = love.math.random(1, #speed_list)
      shot_cooldown = speed_list[random_speed] -- Time between boss shots!
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

return (BOSS)
