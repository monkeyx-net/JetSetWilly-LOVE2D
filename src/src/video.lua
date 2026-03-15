-- video.lua
-- 256×192 pixel buffer, sprite/tile/text rendering.
-- Mirrors the C video.c closely, with Love2D as the backend.

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

-- Pixel buffer: two parallel arrays of size WIDTH*HEIGHT
-- pixelInk[i]   = colour index 0-15
-- pixelPoint[i] = flags: B_LEVEL=1, B_ROBOT=2, B_WILLY=4
local pixelInk   = {}
local pixelPoint = {}
local pixelData  -- love.image.ImageData (the actual RGBA pixels)
local pixelImage -- love.graphics.Image  (GPU texture)
local pixelDirty = true

local borderR, borderG, borderB = 0, 0, 0

-- (viewport is computed dynamically in Video_Present each frame)

-- ── small charset (indices 0-127) ────────────────────────────────────────────
-- Format: {width, col0, col1, ...}  col bytes: bit0=top pixel
local charSet = {
    [0]={0},[1]={0},[2]={0},[3]={0},[4]={0},[5]={0},[6]={0},[7]={0},
    [8]={0},[9]={0},[10]={0},[11]={0},[12]={0},[13]={0},[14]={0},[15]={0},
    [16]={8,128,128,192,192,224,224,240,240},
    [17]={8,248,248,252,252,254,254,255,255},
    [18]={8,255,255,254,254,252,252,248,248},
    [19]={8,240,240,224,224,192,192,128,128},
    [20]={8,0,0,0,0,0,0,0,0},
    [21]={8,255,255,255,255,255,255,255,255},
    [22]={0},[23]={0},[24]={0},[25]={0},[26]={0},[27]={0},[28]={0},[29]={0},[30]={0},[31]={0},
    [32]={3,0,0,0},
    [33]={2,47,0},
    [34]={4,3,0,3,0},
    [35]={7,18,63,18,18,63,18,0},
    [36]={6,46,42,127,42,58,0},
    [37]={7,35,19,8,4,50,49,0},
    [38]={7,16,42,37,42,16,40,0},
    [39]={3,2,1,0},
    [40]={3,30,33,0},
    [41]={3,33,30,0},
    [42]={6,8,42,28,42,8,0},
    [43]={6,8,8,62,8,8,0},
    [44]={3,64,32,0},
    [45]={6,8,8,8,8,8,0},
    [46]={2,32,0},
    [47]={6,32,16,8,4,2,0},
    [48]={6,12,18,33,18,12,0},
    [49]={4,34,63,32,0},
    [50]={6,50,41,41,41,38,0},
    [51]={6,18,33,37,37,26,0},
    [52]={5,15,8,60,8,0},
    [53]={6,23,37,37,37,25,0},
    [54]={6,30,37,37,37,24,0},
    [55]={6,1,1,49,13,3,0},
    [56]={6,26,37,37,37,26,0},
    [57]={6,6,41,41,41,30,0},
    [58]={2,20,0},
    [59]={3,32,20,0},
    [60]={4,8,20,34,0},
    [61]={6,20,20,20,20,20,0},
    [62]={4,34,20,8,0},
    [63]={6,2,1,41,5,2,0},
    [64]={7,30,33,45,43,45,14,0},
    [65]={6,48,14,9,14,48,0},
    [66]={6,63,37,37,37,26,0},
    [67]={6,30,33,33,33,18,0},
    [68]={6,63,33,33,18,12,0},
    [69]={6,63,37,37,37,33,0},
    [70]={6,63,5,5,5,1,0},
    [71]={6,30,33,33,41,26,0},
    [72]={6,63,4,4,4,63,0},
    [73]={4,33,63,33,0},
    [74]={6,16,32,32,32,31,0},
    [75]={6,63,4,10,17,32,0},
    [76]={6,63,32,32,32,32,0},
    [77]={8,56,7,12,16,12,7,56,0},
    [78]={7,63,2,4,8,16,63,0},
    [79]={6,30,33,33,33,30,0},
    [80]={6,63,9,9,9,6,0},
    [81]={7,30,33,41,49,33,30,0},
    [82]={6,63,9,9,25,38,0},
    [83]={6,18,37,37,37,24,0},
    [84]={6,1,1,63,1,1,0},
    [85]={6,31,32,32,32,31,0},
    [86]={6,7,24,32,24,7,0},
    [87]={8,7,24,32,24,32,24,7,0},
    [88]={7,33,18,12,12,18,33,0},
    [89]={6,3,4,56,4,3,0},
    [90]={7,33,49,41,37,35,33,0},
    [91]={3,63,33,0},
    [92]={6,2,4,8,16,32,0},
    [93]={3,33,63,0},
    [94]={6,4,2,63,2,4,0},
    [95]={7,64,64,64,64,64,64,0},
    [96]={6,36,62,37,33,34,0},
    [97]={5,16,42,42,60,0},
    [98]={5,63,34,34,28,0},
    [99]={5,28,34,34,34,0},
    [100]={5,28,34,34,63,0},
    [101]={5,28,42,42,36,0},
    [102]={4,62,5,1,0},
    [103]={5,28,162,162,126,0},
    [104]={5,63,2,2,60,0},
    [105]={2,61,0},
    [106]={4,32,64,61,0},
    [107]={5,63,12,18,32,0},
    [108]={2,63,0},
    [109]={6,62,2,60,2,60,0},
    [110]={5,62,2,2,60,0},
    [111]={5,28,34,34,28,0},
    [112]={5,254,34,34,28,0},
    [113]={5,28,34,34,254,128},
    [114]={4,60,2,2,0},
    [115]={5,36,42,42,16,0},
    [116]={4,2,63,2,0},
    [117]={5,30,32,32,30,0},
    [118]={6,6,24,32,24,6,0},
    [119]={6,30,32,28,32,30,0},
    [120]={6,34,20,8,20,34,0},
    [121]={5,30,160,160,126,0},
    [122]={6,34,50,42,38,34,0},
    [123]={4,4,59,33,0},
    [124]={2,63,0},
    [125]={4,33,59,4,0},
    [126]={5,16,8,16,8,0},
    [127]={9,60,66,153,165,165,129,66,60,0},
}

