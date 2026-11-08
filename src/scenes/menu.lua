local Button = require("src.ui.button")
local Controls = require("src.ui.controls")
local Viewport = require("src.viewport")

local Menu = {}

function Menu.new(scenes)
    local scene = {}
    local headingFont, buttonFont

    local function play()
        scenes:loadWithScreen("game", function()
            local game = scenes.instances.game
            if game then
                game.reset()
            end
        end)
    end

    local function quit()
        love.event.quit()
    end

    local function bounds(offset)
        local width, height = Viewport.dimensions()
        return { x = width / 2 - 150, y = height / 2 + offset, w = 300, h = 76 }
    end

    local playButton = Button.new(function()
        return bounds(10)
    end, play)
    local quitButton = Button.new(function()
        return bounds(110)
    end, quit)
    Controls.bind(scene, { playButton, quitButton })

    function scene.load()
        headingFont = love.graphics.newFont(72)
        buttonFont = love.graphics.newFont(32)
    end

    function scene.draw()
        love.graphics.clear(0.065, 0.09, 0.12)
        Viewport.beginDraw()
        local width, height = Viewport.dimensions()
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(love.window.getTitle(), headingFont, 0, height / 2 - 135, width, "center")
        playButton:draw("Play", buttonFont)
        quitButton:draw("Quit", buttonFont)
        Viewport.endDraw()
    end

    function scene.keypressed(key, _, isrepeat)
        if isrepeat then
            return
        end
        if key == "return" then
            play()
        elseif key == "escape" then
            quit()
        end
    end

    function scene.quit()
        headingFont:release()
        buttonFont:release()
    end

    return scene
end

return Menu
