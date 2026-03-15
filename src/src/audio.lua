-- audio.lua
-- Square-wave polyphonic music + SFX, matching the C audio.c closely.
-- Audio is generated in Lua at SAMPLERATE and queued to a Love2D source.

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

local VOLUME      = math.floor(32768 / 4)
local MUSICVOLUME = math.floor(VOLUME / 8)
local SFXVOLUME   = math.floor(VOLUME / 4)
local NCHANNELS   = 8
local NMUSIC      = 5
local NSFX        = 3

local EV_NOTEOFF = 0x00
local EV_NOTEON  = 0x10
local EV_END     = 0x40

-- Panning lookup (index 0-240 → 0-256)
local panTable = {
    256,255,254,253,252,251,250,249,248,247,246,245,244,243,242,240,
    239,238,237,236,235,234,233,232,231,230,229,228,227,225,224,
    223,222,221,220,219,218,217,216,215,214,213,212,210,209,208,
    207,206,205,204,203,202,201,200,199,198,197,195,194,193,192,
    191,190,189,188,187,186,185,184,183,182,180,179,178,177,176,
    175,174,173,172,171,170,169,168,167,165,164,163,162,161,160,
    159,158,157,156,155,154,153,152,150,149,148,147,146,145,144,
    143,142,141,140,139,138,137,135,134,133,132,131,130,129,128,
    127,126,125,124,123,122,121,119,118,117,116,115,114,113,112,
    111,110,109,108,107,106,104,103,102,101,100, 99, 98, 97, 96,
     95, 94, 93, 92, 91, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80,
     79, 78, 77, 76, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64,
     63, 62, 61, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48,
     47, 46, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32,
     31, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16,
     14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0
}

-- Frequency table: 32-bit phase increment per sample for MIDI note 0-127
-- (same values as C frequencyTable but stored in Lua integers)
local frequencyTable = {
    0x00184cbb,0x0019bea3,0x001b4688,0x001ce5bd,0x001e9da1,0x00206fae,0x00225d71,0x00246891,
    0x002692cb,0x0028ddfb,0x002b4c15,0x002ddf2d,0x00309976,0x00337d46,0x00368d11,0x0039cb7a,
    0x003d3b43,0x0040df5c,0x0044bae3,0x0048d122,0x004d2597,0x0051bbf7,0x0056982b,0x005bbe5b,
    0x006132ed,0x0066fa8b,0x006d1a25,0x007396f4,0x007a7686,0x0081beba,0x008975c6,0x0091a244,
    0x009a4b30,0x00a377ee,0x00ad3056,0x00b77cb7,0x00c265db,0x00cdf516,0x00da344a,0x00e72de9,
    0x00f4ed0c,0x01037d74,0x0112eb8c,0x01234488,0x01349660,0x0146efdc,0x015a60ad,0x016ef96d,
    0x0184cbb6,0x019bea2e,0x01b46891,0x01ce5bd2,0x01e9da1b,0x0206fae5,0x0225d719,0x02468913,
    0x02692cbe,0x028ddfb9,0x02b4c15a,0x02ddf2dc,0x0309976d,0x0337d45a,0x0368d125,0x039cb7a5,
    0x03d3b434,0x040df5cc,0x044bae33,0x048d1224,0x04d2597f,0x051bbf72,0x056982b5,0x05bbe5b7,
    0x06132edb,0x066fa8b7,0x06d1a249,0x07396f4b,0x07a76867,0x081beb9b,0x08975c67,0x091a2448,
    0x09a4b300,0x0a377ee5,0x0ad3056f,0x0b77cb68,0x0c265db7,0x0cdf5173,0x0da3448d,0x0e72de96,
    0x0f4ed0d9,0x1037d72a,0x112eb8ce,0x1234489d,0x134965f4,0x146efdcb,0x15a60ac1,0x16ef96f1,
    0x184cbb6f,0x19bea2c3,0x1b468941,0x1ce5bd2c,0x1e9da187,0x206fae82,0x225d719d,0x24689107,
    0x2692cc1e,0x28ddfb96,0x2b4c1582,0x2ddf2de3,0x309976df,0x337d4586,0x368d1283,0x39cb7a58,
    0x3d3b430f,0x40df5d05,0x44bae33a,0x48d1220f,0x4d25983c,0x51bbf72d,0x56982bf5,0x5bbe5ac8,
    0x6132edbe,0x66fa8c2a,0x6d1a23d8,0x7396f4b1,0x7a768772,0x81beb8a3,0x8975c674,0x91a245b2
}