-- large charset (characters 32-127, stored at index c-32+1 in Lua 1-based)
-- Each entry: 8 u16 column values (16 pixels tall)
local charSetLarge = {
    {0,0,0,0,0,0,0,0},                         -- 32 ' '
    {0,0,60,7166,7166,60,0,0},                  -- 33 '!'
    {0,7,15,0,0,15,7,0},                        -- 34 '"'
    {528,8190,8190,528,8190,8190,528,0},         -- 35 '#'
    {1592,3196,2116,6214,6214,4044,1928,0},      -- 36 '$'
    {6158,7694,1920,480,120,7198,7174,0},        -- 37 '%'
    {3968,8156,4222,4578,4030,8156,4160,0},      -- 38 '&'
    {0,0,8,15,7,0,0,0},                         -- 39 '\''
    {0,0,2040,4092,6150,4098,0,0},               -- 40 '('
    {0,0,4098,6150,4092,2040,0,0},               -- 41 ')'
    {128,672,992,448,992,672,128,0},             -- 42 '*'
    {0,128,128,992,992,128,128,0},               -- 43 '+'
    {0,0,8192,14336,6144,0,0,0},                 -- 44 ','
    {128,128,128,128,128,128,128,0},             -- 45 '-'
    {0,0,0,6144,6144,0,0,0},                     -- 46 '.'
    {6144,7680,1920,480,120,30,6,0},             -- 47 '/'
    {2040,4092,6150,4098,6150,4092,2040,0},      -- 48 '0'
    {0,4104,4108,8190,8190,4096,4096,0},         -- 49 '1'
    {7684,7942,4482,4290,4194,6206,6172,0},      -- 50 '2'
    {2052,6150,4162,4162,4162,8190,4028,0},      -- 51 '3'
    {510,510,4352,8160,8160,4352,256,0},         -- 52 '4'
    {2174,6270,4162,4162,4162,8130,3970,0},      -- 53 '5'
    {4088,8188,4166,4162,4162,8128,3968,0},      -- 54 '6'
    {6,6,7682,8066,450,126,62,0},               -- 55 '7'
    {4028,8190,4162,4162,4162,8190,4028,0},      -- 56 '8'
    {60,4222,4162,4162,6210,4094,2044,0},        -- 57 '9'
    {0,0,0,3096,3096,0,0,0},                     -- 58 ':'
    {0,0,4096,7192,3096,0,0,0},                  -- 59 ';'
    {0,192,480,816,1560,3084,2052,0},            -- 60 '<'
    {576,576,576,576,576,576,576,0},             -- 61 '='
    {0,2052,3084,1560,816,480,192,0},            -- 62 '>'
    {12,14,2,7042,7106,126,60,0},               -- 63 '?'
    {4088,8188,4100,5060,5060,5116,504,0},       -- 64 '@'
    {8176,8184,140,134,140,8184,8176,0},         -- 65 'A'
    {4098,8190,8190,4162,4162,8190,4028,0},      -- 66 'B'
    {2040,4092,6150,4098,4098,6150,3084,0},      -- 67 'C'
    {4098,8190,8190,4098,6150,4092,2040,0},      -- 68 'D'
    {4098,8190,8190,4162,4322,6150,7182,0},      -- 69 'E'
    {4098,8190,8190,4162,226,6,14,0},            -- 70 'F'
    {2040,4092,6150,4226,4226,3974,8076,0},      -- 71 'G'
    {8190,8190,64,64,64,8190,8190,0},            -- 72 'H'
    {0,0,4098,8190,8190,4098,0,0},               -- 73 'I'
    {3072,7168,4096,4098,8190,4094,2,0},         -- 74 'J'
    {4098,8190,8190,192,1008,8126,7182,0},       -- 75 'K'
    {4098,8190,8190,4098,4096,6144,7168,0},      -- 76 'L'
    {8190,8190,28,120,28,8190,8190,0},           -- 77 'M'
    {8190,8190,120,480,1920,8190,8190,0},        -- 78 'N'
    {4092,8190,4098,4098,4098,8190,4092,0},      -- 79 'O'
    {4098,8190,8190,4162,66,126,60,0},           -- 80 'P'
    {4092,8190,4098,7170,30722,32766,20476,0},   -- 81 'Q'
    {4098,8190,8190,66,450,8190,7740,0},         -- 82 'R'
    {3100,7230,4194,4162,4290,8078,3852,0},      -- 83 'S'
    {14,6,4098,8190,8190,4098,6,14},             -- 84 'T'
    {4094,8190,4096,4096,4096,8190,4094,0},      -- 85 'U'
    {1022,2046,3072,6144,3072,2046,1022,0},      -- 86 'V'
    {2046,8190,7168,2016,7168,8190,2046,0},      -- 87 'W'
    {7182,7998,1008,192,1008,7998,7182,0},       -- 88 'X'
    {30,62,4192,8128,8128,4192,62,30},           -- 89 'Y'
    {7694,7942,4482,4290,4194,6206,7198,0},      -- 90 'Z'
    {0,0,8190,8190,4098,4098,0,0},               -- 91 '['
    {6,30,120,480,1920,7680,6144,0},             -- 92 '\'
    {0,0,4098,4098,8190,8190,0,0},               -- 93 ']'
    {8,12,6,3,6,12,8,0},                        -- 94 '^'
    {16384,16384,16384,16384,16384,16384,16384,16384}, -- 95 '_'
    {6176,8190,8191,4129,4099,6150,2048,0},      -- 96 '`'
    {3584,7968,4384,4384,4064,8128,4096,0},      -- 97 'a'
    {4098,8190,4094,4128,4192,8128,3968,0},      -- 98 'b'
    {4032,8160,4128,4128,4128,6240,2112,0},      -- 99 'c'
    {3968,8128,4192,4130,4094,8190,4096,0},      -- 100 'd'
    {4032,8160,4384,4384,4384,6624,2496,0},      -- 101 'e'
    {4128,8188,8190,4130,6,12,0,0},             -- 102 'f'
    {20416,57312,36896,36896,65472,32736,32,0},  -- 103 'g'
    {4098,8190,8190,64,32,8160,8128,0},          -- 104 'h'
    {0,0,4128,8166,8166,4096,0,0},               -- 105 'i'
    {0,24576,57344,32768,32800,65510,32742,0},   -- 106 'j'
    {4098,8190,8190,768,1920,7392,6240,0},       -- 107 'k'
    {0,0,4098,8190,8190,4096,0,0},               -- 108 'l'
    {8160,8160,96,8128,96,8160,8128,0},          -- 109 'm'
    {32,8160,8128,32,32,8160,8128,0},            -- 110 'n'
    {4032,8160,4128,4128,4128,8160,4032,0},      -- 111 'o'
    {32800,65504,65472,36896,4128,8160,4032,0},  -- 112 'p'
    {4032,8160,4128,36896,65472,65504,32800,0},  -- 113 'q'
    {4128,8160,8128,4192,32,224,192,0},          -- 114 'r'
    {2112,6368,4512,4384,4896,7776,3136,0},      -- 115 's'
    {32,32,4092,8190,4128,6176,2048,0},          -- 116 't'
    {4064,8160,4096,4096,4064,8160,4096,0},      -- 117 'u'
    {0,2016,4064,6144,6144,4064,2016,0},         -- 118 'v'
    {4064,8160,6144,3840,6144,8160,4064,0},      -- 119 'w'
    {6240,7392,1920,768,1920,7392,6240,0},       -- 120 'x'
    {4064,40928,36864,36864,53248,32736,16352,0},-- 121 'y'
    {6240,7264,5664,4896,4512,6368,6240,0},      -- 122 'z'
    {0,192,192,4092,7998,4098,4098,0},           -- 123 '{'
    {0,0,0,8190,8190,0,0,0},                     -- 124 '|'
    {0,4098,4098,7998,4092,192,192,0},           -- 125 '}'
    {4,6,2,6,4,6,2,0},                          -- 126 '~'
    {2032,3096,6604,4644,4644,6476,3096,2032},   -- 127
}

