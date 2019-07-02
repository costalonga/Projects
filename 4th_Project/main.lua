local enemiesClass = require("Game/enemies")
local bulletsClass = require("Game/bullets")
local playerClass = require("Game/player")
local itemsClass = require("Game/items")
local bossClass = require("Game/bosses")
local mqtt = require("mqtt_library")
local env  = require("envFile")
local snow = require("snow")
local rain = require("rain")


local function newWeatherControl ()
  local weather = "clear"
  local dayTime = "day"
  local clarity = "normal"
  local isRaining = false
  local isSnowing = false
  local inactiveTime = 0
  local clock = 0.05

  local wait = function(seg)
    inactiveTime = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function control()
    while true do
      if isRaining then
        rain.update()
      elseif isSnowing then
        snow:update()
      end
      wait(clock)
    end
  end
  return {
    update = coroutine.wrap(control),
    getInactiveTime = function () return inactiveTime end,
    setWeather = function (w)
      weather = w
      if weather == "raining" then
        if not isRaining then
          rain.startRain(350)
          isRaining = true
          isSnowing = false
        end
      else
        if isRaining then
          rain.stopRain()
          isRaining = false
        end
        if weather == "snowing" then
          if not isSnowing then
            snow:load(width, height, 30)
            isSnowing = true
          end
        elseif weather == "clear" then
          isSnowing = false
          isRaining = false
        end
      end
    end,

    getWeather = function () return weather end,
    getDayTime = function () return dayTime end,
    getClarity = function () return clarity end,

    setDayTime = function (d) dayTime = d end,
    setClarity = function (c) clarity = c end,

    reset = function ()
      newWeather = nil
      newDayTime = nil
      newClarity = nil
    end,

    draw = function ()
      if isRaining then
        rain.draw()
      elseif isSnowing then
        snow.draw()
      end
    end
  }
end


-- aux function to check if an item is in an list
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- TODO HERE initialize properly
weather_mode = "raining"
dayTime_mode = "day"
clarity_mode = "normal"

function mqttcb(topic, message)
  if curr_mode == "WAITING" then
    if topic == "Weather" then
      local weather_modes = Set {"raining", "snowing", "clear"}
      -- Asserts that subscriber received a valid message
      if weather_modes[message] then
        print("WEATHER: " .. message)
        weather_control.setWeather(message)
        ack1 = true
      end
    end

    if topic == "DayTime" then
      local dayTime_modes = Set {"day", "night"}
      -- Asserts that subscriber received a valid message
      if dayTime_modes[message] then
        print("TIME: " .. message)
        weather_control.setDayTime(message)
        ack2 = true
      end
     end

    if topic == "Clarity" then
      local clarity_modes = Set {"low", "normal", "high"}
      -- Asserts that subscriber received a valid message
      if clarity_modes[message] then
        print("CLARITY: " .. message)
        weather_control.setClarity(message)
        ack3 = true
      end
    end

    -- if weather_mode ~= nil and dayTime_mode ~= nil and clarity_mode ~= nil then
    if ack1 and ack2 and ack3 then
      mqtt_client:disconnect()
      curr_mode = "LOADING"
    else
      curr_mode = "REQUESTING"
    end
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

  mqtt_client = mqtt.client.create("85.119.83.194", 1883, mqttcb)


  width = love.graphics.getWidth()
  height = love.graphics.getHeight()

  -- TODO TESTE MODE to switch
  switch = false

  game_modes = {"BATTLING", "NAVIGATING", "REQUESTING", "WAITING", "LOADING"}
  curr_mode = "BATTLING"
  battle_modes = {"blips", "boss"}
  curr_battle = battle_modes[1]

  weather_control = newWeatherControl()

  local curr_directory = "Game/"
  counter = 1
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
  -- if not switch then
  if daytime_mode == "night" then -- TODO TODO
    if curr_mode == "BATTLING" then
      alpha = alpha/2

      rect_width = 48
      rect_height = 48
      -- TODO
      -- rect_height = 48*1.5 -- great
      -- rect_height = 48     -- good
      -- rect_height = 48/1.5 -- bad

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

    weather_control.draw()
  end
end

--                                                                                LOVE UPDATE
function love.update(dt)
    -- Update Player
    player.update(dt)

    local nowTime = love.timer.getTime()
    if weather_control.getInactiveTime() <= nowTime then
      weather_control.update()
    end

    if curr_mode == "BATTLING" then
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
      if counter == #bg_img_lst then counter = 1 end -- reset counter
      bg = {image=bg_img_lst[counter], x1=0, y1=0, x2=0, y2=0, width=0, height=0}
      bg.width = bg.image:getWidth()
      bg.height = bg.image:getHeight()
      -- curr_mode = player.getMode()

      -- TODO TODO
      local clientID = "square_invaders"
      mqtt_client:connect(clientID)
      mqtt_client:subscribe({"DayTime", "Weather", "Clarity"})

      ack1 = false
      ack2 = false
      ack3 = false

      curr_mode = "REQUESTING"

    end

  elseif curr_mode == "REQUESTING" then
    mqtt_client:handler()
    mqtt_client:publish("request", "weather_status")
    curr_mode = "WAITING"
  elseif curr_mode == "WAITING" then
    mqtt_client:handler()

  elseif curr_mode == "LOADING" then
    curr_mode = "BATTLING"
    -- mqtt_client:handler()
  end
end
