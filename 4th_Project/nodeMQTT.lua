local led1 = 3
local led2 = 6
local sw1 = 1
local sw2 = 2

-- TODO organize!!
local env = require("envFile")
local OWM_API_endpoint = "http://api.openweathermap.org/data/2.5/weather?id=3451190&APPID=" .. env.getAPIKey() .. "&units=metric"
local icons = {
  ["01"] = "cleark_sky",        -- clear sky
  ["02"] = "few_clouds",        -- few clouds
  ["03"] = "scattered_clouds",  -- scattered clouds
  ["04"] = "broken_clouds",     -- broken clouds
  ["09"] = "shower_rain",       -- shower rain
  ["10"] = "rain",              -- rain
  ["11"] = "thunderstorm",      -- thunderstorm
  ["13"] = "snow",              -- snow
  ["50"] = "mist",              -- mist
}

local CHANNEL1 = "clear"
local CHANNEL2 = "raining"
local CHANNEL3 = "snowing"
local CHANNEL4 = "day_time" -- pass actions via message


local m
local connected = false

local led1State = gpio.LOW
local led2State = gpio.LOW

gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
gpio.write(led1, gpio.LOW)
gpio.write(led2, gpio.LOW)
gpio.mode(sw1,gpio.INT,gpio.PULLUP)
gpio.mode(sw2,gpio.INT,gpio.PULLUP)


function startMqttClientConnection()
  -- m = mqtt.Client("blip", 120)
  m = mqtt.Client(clientID, 120)

--  local mosquitoIP = "test.mosquitto.org"
  local mosquitoIP = "85.119.83.194"
  local port = 1883
  m:connect(mosquitoIP, port, 0,
     -- callback em caso de sucesso
    function(client)
      print("connected")

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
              connected = true
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
                -- m:publish("1421229/2", "butbut", 0, 1)
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

--                          CHANNEL 3
-- function send_data(message)
function send_data()
  if connected then
    print("\n\tSending game data!\n")
    -- local message = "butbut"
    local message = get_weather()
    print("\t\tGet weather return value: " .. message)
    if #message ~= 0 then m:publish("mcc", message, 0, 1) end
  end
end


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


function get_weather()
  print("Requestin Weather Status")
  local r = ""
  http.get(OWM_API_endpoint, nil, function(code, data)
    if (code < 0) then
        print("HTTP request failed")
    else
        print("Data: \n", data)
        r = sjson.decode(data)

        -- local resp = sjson.decode(data)
        -- local weather_icon = resp["weather"][1]["icon"]
        -- local weather_index = string.sub(weather_icon, 1, 2)
        -- weather_status = icons[weather_index]

        -- if first_request == 0 then
        --   rtctime.set(resp.dt + resp.timezone)
        --
        --   rtc_timer = tmr.create() -- 20 sec
        --   rtc_timer:register(20000, tmr.ALARM_AUTO, exibe_time)
        --   rtc_timer:start()
        --   first_request = 1
        -- end
    end
  end)
  return r
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

owm_timer = tmr.create() --15min
--owm_timer:register(60000*15, tmr.ALARM_AUTO, get_weather)
owm_timer:register(5000, tmr.ALARM_AUTO, send_data) -- 10s
owm_timer:start()
