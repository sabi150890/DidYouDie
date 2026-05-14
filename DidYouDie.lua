-- DidYouDie.lua
-- -------------------------------------------------------
-- 1. Locale system
-- -------------------------------------------------------
local L                = {}   -- active UI strings
local currentTauntLines = {}  -- active taunt lines
local LocalizeUI              -- forward declared; defined after all UI widgets exist

local SUPPORTED_LOCALES = {
    { code = "deDE", label = "Deutsch" },
    { code = "enUS", label = "English" },
}

local function GetActiveLocale()
    local saved = DidYouDieDB and DidYouDieDB.locale
    if saved then
        for _, loc in ipairs(SUPPORTED_LOCALES) do
            if loc.code == saved then return saved end
        end
    end
    local client = GetLocale()
    for _, loc in ipairs(SUPPORTED_LOCALES) do
        if loc.code == client then return client end
    end
    return "enUS"
end

local function ApplyLocale(code)
    local data = DidYouDieLocales and DidYouDieLocales[code]
    if not data then data = DidYouDieLocales and DidYouDieLocales["enUS"] end
    if not data then return end
    L = data.ui
    currentTauntLines = data.tauntLines
    if LocalizeUI then LocalizeUI() end
end

-- -------------------------------------------------------
-- 2. Datenbank & Hauptvariablen
-- -------------------------------------------------------
local function InitializeDB()
    if not DidYouDieDB then
        DidYouDieDB = {}
    end
    if not DidYouDieDB.count then
        DidYouDieDB.count = 0
    end
    if not DidYouDieDB.unlockKey then
        DidYouDieDB.unlockKey = 1
    end
    if not DidYouDieDB.customLines then
        DidYouDieDB.customLines = {}
    end
    if not DidYouDieDB.disabledDefaults then
        DidYouDieDB.disabledDefaults = {}
    end
    -- locale: nil = auto-detect from client
end

-- -------------------------------------------------------
-- Helper: build active line pool for random pick
-- -------------------------------------------------------
local function BuildActiveLines()
    local lines = {}
    for i, line in ipairs(currentTauntLines) do
        if not DidYouDieDB.disabledDefaults[i] then
            lines[#lines + 1] = line
        end
    end
    for _, line in ipairs(DidYouDieDB.customLines) do
        lines[#lines + 1] = line
    end
    return lines
end

-- -------------------------------------------------------
-- 3. Das visuelle Warn-Element
-- -------------------------------------------------------
local FRAME_W = 800
local FRAME_H = 180

local deathFrame = CreateFrame("Frame", "DidYouDieDeathFrame", UIParent)
deathFrame:SetSize(FRAME_W, FRAME_H)
deathFrame:SetFrameStrata("TOOLTIP")
deathFrame:Hide()

local deathText = deathFrame:CreateFontString(nil, "OVERLAY")
deathText:SetFont("Fonts\\FRIZQT__.TTF", 72, "OUTLINE, THICKOUTLINE")
deathText:SetPoint("TOP", deathFrame, "TOP", 0, 0)
deathText:SetTextColor(1, 0, 0, 1)

local tauntText = deathFrame:CreateFontString(nil, "OVERLAY")
tauntText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
tauntText:SetPoint("TOP", deathText, "BOTTOM", 0, -8)
tauntText:SetTextColor(1, 1, 1, 1)

-- -------------------------------------------------------
-- DVD-Bounce Physik
-- -------------------------------------------------------
local SPEED = 180
local posX, posY = 0, 0
local vx, vy     = SPEED, SPEED * 0.7

local function InitBounce()
    posX = 0
    posY = 50
    vx   = SPEED
    vy   = SPEED * 0.7
end

deathFrame:SetScript("OnUpdate", function(self, elapsed)
    local limitX = UIParent:GetWidth()  * 0.5 - FRAME_W * 0.5
    local limitY = UIParent:GetHeight() * 0.5 - FRAME_H * 0.5

    posX = posX + vx * elapsed
    posY = posY + vy * elapsed

    if posX >= limitX then
        posX = limitX; vx = -math.abs(vx)
    elseif posX <= -limitX then
        posX = -limitX; vx = math.abs(vx)
    end
    if posY >= limitY then
        posY = limitY; vy = -math.abs(vy)
    elseif posY <= -limitY then
        posY = -limitY; vy = math.abs(vy)
    end

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
end)

-- -------------------------------------------------------
-- Blinken-Animation
-- -------------------------------------------------------
local animationGroup = deathFrame:CreateAnimationGroup()

local alphaOut = animationGroup:CreateAnimation("Alpha")
alphaOut:SetFromAlpha(1); alphaOut:SetToAlpha(0.1)
alphaOut:SetDuration(0.4); alphaOut:SetOrder(1); alphaOut:SetSmoothing("IN_OUT")

local alphaIn = animationGroup:CreateAnimation("Alpha")
alphaIn:SetFromAlpha(0.1); alphaIn:SetToAlpha(1)
alphaIn:SetDuration(0.4); alphaIn:SetOrder(2); alphaIn:SetSmoothing("IN_OUT")

animationGroup:SetLooping("REPEAT")

-- -------------------------------------------------------
-- 4. Die "Geist freilassen" Sperre (konfigurierbare Taste)
-- -------------------------------------------------------
local KEY_OPTIONS = {
    { check = IsShiftKeyDown             },
    { check = IsControlKeyDown           },
    { check = IsAltKeyDown               },
    { check = function() return true end },
}

local selectedKeyIndex = 1

local function IsUnlockKeyDown()
    return KEY_OPTIONS[selectedKeyIndex].check()
end

local KEY_LABEL_KEYS = { "keyShift", "keyCtrl", "keyAlt", "keyNone" }

local function GetUnlockKeyLabel()
    return L[KEY_LABEL_KEYS[selectedKeyIndex]] or ""
end

local function LockDeathButton()
    local button = _G["StaticPopup1Button1"]
    if button and button:IsVisible() and StaticPopup1.which == "DEATH" then
        if IsUnlockKeyDown() then
            button:Enable()
            button:SetText(L.releaseNow or "RELEASE!")
        else
            button:Disable()
            button:SetText(GetUnlockKeyLabel() .. (L.holdKey or " HOLD!"))
        end
    end
end

local lockFrame = CreateFrame("Frame")
lockFrame:SetScript("OnUpdate", function(self, elapsed)
    if deathFrame:IsShown() then
        LockDeathButton()
    end
end)

-- -------------------------------------------------------
-- 5. Options-Panel
-- -------------------------------------------------------
local panel = CreateFrame("Frame", "DidYouDieOptionsPanel", UIParent)
panel.name = "DidYouDie"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)

local statText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)

