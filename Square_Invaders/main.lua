--                                                                      -- Blip
local function newBlip (life)
  local square_size = 20
  local width, height = love.graphics.getDimensions( )
  local x = love.math.random(0, width)
  local Yrows = {0, 25, 50, 75, 100}
  local y = Yrows[love.math.random(1, 5)]
  local inactiveTime = 0
  local clock = love.math.random(2, 4) / love.math.random(4, 6)
  local step = love.math.random(5, 12)
  local health = life

  local blipImg = love.graphics.newImage("blips.jpg")
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


--                                                                    -- Player
local function newPlayer ()
  local ship_img_lst = {love.graphics.newImage("ship.png"),
    love.graphics.newImage("l.png"),
    love.graphics.newImage("r.png")}
  local shipImg = ship_img_lst[1]
  local width, height = love.graphics.getDimensions( )
  local x = 200
  local y = 200
  local rect_height = shipImg:getHeight()*3/4
  local rect_width = shipImg:getWidth()*3/4
  local speed = 2.5
  local fire_rate = 0.5 -- shoot step
  local last_shot = 0
  local health = 10
  local kill_count = 0
  local level = 1
  local bullet_size = 1

  return {
    update = function (dt)
      if health == 0 then
        gamemode = "over"
      end
      -- Make ship look straight if it's not going to left or right
      shipImg = ship_img_lst[1]
      if love.keyboard.isDown('up') then player.incY(-speed) end
      if love.keyboard.isDown('down') then player.incY(speed) end
      if love.keyboard.isDown('left') then
        player.incX(-speed)
        shipImg = ship_img_lst[2]
      end
      if love.keyboard.isDown('right') then
        player.incX(speed)
        shipImg = ship_img_lst[3]
      end

      if (x + rect_width) > width then
        x = 0 -- player switch sides from right to left
      elseif x < 0 then
        x = width - rect_width -- player switch sides from left to right
      end
      if y > (height - rect_height) then
        y = height - rect_height -- player can't go any lower
      end
    end,

    getX = function () return x end,
    getXM = function () return x + rect_width/2 end,
    getY = function () return y end,
    getYL = function () return y + rect_height end, -- Y Lower bound
    getXR = function () return x + rect_width end, -- most far right X
    incX = function (nx) x = x + nx end,
    incY = function (ny) y = y + ny end,
    getLastShot = function () return last_shot end,
    shoot_bullet = function () last_shot = love.timer.getTime() + fire_rate end,
    getHp = function () return health end,
    setHp = function (hp) health= health + hp end,
    incKillCount = function () kill_count = kill_count + 1 end,
    getKillCount = function () return kill_count end,
    getSpeed = function () return speed end,
    getFireRate = function () return fire_rate end,
    incFireRate = function (i) fire_rate = fire_rate + i end,
    incSpeed = function (vel) speed = speed + vel end,
    incShootSize = function (x) bullet_size = bullet_size + x end,
    getBulletSize = function () return bullet_size end,
    getLV = function () return level end,
    incLV = function () level = level + 1 end,

    draw = function ()
      love.graphics.rectangle("line", x, y, rect_width, rect_height)
      -- love.graphics.draw(shipImg, x+(rect_width/4), y, 0, 0.5, 0.5, rect_width/2, 0)
      love.graphics.draw(shipImg, x+(rect_width/3), y, 0, 0.75, 0.75, rect_width/2, 0)
    end
  }
end


--                                                                    -- Bullet
local function newBullet (player)
  local sx = player.getXM()
  local sy = player.getY()
  local speed = 0.0005
  local step = 4.5
  local bullet_wait = 0
  local width, height = love.graphics.getDimensions( )
  local size = player.getBulletSize()*1.25
  local bulletImg = love.graphics.newImage("shot.png")
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


--                                                                    -- Attack
local function newAttack (blipXM, blipYL)
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
  local blipShotImg = love.graphics.newImage("blipshot.png")
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
local function newAttackList ()
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
        table.insert(lst, newAttack(blpXM, blpYL))
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



--                                                                     -- Items
local function newItem (sel, existence)
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

  local function exists ()
    local wrapping = coroutine.create(stay)
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
local function newItemGenerator ()
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
      table.insert(lst,newItem(sel, duration))
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


--    Keypressed
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
  if key == 'p' then
    pause = not pause
  end
end


--      LOAD
function love.load()
  love.window.setTitle("Lua Game")

  font =  {
    normal = love.graphics.setNewFont("Starjedi.ttf", 14),
    large =  love.graphics.setNewFont("Starjedi.ttf", 30)
  }

  titlemenu = {
    play=love.graphics.newImage("play.png"),
    help=love.graphics.newImage("help.png"),
    width=0,
    height=0
  }
  titlemenu.width = titlemenu.play:getWidth()
  titlemenu.height = titlemenu.play:getHeight()


  gamemode = "play"
  pause = false
  help = false

  --  Load Images
  bg = {image=love.graphics.newImage("bg.png"), x1=0, y1=0, x2=0, y2=0, width=0, height=0}
  bg.width=bg.image:getWidth()
  bg.height = bg.image:getHeight()
  helpImg = love.graphics.newImage("instrucoes.png")

  item_generator = newItemGenerator()
  player =  newPlayer()
  bullets_list = {}
  listabls = {}
  for i = 1, 5 do
    table.insert(listabls, newBlip(10))
  end
  enemy_fire = newAttackList()
end


--      DRAW
function love.draw()
  --  Draw Images
  if pause then
    love.graphics.setFont(font.large)
    love.graphics.print("pause", 300, 300)
  else
    -- if gamemode == "menu" then
    --   love.graphics.draw(titlemenu.play, 400-titlemenu.width/2, 100)
    --   love.graphics.draw(titlemenu.help, 400-titlemenu.width/2, 100+ titlemenu.height)

    if gamemode == "play" then
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
    elseif gamemode == "over" then
      love.graphics.setFont(font.large)
      love.graphics.print("game over", 300, 150)
    end
  end

  if help then
    --draw help window
    love.graphics.draw(helpImg, 200,100,0, 0.3,0.3)

    --Cancel button
    love.graphics.setFont(font.large)
    love.graphics.print("Close help", 570, 505, 0, 1,1)

  end
end


--    LOVE UPDATE
function love.update(dt)

  if not pause then
    if gamemode == "play" then
      local nowTime = love.timer.getTime()

      -- Update Player
      player.update(dt)

      -- Update Items
      if item_generator.getWaitTime() <= nowTime then
        -- time between items creation
        item_generator.update()
      end
      local items_lst = item_generator.getItemsList()
      for i = #items_lst,1,-1 do
        if items_lst[i].getInactiveTime() <= nowTime then
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
          listabls[i] = newBlip(level * 10 )
        end
      end

      -- Update Bullets
      for i = #bullets_list,1,-1 do
        if bullets_list[i].getWaitTime() <= nowTime then
          local status = bullets_list[i].update()
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
  end
end

-- function love.mousereleased(x, y, button)
--   if pause == false then
--     if button == 1 then
--       if gamemode == "menu" and not help then
--         if x >= 440-titlemenu.width/2 and x <= 360+titlemenu.width/2 then
--           if y >= 180 and y <= titlemenu.height+20 then
--             gamemode = "play"
--           elseif y >= titlemenu.height + 110 and y <= titlemenu.height*2 - 60 then
--             help = true
--           end
--         end
--       elseif help then
--         if x >= 570 and x <= 770 and y >= 505 and y <= 555 then
--           help = false
--         end
--       end
--
--     end
--   end
-- end
