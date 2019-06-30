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
end

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
end

function love.update(dt)
  mqtt_client:handler()
end