local textInk = {0, 0}  -- [1]=paper, [2]=ink  (0-based colour indices)

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function idx(px, py)  return py * WIDTH + px  end  -- flat index (0-based)

local function applyPixel(i, ink)
    pixelInk[i] = ink
    local c = videoColour[ink]
    local px = i % WIDTH
    local py = math.floor(i / WIDTH)
    pixelData:setPixel(px, py, c[1]/255, c[2]/255, c[3]/255, 1)
    pixelDirty = true
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Video_Init()
    -- Create pixel buffer only once
    if not pixelData then
        pixelData  = love.image.newImageData(WIDTH, HEIGHT)
        pixelImage = love.graphics.newImage(pixelData)
        pixelImage:setFilter("nearest", "nearest")
        for i = 0, WIDTH * HEIGHT - 1 do
            pixelInk[i]   = 0
            pixelPoint[i] = 0
        end
    end
    pixelDirty = true
end

function Video_SetBorder(r, g, b)
    borderR, borderG, borderB = r/255, g/255, b/255
end

function Video_GetPixel(pos)
    return pixelPoint[pos] or 0
end

function Video_SetPixel(pos, ink)
    if pos < 0 or pos >= WIDTH * HEIGHT then return end
    pixelPoint[pos] = band(pixelPoint[pos] or 0, 0xFE)  -- clear bit 0 (B_LEVEL set separately)
    applyPixel(pos, ink)
