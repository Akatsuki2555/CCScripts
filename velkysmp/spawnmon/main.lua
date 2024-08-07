-- ComputerCraftScripts
-- Copyright (C) 2024  Akatsuki

-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.

-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License along with this program.
-- If not, see <https://www.gnu.org/licenses/>.


VERSION = "1.08"

require("utils")
local json = require("json")

config_file = readFile("config.json")
config = json.decode(config_file)

local mon = peripheral.wrap(config.side)

if config.text_scale ~= nil then
  mon.setTextScale(config.text_scale)
end

local mon_width, mon_height = mon.getSize()

local setting_show_online_first = false
local has_loaded = false
local api_parsed = {}
local show_settings = false
local small_text = false

function drawMainScreen()
  if show_settings then
    -- Create background
    mon.setBackgroundColor(colors.white)

    mon.setCursorPos(5, 5)
    mon.write("                              ")
    mon.setCursorPos(5, 6)
    mon.write("                              ")
    mon.setCursorPos(5, 7)
    mon.write("                              ")
    mon.setCursorPos(5, 8)
    mon.write("                              ")
    mon.setCursorPos(5, 9)
    mon.write("                              ")
    mon.setCursorPos(5, 10)
    mon.write("                              ")

    mon.setTextColor(colors.black)

    mon.setCursorPos(6, 4)
    mon.write("Settings")

    mon.setCursorPos(6, 6)
    mon.write("[")

    mon.setTextColor(colors.orange)

    if setting_show_online_first then
      mon.write("X")
    else
      mon.write(" ")
    end

    mon.setTextColor(colors.black)

    mon.write("] Show online players first")

    mon.setCursorPos(6, 7)
    mon.write("[")

    mon.setTextColor(colors.orange)

    if small_text then
      mon.write("X")
    else
      mon.write(" ")
    end

    mon.setTextColor(colors.black)

    mon.write("] Smaller text")

    mon.setCursorPos(6, 9)
    mon.setTextColor(colors.orange)
    mon.write("[ Close ]")
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(colors.black)
  else
    if not has_loaded then
      local api_content = http.get("https://velkysmp-mon.vercel.app/api/get").readAll()
      api_parsed = json.decode(api_content)
      has_loaded = true
    end
    local api_sorted = {}

    if setting_show_online_first then
      for k, i in ipairs(api_parsed.players) do
        if i.online then
          table.insert(api_sorted, i)
        end
      end

      for k, i in ipairs(api_parsed.players) do
        if not i.online then
          table.insert(api_sorted, i)
        end
      end
    else
      api_sorted = api_parsed.players
    end

    if small_text then
      mon.setTextScale((config.text_scale or 1) / 2)
    else
      mon.setTextScale(config.text_scale or 1)
    end

    mon_width, mon_height = mon.getSize()

    mon.clear()
    mon.setCursorPos(1, 1)
    prettyWrite(mon, "Akatsuki's VelkySMP monitor - since 2024/02/25!")

    mon.setCursorPos(1, 3)
    prettyWrite(mon, "Top players by online and playtime")

    local items_count = mon_height - 5
    for k, v in ipairs(api_sorted) do
      if k > items_count then
        break
      end

      mon.setCursorPos(2, 4 + k)
      mon.write(k .. ". " .. v.name)
      mon.setCursorPos(mon_width - 20, 4 + k)
      mon.write(v.humantime)

      if v.online then
        mon.setCursorPos(mon_width - 5, 4 + k)
        mon.write("Online")
      end
    end

    mon.setCursorPos(1, mon_height)
    mon.write("Akatsuki ComputerCraft Monitor v" .. VERSION)

    mon.setCursorPos(40, mon_height)
    mon.write("Settings")
  end
end

mon.clear()

mon.setCursorPos(1, 1)
mon.write("Akatsuki's VelkySMP monitor - since 2024/02/25!")

mon.clear()

mon.setCursorPos(2, 3)
mon.write("Refreshing... this may take a while")

drawMainScreen()

rednet.open(config.modemSide)
rednet.host("Akatsuki", config.hostname)

local knownComputers = {}
local computerMsgsStatus = {}

while true do
  event, p1, p2, p3, p4, p5 = os.pullEventRaw()
  if event == "peripheral_detach" then
    -- p1 - side, p2 - type
    http.post(config.webhook, json.encode({
      content = "Peripheral " .. p1 .. " was detached! <@" .. config.userId .. ">"
    }), {
      ["Content-Type"] = "application/json"
    })
  end

  if event == "peripheral" then
    -- p1 - side, p2 - type
    http.post(config.webhook, json.encode({
      content = "Peripheral " .. p1 .. " was attached! <@" .. config.userId .. ">"
    }), {
      ["Content-Type"] = "application/json"
    })
  end

  if event == "timer" then
    -- p1 - timer id
    if timer == p1 then
      for index, value in pairs(computerMsgsStatus) do
        print("Computer " .. index .. " status: " .. value)
        if value == "sent" then
          http.post(config.webhook, json.encode({
            content = "Computer " ..
                index .. " did not respond when sent from " .. os.getComputerID() .. "! <@" .. config.userId .. ">"
          }), {
            ["Content-Type"] = "application/json"
          })
        end
        -- unregister computer
        print("Unregistering computer " .. index)
        computerMsgsStatus[index] = nil
      end

      rednet.broadcast("ping", "Akatsuki")
      -- set all known computers to "Sent"
      for index, value in pairs(knownComputers) do
        computerMsgsStatus[index] = "sent"
      end

      timer = os.startTimer(5)
    end
  end

  if event == "monitor_touch" then
    if p2 > 40 and p2 < 47 and p3 == mon_height then
      show_settings = not show_settings
      print("show settings")
      drawMainScreen()
    end

    if show_settings then
      if p2 == 7 and p3 == 6 then
        setting_show_online_first = not setting_show_online_first
        drawMainScreen()
      end

      if p2 == 7 and p3 == 7 then
        small_text = not small_text
        drawMainScreen()
      end

      if p2 >= 6 and p2 <= 13 and p3 == 9 then
        show_settings = false
        drawMainScreen()
      end
    end
  elseif event == "monitor_resize" then
    drawMainScreen()
  end

  if event == "rednet_message" then
    -- p1 - sender id, p2 - message, p3 - protocol
    if p2 == "ping" and p3 == "Akatsuki" then
      rednet.send(p1, "pong", "Akatsuki")
      print("Ping response sent to " .. tostring(p1))
    end

    if p2 == "pong" and p3 == "Akatsuki" then
      print("Received pong from " .. tostring(p1))
      computerMsgsStatus[p1] = "received"
      -- add to list of known computers if not already there
      if not knownComputers[p1] then
        print("Registering new known computer " .. tostring(p1))
        knownComputers[p1] = true
        http.post(config.webhook, json.encode({
          content = "Computer " .. p1 .. " has connected from " .. os.getComputerID() .. "!"
        }), {
          ["Content-Type"] = "application/json"
        })
      end
    end
  end
end
