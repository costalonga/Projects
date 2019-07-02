
local playerClass = require("mqtt_player")
local mqtt = require("mqtt_library")

local CHANNEL1 = "1421229/1"
local CHANNEL2 = "1421229/2"
local CHANNEL3 = "mcc"
-- local CHANNEL1 = "1421229"
-- local CHANNEL2 = "1421229"

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

function love.keypressed(key)
  local chan = CHANNEL1
  if key == 'a' or key == 's' then
   mqtt_client:publish(chan, key)
  end
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

  -- player =  newPlayer()
  player = playerClass.newPlayer()
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
