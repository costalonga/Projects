local BULLET = {}
local curr_directory = "Game/"

--                                                                    -- Bullet
function BULLET.newBullet (pSx, pSy, pBulletSize)
  local sx = pSx
  local sy = pSy
  local size = pBulletSize*1.05

  local speed = 0.0005
  local step = 4.5
  local bullet_wait = 0
  local width, height = love.graphics.getDimensions( )
  local bulletImg = love.graphics.newImage(curr_directory .. "Images/shot.png")
  local radius = (bulletImg:getHeight()/2)*size
  local active = true
  local killed = false

  -- local battle_mode = "blips"

  local wait = function (seg)
    bullet_wait = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function up()
    while sy > 0 and active == true do
      sy = sy - step -- *Para variar o "passo" da bullet

      if curr_battle == "blips" then
        for j = 1,#listabls do
          if listabls[j].affected(sx, sy, radius) then
            active = false
            listabls[j].setHp(-10)
            if listabls[j].getHp() <= 0 then
              table.remove(listabls, j) -- TODO CHANGE HERE TO ALLOW/NOT ALLOW DAMADGE FOR TESTS
              killed = true
              break
            end
          end
        end
      elseif  curr_battle == "boss" then
        for j = 1,#boss_lst do
          if boss_lst[j].affected(sx, sy, radius) then
            active = false
            boss_lst[j].setHp(-1)
            if boss_lst[j].getHp() <= 0 then
              table.remove(boss_lst, j) -- TODO CHANGE HERE TO ALLOW/NOT ALLOW DAMADGE FOR TESTS
              killed = true
              break
            end
          end
        end
      end

      wait(speed) -- *Para variar o tempo de espera/velocidade da bullet
    end
  end
  local function move ()
    local wrapping = coroutine.create(up)
    return function ()
      return coroutine.resume(wrapping)
    end
  end

  return {
    update = move(),
    getSX = function () return sx end,
    getSY = function () return sy end,
    setSX = function (x) sx = x end,
    setSY = function (y) sy = y end,
    isEnemyDead = function () return killed end,

    getWaitTime = function () return bullet_wait end,
    draw = function ()
      if active then
        love.graphics.draw(bulletImg, sx, sy, 0, size, size, radius, radius)
      end
    end
  }
end

return (BULLET)
