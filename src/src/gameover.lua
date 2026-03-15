-- gameover.lua  -- Boot-kicking animation + "Game Over" screen

local plinthSprite = {14316,30702,0,28662,61431,61431,54619,56251,54619,57339,60791,61175,28022,0,30702,14316}
local bootSprite   = {4224,4224,4224,4224,4224,4224,4224,8320,8320,18498,34869,33801,32769,32770,17293,15478}
local minerSpr     = {960,960,2016,832,992,960,384,960,2016,2016,3952,4016,960,1888,1760,1904}

local bootTicks = 0

-- Colour-control byte sequences for "G a m e" and "O v e r"
-- These are Lua byte arrays matching the C char literals
local textGame = {0x1,0x0, 0x2,0x0, string.byte('G'), string.byte(' '),
                  0x2,0x0, string.byte('a'), string.byte(' '),
                  0x2,0x0, string.byte('m'), string.byte(' '),
                  0x2,0x0, string.byte('e')}
local textOver = {0x1,0x0, 0x2,0x0, string.byte('O'), string.byte(' '),
                  0x2,0x0, string.byte('v'), string.byte(' '),
                  0x2,0x0, string.byte('e'), string.byte(' '),
                  0x2,0x0, string.byte('r')}

-- Convert byte array to string for Video_WriteLarge
local function bytes2str(t)
    local b = {}
    for _, v in ipairs(t) do b[#b+1] = string.char(v) end
    return table.concat(b)
end

local function Gameover_Drawer()
    if bootTicks <= 96 then
        local bootY = bit.band(bootTicks, 126)
        Video_DrawSprite(bootY * WIDTH + 15 * 8, bootSprite, 0x0, 0x7)
        Video_PixelPaperFill(0, 128 * WIDTH, bit.rshift(bit.band(bootTicks, 12), 2))
    end

    if bootTicks < 96 then return end

    Video_WriteLarge(7 * 8,  6 * 8, bytes2str(textGame))
    Video_WriteLarge(18 * 8, 6 * 8, bytes2str(textOver))
end

local function Gameover_Ticker()
    local c = bit.rshift(bootTicks, 2)

    -- Cycle through 8 colours for each letter
    textGame[4]  = bit.band(c,   0x7); c = c + 1
    textGame[8]  = bit.band(c,   0x7); c = c + 1
    textGame[12] = bit.band(c,   0x7); c = c + 1
    textGame[16] = bit.band(c,   0x7); c = c + 1
    textOver[4]  = bit.band(c,   0x7); c = c + 1
    textOver[8]  = bit.band(c,   0x7); c = c + 1
    textOver[12] = bit.band(c,   0x7); c = c + 1
    textOver[16] = bit.band(c,   0x7)

    bootTicks = bootTicks + 1

    if bootTicks >= 256 then
        Action = Title_Action
    end
end

local function Gameover_Init()
    System_Border(0x0)
    Video_PixelFill(0, 128 * WIDTH)
    Video_DrawSprite(96  * WIDTH + 15 * 8, minerSpr,    0x0, 0x7)
    Video_DrawSprite(112 * WIDTH + 15 * 8, plinthSprite, 0x0, 0x2)
    bootTicks = 0

    Audio_Play(MUS_STOP)
    Audio_Sfx(SFX_GAMEOVER)

    Ticker = Gameover_Ticker
end

function Gameover_Action()
    Responder = DoNothing
    Ticker    = Gameover_Init
    Drawer    = Gameover_Drawer
    Action    = DoNothing
end
