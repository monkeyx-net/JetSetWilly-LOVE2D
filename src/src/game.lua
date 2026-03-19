-- game.lua  -- Main game logic: room init, level change, status bar, clock, pause

-- Status bar pixel positions
-- LIVES = (18*8+4)*WIDTH + 4  = 148*256 + 4 = 37892
-- STATUS y-coordinate = 21*8+4 = 172
LIVES  = (18 * 8 + 4) * WIDTH + 4
STATUS = 21 * 8 + 4

-- Border colour per level (0-based index, 60 entries)
local levelBorder = {
    5,4,6,2,3,1,2,1,4,2,
    2,4,6,5,1,3,2,1,2,1,
    2,1,4,4,1,1,5,2,3,2,
    2,2,2,2,1,1,5,6,2,2,
    1,1,2,5,3,4,1,2,4,5,
    5,2,1,2,5,1,2,2,5,5,
}

local gameMusic          = MUS_PLAY
local gameScoreItems     = 0
local gameScoreClock     = {0, 7, 0}   -- {minutes, hours, ampm}
local DoClockUpdate      = DoNothing
local gameInactivityTimer = 0

local lifeInk = {0x2, 0x4, 0x6, 0x1, 0x3, 0x5, 0x7}

-- Exposed globals
gameFrame      = 0
gameLevel      = 0
gameLives      = 7
gameClockTicks = 0
gameMode       = GM_NORMAL
gamePaused     = 0
itemCount      = 0

local gameTimer = newTimer()

-- ── Clock display ────────────────────────────────────────────────────────────

local function DoDrawClock()
    local h    = gameScoreClock[2]
    local min  = gameScoreClock[1]
    local ampm = gameScoreClock[3]

    local hhi = h > 9 and math.floor(h / 10) or 0
    local hlo = h % 10
    local mhi = math.floor(min / 10)
    local mlo = min % 10
    local ap  = ampm == 1 and 'p' or 'a'

    -- Matches C: \x01\x00\x02\x07[htens]\x02\x06[hunits]\x02\x05[:]\x02\x04[mtens]\x02\x03[munits]\x02\x02[ap]\x02\x01[m]
    local s = string.char(0x1, 0x0, 0x2, 0x7)
           .. (hhi > 0 and string.char(48 + hhi) or " ")
           .. string.char(0x2, 0x6)
           .. string.char(48 + hlo)
           .. string.char(0x2, 0x5)
           .. ":"
           .. string.char(0x2, 0x4)
           .. string.char(48 + mhi)
           .. string.char(0x2, 0x3)
           .. string.char(48 + mlo)
           .. string.char(0x2, 0x2)
           .. ap
           .. string.char(0x2, 0x1)
           .. "m"

    Video_WriteLarge(WIDTH - 60, STATUS, s)
    DoClockUpdate = DoNothing
end

local function DrawItems()
    local lo = gameScoreItems % 10
    local hi = gameScoreItems > 9 and math.floor(gameScoreItems / 10) or 0

    -- Matches C: \x01\x00\x02\x06[tens]\x02\x07[units]
    local s = string.char(0x1, 0x0, 0x2, 0x6)
           .. (hi > 0 and string.char(48 + hi) or " ")
           .. string.char(0x2, 0x7)
           .. string.char(48 + lo)

    Video_WriteLarge(6 * 8 + 4, STATUS, s)
end

local function GameDrawLives()
    for l = 0, gameLives - 1 do
        Miner_DrawSeqSprite(LIVES + l * 16, 0x0, lifeInk[l + 1])
    end
end

-- ── Public status draw ────────────────────────────────────────────────────────

function Game_DrawStatus()
    Video_PixelPaperFill(128 * WIDTH, 64 * WIDTH, 0x0)
    Video_PixelInkFill(129 * WIDTH, 8 * WIDTH, 0x6)

    Video_WriteLarge(4, STATUS,
        "\x01\x00\x02\x01I\x02\x02t\x02\x03e\x02\x04m\x02\x05s")

    DrawItems()
    DoDrawClock()
    GameDrawLives()
end

-- ── Level change ──────────────────────────────────────────────────────────────

