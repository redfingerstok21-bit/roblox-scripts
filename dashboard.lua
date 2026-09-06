-- ==========================================================
-- STEAL AN EGG - ACCURATE BEST PET & STAT SCANNER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Database Tier Pet (Order Rarity)
local PET_DATABASE = {
    -- 🌲 Forest
    ["chicken"] = 1, ["dog"] = 2, ["bird"] = 3, ["owl"] = 4, ["raccoon"] = 5, ["bear"] = 6, ["fox"] = 7, ["brr brr patapim"] = 8,
    -- 🌊 Lake
    ["frog"] = 9, ["duckling"] = 10, ["catfish"] = 11, ["turtle"] = 12, ["trulimero trulicina"] = 13, ["swan"] = 14, ["axolotl"] = 15, ["leviathan"] = 16,
    -- 🏜️ Desert
    ["jerboa"] = 17, ["fennec"] = 18, ["camel"] = 19, ["tob tobi tob tob"] = 20, ["snake"] = 21, ["scorpion"] = 22, ["sand spider"] = 23, ["royal sphinx"] = 24,
    -- 🌴 Jungle
    ["toucan"] = 25, ["chimpanzee"] = 26, ["crocodile"] = 27, ["gorilla"] = 28, ["orangutini ananassini"] = 29, ["spider"] = 30, ["tiger"] = 31, ["king snake"] = 32,
    -- ❄️ Snow
    ["penguin"] = 33, ["walrus"] = 34, ["polar bear"] = 35, ["sabertooth tiger"] = 36, ["mammoth"] = 37, ["king mammoth"] = 38, ["yeti"] = 39, ["ice dragon"] = 40,
    -- 🌋 Volcano
    ["lava gecko"] = 41, ["lava frog"] = 42, ["flaming bull"] = 43, ["lava iguana"] = 44, ["chillin chilli"] = 45, ["cerberus"] = 46, ["phoenix"] = 47, ["lava dragon"] = 48,
    -- 🌊 Abyss Ocean
    ["parrotfish"] = 49, ["swordfish"] = 50, ["shark"] = 51, ["orca"] = 52, ["whale shark"] = 53, ["beluga whale"] = 54, ["kraken"] = 55, ["el maja"] = 56,
    -- 🦖 Prehistoric
    ["dodo"] = 57, ["pterodactyl"] = 58, ["ankylosaurus"] = 59, ["triceratops"] = 60, ["bronto"] = 61, ["tralaledon"] = 62, ["trex"] = 63, ["t-rex"] = 63, ["mosasaurus"] = 64,
    -- 🌌 Cosmic
    ["centapede"] = 65, ["cosmic gecko"] = 66, ["cosmic gorilla"] = 67, ["la vacca saturno saturnita"] = 68, ["cosmic dragon"] = 69, ["cosmic skeleton boss"] = 70, ["eternal lunar dragon"] = 71, ["unicorn"] = 72,
    -- 🌸 Cherry Blossom
    ["crane"] = 73, ["salamander"] = 74, ["red panda"] = 75, ["koi"] = 76, ["snowy owl"] = 77, ["stag"] = 78, ["oni tiger"] = 79, ["kitsune"] = 80,
    -- 🗿 Titan Temple
    ["crustacia"] = 81, ["spideron"] = 82, ["bladehide"] = 83, ["mantaris"] = 84, ["rhinotaur"] = 85, ["mutant shark"] = 86, ["gorilla king"] = 87, ["nightflame"] = 88,
    -- 🧠 Brainrot Eggs
    ["tung tung sahur"] = 89, ["bananita dolphinita"] = 90, ["belula beluga"] = 91, ["mangolini parrochini"] = 92, ["bomboclat crocolat"] = 93, ["strawberry elephant"] = 94,
    -- 👾 Monster Eggs
    ["scorpio"] = 95, ["froggo"] = 96, ["crawler"] = 97, ["crocodon"] = 98, ["krakenoid"] = 99, ["dreadscale"] = 100,
    ["mecha scorpio"] = 101, ["mecha froggo"] = 102, ["mecha crawler"] = 103, ["mecha crocodon"] = 104, ["mecha krakenoid"] = 105, ["mecha dreadscale"] = 106
}

local function formatNumber(val)
    if not val then return "0" end
    local num = tonumber(string.match(tostring(val), "%d+%.?%d*")) or 0

    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

local function scanBestEquippedPet()
    local bestPetName = "-"
    local highestRank = -1
    local extraInfo = ""

    pcall(function()
        -- 1. Scan Folder Pet Character / Player
        local searchFolders = {
            LocalPlayer:FindFirstChild("Pets"),
            LocalPlayer:FindFirstChild("EquippedPets"),
            LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Pets"),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Pets")
        }

        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, pet in ipairs(folder:GetChildren()) do
                    local pNameLower = string.lower(pet.Name)
                    for dbName, rank in pairs(PET_DATABASE) do
                        if string.find(pNameLower, dbName, 1, true) and rank > highestRank then
                            highestRank = rank
                            bestPetName = pet.Name
                            
                            local statVal = pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Income") or pet:FindFirstChild("Value") or pet:FindFirstChild("Weight")
                            if statVal then
                                extraInfo = " (" .. formatNumber(statVal.Value) .. ")"
                            end
                        end
                    end
                end
            end
        end

        -- 2. Scan UI jika belum ketemu dari folder
        if bestPetName == "-" then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txt = label.Text
                        local txtLower = string.lower(txt)
                        
                        for dbName, rank in pairs(PET_DATABASE) do
                            if string.find(txtLower, dbName, 1, true) and rank > highestRank then
                                local parentName = string.lower(label.Parent.Name)
                                if not string.find(parentName, "shop") and not string.find(parentName, "index") then
                                    highestRank = rank
                                    bestPetName = txt
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    if bestPetName ~= "-" then
        return bestPetName .. extraInfo
    end

    return "-"
end

local function getGameStats()
    local rawIncome = "0"
    local rawSpeed = "0"

    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            rawSpeed = char.Humanoid.WalkSpeed
        end

        local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Stats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local sName = string.lower(stat.Name)
                if string.find(sName, "income") or string.find(sName, "money") or string.find(sName, "cash") or string.find(sName, "coins") then
                    rawIncome = stat.Value
                elseif string.find(sName, "speed") then
                    rawSpeed = stat.Value
                end
            end
        end
    end)

    return formatNumber(rawIncome) .. "/s", formatNumber(rawSpeed)
end

local function getPetInfo()
    local petInfo = "0 Active"
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and string.find(label.Text, "Active") and not string.find(label.Text, "Would") then
                    petInfo = label.Text
                    break
                end
            end
        end
    end)
    return petInfo
end

local function sendDashboardData()
    local payload = {
        pass = SECRET_PASS,
        username = LocalPlayer.Name,
        bestPet = scanBestEquippedPet(),
        cash = select(1, getGameStats()),
        speed = select(2, getGameStats()),
        equippedPets = getPetInfo(),
        sessionTime = string.format("%dh %dm", math.floor((os.time() - startTime) / 3600), math.floor(((os.time() - startTime) % 3600) / 60))
    }

    local req = request or http_request or (syn and syn.request)
    if req then
        pcall(function()
            req({Url = DASHBOARD_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        end)
    end
end

task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
