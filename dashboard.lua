-- ==========================================================
-- BEST VALUE PET + DIVINE RARITY SCANNER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- 1. Memindai Best Value Pet & Divine Rarity dari Inventory / PlayerGui
local function scanPetsData()
    local bestPetName = "-"
    local bestDivineName = "-"
    
    local highestValue = 0
    local highestDivineValue = 0

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            -- Cari di UI Pet / Inventory Frame
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") then
                    local text = label.Text
                    
                    -- Deteksi Pet dengan Stat Value ($/s atau x Boost)
                    if string.find(text, "%$") or string.find(text, "/s") or string.find(text, "x") then
                        local parent = label.Parent
                        local petName = parent:FindFirstChild("PetName") or parent:FindFirstChild("Title") or parent
                        
                        -- Cek Rarity Divine
                        local isDivine = false
                        for _, child in ipairs(parent:GetDescendants()) do
                            if child:IsA("TextLabel") and string.find(string.lower(child.Text), "divine") then
                                isDivine = true
                                break
                            end
                        end

                        if isDivine then
                            bestDivineName = petName.Name ~= "" and petName.Name or "Divine Pet"
                        end

                        -- Asumsi nama Pet teratas adalah Best Pet
                        if bestPetName == "-" and petName.Name ~= "" then
                            bestPetName = petName.Name .. " (" .. text .. ")"
                        end
                    end
                end
            end
        end
    end)

    -- Alternatif scanning via folder internal Player
    if bestPetName == "-" then
        local petFolder = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("Inventory")
        if petFolder then
            for _, pet in ipairs(petFolder:GetChildren()) do
                local rarity = pet:FindFirstChild("Rarity")
                if rarity and string.lower(rarity.Value) == "divine" then
                    bestDivineName = pet.Name
                end
                bestPetName = pet.Name
            end
        end
    end

    return bestPetName, bestDivineName
end

-- 2. Membaca Stats Money & Speed
local function getGameStats()
    local rawMoney = 0
    local rawSpeed = 0

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and (label.Text == LocalPlayer.Name or label.Text == LocalPlayer.DisplayName) then
                    for _, sibling in ipairs(label.Parent:GetChildren()) do
                        if sibling:IsA("TextLabel") and sibling ~= label then
                            local txt = sibling.Text
                            if string.find(txt, "M") or string.find(txt, "B") or string.find(txt, "T") or string.find(txt, "K") then
                                if rawMoney == 0 then rawMoney = txt else rawSpeed = txt end
                            end
                        end
                    end
                end
            end
        end
    end)

    return tostring(rawMoney), tostring(rawSpeed)
end

-- 3. Membaca Pet Active
local function getPetInfo()
    local petInfo = "No Pets"
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and string.find(label.Text, "Active") then
                    petInfo = label.Text
                    break
                end
            end
        end
    end)
    return petInfo
end

-- 4. Pengiriman Data
local function sendDashboardData()
    local bestPet, divinePet = scanPetsData()
    local moneySecText, speedText = getGameStats()
    local petInfo = getPetInfo()

    local elapsed = os.time() - startTime
    local sessionFormatted = string.format("%dh %dm", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60))

    local payload = {
        pass = SECRET_PASS,
        username = LocalPlayer.Name,
        bestPet = bestPet,
        divinePet = divinePet,
        cash = moneySecText,
        speed = speedText,
        equippedPets = petInfo,
        sessionTime = sessionFormatted
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

-- Loop Pengiriman
task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
