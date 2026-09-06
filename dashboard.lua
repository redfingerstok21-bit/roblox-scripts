-- ==========================================================
-- REVISED DASHBOARD SCRIPT (K,M,B,T FORMAT & CLEAN PET SCANNER)
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Fungsi Konversi Angka ke K, M, B, T, Q
local function formatNumber(n)
    n = tonumber(n)
    if not n then return "0" end
    if n >= 1e15 then return string.format("%.2fQ", n / 1e15) end
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.2fK", n / 1e3) end
    return tostring(math.floor(n))
end

-- 1. Scan Best Value Pet (Filter Teks UI Sistem)
local function scanBestPet()
    local bestPetName = "-"

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and label.Visible then
                    local txt = label.Text
                    
                    -- Hindari teks-teks UI sistem / aksi
                    local isBlacklisted = string.find(txt, "Select") or string.find(txt, "Fuse") or 
                                         string.find(txt, "PlusEquip") or string.find(txt, "EQUIP") or 
                                         string.find(txt, "Buy") or string.find(txt, "Active") or
                                         string.find(txt, "Divine Trail")
                    
                    if not isBlacklisted and txt ~= "" and not tonumber(txt) then
                        -- Ambil nama pet yang valid
                        local parentName = label.Parent.Name
                        if string.find(parentName, "Pet") or string.find(parentName, "Slot") or string.find(parentName, "Item") or string.find(parentName, "Card") then
                            bestPetName = txt
                            break
                        end
                    end
                end
            end
        end
    end)

    -- Alternatif pemindaian internal folder
    if bestPetName == "-" then
        local petFolder = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("Inventory")
        if petFolder then
            for _, pet in ipairs(petFolder:GetChildren()) do
                if pet.Name ~= "" then
                    bestPetName = pet.Name
                    break
                end
            end
        end
    end

    return bestPetName
end

-- 2. Membaca & Format Stats Income/s dan Speed
local function getGameStats()
    local incomeText = "0/s"
    local speedText = "0"

    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            speedText = formatNumber(char.Humanoid.WalkSpeed)
        end
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local name = string.lower(stat.Name)
                if string.find(name, "money") or string.find(name, "cash") or string.find(name, "income") then
                    incomeText = formatNumber(stat.Value) .. "/s"
                elseif string.find(name, "speed") then
                    speedText = formatNumber(stat.Value)
                end
            end
        end
    end)

    return incomeText, speedText
end

-- 3. Membaca Active Equipped Pets
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

-- 4. Pengiriman Data ke Dashboard Vercel
local function sendDashboardData()
    local bestPet = scanBestPet()
    local incomeSec, currentSpeed = getGameStats()
    local petInfo = getPetInfo()

    local elapsed = os.time() - startTime
    local sessionFormatted = string.format("%dh %dm", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60))

    local payload = {
        pass = SECRET_PASS,
        username = LocalPlayer.Name,
        bestPet = bestPet,
        cash = incomeSec,
        speed = currentSpeed,
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

-- Loop Pengiriman Data
task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
