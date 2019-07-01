-- -- TODO TESTING
-- local light = require("lights")
-- -- light.addLight(x, y, size, r, g, b)
-- -- light.clearLights()


local enemiesClass = require("Game/enemies")
local bulletsClass = require("Game/bullets")
local playerClass = require("Game/player")
local itemsClass = require("Game/items")

local env = require("envFile")

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

  -- TODO TESTE MODE
  switch = false

  -- TODO USE MQTT CHANNELS TO CHANGE HERE
  game_modes = {"BATTLING", "NAVIGATING", "LOADING"}
  curr_mode = "BATTLING"

  love.window.setTitle("Square Invaders")
  font =  {
    normal = love.graphics.setNewFont("Game/Images/Starjedi.ttf", 14),
    large =  love.graphics.setNewFont("Game/Images/Starjedi.ttf", 30)
  }

  --  Load Images
  bg = {image=love.graphics.newImage("Game/Images/bg.png"), x1=0, y1=0, x2=0, y2=0, width=0, height=0}
  bg.width = bg.image:getWidth()
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

  print(love.graphics.getColor( ))

end


--                                                                                 LOVE DRAW
function love.draw()

  local alpha = 1
  local blip_color = 1
  local rect_width = bg.width
  local rect_height = bg.height
  local x = player.getX()
  local y = player.getY()

  -- -- TODO SET MODE
  if switch then
    alpha = alpha/2
    rect_width = 48
    rect_height = 48
    blip_color = 1
    -- print("IN SWITCH")
    -- love.graphics.setColor(5, 0, -245, 1)
    -- love.graphics.setColor(0, 250, 0, 0.25)
  -- else
    -- love.graphics.setColor(1, 1, 1, 1)
  end

  -- TODO : Adjust so this variable are initialize by Player Position and variate according to the Light from nodeMCU
  love.graphics.stencil(function ()
                          love.graphics.rectangle("fill", x - 15*rect_width/8,
                                                          y - 5*rect_height,
                                                          5*rect_width,
                                                          8*rect_height)
                        end,
                        "replace", 1, false)
  love.graphics.setStencilTest("greater", 0)
  -- love.graphics.circle("fill", 30, 30, 20)

  love.graphics.draw(bg.image, bg.x1, bg.y1)
  love.graphics.draw(bg.image, bg.x2, bg.y2)
  love.graphics.setFont(font.normal)
  love.graphics.print("health: "..player.getHp(), 20, 560)
  love.graphics.print("hits to kill: " ..player.getLV(), 20, 540)
  love.graphics.print('kills: '.. player.getKillCount(), 20, 520)

  love.graphics.setColor(1, 1, 1, 1)
  player.draw()

  love.graphics.setColor(1, 1, blip_color, aplha)
  for i = 1,#listabls do
    listabls[i].draw()
  end

  -- love.graphics.setColor(0, 0, 250) -- TODO: Invisible
  love.graphics.setColor(1, 1, 1, 1)
  for i = 1,#bullets_list do
    bullets_list[i].draw()
  end

  love.graphics.setColor(0, 250, 0, alpha)
  local attack_lst = enemy_fire.getEnemyFireList()
  for i=1,#attack_lst do
    attack_lst[i].draw()
  end

  love.graphics.setColor(250, 0, 0, 1)
  local items_lst = item_generator.getItemsList()
  for i=1,#items_lst do
    items_lst[i].draw()
  end

  love.graphics.setColor(1, 1, 1, 1)
end


--                                                                                LOVE UPDATE
function love.update(dt)

    if curr_mode == "BATTLING" then

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

      -- TODO TEST MODE
      switch = not switch

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

  -- TODO
  -- elseif curr_mode == "NAVIGATING" then
  --
  -- elseif curr_mode == "LOADING" then

  end

end