local function UpdateMenuText()
    local count = (DidYouDieDB and DidYouDieDB.count) or 0
    statText:SetText((L.totalDeaths or "Deaths: ") .. "|cFFFF0000" .. count .. "|r")
end

local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", statText, "BOTTOMLEFT", 0, -8)
resetButton:SetSize(160, 25)
resetButton:SetScript("OnClick", function()
    DidYouDieDB.count = 0
    UpdateMenuText()
end)

-- Tastenauswahl
local keyHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
keyHeader:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -16)

local radioButtons = {}
local keyLabels    = {}

local function UpdateRadioButtons()
    for i, rb in ipairs(radioButtons) do
        rb:SetChecked(i == selectedKeyIndex)
    end
end

local prevAnchor = keyHeader
for i, option in ipairs(KEY_OPTIONS) do
    local rb = CreateFrame("CheckButton", "DidYouDieKey" .. i, panel, "UIRadioButtonTemplate")
    rb:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -6)
    rb.value = i

    local lbl = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    keyLabels[i] = lbl

    rb:SetScript("OnClick", function(self)
        selectedKeyIndex      = self.value
        DidYouDieDB.unlockKey = selectedKeyIndex
        UpdateRadioButtons()
    end)

    radioButtons[i] = rb
    prevAnchor = rb
end

-- -------------------------------------------------------
-- Sprachauswahl
-- -------------------------------------------------------
local languageHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
languageHeader:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -16)

local localeRadioButtons = {}
local selectedLocaleIndex = 1

local function UpdateLocaleRadioButtons()
    for i, rb in ipairs(localeRadioButtons) do
        rb:SetChecked(i == selectedLocaleIndex)
    end
end

local localePrevAnchor = languageHeader
for i, loc in ipairs(SUPPORTED_LOCALES) do
    local rb = CreateFrame("CheckButton", "DidYouDieLocale" .. i, panel, "UIRadioButtonTemplate")
    rb:SetPoint("TOPLEFT", localePrevAnchor, "BOTTOMLEFT", 0, -6)
    rb.value = i

    local lbl = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    lbl:SetText(loc.label)  -- language names are self-describing, not translated

    rb:SetScript("OnClick", function(self)
        selectedLocaleIndex           = self.value
        DidYouDieDB.locale            = SUPPORTED_LOCALES[self.value].code
        DidYouDieDB.disabledDefaults  = {}  -- reset: indices differ between locales
        ApplyLocale(DidYouDieDB.locale)
        UpdateLocaleRadioButtons()
    end)

    localeRadioButtons[i] = rb
    localePrevAnchor = rb
