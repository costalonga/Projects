-- function love.load()
-- 	local img = love.graphics.newImage('Game/Images/boss_attack1.png')
--
-- 	psystem = love.graphics.newParticleSystem(img, 1)
-- 	psystem:setParticleLifetime(4, 6) -- Particles live at least 2s and at most 5s.
-- 	psystem:setEmissionRate(5) -- Sets the amount of particles emitted per second.
-- 	psystem:setSizeVariation(0) -- (0 meaning no variation and 1 meaning full variation between start and end).
-- 	psystem:setLinearAcceleration(0, 120, 0, 160) -- Random movement in all directions.
--   -- variate using wind!!!
-- 	psystem:setColors(1, 1, 1, 1, 1, 1, 1, 0) -- Fade to transparency.
-- end
--
-- function love.draw()
-- 	-- Draw the particle system at the center of the game window.
-- 	love.graphics.draw(psystem, love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
-- end
--
-- function love.update(dt)
-- 	psystem:update(dt)
-- end

local function newObj (x, y)
  local ox = x
  local oy = y
  local objwait = 0
  local step = 100.3
  local speed = 1.5
  local active = true

  -- local img = love.graphics.newImage('Game/Images/boss_attack1.png')
	-- psystem = love.graphics.newParticleSystem(img, 32)
	-- psystem:setParticleLifetime(2, 5) -- Particles live at least 2s and at most 5s.
	-- psystem:setLinearAcceleration(0, 20, 0, 100) -- Randomized movement towards the bottom of the screen.
	-- psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to black.

  local wait = function (seg)
    objwait  = love.timer.getTime() + seg
    coroutine.yield()
  end
  local function make_it_snow ()
    while true do
      oy = oy + step -- *Para variar o "passo" da bullet
      wait(speed) -- *Para variar o tempo de espera/velocidade da bullet
    end
  end
  local function snow ()
    local wrapping = coroutine.create(make_it_snow)
    return function ()
      return coroutine.resume(wrapping)
    end
  end
  return {
    update = snow(),
    getX = function () return ox end,
    getY = function () return oy end,
    getWaitTime = function () return objwait end,
    draw = function ()
      if active then
        psystem:emit(32)
        -- love.graphics.draw(psystem, x, love.graphics.getHeight() * 0.5)
      end
    end
  }
end

function love.load()
  lstobj = {}
  for i=0,5 do
    table.insert(lstobj, newObj(i*150, 0))
  end
  for i=0,5 do
    table.insert(lstobj, newObj((i+60)*100, 50))
  end
	local img = love.graphics.newImage('Game/Images/boss_attack1.png')
	psystem = love.graphics.newParticleSystem(img, 32)
	psystem:setParticleLifetime(0.5, 1) -- Particles live at least 2s and at most 5s.
  psystem:setEmissionRate(5) -- Sets the amount of particles emitted per second.
	psystem:setSizeVariation(0) -- (0 meaning no variation and 1 meaning full variation between start and end).
	psystem:setLinearAcceleration(0, 90, 0, 100) -- Randomized movement towards the bottom of the screen.
	-- psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to black.
	psystem:setColors(1, 1, 1, 1, 1, 1, 1, 0) -- Fade to transparency.
end

function love.draw()
	-- Draw the particle system at the center of the game window.
  for i = 1,#lstobj do
    lstobj[i].draw()
    love.graphics.draw(psystem, lstobj[i].getX(), lstobj[i].getY())
  end
end

function love.update(dt)
  local nowTime = love.timer.getTime()

  for i = 1,#lstobj do
    if lstobj[i].getWaitTime() <= nowTime then
      lstobj[i].update()
    end
  end
	psystem:update(dt)
end

function love.keypressed(key)
	if key == 'space' then
		psystem:emit(32)
	end
end
