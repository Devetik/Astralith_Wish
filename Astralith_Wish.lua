-- Initialisation
local frame = CreateFrame("Frame", "WishlistFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(800, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Charger la liste d'objets depuis ItemList.lua
if not ItemList then
    print("Erreur : La liste des objets (ItemList.lua) n'a pas été chargée correctement.")
    return
end

-- Titre de la fenêtre
local title = frame:CreateFontString(nil, "OVERLAY")
title:SetFontObject("GameFontHighlight")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("Molten Core Wishlist")

-- ScrollFrame pour la liste
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(380, 300)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)

local scrollContent = CreateFrame("Frame", nil, scrollFrame)
scrollContent:SetSize(360, #ItemList * 50) -- Ajuste la hauteur pour inclure tous les objets
scrollFrame:SetScrollChild(scrollContent)

-- Stockage des boutons et des objets sélectionnés
local buttons = {}
local selectedItems = {}

-- Liste de droite pour les objets sélectionnés
local selectedFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
selectedFrame:SetSize(300, 300)
selectedFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)

local selectedTitle = selectedFrame:CreateFontString(nil, "OVERLAY")
selectedTitle:SetFontObject("GameFontHighlight")
selectedTitle:SetPoint("TOP", selectedFrame, "TOP", 0, -10)
selectedTitle:SetText("Selected Items")

local selectedYOffset = -40
local function UpdateSelectedList()
    for _, child in ipairs({ selectedFrame:GetChildren() }) do
        child:Hide()
    end

    for _, itemID in ipairs(selectedItems) do
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)

        local button = CreateFrame("Frame", nil, selectedFrame)
        button:SetSize(280, 40)
        button:SetPoint("TOP", selectedFrame, "TOP", 0, selectedYOffset)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", button, "LEFT", 0, 0)
        icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local name = button:CreateFontString(nil, "OVERLAY")
        name:SetFontObject("GameFontHighlight")
        name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        name:SetText(itemName or ("Loading Item " .. itemID))

        selectedYOffset = selectedYOffset - 50
    end

    selectedYOffset = -40
end

-- Fonction pour créer un bouton avec une case à cocher
local function CreateItemButton(itemID, yOffset)
    local button = CreateFrame("Frame", nil, scrollContent)
    button:SetSize(360, 40)
    button:SetPoint("TOP", scrollContent, "TOP", 0, yOffset)

    -- Icône
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", button, "LEFT", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- Case à cocher
    local checkbox = CreateFrame("CheckButton", nil, button, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("LEFT", icon, "RIGHT", 10, 0)

    -- Nom de l'objet
    local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
    local name = button:CreateFontString(nil, "OVERLAY")
    name:SetFontObject("GameFontHighlight")
    name:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)
    name:SetText(itemName or ("Loading Item " .. itemID))

    -- Charger l'icône si elle est disponible
    if itemIcon then
        icon:SetTexture(itemIcon)
    end

    -- Gestion des tooltips : uniquement sur l'icône
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE") -- Désactive l'ancrage automatique
        GameTooltip:SetHyperlink("item:" .. itemID)

        -- Mise à jour de la position du tooltip en fonction de la souris
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale() -- Adapter à la résolution
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale - 300, y / scale - 200) -- Décalage
        GameTooltip:Show()
    end)

    icon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Gestion des cases à cocher
    checkbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            table.insert(selectedItems, itemID)
        else
            for i, id in ipairs(selectedItems) do
                if id == itemID then
                    table.remove(selectedItems, i)
                    break
                end
            end
        end
        UpdateSelectedList()
    end)

    -- Stocker le bouton pour mise à jour
    buttons[itemID] = { button = button, icon = icon, checkbox = checkbox, name = name }
end

-- Crée un bouton pour chaque objet
local yOffset = 0
for _, itemID in ipairs(ItemList) do
    CreateItemButton(itemID, yOffset)
    yOffset = yOffset - 35
end

-- Gère les objets non chargés dans le cache
local f = CreateFrame("Frame")
f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
f:SetScript("OnEvent", function(self, event, itemID, success)
    if success and buttons[itemID] then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        local buttonData = buttons[itemID]
        buttonData.icon:SetTexture(itemIcon)
        buttonData.name:SetText(itemName)
    end
end)

-- Commande slash
SLASH_MCADDON1 = "/mcwishlist"
SlashCmdList["MCADDON"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
