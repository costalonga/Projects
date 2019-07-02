local PLAYER = {}
local curr_directory = "Game/"
--                                                                    -- Player
function PLAYER.newPlayer ()
  local ship_img_lst = {love.graphics.newImage(curr_directory .. "Images/ship.png"),
    love.graphics.newImage(curr_directory .. "Images/l.png"),
    love.graphics.newImage(curr_directory .. "Images/r.png")}
  local shipImg = ship_img_lst[1]
  local width, height = love.graphics.getDimensions( )
  local x = width/2
  local y = height/2
  local rect_height = shipImg:getHeight()*3/4
  local rect_width = shipImg:getWidth()*3/4

  local modes = {"BATTLING", "NAVIGATING", "DEAD"}
  local curr_mode = modes[1]
  local directions = {"left", "right", "up", "down"}
  local last_direction = ""

  -- TODO GO BACK
  local speed = 2.5
  local fire_rate = 0.5 -- shoot step
  -- TODO test values
  -- local speed = 5.5
  -- local fire_rate = 0.25 -- shoot step

  local last_shot = 0
  local health = 10
  local kill_count = 0
  local level = 1
  local bullet_size = 1

  return {
    update = function (dt)
      -- Make ship look straight if it's not going to left or right
      shipImg = ship_img_lst[1]
      if love.keyboard.isDown('up') then player.incY(-speed) end

      if love.keyboard.isDown('down') then player.incY(speed) end

      if love.keyboard.isDown('left') then
        shipImg = ship_img_lst[2]
        player.incX(-speed)
      end

      if love.keyboard.isDown('right') then
        shipImg = ship_img_lst[3]
        player.incX(speed)
      end
    end,

    getX = function () return x end,
    getXM = function () return x + rect_width/2 end,
    getY = function () return y end,
    getYL = function () return y + rect_height end, -- Y Lower bound
    getXR = function () return x + rect_width end, -- most far right X

    incX = function (nx)
      x = x + nx
      if curr_mode == "BATTLING" then
        if (x + rect_width) > width then
          x = 0 -- player switch sides from right to left
        elseif x < 0 then
          x = width - rect_width -- player switch sides from left to right
        end

      elseif curr_mode == "NAVIGATING" then
        if ((x + rect_width/2) > width) or ((x + rect_width/2) < 0) then
          if (x + rect_width/2) > width then last_direction = "right"
          else last_direction = "left" end

          -- love.timer.sleep(0.1)
          x = width/2
          y = height/2
          curr_mode = "BATTLING"
        end
      end
    end,

    incY = function (ny)
      if curr_mode == "BATTLING" then
        if ((y + ny) >= 0) and (((y + ny) + rect_height) <= height) then
          y = y + ny -- player cant get out of the screen during battles
        end

      elseif curr_mode == "NAVIGATING" then
        y = y + ny
        if ((y + ny) < 0) or (((y + ny) - rect_height/2) > height) then
          if (y + ny) < 0 then last_direction = "up"
          else last_direction = "down" end

          -- love.timer.sleep(0.1)
          x = width/2
          y = height/2
          curr_mode = "BATTLING"
        end
      end
    end,

    getLastShot = function () return last_shot end,
    shoot_bullet = function () last_shot = love.timer.getTime() + fire_rate end,
    getHp = function () return health end,
    setHp = function (hp) health= health + hp end,
    incKillCount = function () kill_count = kill_count + 1 end,
    getKillCount = function () return kill_count end,
    getSpeed = function () return speed end,
    getFireRate = function () return fire_rate end,
    incFireRate = function (i) fire_rate = fire_rate + i end,
    incSpeed = function (vel) speed = speed + vel end,
    incShootSize = function (x) bullet_size = bullet_size + x end,
    getBulletSize = function () return bullet_size end,
    getLV = function () return level end,
    incLV = function () level = level + 1 end,

    getLastDir = function () return last_direction end,
    getMode = function () return curr_mode end,
    setMode = function (m) curr_mode = m end,

    -- Change players attributes if an item is caught
    applyEffect = function (effType, effVal)
      if effType == "inc_speed" then player.incSpeed(effVal)
      elseif effType == "inc_fire_rate" then
        if player.getFireRate() >= 0.1 then
          player.incFireRate(effVal)
        end
      elseif effType == "dec_fire_rate" then player.incFireRate(effVal)
      elseif effType == "dec_speed" then player.incSpeed(effVal) end
    end,

    draw = function ()
      love.graphics.rectangle("line", x, y, rect_width, rect_height)
      -- love.graphics.draw(shipImg, x+(rect_width/4), y, 0, 0.5, 0.5, rect_width/2, 0)
      love.graphics.draw(shipImg, x+(rect_width/3), y, 0, 0.75, 0.75, rect_width/2, 0)
    end
  }
end

return (PLAYER)
