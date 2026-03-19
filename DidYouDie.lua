-- DidYouDie.lua
-- -------------------------------------------------------
-- 1. Datenbank & Hauptvariablen
-- -------------------------------------------------------
local DEFAULT_TAUNT_LINES = {
    -- Klassiker
    "Na keinen CD gezogen?",
    "Skill issue.",
    "Touch grass, dann touch Wiederbelebung.",
    "Der Boden ist dein Freund jetzt.",
    "GG EZ.",
    "Hast du den Raidboss um Erlaubnis gefragt?",
    "Dein Heiler weint gerade.",
    "Wenigstens stirbst du konsistent.",
    "Schon wieder? Respekt für die Ausdauer.",
    "Der Friedhof kennt deinen Namen auswendig.",
    "Vielleicht hilft ein neues Talent-Build.",
    "Das nächste Mal einfach nicht sterben.",
    -- Heiler-Witze
    "Dein Heiler war gerade AFK. Natürlich.",
    "Healer: 'Ich hab geheilt!' Du: *tot*",
    "Schon mal überlegt, Heiler zu spielen? Ach nein, die sterben ja auch.",
    "Der Heiler hat dich gesehen. Er hat sich entschieden.",
    "Laut Heiler war das deine Schuld.",
    "Der Heiler postet gerade deinen Tod im Gildenchat.",
    -- Tank-Witze
    "Der Tank fragt: 'Wer hat Aggro?' Antwort: der Boden.",
    "Taunt ist keine Beleidigung, sondern eine Fähigkeit. Benutze sie.",
    "Der Tank dreht sich um: 'Alle da?' Nein.",
    "Vielleicht hättest du den Boss nicht angetanzt.",
    -- DPS-Witze
    "Laut Skada warst du auf Platz 1. Kurz.",
    "Die Schadensanzeige zeigt 0. Weil tot.",
    "Stand in der Fläche UND hat trotzdem nicht voll DPS gemacht.",
    "Meter pushen bis zum Tod. Respekt für die Hingabe.",
    -- Klassische WoW-Momente
    "Leeroy Jenkins hätte das genauso gemacht.",
    "Wenigstens hast du nicht den ganzen Raid mitgerissen. Diesmal.",
    "Das war bestimmt ein Lags.",
    "Diese Fläche war nicht in der Raidführung erwähnt. Oder doch?",
    "Haben wir heute schon den Spiritheiler umarmt? Ja, haben wir.",
    "Du hast den Mechanismus gecheckt. Der Mechanismus hat zurückgecheckt.",
    "Die Bosse respektieren Hartnäckigkeit. Leider auch deine.",
    "Willkommen in der Graveyard-Perspektive.",
    "Schritt 1: Nicht in die Fläche stehen. Schritt 2: existiert nicht mehr.",
    "Feuer am Boden ist immer schlecht. Immer.",
    "Der Raidleiter nimmt tief Luft.",
    "Irgendwo weint gerade ein Classic-Spieler für dich.",
    "Der Spiritheiler sagt: 'Schon wieder du.'",
    "Nicht der MVP. Nicht mal der MIP. Einfach tot.",
    "Voll repariert rein, gebrochen raus.",
    "Deine Ausrüstung ist jetzt auf 0 Haltbarkeit. Gut gemacht.",
    "One shot? One shot.",
    "Der Boss hat nicht mal eine Zwischensequenz gespielt. Du warst so unwichtig.",
    "Laut Warcraftlogs war das 100% vermeidbar.",
    "Haben wir den Enrage schon? Nein, nur du bist tot.",
    "Der Raidleiter öffnet gerade Warcraftlogs.",
    "Die Heiler haben mich ignoriert!",
    "Einfach mal stark sein!",
    "Einfach mal stärker sein.",
    "Einfach Todesstoß drücken.",
    "Mach doch mal die Augen auf.",
    "Schon wieder?",
}

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
    -- customLines: array of strings added by user
    if not DidYouDieDB.customLines then
        DidYouDieDB.customLines = {}
    end
    -- disabledDefaults: set of indices (1-based) into DEFAULT_TAUNT_LINES that are disabled
    if not DidYouDieDB.disabledDefaults then
        DidYouDieDB.disabledDefaults = {}
    end
end

