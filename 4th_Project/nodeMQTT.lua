local led1 = 3
local led2 = 6
local sw1 = 1
local sw2 = 2

-- TODO organize!!
local env = require("envFile")
-- local OWM_API_endpoint = "http://api.openweathermap.org/data/2.5/find?lat=-22.958034&lon=-43.203973&cnt=1&APPID=" .. env.getAPIKey() .. "&units=metric"
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

local ids_lst = {3451190, 519188, 2058645, 1861060, 3833367, 5525208}
local index = 1

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
  m = mqtt.Client(clientID, 120)

--  local mosquitoIP = "test.mosquitto.org"
  local mosquitoIP = "85.119.83.194"
  local port = 1883
  m:connect(mosquitoIP, port, 0,
     -- callback em caso de sucesso
    function(client)
      print("connected")

      -- fç chamada qdo inscrição ok:
      m:subscribe("request", 0,
          function (client)
              print("subscribed to channel request")
          end,
          --fç chamada em caso de falha:
          function(client, reason)
              print("subscription to request failed reason: "..reason)
          end
      )
      m:on("message",
          function(client, topic, data)
              if topic == "request" then
                send_weather_data()
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

gpio.mode(sw1,gpio.INT,gpio.PULLUP)
gpio.mode(sw2,gpio.INT,gpio.PULLUP)

function pressedButton1()
    print("Apertei botao 1")
    m:publish("Weather", "raining", 0, 1)
    m:publish("DayTime", "clear", 0, 1)
    m:publish("Clarity", "high", 0, 1)
end
function pressedButton2()
    print("Apertei botao 2")
    m:publish("Weather", "snowing", 0, 1)
    m:publish("DayTime", "night", 0, 1)
    m:publish("Clarity", "normal", 0, 1)
end
gpio.trig(sw1, "down", pressedButton1)
gpio.trig(sw2, "down", pressedButton2)


function send_weather_data()
    local id = ids_lst[index]
    index = math.random(1, #ids_lst)
    print(id)
    local OWM_API_endpoint = "http://api.openweathermap.org/data/2.5/weather?id=" .. id .. "&APPID=" .. env.getAPIKey() .. "&units=metric"

    print("Requestin Weather Status")
    http.get(OWM_API_endpoint, nil, function(code, data)
      if (code < 0) then
          print("HTTP request failed")
      else
          print("Data: \n", data)
          local resp = sjson.decode(data)
          print(resp)

          local weather_icon = resp["weather"][1]["icon"]
          local weather_index = string.sub(weather_icon, 1, 2)
          print("Region: " .. resp["name"] .. "\nCountry: " .. resp["sys"]["country"])
          weather_status = icons[weather_index]

          local w = ""
          if weather_status == "snow" then
              m:publish("Weather", "snowing", 0, 1)
              w = "snowing"
          elseif weather_status == "shower_rain" or weather_status == "thunderstorm" or weather_status == "rain" then
              m:publish("Weather", "raining", 0, 1)
              w = "raining"
          else
              m:publish("Weather", "clear", 0, 1)
              w = "clear"
          end

          local daytime = string.sub(weather_icon, 3, 3) -- d or n
          local d = ""
          if daytime == 'd' then
            m:publish("DayTime", "day", 0, 1)
            d = "day"
          else
            m:publish("DayTime", "night", 0, 1)
            d = "night"
          end

          local env_brightness = adc.read(0)/10 -- read env brightness
          local c = ""
          if (env_brightness <= 40) then
            m:publish("Clarity", "high", 0, 1)
            c = "high"
          elseif (env_brightness <= 85) then
            m:publish("Clarity", "normal", 0, 1)
            c = "normal"
          else
            m:publish("Clarity", "low", 0, 1)
            c = "low"
          end
          print("Weather: "..w)
          print("Daytime: "..d)
          print("Clarity: "..c.. " = " .. env_brightness .." lx")
    end
  end)
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
