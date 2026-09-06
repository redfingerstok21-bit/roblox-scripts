-- ==========================================================
-- ULTIMATE BEST PET SCANNER (DATA INTERNAL & GUI PARSER)
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
    if string.find(lower, "quick") or string.find(lower, "equip") or string.find(lower, "fuse") or string.find(lower, "buy") or string.find(lower, "sell") or string.find(lower, "would") then
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

-- 2. Format Angka untuk Tampilan
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

-- 3. Deteksi Best Value Pet (Mencari Income Pet Tertinggi)
local function scanBestEquippedPet()
    local bestPetName = "-"
    local maxStatValue = -1
    local bestStatText = ""

    pcall(function()
        -- CARA 1: Scan Folder Data Internal Player (Folder Pets / Equipped)
        local searchFolders = {
            LocalPlayer:FindFirstChild("Pets"),
            LocalPlayer:FindFirstChild("EquippedPets"),
            LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Pets"),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Pets")
        }

        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, pet in ipairs(folder:GetChildren()) do
                    local statObj = pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Income") or pet:FindFirstChild("Value") or pet:FindFirstChild("Boost")
                    local statVal = 0
                    
                    if statObj then
                        statVal = tonumber(statObj.Value) or parseRobloxValue(tostring(statObj.Value))
                    end

                    if statVal > maxStatValue then
                        maxStatValue = statVal
                        bestPetName = pet.Name
                        if statVal > 0 then
                            bestStatText = formatNumber(statVal) .. "/s"
                        end
                    end
                end
            end
        end

        -- CARA 2: Scan Langsung Semua Elemen Teks di PlayerGui (Sangat Luas)
        if bestPetName == "-" or maxStatValue <= 0 then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txt = label.Text
                        local cleanTxt = string.lower(txt)

                        -- Cari teks yang mengandung angka dan simbol income (seperti /s, $, B, M)
                        if string.match(txt, "%d") and (string.find(cleanTxt, "/s") or string.find(cleanTxt, "%$") or string.match(cleanTxt, "%d+%.?%d*[kmbtq]")) then
                            local val = parseRobloxValue(txt)
                            
                            -- Pastikan bukan teks global Income/s utama akun
                            if val > maxStatValue and val < (parseRobloxValue(tostring(LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Income") and LocalPlayer.leaderstats.Income.Value)) or 1e20) then
                                local parent = label.Parent
                                local foundName = ""

                                -- Cari label nama pet di sekitarnya
                                for _, sibling in ipairs(parent:GetChildren()) do
                                    if sibling:IsA("TextLabel") and sibling ~= label then
                                        local sTxt = sibling.Text
                                        local sClean = string.lower(sTxt)
                                        if sTxt ~= "" and not string.match(sTxt, "%d") and not string.find(sClean, "active") and not string.find(sClean, "equip") then
                                            foundName = sTxt
                                            break
                                        end
                                    end
                                end

                                if foundName == "" and parent.Name ~= "Frame" and parent.Name ~= "Slot" then
                                    foundName = parent.Name
                                end

                                if foundName ~= "" then
                                    maxStatValue = val
                                    bestPetName = foundName
                                    bestStatText = txt
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    if bestPetName ~= "-" then
        if bestStatText ~= "" then
            return bestPetName .. " (" .. bestStatText .. ")"
        else
            return bestPetName
        end
    end

    return "-"
end

-- 4. Membaca Money & Speed Player
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

-- 6. Pengiriman Ke Vercel
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
