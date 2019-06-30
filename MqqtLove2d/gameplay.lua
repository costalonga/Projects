local function newPlayer ()
  -- local ship_img_lst = {love.graphics.newImage("ship.png"),
  --   love.graphics.newImage("l.png"),
  --   love.graphics.newImage("r.png")}
  -- local shipImg = ship_img_lst[1]
  -- local shipImg = ship_img_lst[1]
  local width, height = love.graphics.getDimensions( )
  local x = 200
  local y = 200

  -- local rect_height = shipImg:getHeight()*3/4
  -- local rect_width = shipImg:getWidth()*3/4
  local rect_height = 250
  local rect_width = 250

  local speed = 2.5
  -- local fire_rate = 0.5 -- shoot step
  -- local last_shot = 0

  -- TODO: delete
  -- local health = 10
  -- local kill_count = 0
  -- local level = 1
  -- local bullet_size = 1

  return {
    update = function (dt)
      -- Make ship look straight if it's not going to left or right
      -- shipImg = ship_img_lst[1]
      if love.keyboard.isDown('up') then player.incY(-speed) end
      if love.keyboard.isDown('down') then player.incY(speed) end
      if love.keyboard.isDown('left') then
        player.incX(-speed)
        -- shipImg = ship_img_lst[2]
      end
      if love.keyboard.isDown('right') then
        player.incX(speed)
        -- shipImg = ship_img_lst[3]
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

    -- TODO: delete
    -- getHp = function () return health end,
    -- setHp = function (hp) health= health + hp end,
    -- incKillCount = function () kill_count = kill_count + 1 end,
    -- getKillCount = function () return kill_count end,
    -- getSpeed = function () return speed end,
    -- getFireRate = function () return fire_rate end,
    -- incFireRate = function (i) fire_rate = fire_rate + i end,
    -- incSpeed = function (vel) speed = speed + vel end,
    -- incShootSize = function (x) bullet_size = bullet_size + x end,
    -- getBulletSize = function () return bullet_size end,
    -- getLV = function () return level end,
    -- incLV = function () level = level + 1 end,

    draw = function ()
      love.graphics.rectangle("line", x, y, rect_width, rect_height)
      -- love.graphics.draw(shipImg, x+(rect_width/4), y, 0, 0.5, 0.5, rect_width/2, 0)
      -- love.graphics.draw(shipImg, x+(rect_width/3), y, 0, 0.75, 0.75, rect_width/2, 0)
    end
  }
end

local mqtt = require("mqtt_library")

local CHANNEL1 = "1421229/1"
local CHANNEL2 = "1421229/2"
local CHANNEL3 = "mcc"
-- local CHANNEL1 = "1421229"
-- local CHANNEL2 = "1421229"

function mqttcb(topic, message)
   print("Received from topic: " .. topic .. " - message:" .. message)
   -- if topic == CHANNEL1 and message == "but1" then
   if topic == CHANNEL2 and message == "but1" then
      controle1 = not controle1
   end
   if topic == CHANNEL2 and message == "but2" then
      controle2 = not controle2
   end

   if topic == CHANNEL3 and message == "butbut" then
      controle3 = not controle3
   end


end

function love.keypressed(key)
  local chan
  if key == 'a' then
    mqtt_client:publish(CHANNEL1, 'a')
--    chan = CHANNEL1 -- Channel 1 VERDE
  end
  if key == 's' then
    mqtt_client:publish(CHANNEL1, 's')
--    chan = CHANNEL2  -- Channel 2 RED
  end

--  local ack = mqtt_client:publish(chan, key)
--  if ack == false then
--    print("FAILED!! Message: " .. key .. " wasnt send to topic: " .. chan)
--  elseif ack == true then
--    print("SUCESS!! Message: " .. key .. " was sent to topic: " .. chan)
--  end
end

--                                        lOVE LOAD
function love.load()
  controle1 = false
  controle2 = false
  controle3 = false
  mqtt_client = mqtt.client.create("85.119.83.194", 1883, mqttcb)

  -- local clientID = "blip"
  local clientID = "player"
  mqtt_client:connect(clientID)
  mqtt_client:subscribe({CHANNEL1, CHANNEL2, CHANNEL3})
  -- mqtt_client:subscribe({CHANNEL1})

  player =  newPlayer()
end

--                                      LOVE DRAW
function love.draw()
   if controle1 then
     love.graphics.rectangle("line", 10, 10, 200, 150)
   end

   if controle2 then
     love.graphics.rectangle("fill", 300, 400, 150, 200)
   end

   if controle3 then
     love.graphics.rectangle("fill", 500, 170, 150, 200)
   end

   player.draw()

end

--                                      LOVE UPDATE
function love.update(dt)
  mqtt_client:handler()
  local nowTime = love.timer.getTime()

  -- Update Player
  player.update(dt)
end
