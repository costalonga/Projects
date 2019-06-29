local mqtt = require("mqtt_library")

local CHANNEL1 = "mc1"
-- local CHANNEL2 = "mc2"

function mqttcb(topic, message)
   print("Received from topic: " .. topic .. " - message:" .. message)
   if topic == "mc1" then
      controle1 = not controle1
   elseif topic == "mc2" then
      controle2 = not controle2
   end
end

function love.keypressed(key)
  -- Channel 1
  if key == 'a' then
    mqtt_client:publish(CHANNEL1, "a")
  end
  if key == 's' then
    mqtt_client:publish(CHANNEL1, "s")
  end

  -- -- Channel 2
  -- if key == 'q' then
  --   mqtt_client:publish(CHANNEL2, "w")
  -- end
  -- if key == 'w' then
  --   mqtt_client:publish(CHANNEL2, "q")
  -- end

end

function love.load()
  controle1 = false
  mqtt_client = mqtt.client.create("85.119.83.194", 1883, mqttcb)
  mqtt_client:connect("cliente love 1")
  -- mqtt_client:subscribe({CHANNEL1, CHANNEL2})
  mqtt_client:subscribe({CHANNEL1})
end

function love.draw()
   if controle1 then
     love.graphics.rectangle("line", 10, 10, 200, 150)
   end

   if controle2 then
     love.graphics.rectangle("fill", 300, 300, 150, 200)
   end
end

function love.update(dt)
  mqtt_client:handler()
end
