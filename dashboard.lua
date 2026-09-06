-- ==========================================================
-- STABLE DASHBOARD SCRIPT (LOCKED UI & LEADERSTATS SCANNER)
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
    local num = tonumber(n)
    if not num then
        -- Jika sudah berbentuk string dengan huruf (seperti "1.2M"), kembalikan langsung
        return tostring(n)
    end
    if num >= 1e15 then return string.format("%.2fQ", num / 1e15) end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9 then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6 then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3 then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 1. Scan Best Value Pet secara Spesifik (Mengabaikan UI Aksi)
local function scanBestPet()
    local bestPetName = "-"

    pcall(function()
        -- Cek folder internal Player terlebih dahulu (Paling Stabil)
        local petFolder = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("Inventory")
        if petFolder then
            local maxStat = 0
            for _, pet in ipairs(petFolder:GetChildren()) do
                local val = pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Value") or pet:FindFirstChild("MultiplierVal")
                if val and tonumber(val.Value) and tonumber(val.Value) > maxStat then
                    maxStat = tonumber(val.Value)
                    bestPetName = pet.Name .. " (" .. formatNumber(maxStat) .. "x)"
                elseif bestPetName == "-" then
                    bestPetName = pet.Name
                end
            end
        end

        -- Jika folder tidak ada, cari dari UI khusus Equip/Inventory
        if bestPetName == "-" then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, obj in ipairs(playerGui:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Visible then
                        local txt = obj.Text
                        -- Hanya ambil dari frame yang bernama PetFrame / Slot / Card
                        local parentName = obj.Parent.Name
                        if (string.find(parentName, "Slot") or string.find(parentName, "Pet") or string.find(parentName, "Card")) 
                           and not string.find(txt, "Select") 
                           and not string.find(txt, "Fuse") 
                           and not string.find(txt, "Equip") 
                           and not string.find(txt, "Buy") 
                           and not string.find(txt, "Active") 
                           and not tonumber(txt) 
                           and txt ~= "" then
                            bestPetName = txt
                            break
                        end
                    end
                end
            end
        end
    end)

    return bestPetName
end

-- 2. Membaca Income/s dan Speed dari Leaderstats / Humanoid
local function getGameStats()
    local incomeText = "0/s"
    local speedText = "0"

    pcall(function()
        -- WalkSpeed Karakter
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            speedText = formatNumber(char.Humanoid.WalkSpeed)
        end
        
        -- Leaderstats Player
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Stats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local name = string.lower(stat.Name)
                if string.find(name, "income") or string.find(name, "money") or string.find(name, "cash") or string.find(name, "coins") then
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
    local petInfo = "0 Active"
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

-- 4. Kirim Data ke Dashboard
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

-- Loop
task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
