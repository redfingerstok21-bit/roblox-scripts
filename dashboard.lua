-- ==========================================================
-- REAL NAMED BEST PET DETECTOR & ACCURATE PARSER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- 1. Konversi Format Angka Roblox (K, M, B, T, Qa, Qi) Ke Angka Nyata
local function parseRobloxValue(str)
    if not str or type(str) ~= "string" then return 0 end
    
    local lower = string.lower(str)
    -- Hindari kata-kata UI umum
    if string.find(lower, "quick") or string.find(lower, "equip") or string.find(lower, "fuse") or string.find(lower, "buy") or string.find(lower, "sell") then
        return 0
    end

    local numStr, suffix = string.match(str, "([%d%.]+)%s*([a-zA-Z]*)")
    local num = tonumber(numStr)
    if not num then return 0 end

    suffix = string.upper(suffix or "")

    if suffix == "K" then return num * 1e3
    elseif suffix == "M" then return num * 1e6
    elseif suffix == "B" then return num * 1e9
    elseif suffix == "T" then return num * 1e12
    elseif suffix == "QA" or suffix == "Q" then return num * 1e15
    elseif suffix == "QI" then return num * 1e18
    end

    return num
end

-- 2. Format Angka ke Tampilan Dashboard
local function formatNumber(val)
    if not val then return "0" end
    local num = tonumber(string.match(tostring(val), "%d+%.?%d*")) or 0

    if num >= 1e18 then return string.format("%.2fQi", num / 1e18) end
    if num >= 1e15 then return string.format("%.2fQa", num / 1e15) end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 3. Deteksi Nama Pet Asli Terkuat Berdasarkan Stat Income
local function scanBestEquippedPet()
    local bestPetName = "-"
    local maxStatValue = -1
    local bestStatText = ""

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, frame in ipairs(playerGui:GetDescendants()) do
                -- Hanya pindai elemen kartu/slot pet
                if frame:IsA("Frame") or frame:IsA("ImageLabel") then
                    local fName = string.lower(frame.Name)
                    
                    if string.find(fName, "pet") or string.find(fName, "slot") or string.find(fName, "card") or string.find(fName, "item") then
                        local currentPetName = ""
                        local currentStatVal = 0
                        local currentStatStr = ""

                        -- Pindai semua label teks dalam frame kartu pet
                        for _, child in ipairs(frame:GetChildren()) do
                            if child:IsA("TextLabel") and child.Visible then
                                local txt = child.Text
                                local cleanTxt = string.lower(txt)

                                local isSystem = string.find(cleanTxt, "equip") or string.find(cleanTxt, "select") or 
                                                 string.find(cleanTxt, "fuse") or string.find(cleanTxt, "active") or 
                                                 string.find(cleanTxt, "quick") or string.find(cleanTxt, "would")

                                if not isSystem and txt ~= "" then
                                    if string.match(txt, "%d") then
                                        local val = parseRobloxValue(txt)
                                        if val > currentStatVal then
                                            currentStatVal = val
                                            currentStatStr = txt
                                        end
                                    else
                                        -- Mengambil nama pet asli
                                        currentPetName = txt
                                    end
                                end
                            end
                        end

                        -- Jika di dalam kartu tidak ada teks nama, gunakan Nama Frame / Asset jika valid
                        if currentPetName == "" and currentStatVal > 0 then
                            if not string.find(fName, "slot") and not string.find(fName, "card") and not string.find(fName, "frame") then
                                currentPetName = frame.Name
                            end
                        end

                        -- Pilih Pet dengan Stat Tertinggi
                        if currentStatVal > maxStatValue and currentStatVal > 0 then
                            maxStatValue = currentStatVal
                            bestStatText = currentStatStr
                            if currentPetName ~= "" then
                                bestPetName = currentPetName
                            end
                        end
                    end
                end
            end
        end

        -- Backup: Jika dari UI nama masih belum ketemu, cari dari folder data game
        if bestPetName == "-" or bestPetName == "" then
            local petFolder = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("Inventory") or LocalPlayer.Character:FindFirstChild("Pets")
            if petFolder then
                for _, pet in ipairs(petFolder:GetChildren()) do
                    if pet.Name ~= "" and not string.find(string.lower(pet.Name), "folder") then
                        bestPetName = pet.Name
                        break
                    end
                end
            end
        end
    end)

    if bestPetName ~= "-" and bestStatText ~= "" then
        return bestPetName .. " (" .. bestStatText .. ")"
    end

    return bestPetName
end

-- 4. Membaca Stat Uang & Speed
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

-- 5. Status Pet Aktif
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

-- 6. Pengiriman Ke Dashboard Vercel
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
