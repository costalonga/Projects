local enemiesClass = require("Game/enemies")
local bulletsClass = require("Game/bullets")
local playerClass = require("Game/player")
local itemsClass = require("Game/items")
local bossClass = require("Game/bosses")
local mqtt = require("mqtt_library")
local env  = require("envFile")
local snow = require("snow")
local rain = require("rain")


function mqttcb(topic, message)
   -- print("Received from topic: " .. topic .. " - message:" .. message)
   -- if topic == CHANNEL1 and message == "but1" then
   if topic == CHANNEL2 and message == "but1" then
      controle1 = not controle1
   end
   if topic == CHANNEL2 and message == "but2" then
      controle2 = not controle2
   end

   -- TODO delete
   -- if topic == CHANNEL3 and message == "butbut" then
   --    controle3 = not controle3
   -- end
   if topic == CHANNEL3 then
      -- message == "butbut"
      print("RECEIVED FROM CHANNEL 3: \n\t" .. message)
      controle3 = not controle3
   end


end

--                                                                                Keypressed
function love.keypressed(key)
  if key == 'a' then
    if curr_mode == "BATTLING" then
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
end

--                                                                                  CLEAR ALL
function clear_all()
  for i = #bullets_list,1,-1 do
    table.remove(bullets_list, i)
  end
  local attack_lst = enemy_fire.getEnemyFireList()

  for i=#attack_lst,1,-1 do
    enemy_fire.removeEnemyFireList(i)
  end

  local items_lst = item_generator.getItemsList()
  for i = #items_lst,1,-1 do
    item_generator.removeItem(i)
  end
end

--                                                                                LOVE LOAD
function love.load()

  -- TODO TESTE MODE
  switch = false

  game_modes = {"BATTLING", "NAVIGATING", "LOADING"}
  curr_mode = "BATTLING"
  battle_modes = {"blips", "boss"}
  curr_battle = battle_modes[1]

  -- TODO HERE
  weather_modes = {"raining", "snowing", "clear"}
  weather_mode = "clear"

  -- Scene size
  width = love.graphics.getWidth()
  height = love.graphics.getHeight()

  rain_drop_lst = {}

  if weather_mode == "raining" then
    -- TODO RAIN
    rain.startRain(350)

  elseif weather_mode == "snowing" then
    -- TODO SNOW
    snow:load(width, height, 30)
  end

  local curr_directory = "Game/"
  bg_img_lst = {love.graphics.newImage(curr_directory .. "Images/bg.png"),
    love.graphics.newImage(curr_directory .. "Images/bg2.png"),
    love.graphics.newImage(curr_directory .. "Images/bg3.png")}

  love.window.setTitle("Square Invaders")
  font =  {
    normal = love.graphics.setNewFont("Game/Images/Starjedi.ttf", 14),
    large =  love.graphics.setNewFont("Game/Images/Starjedi.ttf", 30)
  }

  --  Load Images
  bg = {image=bg_img_lst[counter], x1=0, y1=0, x2=0, y2=0, width=0, height=0}
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

  boss_lst = {}
  boss_fire = bossClass.newAttackList(boss_lst)
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
    if curr_mode == "BATTLING" then
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

  love.graphics.draw(bg.image, bg.x1, bg.y1)
  love.graphics.draw(bg.image, bg.x2, bg.y2)
  love.graphics.setFont(font.normal)
  love.graphics.print("health: "..player.getHp(), 20, 560)
  love.graphics.print("hits to kill: " ..player.getLV(), 20, 540)
  love.graphics.print('kills: '.. player.getKillCount(), 20, 520)

  love.graphics.setColor(1, 1, 1, 1)
  player.draw()

  if curr_mode == "BATTLING" then

    if curr_battle == "blips" then
      love.graphics.setColor(1, 1, blip_color, aplha)
      for i = 1,#listabls do
        listabls[i].draw()
      end
      love.graphics.setColor(0, 250, 0, alpha)
      local attack_lst = enemy_fire.getEnemyFireList()
      for i=1,#attack_lst do
        attack_lst[i].draw()
      end

    elseif curr_battle == "boss" then
      love.graphics.setColor(1, 1, blip_color, aplha)
      for i = 1,#boss_lst do
        boss_lst[i].draw()
      end
      love.graphics.setColor(0, 250, 0, alpha)
      local attack_lst = boss_fire.getEnemyFireList()
      for i=1,#attack_lst do
        attack_lst[i].draw()
      end
    end

    -- love.graphics.setColor(0, 0, 250) -- TODO: Invisible
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1,#bullets_list do
      bullets_list[i].draw()
    end

    love.graphics.setColor(250, 0, 0, 1)
    local items_lst = item_generator.getItemsList()
    for i=1,#items_lst do
      items_lst[i].draw()
    end

    love.graphics.setColor(1, 1, 1, 1)

    if weather_mode == "raining" then
      -- TODO RAIN
      rain.draw()

    elseif weather_mode == "snowing" then
      -- TODO SNOW
      snow:draw()
    end

  end