function Game_ChangeLevel(dir)
    local level = Level_Dir(dir)

    if dir == R_ABOVE then
        -- Special-case: prevent Willy appearing inside the floor
        if (level == THEDRIVE     and minerWilly.x > 22 and minerWilly.x < 32)
        or (level == FIRSTLANDING and minerWilly.x > 182) then
            minerWilly.air = 2
            return
        end
    end

    gameLevel = level

    if dir == R_ABOVE then
        minerWilly.y     = 13 * 8
        minerWilly.x     = bit.band(minerWilly.tile, 31) * 8
        minerWilly.tile  = 13 * 32 + bit.band(minerWilly.tile, 31)
        minerWilly.align = 4
        minerWilly.air   = 0

    elseif dir == R_RIGHT then
        minerWilly.x    = 0
        minerWilly.tile = bit.band(minerWilly.tile, bit.bnot(31))

    elseif dir == R_BELOW then
        if minerWilly.air < 11 then
            minerWilly.air = 2
        end
        minerWilly.y    = 0
        minerWilly.tile = bit.band(minerWilly.tile, 31)

    elseif dir == R_LEFT then
        minerWilly.x    = 30 * 8
        minerWilly.tile = bit.bor(minerWilly.tile, 30)
    end

    Game_InitRoom()
end

-- ── Clock ticker ──────────────────────────────────────────────────────────────

local function ClockTicker()
    gameClockTicks = gameClockTicks + 1
    if gameClockTicks <= 256 then return end

    gameClockTicks = 0
    gameScoreClock[1] = gameScoreClock[1] + 1

    if gameScoreClock[1] == 60 then
        gameScoreClock[1] = 0
        gameScoreClock[2] = gameScoreClock[2] + 1

        if gameScoreClock[2] == 12 then
            gameScoreClock[3] = 1 - gameScoreClock[3]
            if gameScoreClock[3] == 0 and gameMode < GM_MARIA then
                Action = Gameover_Action
            end
        elseif gameScoreClock[2] == 13 then
            gameScoreClock[2] = 1
        end
    end

    DoClockUpdate = DoDrawClock
end

-- ── Item collection ──────────────────────────────────────────────────────────

function Game_GotItem()
    gameScoreItems = gameScoreItems + 1
    DrawItems()

    itemCount = itemCount - 1
    if itemCount == 0 then
        gameMode = GM_MARIA
    end

    audioPanX = minerWilly.x
    Audio_Sfx(SFX_ITEM)
end

-- ── Pause ─────────────────────────────────────────────────────────────────────

local function DoPauseDrawer()
    if gamePaused == 16 * 5 then
        Level_SetBorder()
        Video_CycleColours()
    end
end

local function DoPauseTicker()
    gamePaused = gamePaused + 1
    if gamePaused > 16 * 5 then
        gamePaused = 1
    end
end

-- ── Game draw/tick ────────────────────────────────────────────────────────────

local function DoGameDrawer()
    if gameMusic == MUS_PLAY then
        GameDrawLives()
    end

    if gameFrame == 0 then return end

    Level_Drawer()
    Robots_Drawer()

    if gameMode == GM_TOILET then return end

    Miner_Drawer()
    Rope_Drawer()

    DoClockUpdate()
end

local function DoDrawOnce()
    DoGameDrawer()
    Drawer = DoNothing
end

local function DoGameTicker()
    if gameMusic == MUS_STOP and gameMode < GM_RUNNING then
        gameInactivityTimer = gameInactivityTimer + 1
        if gameInactivityTimer == 256 * 5 then
            Game_Pause(1)
            return
        end
    end

    if gameMusic == MUS_PLAY then
        Miner_IncSeq()
    end

    gameFrame = Timer_Update(gameTimer)
    if gameFrame == 0 then return end

    Level_Ticker()
    Robots_Ticker()

    if gameMode == GM_TOILET then
        gameClockTicks = gameClockTicks + 1
        if gameClockTicks == 256 then
            Action = Title_Action
        end
        return
    end

    Miner_Ticker()

    if gameMode == GM_RUNNING then
        minerWilly.frame = bit.bor(minerWilly.frame, 1)

        if minerWilly.x == 224 and gameLevel == THEBATHROOM then
            gameMode   = GM_TOILET
            Robots_Flush()
            gameClockTicks = 0
        end
        return
    end

    if gameMode == GM_MARIA and gameLevel == MASTERBEDROOM then
        if minerWilly.air == 0 and minerWilly.x == 40 then
            gameMode = GM_RUNNING
        end
    end

    Rope_Ticker()
    ClockTicker()
