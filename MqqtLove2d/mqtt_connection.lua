local led1 = 3
local led2 = 6
local sw1 = 1
local sw2 = 2

local led1State = gpio.LOW
local ledState2 = gpio.LOW

local channel = "1421229"
local m

wificonf = {
    -- verificar ssid e senha
    ssid = "FamCard",
    pwd = "jl11cl27pt29mc09",
    got_ip_cb = function (con)
        print ("meu IP: ", con.IP)

        m = mqtt.Client("blip", 120)
        -- conecta com servidor mqtt na máquina 'ipbroker' e porta 1883:
        m:connect("85.119.83.194", 1883, 0,
            -- callback em caso de sucesso
            function(client)
                print("connected")

                m:on("message",
                    function(client, topic, data)
                        print(topic .. ":" )
                        if (data == 'a' or data == 's') then
                          print(data)
                        end
                        if data == 'a' then
                          if(led1State == gpio.LOW) then
                              gpio.write(led1, gpio.HIGH)
                              led1State = gpio.HIGH
                          else
                              gpio.write(led1, gpio.LOW)
                              led1State = gpio.LOW
                          end
                        end
                    end
                )

                m:subscribe(channel, 0,
                    -- fç chamada qdo inscrição ok:
                    function (client)
                        print("subscribe success")
                        gpio.mode(led1, gpio.OUTPUT)

                        gpio.write(led1, gpio.LOW)

                        gpio.mode(sw1,gpio.INT,gpio.PULLUP)
                        gpio.mode(sw2,gpio.INT,gpio.PULLUP)

                        function pressedButton1()
                            print("Apertei botao 1")
                            m:publish(channel, "apertei1", 0, 1)
                        end

                        function pressedButton2()
                            print("Apertei botao 2")
                            m:publish(channel, "apertei2", 0, 1)
                        end

                        gpio.trig(sw1, "down", pressedButton1)
                        gpio.trig(sw2, "down", pressedButton2)
                    end,
                    --fç chamada em caso de falha:
                    function(client, reason)
                        print("subscription failed reason: "..reason)
                    end
                )
            end,
            -- callback em caso de falha
            function(client, reason)
                print("connection failed reason: "..reason)
            end
        )
    end,
    save = false
}

wifi.setmode(wifi.STATION)
wifi.sta.config(wificonf)
