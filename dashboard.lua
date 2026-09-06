-- ==========================================================
-- REVISED DASHBOARD SCRIPT (FIXED STATS & PET FILTER)
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- 1. Scan Best Value Pet & Divine Rarity (Abaikan UI Tombol)
local function scanPetsData()
    local bestPetName = "-"
    local bestDivineName = "-"

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and label.Visible then
                    local txt = label.Text
                    local parentName = label.Parent.Name
                    
                    -- Filter out tombol UI (seperti PlusEquip, Buy, Equip)
                    if not string.find(txt, "PlusEquip") and not string.find(txt, "EQUIP") and not string.find(txt, "Buy") then
                        -- Cek jika ada Rarity Divine
                        if string.find(string.lower(txt), "divine") then
                            bestDivineName = label.Parent:FindFirstChild("PetName") and label.Parent.PetName.Text or txt
                        end
                        
                        -- Mengambil nama pet pertama yang valid dari inventory / equipped
                        if bestPetName == "-" and (string.find(parentName, "Pet") or string.find(parentName, "Slot") or string.find(parentName, "Item")) then
                            if txt ~= "" and not tonumber(txt) then
                                bestPetName = txt
                            end
                        end
                    end
                end
            end
        end
    end)

    return bestPetName, bestDivineName
end

-- 2. Membaca Stats Income/s dan Speed Secara Fleksibel
local function getGameStats()
    local incomeText = "0/s"
    local speedText = "0"

    -- Cara 1: Cek dari Humanoid WalkSpeed & Leaderstats
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            speedText = tostring(math.floor(char.Humanoid.WalkSpeed))
        end
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local name = string.lower(stat.Name)
                if string.find(name, "money") or string.find(name, "cash") or string.find(name, "income") then
                    incomeText = tostring(stat.Value) .. "/s"
                elseif string.find(name, "speed") then
                    speedText = tostring(stat.Value)
                end
            end
        end
    end)

    -- Cara 2: Pindai Seluruh UI Teks jika Leaderstats kosong
    if incomeText == "0/s" or speedText == "0" then
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txt = label.Text
                        -- Mencari pola format angka K/M/B/T dengan /s atau SPD
                        if string.find(txt, "/s") or (string.find(txt, "M") and string.find(label.Parent.Name, "Money")) then
                            incomeText = txt
                        elseif (string.find(txt, "SPD") or string.find(label.Parent.Name, "Speed")) and not string.find(txt, "Plus") then
                            speedText = txt
                        end
                    end
                end
            end
        end)
    end

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
    local bestPet, divinePet = scanPetsData()
    local incomeSec, currentSpeed = getGameStats()
    local petInfo = getPetInfo()

    local elapsed = os.time() - startTime
    local sessionFormatted = string.format("%dh %dm", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60))

    local payload = {
        pass = SECRET_PASS,
        username = LocalPlayer.Name,
        bestPet = bestPet,
        divinePet = divinePet,
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