-- -------------------------------------------------------
-- Helper: build active line pool for random pick
-- -------------------------------------------------------
local function BuildActiveLines()
    local lines = {}
    for i, line in ipairs(DEFAULT_TAUNT_LINES) do
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
-- 2. Das visuelle Warn-Element
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
-- 3. Die "Geist freilassen" Sperre (konfigurierbare Taste)
-- -------------------------------------------------------
local KEY_OPTIONS = {
    { label = "Shift", check = IsShiftKeyDown               },
    { label = "Strg",  check = IsControlKeyDown             },
    { label = "Alt",   check = IsAltKeyDown                 },
    { label = "Keine", check = function() return true end   },
}

local selectedKeyIndex = 1

local function IsUnlockKeyDown()
    return KEY_OPTIONS[selectedKeyIndex].check()
end

local function GetUnlockKeyLabel()
    return KEY_OPTIONS[selectedKeyIndex].label
end

local function LockDeathButton()
    local button = _G["StaticPopup1Button1"]
    if button and button:IsVisible() and StaticPopup1.which == "DEATH" then
        if IsUnlockKeyDown() then
            button:Enable()
            button:SetText("JETZT FREILASSEN")
        else
            button:Disable()
            button:SetText(GetUnlockKeyLabel() .. " HALTEN!")
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
-- 4. Options-Panel
-- -------------------------------------------------------
local panel = CreateFrame("Frame", "DidYouDieOptionsPanel", UIParent)
panel.name = "DidYouDie"

-- Titel
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("DidYouDie Einstellungen")

-- Todesanzahl
local statText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)

local function UpdateMenuText()
    local count = (DidYouDieDB and DidYouDieDB.count) or 0
    statText:SetText("Gesamtanzahl der Tode: |cFFFF0000" .. count .. "|r")
end

-- Reset-Button (Zähler)
local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", statText, "BOTTOMLEFT", 0, -8)
resetButton:SetText("Zähler zurücksetzen")
resetButton:SetSize(160, 25)
resetButton:SetScript("OnClick", function()
    DidYouDieDB.count = 0
    UpdateMenuText()
end)

-- Abschnitt: Tastenauswahl
local keyHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
keyHeader:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -16)
keyHeader:SetText("Taste zum Freischalten des Geist-Buttons:")

local radioButtons = {}

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
    lbl:SetText(option.label)

    rb:SetScript("OnClick", function(self)
        selectedKeyIndex        = self.value
        DidYouDieDB.unlockKey = selectedKeyIndex
        UpdateRadioButtons()
    end)

    radioButtons[i] = rb
    prevAnchor = rb
end

-- -------------------------------------------------------
-- Spruch-Liste
-- -------------------------------------------------------
local listHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
listHeader:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -20)
listHeader:SetText("Sprüche:")

-- "Reset to Default"-Button (rechts vom Header)
local resetLinesButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetLinesButton:SetPoint("LEFT", listHeader, "RIGHT", 12, 0)
resetLinesButton:SetText("Alles zurücksetzen")
resetLinesButton:SetSize(150, 22)

-- Toggle-All-Button: alle Defaults an/aus
local toggleAllButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
toggleAllButton:SetPoint("LEFT", resetLinesButton, "RIGHT", 6, 0)
toggleAllButton:SetSize(150, 22)

local function UpdateToggleAllButton()
    local allDisabled = true
    for i = 1, #DEFAULT_TAUNT_LINES do
        if not DidYouDieDB.disabledDefaults[i] then
            allDisabled = false
            break
        end
    end
    toggleAllButton:SetText(allDisabled and "Alle aktivieren" or "Alle deaktivieren")
end

-- toggleAllButton OnClick wird nach RefreshList gesetzt (siehe unten)

-- -------------------------------------------------------
-- Tab-Leiste: Default | Custom
-- -------------------------------------------------------
local activeTab = "default"  -- "default" oder "custom"

local tabRow = CreateFrame("Frame", nil, panel)
tabRow:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -8)
tabRow:SetSize(560, 28)