-- Music scores (3 tracks, encoded as C arrays)
local MUS_STOP_VAL = MUS_STOP  -- forward ref
local musicScore = {
    -- MUS_TITLE (index 1)
    {16,58,0,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,0,0,3,1,16,56,0,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,0,0,3,1,16,54,0,19,66,13,3,1,19,70,13,3,1,19,73,13,3,1,19,66,13,3,1,19,70,13,3,1,19,73,13,0,0,3,1,16,51,0,19,66,13,3,1,19,71,13,3,1,19,75,13,3,1,19,66,13,3,1,19,71,13,3,1,19,75,13,0,0,3,1,16,53,0,19,65,13,3,1,19,69,13,3,1,19,75,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,0,0,3,1,16,53,0,19,65,13,3,1,19,70,13,3,1,19,72,13,3,1,19,63,13,3,1,19,69,13,3,1,19,72,13,0,0,3,1,16,46,0,17,53,0,19,61,13,3,1,19,65,13,3,1,19,70,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,0,20,77,13,3,1,19,70,13,4,0,3,1,19,73,13,4,1,20,77,6,0,0,1,0,3,0,4,1,16,45,0,17,53,0,19,65,0,20,77,13,3,1,19,72,13,3,1,19,75,13,3,1,19,65,13,3,1,19,72,13,3,1,19,75,13,3,1,19,65,13,3,1,19,72,13,3,1,19,75,13,3,0,4,1,19,65,0,20,77,13,3,1,19,72,13,4,0,3,1,19,75,13,4,1,20,77,6,0,0,1,0,3,0,4,1,16,46,0,19,65,0,20,77,13,3,1,19,70,13,3,1,19,73,13,3,1,19,65,13,3,1,19,70,13,3,1,19,73,13,0,0,3,0,4,1,16,51,0,19,66,0,20,78,13,3,1,19,70,13,3,1,19,75,13,3,1,19,66,13,3,1,19,70,13,3,1,19,75,13,0,0,3,0,4,1,16,56,0,19,65,0,20,77,13,3,1,19,68,13,3,1,19,73,13,3,1,19,65,13,3,1,19,68,13,3,1,19,73,13,0,0,3,0,4,1,16,56,0,19,66,0,20,75,13,3,1,19,68,13,3,0,4,1,19,72,13,3,1,19,66,0,20,80,13,3,1,19,68,13,3,0,4,1,19,72,13,0,0,3,1,16,61,0,19,65,0,20,73,13,3,1,19,68,13,3,0,4,1,19,73,13,3,1,19,65,13,3,1,19,68,13,3,1,19,73,13,3,1,19,65,13,3,1,19,68,13,3,1,19,73,13,3,1,19,65,13,3,1,19,68,13,3,1,19,73,13,0,0,3,1,16,49,0,19,64,13,3,1,19,68,13,3,1,19,73,13,3,1,19,64,13,3,1,19,68,13,3,1,19,73,13,3,1,19,64,13,3,1,19,68,13,3,1,19,73,13,3,1,19,64,0,20,76,13,3,1,19,68,13,4,0,3,1,19,73,13,4,1,20,76,6,0,0,3,0,4,1,16,47,0,19,64,0,20,76,13,3,1,19,68,13,3,1,19,74,13,3,1,19,64,13,3,1,19,68,13,3,1,19,74,13,3,1,19,64,13,3,1,19,68,13,3,1,19,74,13,3,0,4,1,19,64,0,20,76,13,3,1,19,68,13,4,0,3,1,19,74,13,4,1,20,76,6,0,0,3,0,4,1,16,45,0,19,64,0,20,76,13,3,1,19,69,13,0,0,3,1,19,73,13,3,1,19,64,0,16,44,13,3,1,19,68,13,3,1,19,73,13,0,0,3,1,19,64,0,16,43,13,3,1,19,70,13,3,1,19,73,13,3,0,4,1,19,63,0,20,75,13,3,1,19,70,13,3,0,4,1,19,73,13,3,0,0,1,16,44,0,19,63,0,20,75,13,3,1,19,68,13,3,1,19,71,13,3,1,19,63,13,3,1,19,68,13,3,1,19,71,13,0,0,3,0,4,1,16,49,0,19,64,0,20,76,13,3,1,19,68,13,0,0,3,0,4,1,19,70,13,3,1,19,61,0,20,73,0,16,52,13,3,1,19,68,13,3,0,4,1,19,70,13,0,0,3,1,19,63,0,20,75,0,16,51,13,3,1,19,68,13,3,1,19,71,13,3,1,19,63,13,3,1,19,68,13,3,1,19,71,13,3,0,4,0,0,1,16,51,0,19,63,0,20,75,13,3,1,19,67,13,3,1,19,70,13,3,1,19,63,13,3,1,19,67,13,3,1,19,70,13,0,0,3,0,4,1,16,56,0,19,68,13,3,1,19,71,13,3,1,19,75,13,3,1,19,68,13,3,1,19,71,13,3,1,19,75,13,3,1,19,68,83,0,0,3,1,0x40,MUS_STOP},
    -- MUS_GAME (index 2)
    {16,48,0,19,67,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,64,23,0,0,3,1,16,52,0,17,55,0,19,60,23,0,0,1,0,3,1,16,48,23,0,1,16,52,0,17,55,0,19,64,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,67,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,64,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,69,11,0,0,1,0,3,1,16,48,0,19,70,11,3,1,19,69,11,0,0,3,1,16,52,0,17,55,0,19,70,11,3,1,19,69,11,0,0,1,0,3,1,16,48,0,19,67,23,0,1,16,52,0,17,55,23,0,0,1,0,3,1,16,48,23,0,1,16,52,0,17,55,23,0,0,1,1,16,43,0,19,68,23,0,0,3,1,16,47,0,17,53,0,19,67,23,0,0,1,0,3,1,16,43,0,19,66,23,0,0,3,1,16,47,0,17,53,0,19,65,23,0,0,1,0,3,1,16,48,0,17,51,0,19,63,11,3,1,19,62,11,0,0,1,0,3,1,19,60,11,3,1,19,62,11,3,0,0,1,16,48,0,19,60,0,20,63,23,0,1,16,46,23,0,0,3,0,4,1,16,45,0,17,54,0,19,63,11,3,1,19,62,11,0,0,1,0,3,1,19,60,11,3,1,19,62,11,3,0,0,1,16,45,0,17,53,0,19,63,23,0,0,1,0,3,1,16,50,0,17,53,0,19,60,23,0,0,1,0,3,1,16,43,0,17,53,0,19,59,0,20,67,47,0,0,1,0,3,0,4,1,16,43,23,0,25,0,1,16,48,0,19,67,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,64,23,0,0,3,1,16,52,0,17,55,0,19,60,23,0,0,1,0,3,1,16,48,23,0,1,16,52,0,17,55,0,19,64,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,67,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,65,11,0,0,1,0,3,1,16,48,0,19,64,11,3,1,19,65,11,0,0,3,1,16,52,0,17,55,0,19,67,11,3,1,19,69,11,0,0,1,0,3,1,16,48,0,19,70,11,3,1,19,69,11,0,0,3,1,16,52,0,17,55,0,19,70,11,3,1,19,69,11,0,0,1,0,3,1,16,48,0,19,67,23,0,1,16,52,0,17,55,23,0,0,1,0,3,1,16,48,23,0,1,16,52,0,17,55,23,0,0,1,1,16,43,0,19,68,23,0,0,3,1,16,47,0,17,53,0,19,67,23,0,0,1,0,3,1,16,43,0,19,66,23,0,0,3,1,16,47,0,17,53,0,19,65,23,0,0,1,0,3,1,16,48,0,17,51,0,19,63,11,3,1,19,62,11,0,0,1,0,3,0,19,60,11,3,1,19,62,11,0,0,3,1,16,48,0,19,60,0,20,64,23,0,1,16,46,23,0,0,3,0,4,1,16,45,0,17,54,0,19,63,11,3,1,19,62,11,0,0,1,0,3,0,19,60,11,3,1,19,64,11,0,0,3,1,16,43,0,17,53,0,19,62,11,3,1,19,60,11,0,0,1,0,3,0,19,59,11,3,1,19,62,11,0,0,3,1,16,48,0,17,52,0,19,60,23,0,0,1,0,3,49,0x40,MUS_PLAY},
    -- MUS_LOADER (index 3)
    {0,30,16,60,6,16,62,6,16,64,6,16,65,6,16,67,6,16,69,6,16,71,6,16,72,6,0,0,0x40,MUS_STOP},
}

