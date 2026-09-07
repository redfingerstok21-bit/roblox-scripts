-- ==========================================================
-- STEAL AN EGG - ACCURATE EQUIPPED PET SCANNER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Database Rank Pet
local PET_DATABASE = {
    ["chicken"] = 1, ["dog"] = 2, ["bird"] = 3, ["owl"] = 4, ["raccoon"] = 5, ["bear"] = 6, ["fox"] = 7,
    ["frog"] = 9, ["duckling"] = 10, ["catfish"] = 11, ["turtle"] = 12, ["swan"] = 14, ["axolotl"] = 15, ["leviathan"] = 16,
    ["jerboa"] = 17, ["fennec"] = 18, ["camel"] = 19, ["snake"] = 21, ["scorpion"] = 22, ["sand spider"] = 23, ["royal sphinx"] = 24,
    ["toucan"] = 25, ["chimpanzee"] = 26, ["crocodile"] = 27, ["gorilla"] = 28, ["spider"] = 30, ["tiger"] = 31, ["king snake"] = 32,
    ["penguin"] = 33, ["walrus"] = 34, ["polar bear"] = 35, ["sabertooth tiger"] = 36, ["mammoth"] = 37, ["yeti"] = 39, ["ice dragon"] = 40,
    ["lava gecko"] = 41, ["lava frog"] = 42, ["flaming bull"] = 43, ["cerberus"] = 46, ["phoenix"] = 47, ["lava dragon"] = 48,
    ["parrotfish"] = 49, ["swordfish"] = 50, ["shark"] = 51, ["orca"] = 52, ["kraken"] = 55, ["el maja"] = 56,
    ["dodo"] = 57, ["pterodactyl"] = 58, ["ankylosaurus"] = 59, ["triceratops"] = 60, ["trex"] = 63, ["mosasaurus"] = 64,
    ["centapede"] = 65, ["cosmic gecko"] = 66, ["cosmic gorilla"] = 67, ["cosmic dragon"] = 69, ["eternal lunar dragon"] = 71, ["unicorn"] = 72,
    ["crane"] = 73, ["salamander"] = 74, ["red panda"] = 75, ["koi"] = 76, ["snowy owl"] = 77, ["oni tiger"] = 79, ["kitsune"] = 80,
    ["crustacia"] = 81, ["spideron"] = 82, ["bladehide"] = 83, ["mantaris"] = 84, ["rhinotaur"] = 85, ["gorilla king"] = 87, ["nightflame"] = 88
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

-- Scan khusus Pet yang terpasang (Equipped) di Character
local function scanBestEquippedPet()
    local bestPetName = "-"
    local highestRank = -1

    pcall(function()
        local searchFolders = {
            LocalPlayer:FindFirstChild("EquippedPets"),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Pets"),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("EquippedPets"),
            LocalPlayer:FindFirstChild("Pets")
        }

        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, pet in ipairs(folder:GetChildren()) do
                    local isEquipped = pet:FindFirstChild("Equipped")
                    if isEquipped == nil or isEquipped.Value == true then
                        local pNameLower = string.lower(pet.Name)
                        for dbName, rank in pairs(PET_DATABASE) do
                            if pNameLower == dbName and rank > highestRank then
                                highestRank = rank
                                bestPetName = pet.Name
                            end
                        end
                    end
                end
            end
        end
    end)

    return bestPetName
end

local function getGameStats()
    local rawIncome, rawSpeed = "0", "0"
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            rawSpeed = char.Humanoid.WalkSpeed
        end
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Stats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local sName = string.lower(stat.Name)
                if string.find(sName, "income") or string.find(sName, "money") or string.find(sName, "cash") then
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
    local inc, spd = getGameStats()
    local payload = {
        pass = SECRET_PASS,
        username = LocalPlayer.Name,
        bestPet = scanBestEquippedPet(),
        cash = inc,
        speed = spd,
        equippedPets = getPetInfo(),
        sessionTime = string.format("%dh %dm", math.floor((os.time() - startTime) / 3600), math.floor(((os.time() - startTime) % 3600) / 60))
    }

    local req = request or http_request or (syn and syn.request)
    if req then
        pcall(function()
            req({
                Url = DASHBOARD_URL, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
end

task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
