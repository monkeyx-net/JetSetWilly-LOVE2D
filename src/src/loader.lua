-- loader.lua  -- Loading screen with music and 256-tick timer

local loaderTicks    = 0
local loaderWait     = 0   -- frames spent waiting for music to end (timeout fallback)

-- Colour-control + text: \x1\x7\x2\x2 "JetSet Willy Loading"
local loaderText = "\x01\x07\x02\x02JetSet Willy Loading"

local function updateLoaderText()
    if videoFlash then
        loaderText = "\x01\x07\x02\x02JetSet Willy Loading"
    else
        loaderText = "\x01\x02\x02\x07JetSet Willy Loading"
    end
end

local function DoLoaderResponder()
    Action = Title_Action
end

local function DoLoaderTicker()
    updateLoaderText()

    loaderTicks = loaderTicks + 1
    if loaderTicks >= 256 then
        Action = Codes_Action
    end
end

local function DoLoaderDrawer3()
    Video_WriteLarge(6 * 8, 11 * 8, loaderText)
end

local function DoLoaderDrawer2()
    loaderWait = loaderWait + 1
    -- Wait for music to finish; timeout after ~3 seconds in case audio fails
    if audioMusicPlaying ~= MUS_STOP and loaderWait < 180 then return end

    -- Draw the cassette graphic: \x01\x06 sets paper=6 (yellow), \x14=solid block
    local blk = "\x01\x06" .. string.rep("\x14", 22)
    Video_Write(80 * WIDTH + 5 * 8, blk)
    local blk22 = string.rep("\x14", 22)
    Video_Write(88  * WIDTH + 5 * 8, blk22)
    Video_Write(96  * WIDTH + 5 * 8, blk22)
    Video_Write(104 * WIDTH + 5 * 8, blk22)

    DoLoaderDrawer3()

    Responder = DoLoaderResponder
    Ticker    = DoLoaderTicker
    Drawer    = DoLoaderDrawer3
end

local function DoLoaderDrawer1()
    System_Border(0x1)
    Video_PixelPaperFill(0, WIDTH * HEIGHT, 0x1)

    -- Version line
    Video_Write(23 * 8 * WIDTH, "\x01\x01\x02\x07monkeyx-net")
    Video_Write(23 * 8 * WIDTH + WIDTH - Video_TextWidth(BUILD or ""), "\x02\x00" .. (BUILD or ""))

    Audio_Music(MUS_LOADER, MUS_PLAY)

    Drawer = DoLoaderDrawer2
end

function Loader_Action()
    loaderTicks = 0
    loaderWait  = 0
    Drawer = DoLoaderDrawer1
    Action = DoNothing
end
