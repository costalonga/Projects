local mqtt = require("mqtt_library")

local channel = "1421229"

function mqttcb(topic, message)
   print("Received from topic: " .. topic .. " - message:" .. message)
   controle = not controle
end

function love.keypressed(key)
  if key == 'a' then
    mqtt_client:publish(channel, "a")
  end
end

function love.load()
  controle = false
  mqtt_client = mqtt.client.create("85.119.83.194", 1883, mqttcb)
  mqtt_client:connect("cliente love 1")
  mqtt_client:subscribe({channel})
end

function love.draw()
   if controle then
     love.graphics.rectangle("line", 10, 10, 200, 150)
   end
end

function love.update(dt)
  mqtt_client:handler()
end
