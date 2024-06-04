require("utils")
local json = require("json")

local guestbookEntries = {}

if fs.exists("gustbook.json") then
    guestbookEntries = json.decode(readFile("guestbook.json"))
end

local screen = "main"
local term_width, term_height = term.getSize()

function drawScreen()
    term.clear()

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

    if screen == "main" then
        for index, value in ipairs(guestbookEntries) do
            -- render until out of screen
            local y = index * 3 + 2

            if y > term_height - 3 then
                break
            end

            term.setCursorPos(2, y)
            term.write(value.title)
            term.setCursorPos(3, y + 1)
            term.write(value.content)
        end

        term.setCursorPos(2, term_height - 1)
        term.write("[ Sign ]")

        local time = os.time()
        local dayUnfinished = os.day()
        local year = math.floor(dayUnfinished / 365) + 1
        local month = math.floor((dayUnfinished - (year - 1) * 365) / 30) + 1
        local day = dayUnfinished - (year - 1) * 365 - (month - 1) * 30 + 1
        local hours = math.floor(time)
        local minutes = math.floor((time - hours) * 100 * 0.6)

        term.setCursorPos(1,1)
        term.write(tostring(year) .. "/" .. tostring(month) .. "/" .. tostring(day) .. " " .. tostring(hours) .. ":" .. tostring(minutes))
    elseif screen == "sign" then
        term.setCursorPos(2, 2)
        prettyWrite(term, "Please enter the title of your entry.")

        os.loadAPI("keyboard")
        local title = keyboard.inputKeyboard()
        os.unloadAPI("keyboard")
        term.clear()

        term.setCursorPos(2, 2)
        prettyWrite(term, "Please enter the content of your entry.")

        os.loadAPI("keyboard")
        local content = keyboard.inputKeyboard()
        os.unloadAPI("keyboard")
        term.clear()

        table.insert(guestbookEntries, {
            title = title,
            content = content
        })

        writeFile("guestbook.json", json.encode(guestbookEntries))
        screen = "main"
        drawScreen()
    end
end

drawScreen()

local timer = os.startTimer(5)

while true do
    event, p1, p2, p3, p4, p5 = os.pullEvent()
    if event == "mouse_click" then
        if screen == "main" then
            if p2 > 1 and p2 < 10 and p3 == term_height - 1 then
                screen = "sign"
                drawScreen()
            end
        end
    end

    if event == "timer" then
        if timer == p1 then
            drawScreen()

            timer = os.startTimer(5)
        end
    end
end