-- SFX pitch arrays (note numbers, terminated by <=0)
local sfxPitch = {
    [SFX_ITEM]     = {96,90,84,78,72,66,60,54,0},
    [SFX_DIE]      = {84,81,78,75,72,69,66,63,60,57,54,51,48,45,42,39,0},
    [SFX_GAMEOVER] = {36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,0},
    [SFX_ARROW]    = {48,54,60,66,72,78,84,90,0},
    [SFX_NONE]     = {0},
}

-- Channel state (8 channels: 0-2 SFX, 3-7 Music)
local channels = {}
for i = 0, 7 do
    local isMusic = (i >= 3)
    local vol = isMusic and MUSICVOLUME or 0
    channels[i] = {
        left  = {vol, -vol, 0},   -- [1]=phase0, [2]=phase1, [3]=current
        right = {-vol, vol, 0},
        phase = 0,
        freq  = 0,
        on    = false
    }
end

local musicChannels = {3, 4, 5, 6, 7}  -- channel indices for music

-- SFX channel state
local sfx = {}
for i = 0, NSFX-1 do
    sfx[i] = {pitch={0}, pitchIdx=1, length=0, clock=0, channel=i, doSfx="none"}
end

-- Music state
local musicIndex    = 0
local musicTempo    = AUDIO_TICKRATE
local musicPitch    = 0
local musicClock    = 0
local musicDelta    = 0
local curMusicData  = nil
local curMusicPos   = 1
local samplesMusic  = 0
local samplesSfx    = 0
local sfxClock      = 0

