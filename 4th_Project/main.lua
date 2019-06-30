local enemiesClass = require("enemies")
local playerClass = require("player")

--                                                                    -- Bullet
local function newBullet (player)
  local sx = player.getXM()
  local sy = player.getY()
  local speed = 0.0005
  local step = 4.5
  local bullet_wait = 0
  local width, height = love.graphics.getDimensions( )
  local size = player.getBulletSize()*1.25
  local bulletImg = love.graphics.newImage("Images/shot.png")
  local radius = (bulletImg:getHeight()/2)*size
  local active = true

  local wait = function (seg)
    bullet_wait = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function up()
    while sy > 0 and active == true do
      sy = sy - step -- *Para variar o "passo" da bullet
      for j = 1,#listabls do
        if listabls[j].affected(sx, sy, radius) then
          active = false
          listabls[j].setHp(-10)
          if listabls[j].getHp() <= 0 then
            table.remove(listabls, j) -- TODO CHANGE HERE TO ALLOW/NOT ALLOW DAMADGE FOR TESTS
            player.incKillCount()
            break
          end
        end
      end
      wait(speed) -- *Para variar o tempo de espera/velocidade da bullet
    end
  end
  local function move ()
    local wrapping = coroutine.create(up)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = move(),
    getSX = function () return sx end,
    getSY = function () return sy end,
    setSX = function (x) sx = x end,
    setSY = function (y) sy = y end,
    getWaitTime = function () return bullet_wait end,
    draw = function ()
      if active then
        love.graphics.draw(bulletImg, sx, sy, 0, size, size, radius, radius)
      end
    end
  }
end


--                                                                     -- Items
local function newItem (sel, existence, iniX1, iniY1, iniX2, iniY2)
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

  local function gotcha (posX1, posY1, posX2, posY2)
    if posX1 < x and posX2 > x then
      if posY1 < y and posY2 > y then
        active = false
        if mode == "inc_speed" then player.incSpeed(0.55)
        elseif mode == "inc_fire_rate" then
          if player.getFireRate() >= 0.1 then
            player.incFireRate(-0.1)
          end
        elseif mode == "dec_fire_rate" then player.incFireRate(0.1)
        elseif mode == "dec_speed" then player.incSpeed(-0.3) end
        return true
      end
      return false
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
      if gotcha(posX1, posY1, posX2, posY2) then
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
local function newItemGenerator (iniX1, iniY1, iniX2, iniY2)
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
      table.insert(lst, newItem(sel, duration, posX1, posY1, posX2, posY2))
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


--                                                                                Keypressed
function love.keypressed(key)
  if key == 'a' then
    local last_shot = player.getLastShot()
    if (last_shot == 0) or (last_shot <= love.timer.getTime()) then
      -- player.incShootSize(0.1)
      player.shoot_bullet()
      local bullet = newBullet(player)
      bullet.setSX(player.getXM())
      table.insert(bullets_list, bullet)
    end
  end
end


--                                                                                LOVE LOAD
function love.load()
  love.window.setTitle("Lua Game")

  font =  {
    normal = love.graphics.setNewFont("Images/Starjedi.ttf", 14),
    large =  love.graphics.setNewFont("Images/Starjedi.ttf", 30)
  }

  titlemenu = {
    play=love.graphics.newImage("Images/play.png"),
    width=0,
    height=0
  }
  titlemenu.width = titlemenu.play:getWidth()
  titlemenu.height = titlemenu.play:getHeight()

  --  Load Images
  bg = {image=love.graphics.newImage("Images/bg.png"), x1=0, y1=0, x2=0, y2=0, width=0, height=0}
  bg.width=bg.image:getWidth()
  bg.height = bg.image:getHeight()

  player =  playerClass.newPlayer()

  local posX1 = player.getX()
  local posY1 = player.getY()
  local posX2 = player.getXR()
  local posY2 = player.getYL()

  item_generator = newItemGenerator(posX1, posY1, posX2, posY2)
  bullets_list = {}
  listabls = {}
  for i = 1, 5 do
    table.insert(listabls, enemiesClass.newBlip(10))
  end
  enemy_fire = enemiesClass.newAttackList(listabls)
end


--                                                                                 LOVE DRAW
function love.draw()
  love.graphics.draw(bg.image, bg.x1, bg.y1)
  love.graphics.draw(bg.image, bg.x2, bg.y2)
  love.graphics.setFont(font.normal)
  love.graphics.print("health: "..player.getHp(), 20, 560)
  love.graphics.print("hits to kill: " ..player.getLV(), 20, 540)
  love.graphics.print('kills: '.. player.getKillCount(), 20, 520)

  player.draw()
  for i = 1,#listabls do
    listabls[i].draw()
  end
  for i = 1,#bullets_list do
    bullets_list[i].draw()
  end
  local attack_lst = enemy_fire.getEnemyFireList()
  for i=1,#attack_lst do
    attack_lst[i].draw()
  end
  local items_lst = item_generator.getItemsList()
  for i=1,#items_lst do
    items_lst[i].draw()
  end
end


--                                                                                LOVE UPDATE
function love.update(dt)

  local nowTime = love.timer.getTime()

  -- Update Player
  player.update(dt)

  -- Update Items
  if item_generator.getWaitTime() <= nowTime then
    -- time between items creation
    -- Initialize with Player Position to know if item was caught
    item_generator.setX1(player.getX())
    item_generator.setX2(player.getXR())
    item_generator.setY1(player.getY())
    item_generator.setY2(player.getYL())
    item_generator.update()
  end
  local items_lst = item_generator.getItemsList()
  for i = #items_lst,1,-1 do
    if items_lst[i].getInactiveTime() <= nowTime then
      -- Update Player Position to know if item was caught
      items_lst[i].setX1(player.getX())
      items_lst[i].setX2(player.getXR())
      items_lst[i].setY1(player.getY())
      items_lst[i].setY2(player.getYL())
      local status = items_lst[i].update()

      if status == false then
        item_generator.removeItem(i)
      end
    end
  end

  for i = 1,#listabls do
    if listabls[i].getInactiveTime() <= nowTime then
      listabls[i].update()
    end
  end
  if #listabls == 0 then
    player.incLV()
    local level = player.getLV()
    for i=1, 5*level do
      listabls[i] = enemiesClass.newBlip(level * 10 )
    end
  end

  -- Update Bullets
  for i = #bullets_list,1,-1 do
    if bullets_list[i].getWaitTime() <= nowTime then
      local status = bullets_list[i].update(posX1, posY1, posX2, posY2) -- TODO: test
      if status == false then
        table.remove(bullets_list, i)
      end
    end
  end

  -- Update Enemy's attack, using two coroutines! One for shot speed and other as timer
  if enemy_fire.getWaitTime() <= nowTime then
    -- Wait time between blips shots
    enemy_fire.update()
  end
  local attack_lst = enemy_fire.getEnemyFireList()
  -- Blips bullet speed
  for i=#attack_lst,1,-1 do
    if attack_lst[i].getWaitTime() <= nowTime then
      local status = attack_lst[i].update()
      if status == false then
        enemy_fire.removeEnemyFireList(i)
      end
    end
  end
end