end

prevAnchor = localePrevAnchor

-- -------------------------------------------------------
-- Spruch-Liste
-- -------------------------------------------------------
local listHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
listHeader:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -20)

local resetLinesButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetLinesButton:SetPoint("LEFT", listHeader, "RIGHT", 12, 0)
resetLinesButton:SetSize(150, 22)

local toggleAllButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
toggleAllButton:SetPoint("LEFT", resetLinesButton, "RIGHT", 6, 0)
toggleAllButton:SetSize(150, 22)

local function UpdateToggleAllButton()
    local allDisabled = true
    for i = 1, #currentTauntLines do
        if not DidYouDieDB.disabledDefaults[i] then
            allDisabled = false
            break
        end
    end
    toggleAllButton:SetText(allDisabled and (L.enableAll or "Enable all") or (L.disableAll or "Disable all"))
end

-- -------------------------------------------------------
-- Tab-Leiste: Default | Custom
-- -------------------------------------------------------
local activeTab = "default"

local tabRow = CreateFrame("Frame", nil, panel)
tabRow:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -8)
tabRow:SetSize(560, 28)

local function MakeTabButton(parent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(100, 24)
    return btn
end

local tabDefault = MakeTabButton(tabRow)
tabDefault:SetPoint("BOTTOMLEFT", tabRow, "BOTTOMLEFT", 0, 0)

local tabCustom = MakeTabButton(tabRow)
tabCustom:SetPoint("LEFT", tabDefault, "RIGHT", 4, 0)

local function UpdateTabs()
    if activeTab == "default" then
        tabDefault:SetButtonState("PUSHED", true)
        tabCustom:SetButtonState("NORMAL")
    else
        tabDefault:SetButtonState("NORMAL")
        tabCustom:SetButtonState("PUSHED", true)
    end
end

local addBox = CreateFrame("EditBox", "DidYouDieAddBox", panel, "InputBoxTemplate")
addBox:SetPoint("TOPLEFT", tabRow, "BOTTOMLEFT", 2, -6)
addBox:SetSize(340, 22)
addBox:SetAutoFocus(false)
addBox:SetMaxLetters(200)

local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
addButton:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
addButton:SetSize(100, 22)

-- -------------------------------------------------------
-- ScrollFrame für die Spruch-Liste
-- -------------------------------------------------------
local SCROLL_HEIGHT = 260
local ROW_HEIGHT    = 22

local listHeaderBar = CreateFrame("Frame", nil, panel)
listHeaderBar:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -8)
listHeaderBar:SetSize(552, 20)

local listNameText = listHeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
listNameText:SetPoint("LEFT", listHeaderBar, "LEFT", 2, 0)
listNameText:SetTextColor(1, 0.82, 0, 1)

toggleAllButton:SetParent(listHeaderBar)
toggleAllButton:ClearAllPoints()
toggleAllButton:SetPoint("RIGHT", listHeaderBar, "RIGHT", 0, 0)
toggleAllButton:SetSize(130, 18)

local listBg = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
listBg:SetPoint("TOPLEFT", listHeaderBar, "BOTTOMLEFT", -4, -4)
listBg:SetSize(556, SCROLL_HEIGHT + 8)

local scrollFrame = CreateFrame("ScrollFrame", "DidYouDieScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", listHeaderBar, "BOTTOMLEFT", 2, -8)
scrollFrame:SetSize(516, SCROLL_HEIGHT)

local scrollChild = CreateFrame("Frame", "DidYouDieScrollChild", scrollFrame)
scrollChild:SetSize(500, 1)
scrollFrame:SetScrollChild(scrollChild)

local function SetRowBg(row, rowIndex, disabled)
    if not row.bg then
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
    end
    if disabled then
        row.bg:SetColorTexture(0.35, 0.08, 0.08, 0.55)
    elseif rowIndex % 2 == 0 then
        row.bg:SetColorTexture(0.0, 0.0, 0.0, 0.25)
    else
        row.bg:SetColorTexture(1.0, 1.0, 1.0, 0.03)
    end
end

local rowPool = {}