audioMusicPlaying = MUS_STOP
audioPanX = 128

-- Timers
local timerMusic = {rate=0, remainder=0, divisor=1, acc=0}
local timerSfx   = {rate=0, remainder=0, divisor=1, acc=0}

-- Love2D audio source
local audioSource = nil
local ABUF = 1024  -- samples per queue buffer
local audioAccum = 0  -- sample accumulation

local function channelPhase(ch)
    if not ch.on then
        ch.left[3]  = 0
        ch.right[3] = 0
        return
    end
    ch.phase = ch.phase + ch.freq
    -- LuaJIT bit.band returns a signed 32-bit int; wrap and check the sign bit
    ch.phase = band(ch.phase, 0xFFFFFFFF)
    local side = (ch.phase < 0) and 2 or 1
    ch.left[3]  = ch.left[side]
    ch.right[3] = ch.right[side]
end

local function setPan(ch, pan)
    local panIdx = math.max(1, math.min(241, pan + 1))
    local p = panTable[panIdx]
    local sv = math.floor(SFXVOLUME * p / 256)
    ch.left[1]   = sv;  ch.left[2]  = -sv
    ch.right[1]  = -sv; ch.right[2] = sv
end

local function musicReset()
    for _, mi in ipairs(musicChannels) do
        channels[mi].on = false
        channels[mi].left[3]  = 0
        channels[mi].right[3] = 0
    end
    curMusicData = musicScore[musicIndex] or musicScore[1]
    curMusicPos  = 1
    musicDelta   = 0
    musicClock   = 0
