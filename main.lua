local Input = require("src.input")
local Scenes = require("src.scenes")

local scenes

function love.load()
    scenes = Scenes.new({
        menu = require("src.scenes.menu").new,
        game = require("src.scenes.game").new,
    })
    scenes:switch("menu")
end

function love.update(dt)
    scenes:dispatch("update", dt)
    local acceptingInput = not scenes.loading and not scenes.transition and love.window.hasFocus()
    Input.update(acceptingInput and scenes.active or nil, function(button)
        Input.press(scenes.active, button)
    end, acceptingInput)
end

function love.draw()
    scenes:dispatch("draw")
    if not scenes.loading and not scenes.transition then
        Input.draw()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "return" and love.keyboard.isDown("lalt", "ralt") then
        if not isrepeat then
            love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        end
        return
    end
    return scenes:dispatch("keypressed", key, scancode, isrepeat)
end

for _, event in ipairs({ "mousepressed", "mousereleased", "mousemoved", "wheelmoved" }) do
    love[event] = function(...)
        Input.mouse()
        return scenes:dispatch(event, ...)
    end
end

function love.resize(width, height)
    scenes:dispatch("resize", width, height)
end

function love.focus(focused)
    scenes:dispatch("focus", focused)
end

function love.quit()
    scenes:destroy()
end
