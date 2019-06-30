local led1 = 3
local led2 = 6
local sw1 = 1
local sw2 = 2

local m
-- local CHANNEL1 = "1421229"
local CHANNEL1 = "1421229/1"
local CHANNEL2 = "1421229/2"

local led1State = gpio.LOW
local led2State = gpio.LOW

gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
gpio.write(led1, gpio.LOW)
gpio.write(led2, gpio.LOW)
gpio.mode(sw1,gpio.INT,gpio.PULLUP)
gpio.mode(sw2,gpio.INT,gpio.PULLUP)


function startMqttClientConnection()
  local clientID = "blip"
  -- m = mqtt.Client("blip", 120)
  m = mqtt.Client(clientID, 120)

--  local mosquitoIP = "test.mosquitto.org"
  local mosquitoIP = "85.119.83.194"
  local port = 1883
  m:connect(mosquitoIP, port, 0,
     -- callback em caso de sucesso
    function(client)
      print("connected")

      gpio.mode(led2, gpio.OUTPUT)
      gpio.write(led2, gpio.LOW)
      gpio.mode(sw2,gpio.INT,gpio.PULLUP)

      gpio.mode(led1, gpio.OUTPUT)
      gpio.write(led1, gpio.LOW)
      gpio.mode(sw1,gpio.INT,gpio.PULLUP)

      function pressedButton1()
          print("Apertei botao 1 \tchn:" .. CHANNEL1)
          -- m:publish("1421229/1", "but1", 0, 1)
          m:publish("1421229/2", "but1", 0, 1)
      end
      function pressedButton2()
          print("Apertei botao 2 \tchn:" .. CHANNEL2)

          m:publish("1421229/2", "but2", 0, 1)
      end
      gpio.trig(sw1, "down", pressedButton1)
      gpio.trig(sw2, "down", pressedButton2)

      -- fç chamada qdo inscrição ok:
      m:subscribe(CHANNEL1, 0,
          function (client)
              print("subscribed to channel /1")
          end,
          --fç chamada em caso de falha:
          function(client, reason)
              print("subscription to /1 failed reason: "..reason)
          end
      )

      -- fç chamada qdo inscrição ok:
      m:subscribe(CHANNEL2, 0,
          function (client)
              print("subscribed to channel /2")
          end,
          --fç chamada em caso de falha:
          function(client, reason)
              print("subscription to /2 failed reason: "..reason)
          end
      )

      m:on("message",
          function(client, topic, data)
              print("CHEGOU NO NODE: T: "..topic.." |D: "..data .. "\n")
              if data == 's' then
                if(led1State == gpio.LOW) then
                    gpio.write(led1, gpio.HIGH)
                    led1State = gpio.HIGH
                else
                    gpio.write(led1, gpio.LOW)
                    led1State = gpio.LOW
                end
              end
              if data == 'a' then
                if(led2State == gpio.LOW) then
                    gpio.write(led2, gpio.HIGH)
                    led2State = gpio.HIGH
                else
                    gpio.write(led2, gpio.LOW)
                    led2State = gpio.LOW
                end
              end
            end
          )

    end,
    -- callback em caso de falha
    function(client, reason)
      print("failed reason: "..reason)
    end
  )
end


wificonf = {
  -- verificar ssid e senha
  ssid = "FamCard",
  pwd = "jl11cl27pt29mc09",
  got_ip_cb = function (con)
                print ("meu IP: ", con.IP)
                startMqttClientConnection()
              end,
  save = false
}

wifi.setmode(wifi.STATION)
wifi.sta.config(wificonf)
