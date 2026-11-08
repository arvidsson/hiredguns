-- Semantic gamepad focus; targets are rebuilt by each scene from current rules.
local Baton = require("src.vendor.baton")
local Input = { mode = "mouse", index = 1, targets = {} }
local players = {}
-- Ordered actions keep simultaneous navigation and confirmation deterministic.
local actions = {
    { "left", "dpleft", { "button:dpleft", "axis:leftx-" } },
    { "right", "dpright", { "button:dpright", "axis:leftx+" } },
    { "up", "dpup", { "button:dpup", "axis:lefty-" } },
    { "down", "dpdown", { "button:dpdown", "axis:lefty+" } },
    { "confirm", "a", { "button:a" } },
    { "cancel", "b", { "button:b" } },
    { "menu", "start", { "button:start" } },
}
-- Poll Baton even while input is blocked so held buttons do not leak through
-- loading screens or window focus changes. Mouse movement remains event-driven.
function Input.update(scene, dispatch, enabled)
    local connected, pending = {}, {}
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            connected[joystick] = true
            local player = players[joystick]
            if not player then
                local controls = {}
                for _, action in ipairs(actions) do
                    controls[action[1]] = action[3]
                end
                player = Baton.new({ controls = controls, joystick = joystick, deadzone = 0.55 })
                players[joystick] = player
            end
            player:update()
            for _, action in ipairs(actions) do
                if player:pressed(action[1]) then
                    pending[#pending + 1] = { joystick = joystick, button = action[2] }
                end
            end
        end
    end
    for joystick in pairs(players) do
        if not connected[joystick] then
            players[joystick] = nil
            if Input.joystick == joystick then
                Input.joystick = nil
                Input.mouse()
            end
        end
    end
    Input.refresh(scene)
    if enabled == false then
        return
    end
    -- Dispatch one action per frame; a confirm cannot also activate the next screen.
    local action = pending[1]
    if action then
        Input.mode, Input.joystick = "gamepad", action.joystick
        dispatch(action.button)
    end
end
function Input.mouse()
    if Input.mode == "gamepad" and Input.scene and Input.scene.inputcancel then
        Input.scene.inputcancel()
    end
    Input.mode = "mouse"
end
function Input.refresh(scene)
    if Input.scene ~= scene then
        if Input.scene and Input.scene.inputcancel then
            Input.scene.inputcancel()
        end
        Input.targets = {}
        Input.index, Input.scene = 1, scene
    end
    local old = Input.targets[Input.index]
    Input.targets = scene and scene.inputTargets and scene.inputTargets() or {}
    if old then
        for i, target in ipairs(Input.targets) do
            if target.id == old.id then
                Input.index = i
                break
            end
        end
    end
    Input.index = math.max(1, math.min(Input.index, #Input.targets))
    local selected = Input.targets[Input.index]
    if Input.mode == "gamepad" and selected and selected.reveal then
        selected.reveal()
    end
end
function Input.position()
    local target = Input.mode == "gamepad" and Input.targets[Input.index]
    if target then
        return target.x, target.y
    end
    if Input.mode == "gamepad" then
        return -1000, -1000
    end
end
function Input.press(scene, button)
    Input.mode = "gamepad"
    Input.refresh(scene)
    if scene and scene.gamepadpressed and scene.gamepadpressed(button) then
        Input.refresh(scene)
        return
    end
    local step = ({ dpleft = -1, dpup = -1, dpright = 1, dpdown = 1 })[button]
    if step and #Input.targets > 0 then
        Input.index = (Input.index - 1 + step) % #Input.targets + 1
    elseif button == "a" then
        local target = Input.targets[Input.index]
        if target and target.activate then
            target.activate()
        end
    end
    Input.refresh(scene)
end
function Input.draw()
    local target = Input.targets[Input.index]
    if Input.mode == "gamepad" and target and target.hideCursor then
        return
    end
    local x, y = Input.position()
    if not x then
        return
    end
    love.graphics.push("all")
    local scale = require("src.viewport").scale()
    love.graphics.scale(scale)
    love.graphics.setColor(1, 0.82, 0.4, 0.95)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, 10)
    love.graphics.pop()
end
-- Reuse button hit testing without a held pointer or drag gesture.
function Input.click(scene, x, y)
    local scale = require("src.viewport").scale()
    scene.mousepressed(x * scale, y * scale, 1)
    scene.mousereleased(x * scale, y * scale, 1)
end
function Input.control(list, scene, control, id)
    if control and control.enabled() then
        local b = control.bounds()
        list[#list + 1] = {
            id = id,
            x = b.x + b.w / 2,
            y = b.y + b.h / 2,
            activate = function()
                Input.click(scene, b.x + b.w / 2, b.y + b.h / 2)
            end,
        }
    end
end
return Input
