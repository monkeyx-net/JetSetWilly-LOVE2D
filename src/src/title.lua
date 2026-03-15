-- title.lua  -- Title screen, ticker text, JSW logo, game start

-- Tile indices for the "JET-SET WILLY" logo pixels (100 entries)
local titleJSW = {
    100,101,102,104,105,106,108,109,110,113,114,115,117,118,119,121,122,123,
    133,136,141,145,149,154,
    165,168,169,170,173,177,178,179,181,182,183,186,
    197,200,205,211,213,218,
    228,229,232,233,234,237,241,242,243,245,246,247,250,
    326,330,332,334,338,341,345,
    358,362,364,366,370,373,377,
    390,392,394,396,398,402,405,406,407,408,409,
    422,424,426,428,430,434,439,
    454,455,456,457,458,460,462,463,464,466,467,468,471,
}

-- JSW colour-flash string: \x1\x2\x2\xb\x14 (ink=2/paper=11 initially)
local textJSW_ink1 = 0x2
local textJSW_ink2 = 0xb

-- Scrolling ticker text
local textTicker = "      Press ENTER to Start                                JET-SET WILLY by Matthew Smith   1984 SOFTWARE PROJECTS Ltd                                Guide Willy to collect all the items around the house before Midnight so Maria will let you get to your bed                                Press ENTER to Start      "
local textEnd    = #textTicker - 32   -- stop 32 chars from end so display is full
local textPos    = 0
local textFrame  = 0

local colourCycle    = 1
local colourCycleAdj = {1, 2, 3, 4, 5, 1}   -- [colourCycle] → next

-- ── Game start ───────────────────────────────────────────────────────────────

local function GameStart()
    -- Clear status bar area, set up score/lives display
    Video_PixelFill(128 * WIDTH, 64 * WIDTH)

    Game_GameReset()
    Game_DrawStatus()

    gameLevel = THEBATHROOM
    itemCount = Level_ItemCount()
    Level_RestoreItems()

    Miner_Init()

    if cheatEnabled ~= 0 then
        Robots_DrawCheat()
    end

    gameMode   = GM_NORMAL
    gamePaused = 0

    Game_Action()
end

-- ── Title ticker / drawer ─────────────────────────────────────────────────────

local function DoTitleTicker()
    if audioMusicPlaying ~= MUS_STOP then
        -- Flash the JSW logo colours
        if videoFlash then
            textJSW_ink1 = 0xb
            textJSW_ink2 = 0x2
        else
            textJSW_ink1 = 0x2
            textJSW_ink2 = 0xb
        end
        return
    end

    -- Cycle border colour
    colourCycle = colourCycleAdj[colourCycle]

    if textPos < textEnd then
        if textFrame < 6 then
            textFrame = textFrame + 2
            return
        end
        textPos   = textPos + 1
        textFrame = 0
        return
    end

    -- Scroll complete: restart title
    Action = Title_Action
end

local function DoTitleDrawer()
    if audioMusicPlaying ~= MUS_STOP then
        -- Draw JSW logo with flashing colours
        local jswStr = string.char(0x1, textJSW_ink1, 0x2, textJSW_ink2, 0x14)
        for _, tile in ipairs(titleJSW) do
            local px, py = TILE2XY(tile)
            Video_Write(py * WIDTH + px, jswStr)
        end
        return
    end

    if colourCycle == 1 then
        System_Border(Video_CycleColours())
    end

    -- Bottom-left: blank large char area
    Video_WriteLarge(0, 0, "\x01\x01\x02\x07")
    -- Scrolling ticker at row 19*8
    Video_WriteLarge(-(bit.band(textFrame, 6)), 19 * 8, textTicker:sub(textPos + 1))
end

local function DoTitleResponder()
    if gameInput == KEY_ENTER then
        Action = GameStart
    elseif gameInput == KEY_ESCAPE then
        DoQuit()
    end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

local function DoTitleInit()
    System_Border(0x0)
    Video_PixelFill(0, WIDTH * HEIGHT)

    -- Draw the diamond/border pattern in the centre of the screen
    -- These are the exact pixel positions from the C source (each is y*WIDTH+x)
    Video_Write(16*WIDTH+144, "\x01\x00\x02\x05\x10\x11\x12\x13")
    Video_Write(24*WIDTH+128, "\x10\x14\x01\x05\x14\x14\x02\x09\x10\x14")
    Video_Write(32*WIDTH+112, "\x01\x00\x02\x05\x10\x11\x01\x05\x14\x14\x02\x09\x10\x11\x01\x09\x14\x14")
    Video_Write(40*WIDTH+96,  "\x01\x00\x02\x05\x10\x14\x01\x05\x14\x14\x02\x09\x10\x14\x01\x09\x14\x14\x14\x14")
    Video_Write(48*WIDTH+80,  "\x01\x00\x02\x05\x10\x11\x01\x05\x14\x14\x02\x09\x10\x11\x01\x09\x14\x14\x02\x01\x10\x14\x14\x14")
    Video_Write(56*WIDTH+64,  "\x01\x00\x02\x05\x14\x14\x01\x05\x14\x14\x02\x09\x10\x14\x01\x09\x14\x14\x02\x00\x10\x14\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(64*WIDTH+64,  "\x01\x05\x02\x01\x12\x13\x14\x14\x01\x09\x02\x05\x12\x13\x02\x00\x10\x11\x01\x00\x14\x14\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(72*WIDTH+64,  "\x01\x01\x14\x14\x01\x05\x02\x01\x12\x13\x14\x14\x01\x00\x02\x05\x12\x13\x14\x14\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(80*WIDTH+64,  "\x01\x01\x02\x00\x12\x13\x14\x14\x01\x05\x02\x01\x14\x13\x14\x14\x01\x00\x02\x05\x12\x13\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(88*WIDTH+80,  "\x01\x01\x02\x00\x14\x13\x14\x14\x01\x05\x02\x01\x14\x13\x14\x14\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(96*WIDTH+96,  "\x01\x01\x02\x00\x14\x13\x14\x14\x01\x05\x02\x01\x12\x13\x01\x01\x14\x14\x01\x09\x14\x14")
    Video_Write(104*WIDTH+112,"\x01\x01\x02\x00\x14\x13\x14\x14\x14\x14\x01\x09\x14\x14")
    Video_Write(112*WIDTH+128,"\x01\x01\x14\x13\x14\x14\x01\x09\x14\x14")
    Video_Write(120*WIDTH+144,"\x01\x01\x12\x13\x01\x09\x10\x11")

    Video_WriteLarge(0,    0,      "\x01\x00\x02\x04")
    Video_WriteLarge(0,    19 * 8, textTicker)

    textPos     = 0
    textFrame   = -1
    colourCycle = 1

    Audio_Music(MUS_TITLE, MUS_PLAY)

    Ticker = DoTitleTicker
end

function Title_Action()
    Responder = DoTitleResponder
    Ticker    = DoTitleInit
    Drawer    = DoTitleDrawer
    Action    = DoNothing
end