end

function Video_PixelFill(pos, size)
    for i = pos, pos + size - 1 do
        if i >= 0 and i < WIDTH * HEIGHT then
            pixelPoint[i] = 0
            applyPixel(i, 0)
        end
    end
end

function Video_PixelPaperFill(pos, size, ink)
    for i = pos, pos + size - 1 do
        if i >= 0 and i < WIDTH * HEIGHT then
            if band(pixelPoint[i] or 0, 1) == 0 then
                applyPixel(i, ink)
            end
        end
    end
end

function Video_PixelInkFill(pos, size, ink)
    for i = pos, pos + size - 1 do
        if i >= 0 and i < WIDTH * HEIGHT then
            if band(pixelPoint[i] or 0, 1) ~= 0 then
                applyPixel(i, ink)
            end
        end
    end
end

function Video_CycleColours()
    for i = 0, WIDTH * HEIGHT - 1 do
        local newInk = band((pixelInk[i] or 0) + 3, 0x0F)
        pixelInk[i]  = newInk
        local c = videoColour[newInk]
        pixelData:setPixel(i % WIDTH, math.floor(i / WIDTH), c[1]/255, c[2]/255, c[3]/255, 1)
    end
    pixelDirty = true
    return pixelInk[0]
end

-- Draw rope segment (single pixel, sets B_LEVEL)
function Video_DrawRopeSeg(pos, ink)
    if pos < 0 or pos >= WIDTH * HEIGHT then return end
    pixelPoint[pos] = bor(pixelPoint[pos] or 0, B_LEVEL)
    applyPixel(pos, ink)
