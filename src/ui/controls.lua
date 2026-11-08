local Input = require("src.input")
local Viewport = require("src.viewport")

-- Attach shared button handling to a scene. The buttons remain owned by the scene.
local Controls = {}

function Controls.bind(scene, buttons)
    function scene.update()
        for _, button in ipairs(buttons) do
            button:update()
        end
    end

    function scene.focus(focused)
        if not focused then
            for _, button in ipairs(buttons) do
                button:reset()
            end
        end
    end

    function scene.inputcancel()
        scene.focus(false)
    end

    function scene.inputTargets()
        local targets = {}
        for index, button in ipairs(buttons) do
            Input.control(targets, scene, button, index)
        end
        return targets
    end

    for _, event in ipairs({ "mousepressed", "mousereleased" }) do
        scene[event] = function(x, y, mouseButton)
            x, y = Viewport.toLocal(x, y)
            for _, button in ipairs(buttons) do
                button[event](button, x, y, mouseButton)
            end
        end
    end
end

return Controls