local function GetOrCreateRow(index)
    if not rowPool[index] then
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(498, ROW_HEIGHT)

        local toggle = CreateFrame("Button", nil, row)
        toggle:SetSize(20, 20)
        toggle:SetPoint("LEFT", row, "LEFT", 4, 0)

        local iconEnabled = toggle:CreateTexture(nil, "ARTWORK")
        iconEnabled:SetAllPoints()
        iconEnabled:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        iconEnabled:SetVertexColor(0.2, 1.0, 0.2, 1)
        toggle.iconEnabled = iconEnabled

        local iconDisabled = toggle:CreateTexture(nil, "ARTWORK")
        iconDisabled:SetAllPoints()
        iconDisabled:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        iconDisabled:SetVertexColor(1.0, 0.25, 0.25, 1)
        toggle.iconDisabled = iconDisabled

        local hl = toggle:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.4)

        row.toggle = toggle

        local sep = row:CreateTexture(nil, "BORDER")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        sep:SetColorTexture(1, 1, 1, 0.06)

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", toggle, "RIGHT", 6, 0)
        text:SetPoint("RIGHT", row, "RIGHT", 26, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        row.text = text

        local del = CreateFrame("Button", nil, row)
        del:SetSize(18, 18)
        del:SetPoint("RIGHT", row, "RIGHT", -2, 0)

        local delTex = del:CreateTexture(nil, "ARTWORK")
        delTex:SetAllPoints()
        delTex:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        delTex:SetVertexColor(1, 0.3, 0.3, 1)

        local delHl = del:CreateTexture(nil, "HIGHLIGHT")
        delHl:SetAllPoints()
        delHl:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        delHl:SetVertexColor(1, 0.7, 0.7, 1)

        row.del = del

        rowPool[index] = row
    end
    return rowPool[index]
end

local function SetToggleState(toggle, enabled)
    if enabled then
        toggle.iconEnabled:Show()
        toggle.iconDisabled:Hide()
    else
        toggle.iconEnabled:Hide()
        toggle.iconDisabled:Show()
    end
end

local RefreshList

RefreshList = function()
    if activeTab == "default" then
        listNameText:SetText(L.listDefault or "")
        toggleAllButton:Show()
    else
        listNameText:SetText(L.listCustom or "")
        toggleAllButton:Hide()
    end

    local customCount = #DidYouDieDB.customLines
    local tabCustomLabel = L.tabCustom or "Custom"
    tabCustom:SetText(customCount > 0 and (tabCustomLabel .. " (" .. customCount .. ")") or tabCustomLabel)

    local disabledCount = 0
    for _ in pairs(DidYouDieDB.disabledDefaults) do disabledCount = disabledCount + 1 end
    local tabDefaultLabel = L.tabDefault or "Default"
    local defaultLabel = disabledCount > 0
        and (tabDefaultLabel .. " (" .. (#currentTauntLines - disabledCount) .. "/" .. #currentTauntLines .. ")")
        or  (tabDefaultLabel .. " (" .. #currentTauntLines .. ")")
    tabDefault:SetText(defaultLabel)
    UpdateTabs()

    if activeTab == "custom" then
        addBox:Show(); addButton:Show()
    else
        addBox:Hide(); addButton:Hide()
    end

    for _, row in ipairs(rowPool) do
        row:Hide()
    end

    local y = 0
    local rowIndex = 0

    if activeTab == "default" then
        for i, line in ipairs(currentTauntLines) do
            rowIndex = rowIndex + 1
            local row = GetOrCreateRow(rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
            row:Show()

            local disabled = DidYouDieDB.disabledDefaults and DidYouDieDB.disabledDefaults[i]

            row.toggle:Show()
            row.text:SetPoint("LEFT", row.toggle, "RIGHT", 6, 0)
            SetToggleState(row.toggle, not disabled)
            SetRowBg(row, rowIndex, disabled)

            if disabled then
                row.text:SetTextColor(0.4, 0.4, 0.4, 1)
            else
                row.text:SetTextColor(0.75, 0.75, 0.75, 1)
            end

            local capturedI = i
            row.toggle:SetScript("OnClick", function()
                if DidYouDieDB.disabledDefaults[capturedI] then
                    DidYouDieDB.disabledDefaults[capturedI] = nil
                else
                    DidYouDieDB.disabledDefaults[capturedI] = true
                end
                RefreshList()
            end)

            row.text:SetText(line)
            row.del:Hide()

            y = y + ROW_HEIGHT
        end

    else
        if #DidYouDieDB.customLines == 0 then
            rowIndex = rowIndex + 1
            local row = GetOrCreateRow(rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
            row:Show()
            SetRowBg(row, 1, false)
            row.toggle:Hide()
            row.text:SetText("|cFF888888" .. (L.noCustomLines or "") .. "|r")
            row.text:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.del:Hide()
            y = y + ROW_HEIGHT
        else
            for ci, line in ipairs(DidYouDieDB.customLines) do
                rowIndex = rowIndex + 1
                local row = GetOrCreateRow(rowIndex)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
                row:Show()

                SetToggleState(row.toggle, true)
                row.toggle:Show()
                row.text:SetPoint("LEFT", row.toggle, "RIGHT", 6, 0)
                SetRowBg(row, rowIndex, false)
                row.toggle:SetScript("OnClick", nil)

                row.text:SetText(line)
                row.text:SetTextColor(1, 1, 1, 1)

                row.del:Show()
                local capturedCI = ci
                row.del:SetScript("OnClick", function()
                    table.remove(DidYouDieDB.customLines, capturedCI)
                    RefreshList()
                end)

                y = y + ROW_HEIGHT
            end
        end
    end

    scrollChild:SetHeight(math.max(y, SCROLL_HEIGHT))
    UpdateToggleAllButton()
end

-- Tab-Klick-Handler
tabDefault:SetScript("OnClick", function()
    activeTab = "default"
    RefreshList()
end)

tabCustom:SetScript("OnClick", function()
    activeTab = "custom"
    RefreshList()
end)

toggleAllButton:SetScript("OnClick", function()
    local allDisabled = true
    for i = 1, #currentTauntLines do
        if not DidYouDieDB.disabledDefaults[i] then
            allDisabled = false
            break
        end
    end
    if allDisabled then
        DidYouDieDB.disabledDefaults = {}
    else
        for i = 1, #currentTauntLines do
            DidYouDieDB.disabledDefaults[i] = true
        end
    end
    UpdateToggleAllButton()
    RefreshList()
end)

addButton:SetScript("OnClick", function()
    local txt = addBox:GetText()
    if txt and txt:match("%S") then
        txt = txt:match("^%s*(.-)%s*$")
        table.insert(DidYouDieDB.customLines, txt)
        addBox:SetText("")
        RefreshList()
    end
end)

addBox:SetScript("OnEnterPressed", function(self)
    addButton:Click()
    self:ClearFocus()
end)

resetLinesButton:SetScript("OnClick", function()
    DidYouDieDB.disabledDefaults = {}
    DidYouDieDB.customLines = {}
    RefreshList()
end)

panel:SetScript("OnShow", function()
    UpdateMenuText()
    UpdateToggleAllButton()
    RefreshList()
end)

-- -------------------------------------------------------
-- LocalizeUI: update all static widget texts
-- Called by ApplyLocale() whenever the language changes
-- -------------------------------------------------------
LocalizeUI = function()
    title:SetText(L.panelTitle or "DidYouDie")
    resetButton:SetText(L.resetCounter or "Reset")
    keyHeader:SetText(L.unlockKeyHeader or "")
    for i, lbl in ipairs(keyLabels) do
        lbl:SetText(L[KEY_LABEL_KEYS[i]] or "")
    end
    languageHeader:SetText(L.languageHeader or "Language:")
    listHeader:SetText(L.linesHeader or "")
    resetLinesButton:SetText(L.resetAll or "")
    addButton:SetText(L.addButton or "")
    UpdateMenuText()
    UpdateToggleAllButton()
    RefreshList()
end

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

-- -------------------------------------------------------
-- 6. Event-Handler
-- -------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DidYouDie" then
        InitializeDB()
        selectedKeyIndex = DidYouDieDB.unlockKey or 1
        UpdateRadioButtons()

        local activeCode = GetActiveLocale()
        for i, loc in ipairs(SUPPORTED_LOCALES) do
            if loc.code == activeCode then
                selectedLocaleIndex = i
                break
            end
        end
        UpdateLocaleRadioButtons()
        ApplyLocale(activeCode)  -- sets L, currentTauntLines, calls LocalizeUI

    elseif event == "PLAYER_DEAD" then
        DidYouDieDB.count = (DidYouDieDB.count or 0) + 1
        deathText:SetText((L.deathMessage or "You died!") .. "  (" .. (L.deathNr or "#") .. DidYouDieDB.count .. ")")
        local activeLines = BuildActiveLines()
        tauntText:SetText(#activeLines > 0 and activeLines[math.random(#activeLines)] or (L.noActiveLines or ""))
        InitBounce()
        deathFrame:Show()
        animationGroup:Play()
        UpdateMenuText()

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        if not UnitIsDeadOrGhost("player") then
            animationGroup:Stop()
            deathFrame:Hide()
        end
    end
end)
