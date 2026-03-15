-- common.lua  -- Constants, colour palette, key codes, timer utilities

WIDTH  = 256
HEIGHT = 192

-- Tile flags (pixel point bits)
B_LEVEL = 1
B_ROBOT = 2
B_WILLY = 4

-- Direction indices
R_ABOVE = 1
R_RIGHT = 2
R_BELOW = 3
R_LEFT  = 4

-- Game modes
GM_NORMAL  = 0
GM_MARIA   = 1
GM_RUNNING = 2
GM_TOILET  = 3

-- Tile types
T_ITEM      = 0
T_SPACE     = 1
T_SOLID     = 2
T_FLOOR     = 3
T_SOLIDFLOOR = 4
T_CONVEYL   = 5
T_CONVEYR   = 6
T_RAMPL     = 7
T_RAMPR     = 8
T_RAMPLC    = 9
T_RAMPRC    = 10
T_HARM      = 11

-- Conveyor directions
C_NONE  = 0
C_LEFT  = 1
C_RIGHT = 2

-- Miner directions
D_RIGHT = 0
D_LEFT  = 1
D_JUMP  = 2

-- Named level indices
THEDRIVE      = 4
QUIRKAFLEEG   = 16
ONTHEROOF     = 18
BALLROOMEAST  = 20
COLDSTORE     = 25
THECHAPEL     = 27
FIRSTLANDING  = 28
NIGHTMAREROOM = 29
SWIMMINGPOOL  = 31
EASTWALL      = 32
THEBATHROOM   = 33
MASTERBEDROOM = 35
THEBEACH      = 57

-- Music constants
MUS_STOP   = 0
MUS_PLAY   = 1
MUS_TITLE  = 1
MUS_GAME   = 2
MUS_LOADER = 3

-- SFX constants
SFX_ITEM     = 1
SFX_DIE      = 2
SFX_GAMEOVER = 3
SFX_ARROW    = 4
SFX_WILLY    = 5
SFX_NONE     = 6

GAME_FPS      = 30    -- configurable target game update / render rate
TICKRATE      = GAME_FPS
AUDIO_TICKRATE = 60   -- audio clock is always 60 Hz so music tempo stays correct
SAMPLERATE    = 22050

-- Key codes (mapped from Love2D key names)
KEY_LEFT   = "left"
KEY_RIGHT  = "right"
KEY_JUMP   = "space"
KEY_ENTER  = "return"
KEY_LSHIFT = "lshift"
KEY_RSHIFT = "rshift"
KEY_1  = "1"
KEY_2  = "2"
KEY_3  = "3"
KEY_4  = "4"
KEY_5  = "5"
KEY_6  = "6"
KEY_7  = "7"
KEY_8  = "8"
KEY_9  = "9"
KEY_0  = "0"
KEY_A  = "a"
KEY_B  = "b"
KEY_C  = "c"
KEY_D  = "d"
KEY_E  = "e"
KEY_F  = "f"
KEY_G  = "g"
KEY_H  = "h"
KEY_I  = "i"
KEY_J  = "j"
KEY_K  = "k"
KEY_L  = "l"
KEY_M  = "m"
KEY_N  = "n"
KEY_O  = "o"
KEY_P  = "p"
KEY_Q  = "q"
KEY_R  = "r"
KEY_S  = "s"
KEY_T  = "t"
KEY_ESCAPE = "escape"
KEY_PAUSE  = "pause"
KEY_MUTE   = "lalt"
KEY_NONE   = nil
KEY_ELSE   = "?"

-- 16-colour ZX Spectrum-style palette (0-15)
videoColour = {
    [0]  = {0,   0,   0},    -- black
    [1]  = {0,   0,   255},  -- blue
    [2]  = {255, 0,   0},    -- red
    [3]  = {255, 0,   255},  -- magenta
    [4]  = {0,   255, 0},    -- green
    [5]  = {0,   170, 255},  -- light blue
    [6]  = {255, 255, 0},    -- yellow
    [7]  = {255, 255, 255},  -- white
    [8]  = {204, 204, 204},  -- mid grey
    [9]  = {0,   85,  255},  -- mid blue
    [10] = {170, 0,   0},    -- mid red
    [11] = {85,  0,   0},    -- dark red
    [12] = {0,   170, 0},    -- mid green
    [13] = {0,   85,  0},    -- dark green
    [14] = {255, 128, 0},    -- orange
    [15] = {128, 64,  0},    -- brown
}

-- Convert tile index → pixel (x, y)
function TILE2XY(t)
    local col = t % 32
    local row = math.floor(t / 32)
    return col * 8, row * 8
end

-- Convert (x, y) → tile index
function XY2TILE(x, y)
    return math.floor(y / 8) * 32 + math.floor(x / 8)
end

-- Willy's vertical alignment packing (mirrors the C macro YALIGN)
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
function YALIGN(y)
    return bor(4,
        bor(rshift(band(y, 4), 1),
        bor(band(y, 2),
            lshift(band(y, 1), 1))))
end

-- Timer (mirrors C TIMER struct + Timer_Set/Timer_Update)
function Timer_Set(timer, numerator, divisor)
    timer.rate      = math.floor(numerator / divisor)
    timer.remainder = numerator - timer.rate * divisor
    timer.divisor   = divisor
    timer.acc       = 0
end

function Timer_Update(timer)
    timer.acc = timer.acc + timer.remainder
    if timer.acc < timer.divisor then
        return timer.rate
    end
    timer.acc = timer.acc - timer.divisor
    return timer.rate + 1
end

function newTimer()
    return {rate = 0, remainder = 0, divisor = 1, acc = 0}
end
