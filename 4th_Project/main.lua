local enemiesClass = require("Game/enemies")
local bulletsClass = require("Game/bullets")
local playerClass = require("Game/player")
local itemsClass = require("Game/items")

--                                                                                Keypressed
function love.keypressed(key)
  if key == 'a' then
    local last_shot = player.getLastShot()
    if (last_shot == 0) or (last_shot <= love.timer.getTime()) then
      -- player.incShootSize(0.1)
      player.shoot_bullet()
      local pSx = player.getXM()
      local pSy = player.getY()
      local pBSize = player.getBulletSize()*1.25
      local bullet = bulletsClass.newBullet(pSx, pSy, pBSize)
      bullet.setSX(player.getXM())
      table.insert(bullets_list, bullet)
    end
  end
end


--                                                                                LOVE LOAD
function love.load()
  love.window.setTitle("Square Invaders")
  font =  {
    normal = love.graphics.setNewFont("Game/Images/Starjedi.ttf", 14),
    large =  love.graphics.setNewFont("Game/Images/Starjedi.ttf", 30)
  }



  --  Load Images
  bg = {image=love.graphics.newImage("Game/Images/bg.png"), x1=0, y1=0, x2=0, y2=0, width=0, height=0}
  bg.width = bg.image:getWidth()
  bg.height = bg.image:getHeight()

  -- TODO
  heightLV = love.graphics.getHeight()
  widthLV = love.graphics.getWidth()
  print("H: " .. heightLV .. "\tW: " .. widthLV)
  TEMP_SWITCH = false

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
  -- TODO adjust Rotation and FLip modes
  -- if TEMP_SWITCH then
  --   --          FLIP
  --   love.graphics.scale(1,-1)
  --   love.graphics.translate(0, -heightLV)
  --
  --   --         MIRROR
  --   -- TODO: Make it as an "Item" just to confuse everything
  --   -- love.graphics.scale(-1, 1)
  --   -- love.graphics.translate(-widthLV, 0)
  --
  --   -- -- rotate around the center of the screen by angle radians
  --   -- love.graphics.translate(-widthLV, 0)
  --   -- local angle = math.pi/2
  --   -- love.graphics.translate(widthLV/2, heightLV/2)
  -- 	-- love.graphics.rotate(angle)
  --   -- love.graphics.translate(-widthLV/2, -heightLV/2)
  --   -- -- love.graphics.translate(-heightLV/2, -widthLV/2)
  --   -- love.graphics.translate(0, 0)
  --
  --   -- love.graphics.scale(-1, 1)
  --   -- love.graphics.translate(-widthLV, 0)
  --
  --   -- love.graphics.rotate( math.pi/2 )
  -- end

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

    --TODO CHANGE
    TEMP_SWITCH = not TEMP_SWITCH
    -- TODO
    local hLV = love.graphics.getHeight()
    local wLV = love.graphics.getWidth()
    print(hLV .. "\t" .. wLV)

    player.incLV()
    local level = player.getLV()
    for i=1, 5*level do
      listabls[i] = enemiesClass.newBlip(level * 10 )
    end
  end

  -- Update Bullets
  for i = #bullets_list,1,-1 do
    if bullets_list[i].getWaitTime() <= nowTime then
      local status = bullets_list[i].update(posX1, posY1, posX2, posY2)
      if status == false then
        if bullets_list[i].isEnemyDead() then
          player.incKillCount()
        end
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