end

-- Draw an arrow trap (two horizontal pixel marks)
function Video_DrawArrow(pos, dir)
    local function setArrow(p)
        if p < 0 or p >= WIDTH*HEIGHT then return end
        pixelPoint[p] = bor(pixelPoint[p] or 0, bor(B_ROBOT, 1))
        applyPixel(p, 7)
    end
    local p = pos + dir
    setArrow(p); setArrow(p + 6)
    p = p + WIDTH
    setArrow(p + WIDTH); setArrow(p + WIDTH + 6)
    p = p - dir
    for b = 0, 7 do setArrow(p + b) end
end

-- Draw an 8×8 tile.
-- tile = tile index (0-511), what = 8-element array of bytes, paper/ink = colour idx
function Video_DrawTile(tileIdx, what, paper, ink)
    local tx, ty = TILE2XY(tileIdx)
    local colour = {paper, ink}
    for row = 0, 7 do
        local byte = what[row + 1] or 0
        for bit = 0, 7 do
            local px = tx + (7 - bit)  -- bit0 → rightmost (x+7)
            local py = ty + row
            local pos = py * WIDTH + px
            local b = band(byte, 1)
            pixelPoint[pos] = b  -- B_LEVEL flag
            applyPixel(pos, colour[b + 1])
            byte = rshift(byte, 1)
        end
    end
end

-- Draw a 16×16 miner sprite.  Returns true if collision with a robot occurred.
-- pos = flat pixel position of top-left (aligned to 8px boundary)
-- line = 16-element array of u16 values
-- level = attr split row (for colour switching)
function Video_DrawMiner(pos, line, level)
    pos = band(pos, bit.bnot(7))  -- align to 8-pixel boundary
    local startY = math.floor(pos / WIDTH)
    local startX = pos % WIDTH
    local die = false
    local attr = {0x8, 0x8, 0x8, 0x1}  -- ink per 4-row band
    for row = 0, 15 do
        local y = startY + row
        local word = line[row + 1] or 0
        local ink = attr[math.floor(y / bit.lshift(1, level)) + 1] or 0x8
        for bit = 0, 15 do
            local px = startX + (15 - bit)
            if band(word, 1) ~= 0 and px >= 0 and px < WIDTH and y >= 0 and y < HEIGHT then
                local p = y * WIDTH + px
                if band(pixelPoint[p] or 0, B_ROBOT) ~= 0 then
                    die = true
                end
                pixelPoint[p] = bor(pixelPoint[p] or 0, bor(B_WILLY, 1))
                applyPixel(p, ink)
            end
            word = rshift(word, 1)
        end
    end
    return die
end

-- Draw a 16×16 robot sprite (sets B_ROBOT flag)
function Video_DrawRobot(pos, line, ink)
    local startY = math.floor(pos / WIDTH)
    local startX = pos % WIDTH
    for row = 0, 15 do
        local y = startY + row
        local word = line[row + 1] or 0
        for bit = 0, 15 do
            local px = startX + (15 - bit)
            if band(word, 1) ~= 0 and px >= 0 and px < WIDTH and y >= 0 and y < HEIGHT then
                local p = y * WIDTH + px
                pixelPoint[p] = bor(pixelPoint[p] or 0, bor(B_ROBOT, 1))
                applyPixel(p, ink)
            end
            word = rshift(word, 1)
        end
    end
