-- miner.lua  -- Willy sprite, physics, movement

local band, bor, rshift, lshift, bxor = bit.band, bit.bor, bit.rshift, bit.lshift, bit.bxor

-- 16 sprite rows (0-based index), each 16 u16 pixel columns
-- Layout: rows 0-7 = normal, rows 8-15 = Nightmare Room variant
-- Access via minerFrameBase + (dir<<2|frame)
local minerSprite = {
    [0]  = {15360,15360,32256,13312,15872,15360,6144,15360,32256,32256,63232,64256,15360,30208,28160,30464},
    [1]  = {3840,3840,8064,3328,3968,3840,1536,3840,7040,7040,7040,7552,3840,1536,1536,1792},
    [2]  = {960,960,2016,832,992,960,384,960,2016,2016,3952,4016,960,1888,1760,1904},
    [3]  = {240,240,504,208,248,240,96,240,504,1020,2046,1782,248,474,782,908},
    [4]  = {3840,3840,8064,2816,7936,3840,1536,3840,8064,16320,32736,28512,7936,23424,28864,12736},
    [5]  = {960,960,2016,704,1984,960,384,960,2016,2016,3824,3568,960,1760,1888,3808},
    [6]  = {240,240,504,176,496,240,96,240,472,472,472,440,240,96,96,224},
    [7]  = {60,60,126,44,124,60,24,60,126,126,239,223,60,110,118,238},
    [8]  = {32768,20480,43008,20480,43008,54528,27136,55040,43648,55232,65472,32256,17408,17408,0,0},
    [9]  = {0,0,0,0,0,11328,7808,16320,10912,22000,11248,24448,4352,8320,0,0},
    [10] = {0,0,0,0,0,2832,1952,4080,3432,2748,5500,2784,5440,10816,5120,10240},
    [11] = {0,0,0,0,0,712,488,1020,682,1375,703,1528,272,160,0,0},
    [12] = {0,0,0,0,0,4928,6016,16320,21824,64160,64832,8096,2176,1280,0,0},
    [13] = {0,0,0,0,0,2256,1504,4080,5808,15696,16040,1872,680,596,40,20},
    [14] = {0,0,0,0,0,564,376,1020,1364,4010,4052,506,136,260,0,0},
    [15] = {3,10,21,10,21,171,86,235,341,1003,1023,126,34,34,0,0},
}

-- 18-step jump arc: {jump_y, tile_offset, align, sfx_length, sfx_pitch}
local jumpInfo = {
    {jump=-4, tile=-32, align=6, length=5, pitch=72},
    {jump=-4, tile=0,   align=4, length=5, pitch=74},
    {jump=-3, tile=-32, align=6, length=4, pitch=76},
    {jump=-3, tile=0,   align=6, length=4, pitch=78},
    {jump=-2, tile=0,   align=4, length=3, pitch=80},
    {jump=-2, tile=-32, align=6, length=3, pitch=82},
    {jump=-1, tile=0,   align=6, length=2, pitch=84},
    {jump=-1, tile=0,   align=6, length=2, pitch=86},
    {jump=0,  tile=0,   align=6, length=1, pitch=88},
    {jump=0,  tile=0,   align=6, length=1, pitch=88},
    {jump=1,  tile=0,   align=6, length=2, pitch=86},
    {jump=1,  tile=0,   align=6, length=2, pitch=84},
    {jump=2,  tile=32,  align=4, length=3, pitch=82},
    {jump=2,  tile=0,   align=6, length=3, pitch=80},
    {jump=3,  tile=0,   align=6, length=4, pitch=78},
    {jump=3,  tile=32,  align=4, length=4, pitch=76},
    {jump=4,  tile=0,   align=6, length=5, pitch=74},
    {jump=4,  tile=32,  align=4, length=5, pitch=72},
}

local minerStore     = {}
local minerFrameBase = 0    -- 0 = normal, 8 = NIGHTMAREROOM
local minerSeqIndex  = 0    -- 0-based
local minerTimer     = newTimer()

-- walking animation sequence (0-based frame indices)
local minerSequence = {0, 1, 2, 3, 7, 6, 5, 4}   -- [1..8] for Lua indexing

-- Globals exposed to other modules
minerWilly     = {x=0, y=0, tile=0, align=4, frame=0, dir=D_RIGHT, move=0, air=0, jump=0}
minerWillyRope = 0
minerAttrSplit = 6

-- ── Public API ──────────────────────────────────────────────────────────────

function Miner_SetSeq(index, speed)
    Timer_Set(minerTimer, 1, speed)
    minerSeqIndex = index
end

function Miner_IncSeq()
    minerSeqIndex = band(minerSeqIndex + Timer_Update(minerTimer), 7)