end

-- Generate one stereo sample pair → L, R  (integers, ±32768 range)
local function generateSample()
    -- Music timer
    if samplesMusic <= 0 then
        samplesMusic = Timer_Update(timerMusic)
        if audioMusicPlaying == MUS_PLAY and curMusicData then
            -- Process music events at current clock
            while musicDelta == musicClock do
                local data = curMusicData[curMusicPos]; curMusicPos = curMusicPos + 1
                local ch   = band(data, 0x0F)
                local ev   = band(data, 0xF0)
                if ev == EV_NOTEOFF then
                    local mch = musicChannels[ch + 1]
                    if mch then channels[mch].on = false end
                    local time = curMusicData[curMusicPos]; curMusicPos = curMusicPos + 1
                    musicDelta = musicDelta + time
                    if time ~= 0 then break end
                elseif ev == EV_NOTEON then
                    local note = curMusicData[curMusicPos]; curMusicPos = curMusicPos + 1
                    local mch  = musicChannels[ch + 1]
                    if mch and note and frequencyTable[note + musicPitch + 1] then
                        channels[mch].freq = frequencyTable[note + musicPitch + 1]
                        channels[mch].on   = true
                    end
                    local time = curMusicData[curMusicPos]; curMusicPos = curMusicPos + 1
                    musicDelta = musicDelta + time
                    if time ~= 0 then break end
                elseif ev == EV_END then
                    audioMusicPlaying = curMusicData[curMusicPos]
                    musicReset()
                    -- no break: let while re-check immediately (musicDelta==musicClock==0)
                else
                    break  -- unknown event, skip
                end
            end
            musicClock = musicClock + 1
        end
    end
    samplesMusic = samplesMusic - 1

    -- SFX timer
    if samplesSfx <= 0 then
        samplesSfx = Timer_Update(timerSfx)
        for si = 0, NSFX-1 do
            local s = sfx[si]
            if s.doSfx ~= "none" and s.clock == sfxClock then
                if s.doSfx == "willy" then
                    -- Turn channel on for one length period, then schedule off
                    channels[s.channel].on = true
                    s.clock = s.clock + s.length
                    s.doSfx = "off"
                elseif s.doSfx == "off" then
                    channels[s.channel].on = false
                    s.doSfx = "none"
                elseif s.doSfx == "on" then
                    -- Start pitch sequence: turn channel on then fall through to first note
                    channels[s.channel].on = true
                    s.doSfx = "play"
                end
                if s.doSfx == "play" then
                    local note = s.pitch[s.pitchIdx]
                    if note and note > 0 then
                        channels[s.channel].freq = frequencyTable[note + 1] or 0
                        s.clock    = s.clock + s.length
                        s.pitchIdx = s.pitchIdx + 1
                        if not s.pitch[s.pitchIdx] or s.pitch[s.pitchIdx] <= 0 then
                            s.doSfx = "off"
                        end
                    else
                        channels[s.channel].on = false
                        s.doSfx = "none"
                    end
                end
            end
        end
        sfxClock = sfxClock + 1
    end
    samplesSfx = samplesSfx - 1

    -- Mix all channels
    local L, R = 0, 0
    for i = 0, NCHANNELS - 1 do
        channelPhase(channels[i])
        L = L + channels[i].left[3]
        R = R + channels[i].right[3]
    end
    return L, R
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Audio_Init()
    Timer_Set(timerSfx,   SAMPLERATE, AUDIO_TICKRATE)
    Timer_Set(timerMusic, SAMPLERATE, AUDIO_TICKRATE)
    audioSource = love.audio.newQueueableSource(SAMPLERATE, 16, 2, 8)
    -- Do NOT call play() here: source is empty, playing immediately starves it.
    -- Audio_Update fills buffers first, then calls play().