end


--                                                                                LOVE UPDATE
function love.update(dt)

    -- Update Player
    player.update(dt)

    if weather_mode == "raining" then
      -- TODO RAIN
      rain.update()

    elseif weather_mode == "snowing" then
      -- TODO SNOW
       snow:update(dt)
    end


    if curr_mode == "BATTLING" then
      local nowTime = love.timer.getTime()

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

      -- Update Blips Movement!
      if curr_battle == "blips" then
        for i = 1,#listabls do
          if listabls[i].getInactiveTime() <= nowTime then
            listabls[i].update()
          end
        end
      end

      -- Update Boss Movement!
      if curr_battle == "boss" then
        for i = 1,#boss_lst do
          if boss_lst[i].getInactiveTime() <= nowTime then
            boss_lst[i].update()
          end
        end
      end

      -- Check if player survived level
      if curr_battle == "blips" and #listabls == 0 then
        -- TODO :                                                                       HERE NEW LEVEL
        -- TODO TEST MODE
        switch = not switch
        player.incLV()
        local level = player.getLV()
        if level==3 or level==5 or level==7 or level==11 or level==13 or level==17 then
          curr_battle = "boss"
          print("\n\t\tCREATING BOSS\n")
          table.insert(boss_lst, bossClass.newBoss(level * 10))
          print(#boss_lst, boss_lst)
        else
          for i=1, 5*level do
            listabls[i] = enemiesClass.newBlip(level * 10 )
          end
        end
        -- TODO TEST MODE
        curr_mode = "NAVIGATING"
        clear_all()
        player.setMode(curr_mode)
      end

      -- Check if player won boss battle
      if curr_battle == "boss" and #boss_lst == 0 then
        switch = not switch
        player.incLV()
        local level = player.getLV()
        curr_battle = "blips"
        for i=1, 5*level do
          listabls[i] = enemiesClass.newBlip(level * 10 )
        end
        -- TODO TEST MODE
        curr_mode = "NAVIGATING"
        clear_all()
        player.setMode(curr_mode)
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
      if curr_battle == "blips" then
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

      -- Update Bosses's attack, using two coroutines! One for shot speed and other as timer
      if curr_battle == "boss" then
        if boss_fire.getWaitTime() <= nowTime then
          -- Wait time between blips shots
          boss_fire.update()
        end
        local boss_attack_lst = boss_fire.getEnemyFireList()
        -- Blips bullet speed
        for i=#boss_attack_lst,1,-1 do
          if boss_attack_lst[i].getWaitTime() <= nowTime then
            local status = boss_attack_lst[i].update()
            if status == false then
              boss_fire.removeEnemyFireList(i)
            end
          end
        end
      end

  -- TODO
  elseif curr_mode == "NAVIGATING" then
    if curr_mode ~= player.getMode() then
      counter = counter + 1
      if counter == 4 then counter = 1 end
      bg = {image=bg_img_lst[counter], x1=0, y1=0, x2=0, y2=0, width=0, height=0}
      bg.width = bg.image:getWidth()
      bg.height = bg.image:getHeight()
      curr_mode = player.getMode()
    end

  -- elseif curr_mode == "LOADING" then
  end
end
