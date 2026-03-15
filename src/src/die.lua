-- die.lua  -- Death animation: fade + life removal

local dieBlank = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local dieLevel = 0

local function Die_Drawer()
    -- Fill top game area (128 rows) with cycling ink colour
    Video_PixelInkFill(0, 128 * WIDTH, bit.rshift(dieLevel, 1))
end

local function Die_Ticker()
    if dieLevel > 0 then
        dieLevel = dieLevel - 1
        return
    end

    if gameLives < 0 then
        Action = Gameover_Action
        return
    end

    -- Erase one life sprite from the status bar
    Video_DrawSprite(LIVES + gameLives * 16, dieBlank, 0x0, 0x0)

    Miner_Restore()
    Audio_ReduceMusicSpeed()
    Action = Game_Action
end

local function Die_Init()
    gameLives = gameLives - 1
    dieLevel  = 15

    System_Border(0x0)
    Video_PixelPaperFill(0, 128 * WIDTH, 0x0)

    audioPanX = minerWilly.x
    Audio_Sfx(SFX_DIE)

    Ticker = Die_Ticker
end

function Die_Action()
    Responder = DoNothing
    Ticker    = Die_Init
    Drawer    = Die_Drawer
    Action    = DoNothing
end