end

function Audio_Music(music, playing)
    musicIndex = music
    musicPitch = 0
    musicTempo = AUDIO_TICKRATE
    musicReset()
    Timer_Set(timerMusic, SAMPLERATE, AUDIO_TICKRATE)
    -- Stop all SFX
    for i = 0, NSFX-1 do
        sfx[i].doSfx = "none"
        channels[i].on = false
    end
    samplesMusic = 0
    Audio_Play(playing)
end

function Audio_Play(playing)
    audioMusicPlaying = playing
    -- Enable/disable music channels
    if playing ~= MUS_PLAY then
        for _, mi in ipairs(musicChannels) do
            channels[mi].on = false
            channels[mi].left[3]  = 0
            channels[mi].right[3] = 0
        end
    end
end

function Audio_Sfx(sfxType)
    local si
    if sfxType == SFX_GAMEOVER or sfxType == SFX_DIE then
        sfx[0].doSfx = "none"; channels[0].on = false
        sfx[1].doSfx = "none"; channels[1].on = false
        si = 2
    elseif sfxType == SFX_ARROW then
        si = 2
    else
        si = 1
    end
    local s = sfx[si]
    s.pitch    = sfxPitch[sfxType] or sfxPitch[SFX_NONE]
    s.pitchIdx = 1
    s.clock  = sfxClock
    s.doSfx  = "on"
    if sfxType == SFX_GAMEOVER then
        s.length = 2
        channels[si].left[1]  =  SFXVOLUME
        channels[si].left[2]  = -SFXVOLUME
        channels[si].right[1] = -SFXVOLUME
        channels[si].right[2] =  SFXVOLUME
    else
        s.length = 1
        setPan(channels[si], audioPanX)
        if sfxType == SFX_ARROW then
            -- panned opposite side
            setPan(channels[si], 256 - audioPanX)
        end
    end
end

function Audio_WillySfx(note, length)
    if not frequencyTable[note + 1] then return end
    channels[0].freq = frequencyTable[note + 1]
    sfx[0].clock  = sfxClock
    sfx[0].length = length
    sfx[0].doSfx  = "willy"
    setPan(channels[0], audioPanX)
end

function Audio_ReduceMusicSpeed()
    musicPitch  = musicPitch - 1
    musicTempo  = math.max(6, musicTempo - 6)   -- floor at 6 to avoid stall/crash
    Timer_Set(timerMusic, SAMPLERATE, musicTempo)
end

function Audio_ResetTempo()
    musicPitch = 0
    musicTempo = AUDIO_TICKRATE
    Timer_Set(timerMusic, SAMPLERATE, musicTempo)
end

-- Called every love.update() to fill the audio queue
function Audio_Update()
    if not audioSource then return end
    while audioSource:getFreeBufferCount() > 0 do
        local sd = love.sound.newSoundData(ABUF, SAMPLERATE, 16, 2)
        for i = 0, ABUF - 1 do
            local L, R = generateSample()
            sd:setSample(i * 2,     math.max(-1, math.min(1, L / 32768)))
            sd:setSample(i * 2 + 1, math.max(-1, math.min(1, R / 32768)))
        end
        audioSource:queue(sd)
    end
    -- Restart if starved (source stops when it runs out of queued buffers)
    if not audioSource:isPlaying() then
        audioSource:play()
    end
end
