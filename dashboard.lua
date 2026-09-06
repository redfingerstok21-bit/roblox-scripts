-- ==========================================================
-- UNIVERSAL BEST PET SCANNER & STABILIZER
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- Mengonversi string UI seperti "1.5B/s" menjadi angka riil (1500000000) untuk dikalkulasi
local function parseStringToNumber(str)
    if not str then return 0 end
    local cleanStr = string.match(str, "([%d%.]+[kKmMbBtTqQ]?)")
    if not cleanStr then return 0 end
    
    local numStr = string.match(cleanStr, "[%d%.]+")
    local suffix = string.upper(string.match(cleanStr, "[kKmMbBtTqQ]") or "")
    
    local num = tonumber(numStr)
    if not num then return 0 end
    
    if suffix == "K" then num = num * 1e3
    elseif suffix == "M" then num = num * 1e6
    elseif suffix == "B" then num = num * 1e9
    elseif suffix == "T" then num = num * 1e12
    elseif suffix == "Q" then num = num * 1e15
    end
    
    return num
end

-- Format angka kembali untuk ditampilkan di Dashboard
local function formatNumber(val)
    if not val then return "0" end
    if type(val) == "string" and string.find(val, "%a") and not string.find(val, "e") then return val end

    local num = tonumber(string.match(tostring(val), "%d+%.?%d*")) or 0

    if num >= 1e15 then return string.format("%.2fQ", num / 1e15) end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 1. Scan UI Mencari Pet Dengan Income/Stat Tertinggi
local function scanBestEquippedPet()
    local bestPetName = "-"
    local maxStat = -1

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, label in ipairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and label.Visible then
                    local txt = label.Text
                    
                    -- Deteksi jika teks berisi angka stat pet (ada unsur /s, x, $, atau angka dengan K/M/B/T)
                    if string.match(txt, "%d") and (string.find(txt, "/s") or string.find(txt, "x") or string.find(txt, "%$") or string.match(txt, "%d+%.?%d*[KMBTQ]")) then
                        
                        -- Hindari mendeteksi UI uang utama (Leaderstats frame)
                        local parent = label.Parent
                        if parent and not string.find(parent.Name, "Leader") and not string.find(parent.Name, "Main") then
                            
                            local statVal = parseStringToNumber(txt)
                            
                            -- Jika nilai stat lebih besar dari yang pernah ditemukan
                            if statVal > maxStat then
                                
                                local tempName = "Unknown Pet"
                                -- Cari label lain di dalam frame yang sama (biasanya ini adalah Nama Pet)
                                for _, sibling in ipairs(parent:GetChildren()) do
                                    if sibling:IsA("TextLabel") and sibling ~= label then
                                        local sTxt = sibling.Text
                                        if not string.match(sTxt, "%d") and sTxt ~= "Equipped" and sTxt ~= "Active" and sTxt ~= "" then
                                            tempName = sTxt
                                        end
                                    end
                                end
                                
                                -- Filter teks UI sistem yang tidak sengaja terbaca
                                local isGarbage = string.find(string.lower(tempName), "select") or string.find(string.lower(tempName), "fuse") or string.find(string.lower(tempName), "equip")
                                if not isGarbage then
                                    maxStat = statVal
                                    bestPetName = tempName .. " (" .. txt .. ")"
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

-- 2. Membaca & Memformat Stats Global (Money & Speed)
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

-- 3. Membaca Total Pet Aktif
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
