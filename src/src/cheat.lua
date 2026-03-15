-- cheat.lua  -- "writetyper" cheat code + level select

local cheatCode = "writetyper"
local cheatPos  = 0

cheatEnabled    = 0
Cheat_Responder = nil   -- set below after Cheat_Disabled is defined

function Cheat_Enabled()
    local level = 0

    -- Keys 1-9, 0 map to levels 1-30 (0 = level 10, etc.)
    -- KEY_1..KEY_0 are the string names "1".."0"
    local numKeys = {"1","2","3","4","5","6","7","8","9","0",
                     "a","b","c","d","e","f","g","h","i","j",
                     "k","l","m","n","o","p","q","r","s","t"}
    for i, k in ipairs(numKeys) do
        if System_IsKey(k) then
            level = i
            break
        end
    end

    if not System_IsKey(KEY_ENTER) then
        Game_Pause(0)
        return
    end

    if level == 0 then return end

    if System_IsKey(KEY_LSHIFT) or System_IsKey(KEY_RSHIFT) then
        level = level + 30
    end

    level = level - 1   -- convert to 0-based
    if level == gameLevel then return end

    gameLevel = level
    Action = Game_InitRoom
end

function Cheat_Disabled()
    local ch = cheatCode:sub(cheatPos + 1, cheatPos + 1)   -- 1-indexed

    if gameLevel ~= FIRSTLANDING
    or minerWilly.y ~= 104
    or ch ~= gameInput then
        cheatPos = 0
        Game_Pause(0)
        return
    end

    cheatPos = cheatPos + 1

    if cheatPos < #cheatCode then
        return
    end

    Game_CheatEnabled()
    Cheat_Responder = Cheat_Enabled
end

Cheat_Responder = Cheat_Disabled
