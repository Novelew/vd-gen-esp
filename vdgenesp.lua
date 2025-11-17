local DrawingTable = {}
local Map = workspace.Map
local function GetRepairProgress(generator)
    if not generator then return 0 end
    local progress = generator:GetAttribute("RepairProgress")
    if type(progress) ~= "number" then return 0 end
    return progress
end
local function GetProgressColor(progress)
    progress = math.clamp(progress, 0, 100)
    local r, g, b = 255, 0, 0
    if progress <= 50 then
        local factor = progress / 50
        r = 255
        g = math.floor(255 * factor)
        b = 0
    else
        local factor = (progress - 50) / 50
        r = math.floor(255 * (1 - factor))
        g = 255
        b = 0
    end
    return Color3.fromRGB(r, g, b)
end
local function scanGenerators()
    if not Map then return end
    local foundCount = 0
    local skippedCount = 0
    local descendants = Map:GetDescendants()
    for _, v in pairs(descendants) do
        if v:IsA("Model") then
            local attributes = v:GetAttributes()
            local hasRepairProgress = false
            for _, attrName in pairs(attributes) do
                if attrName == "RepairProgress" then
                    hasRepairProgress = true
                    break
                end
            end
            if not hasRepairProgress then continue end
            if DrawingTable[v.Address] then 
                skippedCount = skippedCount + 1
                continue 
            end
            local Hb = v:FindFirstChild("HitBox")
            if not Hb then continue end
            if not Hb.Position then continue end
            local GeneratorDrawing = Drawing.new("Text")
            GeneratorDrawing.Color = Color3.new(0, 1, 0)
            GeneratorDrawing.Visible = false
            GeneratorDrawing.Center = true
            GeneratorDrawing.Outline = true
            GeneratorDrawing.Text = "Generator: 0%"
            GeneratorDrawing.ZIndex = 10
            DrawingTable[v.Address] = {GeneratorDrawing, Hb.Position, Hb, v}
            foundCount = foundCount + 1
        end
    end
    if foundCount > 0 or skippedCount > 0 then
        print(string.format("Generator ESP: Found %d new generators, %d already tracked", foundCount, skippedCount))
    end
end
spawn(function()
    local hasScanned = false
    local lastMapState = false
    while true do
        local currentMap = workspace.Map
        if currentMap then
            local children = currentMap:GetChildren()
            local hasContent = #children > 0
            if hasContent and not hasScanned then
                Map = currentMap
                scanGenerators()
                hasScanned = true
                lastMapState = true
            elseif not hasContent and lastMapState then
                hasScanned = false
                lastMapState = false
                for address, data in pairs(DrawingTable) do
                    if data[1] then
                        data[1]:Remove()
                    end
                    DrawingTable[address] = nil
                end
            elseif not hasContent then
                lastMapState = false
            end
        else
            hasScanned = false
            lastMapState = false
            Map = nil
        end
        wait(5)
    end
end)
local FRAME_TIME = 1 / TARGET_FPS
local lastTick = os.clock()
spawn(function()
    while true do
        local now = os.clock()
        local delta = now - lastTick
        if delta < FRAME_TIME then
            task.wait(FRAME_TIME - delta)
        else
            task.wait()
        end
        lastTick = os.clock()
        for address, data in pairs(DrawingTable) do
            local Drawing = data[1]
            local HitBox = data[3]
            local Generator = data[4]
            if not HitBox or not HitBox.Parent then
                if Drawing then Drawing:Remove() end
                DrawingTable[address] = nil
                continue
            end
            local Position = HitBox.Position
            data[2] = Position
            local screenPos, onScreen = WorldToScreen(Position)
            if onScreen and Drawing then
                local progress = GetRepairProgress(Generator)
                local percentage = math.clamp(math.floor(progress), 0, 100)
                Drawing.Text = string.format("Generator: %d%%", percentage)
                Drawing.Color = GetProgressColor(progress)
                Drawing.Position = screenPos
                Drawing.Visible = true
            else
                Drawing.Visible = false
            end
        end
    end
end)
print("Generator ESP loaded!")