-- Eigene Tab-Buttons (kein Blizzard-Template nötig)
local function MakeTabButton(label, parent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(100, 24)
    btn:SetText(label)
    return btn
end

local tabDefault = MakeTabButton("Default", tabRow)
tabDefault:SetPoint("BOTTOMLEFT", tabRow, "BOTTOMLEFT", 0, 0)

local tabCustom = MakeTabButton("Custom", tabRow)
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

-- Eingabezeile (nur im Custom-Tab sichtbar)
local addBox = CreateFrame("EditBox", "DidYouDieAddBox", panel, "InputBoxTemplate")
addBox:SetPoint("TOPLEFT", tabRow, "BOTTOMLEFT", 2, -6)
addBox:SetSize(340, 22)
addBox:SetAutoFocus(false)
addBox:SetMaxLetters(200)

local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
addButton:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
addButton:SetText("Hinzufügen")
addButton:SetSize(100, 22)

-- -------------------------------------------------------
-- ScrollFrame für die Spruch-Liste
-- -------------------------------------------------------
local SCROLL_HEIGHT = 260
local ROW_HEIGHT    = 22

-- Header-Leiste über der Liste: Listenname links, Toggle-All rechts
local listHeaderBar = CreateFrame("Frame", nil, panel)
listHeaderBar:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -8)
listHeaderBar:SetSize(552, 20)

local listNameText = listHeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
listNameText:SetPoint("LEFT", listHeaderBar, "LEFT", 2, 0)
listNameText:SetTextColor(1, 0.82, 0, 1)  -- WoW-Gold

-- Toggle-All direkt in der Header-Leiste, rechtsbündig
toggleAllButton:SetParent(listHeaderBar)
toggleAllButton:ClearAllPoints()
toggleAllButton:SetPoint("RIGHT", listHeaderBar, "RIGHT", 0, 0)
toggleAllButton:SetSize(130, 18)

-- Hintergrund-Container
local listBg = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
listBg:SetPoint("TOPLEFT", listHeaderBar, "BOTTOMLEFT", -4, -4)
listBg:SetSize(556, SCROLL_HEIGHT + 8)

local scrollFrame = CreateFrame("ScrollFrame", "DidYouDieScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", listHeaderBar, "BOTTOMLEFT", 2, -8)
scrollFrame:SetSize(516, SCROLL_HEIGHT)

local scrollChild = CreateFrame("Frame", "DidYouDieScrollChild", scrollFrame)
scrollChild:SetSize(500, 1)   -- Höhe wird dynamisch gesetzt
scrollFrame:SetScrollChild(scrollChild)

-- Zebra-Hintergrundfarben für Zeilen
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

-- Pool für Zeilen-Widgets
local rowPool = {}

