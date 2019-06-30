local enemiesClass = require("enemies")
local playerClass = require("player")
local itemsClass = require("items")

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

  item_generator = itemsClass.newItemGenerator(posX1, posY1, posX2, posY2)
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

        -- If player caught item
        -- if effect_value ~= 0 then -- TODO
        if items_lst[i].CaughtIt() then
          local effect_type = items_lst[i].getEffectType()
          local effect_value = items_lst[i].getEffectValue()
          player.applyEffect(effect_type, effect_value)
        end
        print("Effect type: " .. items_lst[i].getEffectType())
        print("Effect value: " .. items_lst[i].getEffectValue())

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
