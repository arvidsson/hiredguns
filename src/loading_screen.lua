local Loading = {}
Loading.__index = Loading
local worker

function Loading.new(destination)
    return setmetatable({ destination = destination, font = love.graphics.newFont(48), elapsed = 0, drawn = false }, Loading)
end

function Loading:update(dt)
    self.elapsed = self.elapsed + math.max(0, dt)
end

-- Yield only from an active loading job, between complete asset operations.
function Loading.step()
    if worker and coroutine.running() == worker then
        coroutine.yield()
    end
end

function Loading:resume(job)
    self.thread = self.thread or coroutine.create(job)
    worker = self.thread
    local ok, message = coroutine.resume(self.thread)
    worker = nil
    if not ok then
        error(debug.traceback(self.thread, message), 0)
    end
    return coroutine.status(self.thread) == "dead"
end

function Loading:draw()
    local width, height = love.graphics.getDimensions()
    local scale = math.min(width / 1920, height / 1080)
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.clear(0.025, 0.035, 0.038, 1)
    love.graphics.translate(width / 2, height / 2)
    love.graphics.scale(scale)
    love.graphics.setColor(0.88, 0.86, 0.77, 1)
    local label = "Loading"
    local left, top = -self.font:getWidth(label) / 2, -self.font:getHeight() / 2
    love.graphics.printf(label, self.font, left, top, 500, "left")
    love.graphics.printf(string.rep(".", math.floor(self.elapsed / 0.35) % 4), self.font, left + self.font:getWidth(label), top, 100, "left")
    love.graphics.pop()
    self.drawn = true
end

function Loading:destroy()
    self.font:release()
    self.thread = nil
end

return Loading
