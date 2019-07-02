-- The MIT License (MIT)
--
-- Copyright (c) 2016 Brice Thomas
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- from https://github.com/Cowa/love-snowflakes-effect
--
-- Port of the "HTML5 Canvas and Javascript" version to Lua and Löve
-- Original version: http://thecodeplayer.com/walkthrough/html5-canvas-snow-effect
--
local module = {}
local angle = 0.0
local module = {}
local snowParticles = {}

local width, height, maxParticles

function module:load(width, height, maxParticles)
  self.width, self.height, self.maxParticles = width, height, maxParticles

  for i = 1, maxParticles do
    table.insert(snowParticles, {
      x = math.random() * width,
      y = math.random() * height,
      r = math.random() * 4 + 1,
      d = math.random() * maxParticles
    })
  end
end

function module:update(dt)
  angle = angle + 0.01

  for i, p in pairs(snowParticles) do
    p.y = p.y + math.cos(angle + p.d) + 1 + p.r / 2
    p.x = p.x + math.sin(angle) * 2

    if p.y > self.height then
      p.x = math.random() * self.width
      p.y = -10

    elseif p.x > self.width + 5 or p.x < -5 then
      -- Exit from right
      if (math.sin(angle) > 0) then p.x = -5

      -- Exit from left
      else p.x = self.width + 5
      end
    end
  end
end

function module:draw()
  love.graphics.setColor(255, 255, 255, 255)

  for i, p in pairs(snowParticles) do
    love.graphics.circle("fill", p.x, p.y, p.r, 5)
  end
end

return module