end

-- Draw a 16×16 sprite (no collision flags, sets paper/ink)
function Video_DrawSprite(pos, line, paper, ink)
    local startY = math.floor(pos / WIDTH)
    local startX = pos % WIDTH
    local colour = {paper, ink}
    for row = 0, 15 do
        local y = startY + row
        local word = line[row + 1] or 0
        for bit = 0, 15 do
            local px = startX + (15 - bit)
            if px >= 0 and px < WIDTH and y >= 0 and y < HEIGHT then
                local p = y * WIDTH + px
                local b = band(word, 1)
                pixelPoint[p] = b
                applyPixel(p, colour[b + 1])
            end
            word = rshift(word, 1)
        end
    end
end

-- Parse text control codes; returns new ink values if control, else nil
local function applyTextCode(str, idx_)
    local b = str:byte(idx_)
    if b == 1 then
        textInk[1] = str:byte(idx_ + 1)
        return true
    end
    if b == 2 then
        textInk[2] = str:byte(idx_ + 1)
        return true
    end
    return false
end

-- Measure text width (small font)
function Video_TextWidth(text)
    local w = 0
    local i = 1
    while i <= #text do
        local b = text:byte(i)
        if b == 1 or b == 2 then i = i + 2
        else
            local glyph = charSet[b]
            if glyph then w = w + (glyph[1] or 0) end
            i = i + 1
        end
    end
    return w
end

-- Write small text to the pixel buffer.
-- pos = flat pixel position of top-left of first character
function Video_Write(pos, text)
    local i = 1
    while i <= #text do
        local b = text:byte(i)
        if b == 1 or b == 2 then
            if applyTextCode(text, i) then i = i + 2 end
        else
            local glyph = charSet[b]
            if glyph then
                local width = glyph[1] or 0
                for col = 1, width do
                    local byte = glyph[col + 1] or 0
                    for bit = 0, 7 do
                        local p = pos + col - 1 + bit * WIDTH
                        if p >= 0 and p < WIDTH * HEIGHT then
                            local bv = band(byte, 1)
                            pixelPoint[p] = bv
                            applyPixel(p, textInk[bv + 1])
                        end
                        byte = rshift(byte, 1)
                    end
                end
                pos = pos + width
            end
            i = i + 1
        end
    end
end

-- Write large text (16px tall, 8px wide per char)
-- x, y = pixel coordinates
function Video_WriteLarge(x, y, text)
    local posY = y * WIDTH
    local curX = x
    local i = 1
    while i <= #text do
        local b = text:byte(i)
        if b == 1 or b == 2 then
            if applyTextCode(text, i) then i = i + 2 end
        else
            local glyph = charSetLarge[b - 31]  -- ' ' is index 1
            if glyph then
                for col = 0, 7 do
                    local cx = curX + col
                    if cx >= 0 and cx < WIDTH then
                        local colval = glyph[col + 1] or 0
                        for bit = 0, 15 do
                            local p = posY + cx + bit * WIDTH
                            if p >= 0 and p < WIDTH * HEIGHT then
                                local bv = band(colval, 1)
                                applyPixel(p, textInk[bv + 1])
                            end
                            colval = rshift(colval, 1)
                        end
                    end
                end
                curX = curX + 8
            end
            i = i + 1
        end
    end
end

-- Present the pixel buffer to screen
function Video_Present()
    if pixelDirty then
        pixelImage:replacePixels(pixelData)
        pixelDirty = false
    end
    local winW, winH = love.graphics.getDimensions()
    local scale = math.min(winW / WIDTH, winH / HEIGHT)
    local vW = WIDTH  * scale
    local vH = HEIGHT * scale
    local vX = math.floor((winW - vW) / 2)
    local vY = math.floor((winH - vH) / 2)
    love.graphics.setBackgroundColor(borderR, borderG, borderB)
    love.graphics.clear(borderR, borderG, borderB)
    love.graphics.draw(pixelImage, vX, vY, 0, scale, scale)
end
