-- ==========================================================
-- STEAL AN EGG - SPECIFIC BEST PET DETECTOR
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Database Hirarki Rarity & Pet Game "Steal an Egg" (Nilai lebih tinggi = Income/Value lebih tinggi)
local PET_DATABASE = {
    -- Divine (Tier 10)
    ["kitsune"] = 1000, ["unicorn"] = 1000, ["dreadscale"] = 1000, ["mecha dreadscale"] = 1000,
    
    -- Divine / High Secret Variants
    ["nightflame"] = 950, ["phoenix"] = 950,
    
    -- Eternal (Tier 9)
    ["gorilla king"] = 900, ["ice dragon"] = 900, ["oni tiger"] = 900, 
    ["eternal moon dragon"] = 900, ["mosasaurus"] = 900, ["krakenoid"] = 900,
    
    -- Secret (Tier 8)
    ["king snake"] = 800, ["yeti"] = 800, ["magma dragon"] = 800, 
    ["stag"] = 800, ["cosmic dragon"] = 800, ["mutant shark"] = 800, ["crocodon"] = 800,
    
    -- Cosmic (Tier 7)
    ["leviathan"] = 700, ["royal sphinx"] = 700, ["king mammoth"] = 700, 
    ["ember mammoth"] = 700, ["koi"] = 700, ["snowy owl"] = 700, ["crawler"] = 700,
    
    -- Mythic (Tier 6)
    ["tiger"] = 600, ["spider"] = 600, ["sabertooth tiger"] = 600, ["mammoth"] = 600,
    ["chillin chilli"] = 600, ["red panda"] = 600, ["cosmic gorilla"] = 600, 
    ["ankylosaurus"] = 600, ["froggo"] = 600,
    
    -- Legendary (Tier 5)
    ["brr brr patapim"] = 500, ["axolotl"] = 500, ["snake"] = 500, ["parrot"] = 500,
    ["polar bear"] = 500, ["fire snake"] = 500, ["salamander"] = 500, 
    ["cosmic gecko"] = 500, ["t-rex"] = 500, ["scorpio"] = 500,
    
    -- Epic (Tier 4)
    ["fox"] = 400, ["bear"] = 400, ["trulimero trulicina"] = 400, ["swan"] = 400,
    ["tob tobi tob tob"] = 400, ["crocodile"] = 400, ["walrus"] = 400, 
    ["magma turtle"] = 400, ["crane"] = 400,
    
    -- Rare (Tier 3)
    ["owl"] = 300, ["raccoon"] = 300, ["turtle"] = 300, ["camel"] = 300,
    ["toucan"] = 300, ["chimpanzee"] = 300, ["penguin"] = 300, 
    ["lava gecko"] = 300,
    
    -- Uncommon (Tier 2)
    ["bird"] = 200, ["catfish"] = 200,
    
    -- Common (Tier 1)
    ["chicken"] = 100, ["dog"] = 100, ["frog"] = 100, ["duckling"] = 100
}

-- 1. Format Angka untuk Tampilan Dashboard
local function formatNumber(val)
    if not val then return "0" end
    local num = tonumber(string.match(tostring(val), "%d+%.?%d*")) or 0

    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 2. Pemindai Nama Best Pet Berdasarkan Database Game Steal An Egg
local function scanBestEquippedPet()
    local bestPetName = "-"
    local highestRank = -1

    pcall(function()
        -- CARA A: Pemindaian Folder Internal Player (Folder Equipped/Pets)
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
                        if string.find(pNameLower, dbName) and rank > highestRank then
                            highestRank = rank
                            bestPetName = pet.Name
                        end
                    end
                end
            end
        end

        -- CARA B: Pemindaian Seluruh UI PlayerGui (Mencari Teks Nama Pet dari Database)
        if bestPetName == "-" or highestRank <= 0 then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txtLower = string.lower(label.Text)
                        
                        -- Cek apakah teks UI cocok dengan daftar nama pet
                        for dbName, rank in pairs(PET_DATABASE) do
                            if string.find(txtLower, dbName) then
                                local parent = label.Parent
                                local pNameLower = string.lower(parent.Name)
                                
                                -- Hindari membaca dari tombol/sistem UI global
                                local isSystem = string.find(pNameLower, "button") or string.find(pNameLower, "shop") or string.find(pNameLower, "index")
                                
                                if not isSystem and rank > highestRank then
                                    highestRank = rank
                                    bestPetName = label.Text
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    return bestPetName
end

-- 3. Membaca Money & Speed Player
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

-- 4. Membaca Status Pet Aktif
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

-- 5. Pengiriman Data Ke Dashboard Vercel
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