end

function Miner_DrawSeqSprite(pos, paper, ink)
    local frame = minerSequence[minerSeqIndex + 1]   -- +1: Lua tables are 1-based
    Video_DrawSprite(pos, minerSprite[minerFrameBase + frame], paper, ink)
end

function Miner_Save()
    for k, v in pairs(minerWilly) do minerStore[k] = v end
    minerFrameBase = (gameLevel == NIGHTMAREROOM) and 8 or 0
end

function Miner_Restore()
    for k, v in pairs(minerStore) do minerWilly[k] = v end
end

-- ── Local helpers ────────────────────────────────────────────────────────────

local function IsSolid(tile)
    if tile < 0 or tile == 512 then return false end
    if Level_GetTileType(tile)      == T_SOLID then return true end
    if Level_GetTileType(tile + 32) == T_SOLID then return true end
    if tile + 64 > 511 then return false end
    if Level_GetTileType(tile + 64) ~= T_SOLID then return false end
    if minerWilly.align == 6 then return true end
    if minerWilly.air == 1 and minerWilly.jump > 9 then
        minerWilly.air = 0
    end
    return false
end

local function MoveLeftRight()
    local y, offset = 0, 0

    if minerWilly.move == 0 then return end
    if minerWillyRope > 0  then return end

    if minerWilly.dir == D_RIGHT then
        if minerWilly.frame < 3 then
            minerWilly.frame = minerWilly.frame + 1
            return
        end

        if minerWilly.air == 0 then
            if Level_GetTileRamp(minerWilly.tile + 64) == T_RAMPL then
                y = 8;  offset = 32
            elseif Level_GetTileRamp(minerWilly.tile + 34) == T_RAMPR then
                y = -8; offset = -32
            end
        end

        if minerWilly.x == 30 * 8 then
            Game_ChangeLevel(R_RIGHT)
            return
        end

        if IsSolid(minerWilly.tile + offset + 2) then return end

        minerWilly.x    = minerWilly.x    + 8
        minerWilly.tile = minerWilly.tile + 1
        minerWilly.frame = 0

    elseif gameMode ~= GM_RUNNING then
        if minerWilly.frame > 0 then
            minerWilly.frame = minerWilly.frame - 1
            return
        end

        if minerWilly.air == 0 then
            if Level_GetTileRamp(minerWilly.tile + 31) == T_RAMPL then
                y = -8; offset = -32
            elseif Level_GetTileRamp(minerWilly.tile + 65) == T_RAMPR then
                y = 8;  offset = 32
            end
        end

        if minerWilly.x == 0 then
            Game_ChangeLevel(R_LEFT)
            return
        end

        if IsSolid(minerWilly.tile + offset - 1) then return end

        minerWilly.x    = minerWilly.x    - 8
        minerWilly.tile = minerWilly.tile - 1
        minerWilly.frame = 3
    end

    minerWilly.y    = minerWilly.y    + y
    minerWilly.tile = minerWilly.tile + offset
end

local function UpdateDir(conveyDir)
    local dir = 0

    if (System_IsKey(KEY_LEFT) or conveyDir == C_LEFT) and gameMode < GM_RUNNING then
        dir = dir + 1
    end
    if System_IsKey(KEY_RIGHT) or conveyDir == C_RIGHT or gameMode == GM_RUNNING then
        dir = dir + 2
    end

    if dir == 0 then
        minerWilly.move = 0
    elseif dir == 1 then
        if minerWilly.dir == D_RIGHT then
            minerWilly.dir  = D_LEFT
            minerWilly.move = 0
        else
            minerWilly.move = 1
        end
    elseif dir == 2 then
        if minerWilly.dir == D_LEFT then
            minerWilly.dir  = D_RIGHT
            minerWilly.move = 0
        else
            minerWilly.move = 1
        end
    end

    if System_IsKey(KEY_JUMP) and gameMode < GM_RUNNING then
        minerWilly.air  = 1
        minerWilly.jump = 0
        if minerWillyRope > 0 then
            minerWillyRope   = -16
            minerWilly.y     = band(minerWilly.y, 120)
            minerWilly.align = 4
            minerWilly.move  = 1
        end
    end
end

