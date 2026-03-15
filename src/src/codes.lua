-- codes.lua  -- Copy-protection code entry screen

local codesDigit = {
    43, 76, 15, 123, 206, 101, 35, 212, 99, 39, 8, 55, 204, 37, 1, 32, 2, 81,
    44, 202, 222, 181, 47, 83, 74, 179, 90, 45, 154, 27, 165, 71, 44, 238, 124, 65,
    228, 159, 217, 233, 237, 71, 102, 67, 46, 4, 238, 89, 30, 113, 29, 93, 30, 117,
    88, 217, 120, 36, 250, 185, 243, 93, 66, 98, 99, 100, 101, 102, 190, 232, 130, 9,
    77, 104, 132, 40, 140, 138, 24, 13, 109, 20, 87, 114, 33, 113, 129, 23, 15, 35,
    164, 121, 153, 228, 189, 93, 141, 153, 100, 129, 138, 40, 8, 128, 121, 115, 106, 64,
    148, 132, 59, 190, 142, 92, 85, 155, 133, 96, 69, 163, 99, 163, 94, 187, 103, 165,
    132, 76, 218, 159, 68, 26, 157, 112, 2, 60, 82, 211, 168, 173, 112, 205, 192, 112,
    208, 114, 180, 117, 212, 86, 89, 202, 178, 102, 209, 190, 26, 155, 202, 107, 24, 190,
    160, 109, 112, 29, 195, 210, 141, 118, 62, 180, 141, 213, 181, 134, 138, 115, 208, 118,
}

local codesSprite = {
    [0] = {32766,49923,49149,49149,65533,65533,65533,63997,61951,63999,63999,63999,63997,63997,65531,32766},
    [1] = {32766,50947,49149,49149,65533,65533,65533,61951,60671,64767,63999,62463,59391,57597,65523,32766},
    [2] = {32766,50691,49149,49149,49149,65533,65535,61951,60671,64767,61951,64767,60671,61949,65511,32766},
    [3] = {32766,50691,49149,49149,49149,49151,65535,65023,63999,61951,59903,57599,63999,63997,65435,32766},
}

local codesAttempt  = 1
local codesNeeded   = 0
local codesPos      = 0
local codesPosLast  = 0
local codesCode     = {0, 0, 0, 0}   -- 1-indexed
local codesKey      = -1

-- Cell display: \x1\x0\x2\x7\x14\x14  (ink/paper + 2 block chars)
local codesCell = {0x1, 0x0, 0x2, 0x7, 0x14, 0x14}

local function cellStr()
    local b = {}
    for _, v in ipairs(codesCell) do b[#b+1] = string.char(v) end
    return table.concat(b)
end

local function DrawCursor(pos)
    local pixel = 88 * WIDTH + 16 * 8
    codesCell[2] = codesCode[pos + 1]   -- +1 for Lua indexing (pos is 0-based)
    local s = cellStr()
    Video_Write(pixel + pos * 24, s)
    pixel = pixel + 8 * WIDTH
    Video_Write(pixel + pos * 24, s)
end

local function GetCode()
    local idx = System_Rnd() % 180   -- 0..179
    -- Build location string: column letter + row digit
    local col = string.char(idx % 18 + string.byte('A'))
    local row = string.char(math.floor(idx / 18) + string.byte('0'))
    Video_WriteLarge(29 * 8, 8 * 8, "\x02\x07" .. col .. row)

    codesNeeded   = codesDigit[idx + 1]   -- 1-indexed table
    codesCode[1]  = 0
    codesCode[2]  = 0
    codesCode[3]  = 0
    codesCode[4]  = 0
    codesKey      = -1
    codesPos      = 0
    codesPosLast  = 0

    codesCell[1] = 0x1
    codesCell[3] = 0x2
    DrawCursor(1)
    DrawCursor(2)
    DrawCursor(3)
end

local function DoCodesDrawer()
    codesCell[4] = 0x7
    DrawCursor(codesPos)

    if codesKey == 0 then return end

    codesCell[4] = codesCode[codesPosLast + 1]
    DrawCursor(codesPosLast)
    codesKey = 0
end

local function DoCodesTicker()
    if videoFlash then
        codesCell[1] = 0x2
        codesCell[3] = 0x1
    else
        codesCell[1] = 0x1
        codesCell[3] = 0x2
    end

    if codesKey < 1 then return end

    codesPosLast         = codesPos
    codesCode[codesPos + 1] = codesKey   -- +1: Lua 1-based
    codesPos             = bit.band(codesPos + 1, 3)
end

local function DoCodesResponder()
    if gameInput == KEY_1 then
        codesKey = 1
    elseif gameInput == KEY_2 then
        codesKey = 2
    elseif gameInput == KEY_3 then
        codesKey = 3
    elseif gameInput == KEY_4 then
        codesKey = 4
    elseif gameInput == KEY_ENTER then
        if codesCode[4] == 0 then return end

        -- Compute submitted code: (c0-1)<<6 | (c1-1)<<4 | (c2-1)<<2 | (c3-1)
        local submitted = bit.bor(
            bit.lshift(codesCode[1] - 1, 6),
            bit.bor(
                bit.lshift(codesCode[2] - 1, 4),
                bit.bor(
                    bit.lshift(codesCode[3] - 1, 2),
                    codesCode[4] - 1
                )
            )
        )

        if submitted == codesNeeded then
            Action = Title_Action
            return
        end

        if codesAttempt == 2 then
            DoQuit()
            return
        end

        Video_WriteLarge(0, 8 * 8, "\x01\x00\x02\x05Sorry, try code at location     ")
        codesAttempt = 2
        GetCode()

    elseif gameInput == KEY_ESCAPE then
        DoQuit()
    end
end

function Codes_Action()
    System_Border(0)
    Video_PixelFill(0, WIDTH * HEIGHT)
    Video_WriteLarge(0, 8 * 8, "\x01\x00\x02\x05Enter Code at grid location     ")

    -- Draw the 4 colour-hint sprites with separators
    Video_Write(88 * WIDTH + 3 * 8 - 1, "\x02\x07\x15")
    Video_DrawRobot(88 * WIDTH + 2 * 8, codesSprite[0], 1)
    Video_Write(88 * WIDTH + 6 * 8 - 1, "\x15")
    Video_DrawRobot(88 * WIDTH + 5 * 8, codesSprite[1], 2)
    Video_Write(88 * WIDTH + 9 * 8 - 1, "\x15")
    Video_DrawRobot(88 * WIDTH + 8 * 8, codesSprite[2], 3)
    Video_Write(88 * WIDTH + 12 * 8 - 1, "\x15")
    Video_DrawRobot(88 * WIDTH + 11 * 8, codesSprite[3], 4)

    GetCode()

    Responder = DoCodesResponder
    Ticker    = DoCodesTicker
    Drawer    = DoCodesDrawer
    Action    = DoNothing
end
