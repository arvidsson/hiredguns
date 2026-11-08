local Scenes = {}
Scenes.__index = Scenes
local Transition = require("src.scene_transition")
local Loading = require("src.loading_screen")

function Scenes.new(factories, musicPaths, musicVolumes)
    return setmetatable({ factories = factories, instances = {}, musicPaths = musicPaths or {}, music = {}, musicVolumes = musicVolumes or {}, sourceVolumes = {} }, Scenes)
end

-- Present a lightweight frame before synchronous scene assets begin loading.
-- Other switches stay immediate so callers can prepare an incoming scene.
function Scenes:loadWithScreen(name, prepare)
    if self.loading or self.transition then
        return
    end
    assert(self.factories[name], "Unknown scene: " .. tostring(name))
    if self.active and self.active == self.instances[name] then
        return
    end
    self:dispatch("focus", false)
    self.loading = Loading.new(name)
    self.loading.prepare = prepare
end

-- Prepare a scene without presenting it or starting music/transitions.
function Scenes:load(name)
    local factory = assert(self.factories[name], "Unknown scene: " .. tostring(name))
    if not self.instances[name] then
        local scene = factory(self)
        if scene.load then
            scene.load()
        end
        self.instances[name] = scene
    end
    return self.instances[name]
end

-- Load scenes lazily and retain them so switching preserves their state.
function Scenes:switch(name, outgoing)
    if self.transition or self.loading then
        return
    end
    assert(self.factories[name], "Unknown scene: " .. tostring(name))
    local nextScene = self.instances[name]
    if nextScene and nextScene == self.active then
        return
    end
    local previousScreen = outgoing or self.active
    local transition = previousScreen and Transition.new(previousScreen)
    nextScene = nextScene or self:load(name)
    -- Cancel transient interaction before suspending the outgoing scene.
    self:dispatch("focus", false)
    local previousMusic = self.activeMusic
    local path = self.musicPaths[name]
    local music = path and self.music[path]
    if not music and path then
        music = love.audio.newSource(path, "stream")
        music:setLooping(true)
        self.sourceVolumes[music] = self.musicVolumes[name] or 0.15
        music:setVolume(self.sourceVolumes[music])
        self.music[path] = music
    end
    self.activeMusic = music
    if music and music ~= previousMusic then
        music:setVolume(transition and 0 or self.sourceVolumes[music])
        music:play()
    end
    self.active = nextScene
    self:dispatch("resize", love.graphics.getDimensions())
    if transition then
        self:dispatch("focus", false)
    else
        self:dispatch("focus", love.window.hasFocus())
    end
    self.transition = transition
    self.outgoingMusic = previousMusic ~= music and previousMusic or nil
end

function Scenes:dispatch(event, ...)
    if self.loading then
        if event == "draw" then
            return self.loading:draw()
        elseif event == "update" then
            self.loading:update(...)
            if not self.loading.drawn then
                return
            end
            -- The preceding frame has been presented by LÃ–VE's main loop.
            local loading = self.loading
            self.loading = nil
            -- Capture the visible loading screen, not the suspended menu.
            local done = loading:resume(function()
                local outgoing = self.active and {
                    draw = function()
                        loading:draw()
                    end,
                }
                if loading.prepare then
                    loading.prepare()
                end
                self:switch(loading.destination, outgoing)
            end)
            if done then
                loading:destroy()
            else
                self.loading = loading
            end
        end
        return
    end
    local transition = self.transition
    if transition then
        if event == "draw" then
            return transition:draw(self.active)
        elseif event == "update" then
            local dt = ...
            local done = transition:update(math.min(dt, 0.05))
            local progress = transition:progress()
            if self.outgoingMusic then
                self.outgoingMusic:setVolume(self.sourceVolumes[self.outgoingMusic] * (1 - progress))
            end
            if self.activeMusic and self.activeMusic ~= self.outgoingMusic then
                -- A track shared by both scenes continues without restarting or dipping.
                if self.outgoingMusic or self.activeMusic:getVolume() < self.sourceVolumes[self.activeMusic] then
                    self.activeMusic:setVolume(self.sourceVolumes[self.activeMusic] * progress)
                end
            end
            if done then
                transition:destroy()
                self.transition = nil
                if self.outgoingMusic then
                    self.outgoingMusic:pause()
                    self.outgoingMusic:setVolume(self.sourceVolumes[self.outgoingMusic])
                    self.outgoingMusic = nil
                end
                if self.activeMusic then
                    self.activeMusic:setVolume(self.sourceVolumes[self.activeMusic])
                end
                self:dispatch("focus", love.window.hasFocus())
            end
            return
        elseif event == "focus" then
            return
        elseif event ~= "resize" then
            return
        end
    end
    local handler = self.active and self.active[event]
    if handler then
        return handler(...)
    end
end

function Scenes:destroy()
    if self.loading then
        self.loading:destroy()
        self.loading = nil
    end
    if self.transition then
        self.transition:destroy()
        self.transition = nil
    end
    for _, music in pairs(self.music) do
        music:stop()
        music:release()
    end
    self.music = {}
    self.activeMusic = nil
    for _, scene in pairs(self.instances) do
        if scene.quit then
            scene.quit()
        end
    end
    self.instances = {}
    self.active = nil
end

return Scenes
