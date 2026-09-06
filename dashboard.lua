-- ==========================================================
-- STRICT BEST PET SCANNER (STRICT QA & UI BUTTON FILTER)
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local DASHBOARD_URL = "https://roblox-dashboard-puce.vercel.app/api/update"
local SECRET_PASS = "AKUN_SAYA_SAJA_123"
local UPDATE_INTERVAL = 5 

local startTime = os.time()

-- 1. Konversi Format Angka Roblox Ke Angka Nyata (Sambil Memblokir "Qa" & UI Palsu)
local function parseRobloxValue(str)
    if not str or type(str) ~= "string" then return 0 end
    
    local lower = string.lower(str)
    
    -- Filter ketat: Abaikan kata-kata UI, tombol, dan istilah "qa" / "quick"
    if string.find(lower, "quick") or string.find(lower, "equip") or string.find(lower, "fuse") or 
       string.find(lower, "buy") or string.find(lower, "sell") or string.find(lower, "would") or 
       string.find(lower, "qa") or string.find(lower, "quality") or string.find(lower, "upgrade") then
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
    end

    return num
end

-- 2. Format Angka untuk Tampilan
local function formatNumber(val)
    if not val then return "0" end
    local num = tonumber(string.match(tostring(val), "%d+%.?%d*")) or 0

    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9  then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6  then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3  then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- 3. Pemindai Best Pet Khusus Nilai Riil (B / M / K)
local function scanBestEquippedPet()
    local bestPetName = "-"
    local maxStatValue = -1
    local bestStatText = ""

    pcall(function()
        -- CARA 1: Scan Folder Data Internal Game
        local searchFolders = {
            LocalPlayer:FindFirstChild("Pets"),
            LocalPlayer:FindFirstChild("EquippedPets"),
            LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Pets"),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Pets")
        }

        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, pet in ipairs(folder:GetChildren()) do
                    local statObj = pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Income") or pet:FindFirstChild("Value") or pet:FindFirstChild("Boost") or pet:FindFirstChild("Stat")
                    if statObj then
                        local val = tonumber(statObj.Value) or parseRobloxValue(tostring(statObj.Value))
                        if val > maxStatValue then
                            maxStatValue = val
                            bestPetName = pet.Name
                            if val > 0 then
                                bestStatText = formatNumber(val) .. "/s"
                            end
                        end
                    end
                end
            end
        end

        -- CARA 2: Scan PlayerGui Dengan Filter Ketat
        if bestPetName == "-" or maxStatValue <= 0 then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, label in ipairs(playerGui:GetDescendants()) do
                    if label:IsA("TextLabel") and label.Visible then
                        local txt = label.Text
                        local cleanTxt = string.lower(txt)

                        -- Hanya proses teks yang mempunyai angka dan mengandung pembagi /s atau simbol $, B, M, K
                        if string.match(txt, "%d") and (string.find(cleanTxt, "/s") or string.find(cleanTxt, "%$") or string.match(cleanTxt, "%d+%.?%d*[kmb]")) then
                            local val = parseRobloxValue(txt)
                            
                            if val > maxStatValue then
                                local parent = label.Parent
                                local pName = string.lower(parent.Name)
                                
                                -- Pastikan parent frame bukan tombol/UI sistem
                                local isSystemUI = string.find(pName, "button") or string.find(pName, "buy") or string.find(pName, "upgrade") or string.find(pName, "quick")
                                
                                if not isSystemUI then
                                    local foundName = ""

                                    -- Cari nama pet di label terdekat
                                    for _, sibling in ipairs(parent:GetChildren()) do
                                        if sibling:IsA("TextLabel") and sibling ~= label then
                                            local sTxt = sibling.Text
                                            local sClean = string.lower(sTxt)
                                            if sTxt ~= "" and not string.match(sTxt, "%d") and not string.find(sClean, "active") and not string.find(sClean, "equip") and not string.find(sClean, "fuse") and not string.find(sClean, "qa") then
                                                foundName = sTxt
                                                break
                                            end
                                        end
                                    end

                                    if foundName == "" and not string.find(pName, "frame") and not string.find(pName, "slot") and not string.find(pName, "scroll") then
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
