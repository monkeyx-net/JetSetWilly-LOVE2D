-- rope.lua  -- Rope swinging mechanics (5 levels have ropes)

-- 86-entry oscillation data: {x_delta, y_delta} per segment per step
local ropeData = {
    {0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},
    {0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},
    {0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},{0,3},
    {0,3},{0,3},{1,3},{1,3},{1,3},{1,3},{1,3},{1,3},{1,3},{1,3},
    {1,3},{1,3},{1,3},{1,3},{2,3},{2,3},{2,3},{2,3},{2,2},{2,3},
    {2,3},{2,2},{2,3},{2,2},{2,3},{2,2},{2,3},{2,2},{2,2},{2,2},
    {2,3},{2,2},{2,2},{2,2},{2,2},{2,2},{1,2},{2,2},{2,2},{1,2},
    {1,2},{2,2},{1,2},{1,2},{2,2},{2,2},{3,2},{2,2},{3,2},{2,2},
    {3,2},{3,2},{3,2},{3,2},{3,2},{3,2},
}

local ROPE_SEGS = 33

local ropeMove = {-1, 1}   -- [1]=left, [2]=right (1-indexed)

local ropeDir, ropePos, ropeHold
local ropeX, ropeSide
local ropeInk

-- Rope_Ticker and Rope_Drawer are globals (assigned by Rope_Init or set to DoNothing)
Rope_Ticker = DoNothing
Rope_Drawer = DoNothing

local function DoRopeDrawer()
    local x   = ropeX * 8
    local y   = 0
    local seg = 1
    local dataIdx = ropePos + 1   -- 1-based index into ropeData

    -- draw top anchor pixel
    Video_DrawRopeSeg(x, ropeInk)

    if ropePos == 0 then
        ropeSide = bit.bxor(ropeSide, 1)
    end

    local sideDir = ropeMove[ropeSide + 1]   -- +1: Lua 1-based

    for s = 1, ROPE_SEGS - 1 do
        local d = ropeData[dataIdx]
        dataIdx = dataIdx + 1
        y = y + d[2]
        x = x - d[1] * sideDir

        local pos = y * WIDTH + x

        if minerWillyRope == 0 and bit.band(Video_GetPixel(pos), B_WILLY) ~= 0 then
            minerWillyRope = s
            ropeHold = 1
        end

        if minerWillyRope == s and ropeHold ~= 0 then
            minerWilly.x = bit.band(x, 248)
            minerWilly.y = y - 8

            local xmod = bit.band(x, 6)
            if xmod == 6 then
                minerWilly.frame = 1
            elseif bit.band(x, 4) ~= 0 then
                minerWilly.frame = 0
            else
                minerWilly.x = minerWilly.x - 8
                if bit.band(x, 2) ~= 0 then
                    minerWilly.frame = 3
                else
                    minerWilly.frame = 2
                end
            end

            minerWilly.tile  = math.floor(minerWilly.y / 8) * 32 + math.floor(minerWilly.x / 8)
            minerWilly.align = YALIGN(y)   -- y before deduction
        end

        Video_DrawRopeSeg(pos, ropeInk)
    end

    -- Allow Willy to jump or fall off the rope
    if minerWillyRope < 0 then
        minerWillyRope = minerWillyRope + 1
        ropeHold = 0
        return
    end

    if ropeHold ~= 0 and minerWilly.move ~= 0 then
        local dirIdx = bit.bxor(ropeDir, minerWilly.dir)
        local seg2   = minerWillyRope + ropeMove[dirIdx + 1]

        if Level_Dir(R_ABOVE) == 0 and seg2 < 15 then
            seg2 = 15
        end

        if seg2 < ROPE_SEGS then
            minerWillyRope = seg2
            return
        end

        minerWillyRope   = -16
        minerWilly.y     = bit.band(minerWilly.y, 124)
        minerWilly.air   = 0
    end
end

local function DoRopeTicker()
    local step = ropeMove[bit.bxor(ropeDir, ropeSide) + 1] * 2
    ropePos = ropePos + step
    if ropePos < 16 then
        ropePos = ropePos + step
    elseif ropePos == 54 then
        ropeDir = bit.bxor(ropeDir, 1)
    end
end

function Rope_Init()
    if gameLevel == QUIRKAFLEEG then
        ropeX   = 16
        ropeInk = 6
    elseif gameLevel == ONTHEROOF then
        ropeX   = 16
        ropeInk = 4
    elseif gameLevel == COLDSTORE then
        ropeX   = 16
        ropeInk = 6
    elseif gameLevel == SWIMMINGPOOL then
        ropeX   = 16
        ropeInk = 7
    elseif gameLevel == THEBEACH then
        ropeX   = 14
        ropeInk = 5
    else
        Rope_Ticker = DoNothing
        Rope_Drawer = DoNothing
        return
    end

    ropeDir  = 0
    ropePos  = 34
    ropeSide = 0
    ropeHold = 0

    Rope_Ticker = DoRopeTicker
    Rope_Drawer = DoRopeDrawer
end