end

-- ── Cheat enable ──────────────────────────────────────────────────────────────

function Game_CheatEnabled()
    if gamePaused ~= 0 then
        gameFrame = 1
        Ticker    = DoNothing
        Drawer    = DoDrawOnce
        Game_DrawStatus()
        System_Border(levelBorder[gameLevel + 1])   -- +1: 1-based table
    end

    cheatEnabled = 1
    Robots_DrawCheat()
end

-- ── Save state ────────────────────────────────────────────────────────────────

local SAVE_FILE        = "savestate.lua"
local saveStateSnapshot = nil

-- ── Serialization helpers ────────────────────────────────────────────────────

local function serWilly(w)
    return string.format("{x=%d,y=%d,tile=%d,align=%d,frame=%d,dir=%d,move=%d,air=%d,jump=%d}",
        w.x, w.y, w.tile, w.align, w.frame, w.dir, w.move, w.air, w.jump)
end

local function serRobot(r)
    return string.format("{pos=%d,min=%d,max=%d,speed=%d,fUpdate=%d,fIndex=%d,fMask=%d,ink=%d,moveName=%q,drawName=%q}",
        r.pos, r.min, r.max, r.speed, r.fUpdate, r.fIndex, r.fMask, r.ink,
        Robots_GetMoveName(r.DoMove), Robots_GetDrawName(r.DoDraw))
end