local function DoMinerTicker()
    local conveyDir = C_NONE

    if minerWillyRope > 0 then
        UpdateDir(conveyDir)
        return
    end

    if minerWilly.air == 1 then
        local ji   = jumpInfo[minerWilly.jump + 1]   -- 1-indexed
        local y    = minerWilly.y + ji.jump
        local tile = minerWilly.tile + ji.tile

        if y < 0 then
            Game_ChangeLevel(R_ABOVE)
            return
        end

        if Level_GetTileType(tile) == T_SOLID or Level_GetTileType(tile + 1) == T_SOLID then
            minerWilly.y     = band(y + 8, 120)
            minerWilly.tile  = tile + 32
            minerWilly.align = 4
            minerWilly.air   = 2
            minerWilly.move  = 0
            return
        end

        audioPanX = minerWilly.x
        Audio_WillySfx(ji.pitch, ji.length)

        minerWilly.y     = y
        minerWilly.tile  = tile
        minerWilly.align = ji.align
        minerWilly.jump  = minerWilly.jump + 1

        if minerWilly.jump == 18 then
            minerWilly.air = 6
            return
        end

        if minerWilly.jump ~= 13 and minerWilly.jump ~= 16 then
            MoveLeftRight()
            return
        end
    end

    if minerWilly.align == 4 then
        local tile = minerWilly.tile + 64

        if band(tile, 512) ~= 0 then
            Game_ChangeLevel(R_BELOW)
            return
        end

        local t0 = Level_GetTileType(tile)
        local t1 = Level_GetTileType(tile + 1)

        if t0 == T_HARM or t1 == T_HARM then
            if minerWilly.air == 1 and (t0 <= T_SPACE or t1 <= T_SPACE) then
                MoveLeftRight()
            else
                Action = Die_Action
            end
            return
        end

        if t0 > T_SPACE or t1 > T_SPACE then
            if minerWilly.air >= 12 then
                Action = Die_Action
                return
            end

            minerWilly.air = 0

            if t0 == T_CONVEYL or t1 == T_CONVEYL then
                conveyDir = C_LEFT
            elseif t0 == T_CONVEYR or t1 == T_CONVEYR then
                conveyDir = C_RIGHT
            end

            UpdateDir(conveyDir)
            MoveLeftRight()
            return
        end
    end

    if minerWilly.air == 1 then
        MoveLeftRight()
        return
    end

    minerWilly.move = 0
    if minerWilly.air == 0 then
        minerWilly.air = 2
        return
    end

    minerWilly.air = minerWilly.air + 1
    if minerWilly.air == 16 then
        minerWilly.air = 12
    end

    audioPanX = minerWilly.x
    Audio_WillySfx(78 - minerWilly.air, 4)
    minerWilly.y     = minerWilly.y + 4
    minerWilly.align = 4
    if band(minerWilly.y, 7) ~= 0 then
        minerWilly.align = minerWilly.align + 2
    else
        minerWilly.tile = minerWilly.tile + 32
    end
end

-- ── Public tick/draw ─────────────────────────────────────────────────────────

function Miner_Ticker()
    DoMinerTicker()
    if minerWilly.y < 0 then
        Game_ChangeLevel(R_ABOVE)
    end
end

function Miner_Drawer()
    local align  = minerWilly.align
    local offset = 0

    if minerWilly.air == 0 then
        if Level_GetTileRamp(minerWilly.tile + 64) == T_RAMPL then
            offset = minerWilly.frame * 2
            align  = YALIGN(offset)
        elseif Level_GetTileRamp(minerWilly.tile + 65) == T_RAMPR then
            offset = 6 - (minerWilly.frame * 2)
            align  = YALIGN(offset)
        end
    end

    local sprIdx = minerFrameBase + bor(lshift(minerWilly.dir, 2), minerWilly.frame)
    local pos    = bor(lshift(minerWilly.y + offset, 8), minerWilly.x)

    if Video_DrawMiner(pos, minerSprite[sprIdx], minerAttrSplit) then
        Action = Die_Action
        return
    end

    -- Check HARM tiles in the 'align' cells Willy occupies
    -- The C walks: tile, tile+1, tile+32, tile+33, ... alternating +1/+31
    local tile, adj = minerWilly.tile, 1
    for _ = 0, align - 1 do
        if Level_GetTileType(tile) == T_HARM then
            Action = Die_Action
            return
        end
        tile = tile + adj
        adj  = bxor(adj, 30)   -- alternates 1 <-> 31
    end

    -- Collect items
    tile, adj = minerWilly.tile, 1
    for _ = 0, align - 1 do
        if Level_GetTileType(tile) == T_ITEM then
            Level_EraseItem(tile)
            Game_GotItem()
        end
        tile = tile + adj
        adj  = bxor(adj, 30)
    end
end

function Miner_Init()
    minerWilly.x     = 20 * 8
    minerWilly.y     = 13 * 8
    minerWilly.tile  = 13 * 32 + 20
    minerWilly.align = 4
    minerWilly.move  = 0
    minerWilly.air   = 0
    Miner_Save()
end
