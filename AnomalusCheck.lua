-- AnomalusCheck - Arcane Resistance Checker for Raids
-- Author: Fayz
-- Version: 1.0

local ADDON_PREFIX = "AnomalusCheck"
local ARCANE_RESIST_THRESHOLD = 200
local resistData = {}
local allRaidMembers = {}
local checkInProgress = false

-- Create the main frame
local frame = CreateFrame("Frame", "AnomalusCheckFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")

-- UI Frame
local ui = CreateFrame("Frame", "AnomalusCheckUI", UIParent)
ui:SetWidth(300)
ui:SetHeight(400)
ui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ui:SetFrameStrata("HIGH")
ui:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", function()
    this:StartMoving()
end)
ui:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)
ui:Hide()

-- Title
local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", ui, "TOP", -25, -15)
title:SetText("AnomalusCheck")

-- Author credit
local author = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
author:SetPoint("LEFT", title, "RIGHT", 5, 0)
author:SetTextColor(1, 1, 1)
author:SetText("By Fayz")

-- Drag hint
local dragHint = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragHint:SetPoint("TOP", title, "BOTTOM", 15, -2)
dragHint:SetText("|cFF888888(drag to move)|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- Refresh button
local refreshBtn = CreateFrame("Button", "AnomalusCheckRefreshBtn", ui, "UIPanelButtonTemplate")
refreshBtn:SetWidth(80)
refreshBtn:SetHeight(22)
refreshBtn:SetPoint("TOPLEFT", ui, "TOPLEFT", 15, -35)
refreshBtn:SetText("Refresh")
refreshBtn:SetScript("OnClick", function()
    AnomalusCheck_PerformCheck()
end)

-- Scroll frame for results
local scrollFrame = CreateFrame("ScrollFrame", "AnomalusCheckScroll", ui, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250)
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

-- Results text
local resultsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultsText:SetPoint("TOPLEFT", 0, 0)
resultsText:SetWidth(250)
resultsText:SetJustifyH("LEFT")
resultsText:SetText("Click Refresh to check raid AR")

-- Helper function to get player's arcane resistance
local function GetPlayerArcaneResist()
    local _, _, arcaneResist = UnitResistance("player", 5)
    return arcaneResist or 0
end

-- Helper function to check if player can perform checks
local function CanPerformCheck()
    if GetNumRaidMembers() > 0 then
        -- In a raid
        return IsRaidLeader() or IsRaidOfficer()
    elseif GetNumPartyMembers() > 0 then
        -- In a party, anyone can check
        return true
    end
    return false
end

-- Perform the resistance check
function AnomalusCheck_PerformCheck()
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000AnomalusCheck:|r You must be in a party or raid to perform a check.")
        return
    end
    
    if GetNumRaidMembers() > 0 and not CanPerformCheck() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000AnomalusCheck:|r Only raid leaders and assistants can perform checks.")
        return
    end
    
    resistData = {}
    allRaidMembers = {}
    checkInProgress = true
    
    -- Record all raid members at the start
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = UnitName("raid"..i)
            if name then
                allRaidMembers[name] = true
            end
        end
    else
        -- Party
        allRaidMembers[UnitName("player")] = true
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party"..i)
            if name then
                allRaidMembers[name] = true
            end
        end
    end
    
    -- Add my own data first
    local myAR = GetPlayerArcaneResist()
    resistData[UnitName("player")] = myAR
    
    -- Send the check request
    if GetNumRaidMembers() > 0 then
        SendAddonMessage(ADDON_PREFIX, "CHECK", "RAID")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AnomalusCheck:|r Checking raid arcane resistance...")
    else
        SendAddonMessage(ADDON_PREFIX, "CHECK", "PARTY")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AnomalusCheck:|r Checking party arcane resistance...")
    end
    
    -- Update display after a short delay to collect responses
    frame:SetScript("OnUpdate", function()
        if checkInProgress then
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed >= 2 then
                this.elapsed = 0
                checkInProgress = false
                AnomalusCheck_UpdateDisplay()
            end
        end
    end)
end

-- Update the display with collected data
function AnomalusCheck_UpdateDisplay()
    local output = ""
    local passCount = 0
    local failCount = 0
    local noAddonCount = 0
    local totalCount = 0
    
    -- Sort by arcane resist (highest first), then alphabetically for no-addon players
    local sortedNames = {}
    
    -- Add players who responded
    for name, ar in pairs(resistData) do
        table.insert(sortedNames, {name = name, ar = ar, hasAddon = true})
    end
    
    -- Add players who didn't respond
    for name, _ in pairs(allRaidMembers) do
        if not resistData[name] then
            table.insert(sortedNames, {name = name, ar = -1, hasAddon = false})
        end
    end
    
    -- Sort: addon users by AR descending, then non-addon users alphabetically
    table.sort(sortedNames, function(a, b)
        if a.hasAddon and not b.hasAddon then
            return true
        elseif not a.hasAddon and b.hasAddon then
            return false
        elseif a.hasAddon and b.hasAddon then
            return a.ar > b.ar
        else
            return a.name < b.name
        end
    end)
    
    -- Build output with better spacing
    for _, data in ipairs(sortedNames) do
        totalCount = totalCount + 1
        local colorCode
        local displayText
        
        if not data.hasAddon then
            colorCode = "|cFFFFFF00" -- Yellow
            displayText = data.name .. ": No addon"
            noAddonCount = noAddonCount + 1
        elseif data.ar >= ARCANE_RESIST_THRESHOLD then
            colorCode = "|cFF00FF00" -- Green
            displayText = data.name .. ": " .. data.ar .. " AR"
            passCount = passCount + 1
        else
            colorCode = "|cFFFF0000" -- Red
            displayText = data.name .. ": " .. data.ar .. " AR"
            failCount = failCount + 1
        end
        
        output = output .. colorCode .. displayText .. "|r\n\n"
    end
    
    -- Add summary at top with better formatting
    local summary = string.format("|cFFFFFF00Summary:|r %d/%d meet 200+ AR", passCount, totalCount)
    if noAddonCount > 0 then
        summary = summary .. string.format("\n|cFFFFFF00%d without addon|r", noAddonCount)
    end
    summary = summary .. "\n\n"
    
    resultsText:SetText(summary .. output)
    
    -- Adjust scroll child height
    scrollChild:SetHeight(math.max(350, resultsText:GetHeight() + 50))
    
    -- Show the UI
    ui:Show()
end

-- Event handler
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "AnomalusCheck" then
        -- Addon loaded
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AnomalusCheck loaded.|r Type /ac or /anomalus to check arcane resistance.")
        
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == ADDON_PREFIX then
            local message = arg2
            local sender = arg4
            
            if message == "CHECK" then
                -- Someone is requesting a check, respond with our AR
                local myAR = GetPlayerArcaneResist()
                SendAddonMessage(ADDON_PREFIX, "RESPONSE:" .. myAR, "RAID")
                
            elseif string.find(message, "RESPONSE:") then
                -- Got a response from someone
                local ar = tonumber(string.sub(message, 10))
                if ar and sender then
                    resistData[sender] = ar
                end
            end
        end
    end
end)

-- Slash commands
SLASH_ANOMALUSCHECK1 = "/anomalus"
SLASH_ANOMALUSCHECK2 = "/ac"
SlashCmdList["ANOMALUSCHECK"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "show" then
        ui:Show()
    elseif msg == "hide" then
        ui:Hide()
    elseif msg == "check" or msg == "" then
        AnomalusCheck_PerformCheck()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AnomalusCheck Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/ac or /anomalus - Perform AR check")
        DEFAULT_CHAT_FRAME:AddMessage("/ac show - Show results window")
        DEFAULT_CHAT_FRAME:AddMessage("/ac hide - Hide results window")
    end
end
