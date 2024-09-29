
function selectWheat()
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount(i) > 0 then
            if turtle.getItemDetail(i).name == "minecraft:wheat" then
                return true
            end
        end
    end
    return false
end

local function main()
    local flipped = false
    while true do
        if not turtle.forward() then
            if flipped then
                turtle.turnRight()
            else
                turtle.turnLeft()
            end

            if not turtle.forward() then
                turtle.turnLeft()
            end

            if flipped then
                turtle.turnLeft()
            else
                turtle.turnRight()
            end

            flipped = not flipped
        end

        selectWheat()
        turtle.placeDown()
        os.sleep(0.05)
    end
end

main()