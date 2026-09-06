-- ==========================================================
-- PERBAIKAN STABILITAS DASHBOARD & BEST EQUIPPED PET SCANNER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Fungsi Pengubah Angka Mentah ke Format K, M, B, T, Q
local function formatNumber(val)
    if not val then return "0" end
    
    -- Jika val sudah string dan punya huruf (seperti 19.32B), langsung kembalikan
    if type(val) == "string" and string.find(val, "%a") and not string.find(val, "e") then
        return val
    end

    local num = tonumber(val)
    if not num then
        -- Ekstrak angka dari teks jika bercampur karakter lain
        local extracted = string.match(tostring(val), "%d+%.?%d*")
        num = tonumber(extracted) or 0
    end

    if num >= 1e15 then return string.format("%.2fQ", num / 1e15) end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 1. Deteksi Pet Yang Dipakai (Equipped) Dengan Income / Stat Terbaik
local function scanBestEquippedPet()
    local bestPetName = "-"
    local maxStat = -1

    pcall(function()
        -- Prioritas 1: Scan dari Folder Internal Character/Player (Paling Akurat & Tidak Berubah-ubah)
        local equippedFolder = LocalPlayer.Character:FindFirstChild("Pets") 
            or LocalPlayer:FindFirstChild("EquippedPets") 
            or LocalPlayer:FindFirstChild("Pets")

        if equippedFolder then
            for _, pet in ipairs(equippedFolder:GetChildren()) do
                -- Cek penanda pet yang sedang di-equip
                local isEquipped = pet:FindFirstChild("Equipped") or pet:FindFirstChild("IsEquipped") or pet.Parent.Name == "EquippedPets"
                if isEquipped or equippedFolder.Name == "EquippedPets" or pet.Parent == LocalPlayer.Character then
                    local statVal = 0
                    local statObj = pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Value") or pet:FindFirstChild("Income") or pet:FindFirstChild("Boost")
                    
                    if statObj then
                        statVal = tonumber(statObj.Value) or 0
                    end

                    if statVal > maxStat then
                        maxStat = statVal
                        local formattedStat = statVal > 0 and (" (" .. formatNumber(statVal) .. "x)") or ""
                        bestPetName = pet.Name .. formattedStat
                    elseif bestPetName == "-" then
                        bestPetName = pet.Name
                    end
                end
            end
        end

        -- Prioritas 2: Jika tidak ada folder internal, gunakan Strict UI Filter (Abaikan Dialog/Sistem)
        if bestPetName == "-" then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txt = label.Text
                        
                        -- Blacklist total untuk teks dialog, konfirmasi, dan tombol UI
                        local isGarbage = string.find(txt, "Would you") or string.find(txt, "sell") or 
                                          string.find(txt, "Select") or string.find(txt, "Fuse") or 
                                          string.find(txt, "Equip") or string.find(txt, "Buy") or 
                                          string.find(txt, "Active") or string.find(txt, "for") or
                                          string.find(txt, "%?") or tonumber(txt) ~= nil or txt == ""

                        if not isGarbage then
                            local pName = label.Parent.Name
                            if string.find(pName, "Equipped") or string.find(pName, "Slot") or string.find(pName, "PetCard") then
                                bestPetName = txt
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    return bestPetName
end

-- 2. Membaca & Memformat Income/s dan Speed
local function getGameStats()
    local rawIncome = "0"
    local rawSpeed = "0"

    pcall(function()
        -- Speed dari Character Humanoid
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            rawSpeed = char.Humanoid.WalkSpeed
        end

        -- Income & Speed dari Leaderstats
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

    -- Konversi Hasil Akhir Menggunakan formatNumber
    local formattedIncome = formatNumber(rawIncome) .. "/s"
    local formattedSpeed = formatNumber(rawSpeed)

    return formattedIncome, formattedSpeed
end

-- 3. Membaca Status Jumlah Pet Aktif
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

-- 4. Pengiriman Data Ke Vercel
local function sendDashboardData()
    local bestPet = scanBestEquippedPet()
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

-- Loop Eksekusi
task.spawn(function()
    while true do
        sendDashboardData()
        task.wait(UPDATE_INTERVAL)
    end
end)