local function GetOrCreateRow(index)
    if not rowPool[index] then
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(498, ROW_HEIGHT)

        -- Toggle-Button: Icon-only, kein UIPanelButtonTemplate-Rahmen
        local toggle = CreateFrame("Button", nil, row)
        toggle:SetSize(20, 20)
        toggle:SetPoint("LEFT", row, "LEFT", 4, 0)

        -- Icon-Textur für aktiv (grüner Haken)
        local iconEnabled = toggle:CreateTexture(nil, "ARTWORK")
        iconEnabled:SetAllPoints()
        iconEnabled:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        iconEnabled:SetVertexColor(0.2, 1.0, 0.2, 1)
        toggle.iconEnabled = iconEnabled

        -- Icon-Textur für deaktiviert (rotes X)
        local iconDisabled = toggle:CreateTexture(nil, "ARTWORK")
        iconDisabled:SetAllPoints()
        iconDisabled:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        iconDisabled:SetVertexColor(1.0, 0.25, 0.25, 1)
        toggle.iconDisabled = iconDisabled

        -- Hover-Highlight
        local hl = toggle:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.4)

        row.toggle = toggle

        -- Trennlinie unten
        local sep = row:CreateTexture(nil, "BORDER")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        sep:SetColorTexture(1, 1, 1, 0.06)

        -- Spruch-Text
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", toggle, "RIGHT", 6, 0)
        text:SetPoint("RIGHT", row, "RIGHT", 26, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        row.text = text

        -- Löschen-Button (nur Custom): kleines rotes X rechts
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

-- Hilfsfunktion: Toggle-Icons umschalten
local function SetToggleState(toggle, enabled)
    if enabled then
        toggle.iconEnabled:Show()
        toggle.iconDisabled:Hide()
    else
        toggle.iconEnabled:Hide()
        toggle.iconDisabled:Show()
    end
end

-- Forward-Declare RefreshList so callbacks can call it
local RefreshList

RefreshList = function()
    -- Listentitel und Toggle-All sichtbarkeit
    if activeTab == "default" then
        listNameText:SetText("Standard-Sprüche")
        toggleAllButton:Show()
    else
        listNameText:SetText("Eigene Sprüche")
        toggleAllButton:Hide()
    end

    -- Tab-Label mit Anzahl aktualisieren
    local customCount = #DidYouDieDB.customLines
    tabCustom:SetText(customCount > 0 and ("Custom (" .. customCount .. ")") or "Custom")
    local disabledCount = 0
    for _ in pairs(DidYouDieDB.disabledDefaults) do disabledCount = disabledCount + 1 end
    local defaultLabel = disabledCount > 0
        and ("Default (" .. (#DEFAULT_TAUNT_LINES - disabledCount) .. "/" .. #DEFAULT_TAUNT_LINES .. ")")
        or  ("Default (" .. #DEFAULT_TAUNT_LINES .. ")")
    tabDefault:SetText(defaultLabel)
    UpdateTabs()

    -- AddBox nur im Custom-Tab
    if activeTab == "custom" then
        addBox:Show(); addButton:Show()
    else
        addBox:Hide(); addButton:Hide()
    end

    -- Verstecke alle alten Rows
    for _, row in ipairs(rowPool) do
        row:Hide()
    end

    local y = 0
    local rowIndex = 0

    if activeTab == "default" then
        -- Default-Sprüche
        for i, line in ipairs(DEFAULT_TAUNT_LINES) do
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
        -- Custom-Sprüche
        if #DidYouDieDB.customLines == 0 then
            -- Leere-Liste-Hinweis
            rowIndex = rowIndex + 1
            local row = GetOrCreateRow(rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
            row:Show()
            SetRowBg(row, 1, false)
            row.toggle:Hide()
            row.text:SetText("|cFF888888Noch keine eigenen Sprüche. Füge welche hinzu!|r")
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

-- Toggle-All OnClick (hier, weil RefreshList erst ab hier verfügbar)
toggleAllButton:SetScript("OnClick", function()
    local allDisabled = true
    for i = 1, #DEFAULT_TAUNT_LINES do
        if not DidYouDieDB.disabledDefaults[i] then
            allDisabled = false
            break
        end
    end
    if allDisabled then
        DidYouDieDB.disabledDefaults = {}
    else
        for i = 1, #DEFAULT_TAUNT_LINES do
            DidYouDieDB.disabledDefaults[i] = true
        end
    end
    UpdateToggleAllButton()
    RefreshList()
end)

-- Hinzufügen-Button Logik
addButton:SetScript("OnClick", function()
    local txt = addBox:GetText()
    if txt and txt:match("%S") then  -- nicht nur Whitespace
        txt = txt:match("^%s*(.-)%s*$")  -- trim
        table.insert(DidYouDieDB.customLines, txt)
        addBox:SetText("")
        RefreshList()
    end
end)

-- Enter in der EditBox = Hinzufügen
addBox:SetScript("OnEnterPressed", function(self)
    addButton:Click()
    self:ClearFocus()
end)

-- Reset-Defaults-Button Logik
resetLinesButton:SetScript("OnClick", function()
    DidYouDieDB.disabledDefaults = {}
    DidYouDieDB.customLines = {}
    RefreshList()
end)

-- Panel wird geöffnet → Liste neu aufbauen
panel:SetScript("OnShow", function()
    UpdateMenuText()
    UpdateToggleAllButton()
    RefreshList()
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

-- -------------------------------------------------------
-- 5. Event-Handler
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
        UpdateMenuText()

    elseif event == "PLAYER_DEAD" then
        DidYouDieDB.count = (DidYouDieDB.count or 0) + 1
        deathText:SetText("Bleib liegen du Pfosten!  (Tod Nr. " .. DidYouDieDB.count .. ")")
        local activeLines = BuildActiveLines()
        tauntText:SetText(#activeLines > 0 and activeLines[math.random(#activeLines)] or "Füge eigene Sprüche hinzu oder aktiviere Standard-Sprüche!")
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