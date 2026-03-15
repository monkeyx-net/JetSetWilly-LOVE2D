function love.conf(t)
    t.version       = "11.5"
    t.console       = false

    t.window.title          = "Jet-Set Willy"
    t.window.width          = 768   -- 256 * 3
    t.window.height         = 576   -- 192 * 3
    t.window.resizable      = true
    t.window.minwidth       = 256
    t.window.minheight      = 192
    t.window.vsync          = 1

    t.audio.mixwith = false
end