local function serItems(items)
    local rows = {}
    for li = 1, 60 do
        local row = items[li] or {}
        local vals = {}
        for _, v in ipairs(row) do vals[#vals+1] = tostring(v) end
        rows[li] = "{"..table.concat(vals, ",").."}"
    end
    return "{"..table.concat(rows, ",").."}"
end

local function serializeState(s)
    local robots = {}
    for i = 1, 8 do robots[i] = serRobot(s.robots[i]) end
    return string.format(
        "return{level=%d,lives=%d,scoreItems=%d,clock={%d,%d,%d},clockTicks=%d,mode=%d,itemCount=%d,willy=%s,robots={%s},items=%s}",
        s.level, s.lives, s.scoreItems,
        s.clock[1], s.clock[2], s.clock[3],
        s.clockTicks, s.mode, s.itemCount,
        serWilly(s.willy),
        table.concat(robots, ","),
        serItems(s.items))
end

local function deserializeState(str)
    local fn, err = load(str)
    if not fn then return nil end
    local ok, s = pcall(fn)
    if not ok or type(s) ~= "table" then return nil end
    for i = 1, 8 do
        local r    = s.robots[i]
        r.DoMove = Robots_GetMoveFunc(r.moveName)
        r.DoDraw = Robots_GetDrawFunc(r.drawName)
    end
    return s
end

-- ── Core save/load ───────────────────────────────────────────────────────────

local function applyState(s)
    Level_LoadItems(s.items)

    gameLevel      = s.level
    gameLives      = s.lives
    gameScoreItems = s.scoreItems
    gameScoreClock[1] = s.clock[1]
    gameScoreClock[2] = s.clock[2]
    gameScoreClock[3] = s.clock[3]
    gameClockTicks = s.clockTicks
    gameMode       = s.mode
    itemCount      = s.itemCount

    Level_Init()
    Robots_Init()
    Rope_Init()
    System_Border(levelBorder[gameLevel + 1])

    Robots_LoadPositions(s.robots)

    for k, v in pairs(s.willy) do minerWilly[k] = v end
    Miner_Save()

    minerAttrSplit = 6
    if gameLevel == SWIMMINGPOOL then minerAttrSplit = 5 end

    Audio_ResetTempo()
    Timer_Set(gameTimer, 12, TICKRATE)
    gameFrame           = 1
    gameInactivityTimer = 0
    minerWillyRope      = 0
    DoClockUpdate       = DoDrawClock

    Game_DrawStatus()

    if gamePaused ~= 0 then
        Ticker = DoNothing
        Drawer = DoDrawOnce
    else
        Ticker = DoGameTicker
        Drawer = DoGameDrawer
    end
end

local function Game_SaveState()
    local w = {}
    for k, v in pairs(minerWilly) do w[k] = v end

    saveStateSnapshot = {
        willy      = w,
        robots     = Robots_SaveState(),
        items      = Level_SaveItems(),
        level      = gameLevel,
        lives      = gameLives,
        scoreItems = gameScoreItems,
        clock      = {gameScoreClock[1], gameScoreClock[2], gameScoreClock[3]},
        clockTicks = gameClockTicks,
        mode       = gameMode,
        itemCount  = itemCount,
    }

    local ok, err = love.filesystem.write(SAVE_FILE, serializeState(saveStateSnapshot))
    if not ok then
        print("SaveState: write failed: " .. tostring(err))
    end
end

local function Game_LoadState()
    -- Try file first; fall back to in-memory snapshot
    local str = love.filesystem.read(SAVE_FILE)
    local s = str and deserializeState(str) or saveStateSnapshot
    if not s then return end
    saveStateSnapshot = s  -- keep in sync
    applyState(s)
end

-- ── Responder ─────────────────────────────────────────────────────────────────

local function DoGameResponder()
    gameInactivityTimer = 0

    if gameInput == KEY_PAUSE then
        Game_Pause(gamePaused ~= 0 and 0 or 1)
    elseif gameInput == KEY_MUTE then
        gameMusic = (gameMusic == MUS_PLAY) and MUS_STOP or MUS_PLAY
        Audio_Play(gameMusic)
        Game_Pause(0)
    elseif gameInput == KEY_ESCAPE then
        Action = Title_Action
    elseif gameInput == KEY_S then
        Game_SaveState()
    elseif gameInput == KEY_L then
        Game_LoadState()
    else
        Cheat_Responder()
    end
end

-- ── Pause API ─────────────────────────────────────────────────────────────────

function Game_Pause(state)
    if gamePaused == state or gameMode >= GM_RUNNING then return end

    gamePaused = state

    if gamePaused ~= 0 then
        if cheatEnabled ~= 0 then
            Ticker = DoNothing
            Drawer = DoNothing
        else
            Ticker = DoPauseTicker
            Drawer = DoPauseDrawer
        end
        Audio_Play(MUS_STOP)
    else
        Ticker = DoGameTicker
        Drawer = DoGameDrawer
        Audio_Play(gameMusic)

        gameInactivityTimer = 0
        if cheatEnabled == 0 then
            Game_DrawStatus()
            System_Border(levelBorder[gameLevel + 1])
        end
    end
end

-- ── Room init ────────────────────────────────────────────────────────────────

function Game_InitRoom()
    Level_Init()
    Robots_Init()
    Rope_Init()
    System_Border(levelBorder[gameLevel + 1])
    Miner_Save()

    minerAttrSplit = 6
    if gameLevel == SWIMMINGPOOL then
        minerAttrSplit = 5   -- Willy goes blue underwater
    end

    Audio_ResetTempo()
    Timer_Set(gameTimer, 12, TICKRATE)
    gameFrame           = 1
    gameInactivityTimer = 0
    minerWillyRope      = 0

    if gamePaused ~= 0 then
        Ticker = DoNothing
        Drawer = DoDrawOnce
    else
        Ticker = DoGameTicker
    end

    Action = DoNothing
end

-- ── Game reset ────────────────────────────────────────────────────────────────

function Game_GameReset()
    gameScoreItems    = 0
    gameScoreClock[1] = 0
    gameScoreClock[2] = 7
    gameScoreClock[3] = 0   -- am
    DoClockUpdate     = DoDrawClock
    gameClockTicks    = 0
    gamePaused        = 0

    Miner_SetSeq(0, 20)
    gameLives = 7

    Audio_Music(MUS_GAME, gameMusic)
end

-- ── Action entry point ────────────────────────────────────────────────────────

function Game_Action()
    Responder = DoGameResponder
    Ticker    = Game_InitRoom
    Drawer    = DoGameDrawer
end
