-- main.lua  -- Love2D entry point for Jet-Set Willy

-- ── Globals needed before any src/ file is loaded ────────────────────────────

function DoNothing() end

function DoQuit()
    love.event.quit()
    Drawer = DoNothing
    Ticker = DoNothing
end

-- State machine (each slot holds a function)
Action    = DoNothing
Responder = DoNothing
Ticker    = DoNothing
Drawer    = DoNothing

-- Input / display globals
gameInput  = nil     -- Love2D key name string set during keypressed, then cleared
videoFlash = false   -- toggled at ~3.125 Hz
audioPanX  = 0       -- 0-255 x-position for audio panning

BUILD = "love2d"

-- System abstraction layer (called by game modules)
function System_IsKey(key)
    if key == nil then return false end
    return love.keyboard.isDown(key)
end

function System_Border(index)
    -- videoColour is defined in common.lua after love.load runs
    local c = videoColour and videoColour[index] or videoColour and videoColour[0]
    if c then Video_SetBorder(c[1], c[2], c[3]) end
end

function System_Rnd()
    return math.random(0, 65535)
end

-- ── Module loader ─────────────────────────────────────────────────────────────

local function loadSrc(path)
    local fn, err = love.filesystem.load(path)
    if not fn then error("Cannot load " .. path .. ": " .. tostring(err)) end
    fn()
end

-- ── Game-loop state (declared here, initialised in love.load) ─────────────────

local timerFlash, timerFrame
local accumulator = 0
local FRAME_TIME  = 1 / 60   -- overridden after common.lua sets TICKRATE

-- ── love.load ────────────────────────────────────────────────────────────────

function love.load()
    -- Load order matters: common first (constants/helpers), then subsystems
    loadSrc("src/common.lua")
    loadSrc("src/video.lua")
    loadSrc("src/audio.lua")
    loadSrc("src/levels.lua")
    loadSrc("src/miner.lua")
    loadSrc("src/robots.lua")
    loadSrc("src/rope.lua")
    loadSrc("src/die.lua")
    loadSrc("src/gameover.lua")
    loadSrc("src/cheat.lua")
    loadSrc("src/loader.lua")
    loadSrc("src/codes.lua")
    loadSrc("src/title.lua")
    loadSrc("src/game.lua")

    -- Now TICKRATE is defined
    FRAME_TIME = 1 / TICKRATE

    Video_Init()
    Audio_Init()

    math.randomseed(os.time())

    timerFlash = newTimer()
    timerFrame = newTimer()
    Timer_Set(timerFlash, 25, TICKRATE * 8)   -- ~3.125 Hz flash rate

    love.mouse.setVisible(false)

    -- Enter loading screen
    Action = Loader_Action
end

-- ── love.update ──────────────────────────────────────────────────────────────

function love.update(dt)
    accumulator = accumulator + dt

    while accumulator >= FRAME_TIME do
        accumulator = accumulator - FRAME_TIME

        -- State-machine dispatch: Action sets Ticker/Drawer/Responder then becomes DoNothing
        Action()

        Ticker()

        -- Flash-colour timer (~3 Hz)
        if timerFlash and Timer_Update(timerFlash) ~= 0 then
            videoFlash = not videoFlash
        end
    end

    Audio_Update()
end

-- ── love.draw ────────────────────────────────────────────────────────────────

function love.draw()
    Drawer()
    Video_Present()
end

-- ── Input ─────────────────────────────────────────────────────────────────────

-- Keys that trigger the Responder (non-polling inputs)
-- Movement keys (left/right/space/shift) are polled via System_IsKey()
local responderKeys = {
    ["return"]  = "return",    -- KEY_ENTER
    ["escape"]  = "escape",    -- KEY_ESCAPE
    ["pause"]   = "pause",     -- KEY_PAUSE
    ["tab"]     = "pause",
    ["lalt"]    = "lalt",      -- KEY_MUTE
    ["ralt"]    = "lalt",
    ["1"]="1",["2"]="2",["3"]="3",["4"]="4",["5"]="5",
    ["6"]="6",["7"]="7",["8"]="8",["9"]="9",["0"]="0",
    ["a"]="a",["b"]="b",["c"]="c",["d"]="d",["e"]="e",
    ["f"]="f",["g"]="g",["h"]="h",["i"]="i",["j"]="j",
    ["k"]="k",["l"]="l",["m"]="m",["n"]="n",["o"]="o",
    ["p"]="p",["q"]="q",["r"]="r",["s"]="s",["t"]="t",
    ["u"]="u",["v"]="v",["w"]="w",["x"]="x",["y"]="y",["z"]="z",
}

function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    -- Alt+Enter: toggle fullscreen
    if key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        return
    end

    local mapped = responderKeys[key]
    if mapped then
        gameInput = mapped
        Responder()
        gameInput = nil
    end
end

-- ── Window resize ─────────────────────────────────────────────────────────────

function love.resize(w, h)
    -- viewport is computed dynamically in Video_Present; nothing to do here
end
