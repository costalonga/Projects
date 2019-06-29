local led1 = 3
local led2 = 6
local sw1 = 1
local sw2 = 2

local wifi_ssid = "***********"
local wifi_pwd = "************"
local key = "*****************"
local email_key = "***********"
local weather_key = "*********"
local ifttt_API_url = "*******"
local telegramKey = "*********"

-- lx ok = 30min 70max
local weather_status

--local env_brightness
local first_request = 0

local owm_base_url = "http://api.openweathermap.org/data/2.5/weather?"
local city_id = 3451190 -- or use city_name = "Rio de Janeiro" -> &q=city_name
local OWM_API_endpoint = owm_base_url .. string.format("id=%d&APPID=%s", city_id, weather_key)

gpio.mode(led1, gpio.OUTPUT)
gpio.write(led1, gpio.LOW)
gpio.mode(sw1,gpio.INT,gpio.PULLUP)
gpio.mode(sw2,gpio.INT,gpio.PULLUP)

---- OBS: LINK TO OWM API DOC VALUES: https://openweathermap.org/weather-conditions
icons = {
  ["01"] = 1, -- clear sky
  ["02"] = 2, -- few clouds
  ["03"] = 3, -- scattered clouds
  ["04"] = 4, -- broken clouds
  ["09"] = 9, -- shower rain
  ["10"] = 10, -- rain
  ["11"] = 11, -- thunderstorm
}

function get_hour()
  local tm = rtctime.epoch2cal(rtctime.get())
  local h = tonumber(tm["hour"])
  if h >= 7 and h < 12 then
    return "manha"
  elseif h < 18 then
    return "tarde"
  elseif h < 22 then
    return "noite"
  else
    return "goto_sleep"
  end
end

-- function create_message(weather, curr_time, env_brightness)
function create_message()
  local status = 0
  local message = ""
  local tm = rtctime.epoch2cal(rtctime.get())
  local env_brightness = adc.read(0)/10 -- read env brightness
  local curr_hour = get_hour()

  print("Brightness = ", env_brightness)
  print("Weather = ", weather_status)
  print("Hour = ", curr_hour)

  if (env_brightness <  30) then
    status = 1
    message = "It's too bright in here, close your courtins, turn some lights off!"
  end

  if (env_brightness > 70) then
    if (curr_hour == "manha" or curr_hour == "tarde") then
      status = 1
      message = "It's too dark in here! "
      if (weather_status <= 2) then
        message = message .. "Open your windows, it's sunny outside, don't waste energy!"
      elseif (weather_status == 3) then
        message = message .. "Open your windows, it's not sunny outside, but it's still brighter than here!"
      else
        message = message .. "Turn your lights on!"
      end

    elseif (curr_hour == "noite") then
      status = 1
      message = message .. "Turn your lights on!"
    end
  end

  if (curr_hour == "goto_sleep" and env_brightness <= 70) then
    status = 1
    message = "It's too late, turn your lights off and go to sleep! Take care of your vision!"
    if (weather_status >= 9 and weather_status <= 11) then
      message = message .. " Don't forget to close your windows may rain later!"
    end
  end

  if status == 1 then
    print("\n " .. message .. "\n\n")
    post_tweet(message)
    -- email_send (message)
    -- sendTelegram(message)
  end
  return message
--  print("\n\n\t" .. sjson.encode(message) .. "\n\n")
end



function post_tweet (message)
--  local message = create_message()
--  local message = "testing message"
--  local message = "123"
  print("Posting message on Twitter", message)
  print("cURL: ", ifttt_API_url .. key .. "?value1=" .. message)

  if #message > 0 then
    local tweet_post_url = ifttt_API_url .. key .. "?value1=" .. message
    http.post(tweet_post_url, nil, function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        print(code, "Tweet Posted")
      end
    end)

  else
    print("Everything it's okay, nothing to warn, message wasn't send")
  end
end

function email_send()
  local message = create_message()
  print("Sending message via Email", message)
  print("cURL: ", "https://maker.ifttt.com/trigger/trigger2/with/key/" .. email_key .. "?value1=" .. message)

  if #message > 0 then
    local email_post_url = "https://maker.ifttt.com/trigger/trigger2/with/key/" .. email_key .. "?value1=" .. message
    http.post(email_post_url, nil, function(code, data)
      if (code < 0) then
          print("HTTP request failed")
      else
          print(code, "Email Sent")
      end
    end)

  else
    print("Everything it's okay, nothing to warn, message wasn't send")
  end
end


function sendTelegram()

  local message = create_message()
  print("Seding message on Telegram", message)
  print("cURL: ", "https://maker.ifttt.com/trigger/sendMessage/with/key/" .. telegramKey .. "?value1=" .. message)


  if #message > 0 then
    local telegram_post_url = "https://maker.ifttt.com/trigger/sendMessage/with/key/" .. telegramKey .. "?value1=" .. message
    http.post(telegram_post_url, nil, function(code, data)
      if (code < 0) then
          print("HTTP request failed")
      else
          print(code, "Telegram Message Sent")
      end
    end)
  else
    print("Everything it's okay, nothing to warn, message wasn't send")
  end
end

-- Converts Unix epoch time to readable time
function exibe_time ()
  local tm = rtctime.epoch2cal(rtctime.get())
  print(string.format("%02d/%02d/%04d %02d:%02d:%02d",
                      tm["day"], tm["mon"], tm["year"],
                      tm["hour"], tm["min"], tm["sec"]))
end


function get_weather()
  print("Requestin Weather Status")
  http.get(OWM_API_endpoint, nil, function(code, data)
    if (code < 0) then
        print("HTTP request failed")
    else
        print("Data: \n", data)
        local resp = sjson.decode(data)
        local weather_icon = resp["weather"][1]["icon"]
        local weather_index = string.sub(weather_icon, 1, 2)
        weather_status = icons[weather_index]

        if first_request == 0 then
          rtctime.set(resp.dt + resp.timezone)

          rtc_timer = tmr.create() -- 20 sec
          rtc_timer:register(20000, tmr.ALARM_AUTO, exibe_time)
          rtc_timer:start()

          message_timer = tmr.create() --1min
          message_timer:register(60000, tmr.ALARM_AUTO, create_message)
          message_timer:start()

          first_request = 1
        end
    end
  end)
end

function pressedButton1 ()
  print("But1 Pressed!")
   create_message()
end

function pressedButton2 ()
  print("But2 Pressed!")
  get_weather()
end

-- Set nodeMCU as a wifi.STATION
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=wifi_ssid, pwd=wifi_pwd})

gpio.trig(sw1, "down", pressedButton1)
gpio.trig(sw2, "down", pressedButton2)

owm_timer = tmr.create() --15min
--owm_timer:register(60000*15, tmr.ALARM_AUTO, get_weather)
owm_timer:register(120000, tmr.ALARM_AUTO, get_weather) -- 2min
owm_timer:start()
