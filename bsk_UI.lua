-- Create the button
local armorButton = CreateFrame("Button", "zanArmorExtension", PaperDollFrame, "UIPanelButtonTemplate")

-- Set button properties
armorButton:SetSize(80, 22) -- Width, Height
armorButton:SetText("Armor Sets")
armorButton:SetPoint("BOTTOMRIGHT", PaperDollFrame, "BOTTOMRIGHT", -275, 85) -- Position relative to PaperDollFrame




local zan_ArmorPanel = CreateFrame("Frame", "zanArmorExtension", PaperDollFrame, "BackdropTemplate")

-- This creates the panel that displays all of the sets
zan_ArmorPanel:SetSize(200, 300) -- Width, Height
zan_ArmorPanel:SetPoint("LEFT", PaperDollFrame, "RIGHT", -40, 40) -- Position it to the right of the PaperDollFrame
zan_ArmorPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Border texture
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
zan_ArmorPanel:SetBackdropColor(0, 0, 0, 0.8) -- Background color (black with transparency)

zan_ArmorPanel:Hide()

--We now create the button that will reside at the top of the ``zan_ArmorPanel``, which will allow the user to create new armor sets

local newSetButton = CreateFrame("Button", "zanArmorExtension", zan_ArmorPanel, "UIPanelButtonTemplate")
newSetButton:SetSize(80,22) -- Width, Height
newSetButton:SetText("New Set")
newSetButton:SetPoint("TOP", zan_ArmorPanel, "TOP", -15, 10)

-----------------------------

local scrollFrame = CreateFrame("ScrollFrame", "zanArmorExtension", zan_ArmorPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

-- Create the content inside the scroll frame
local scrollContent = CreateFrame("Frame", "zanArmorExtension", scrollFrame)
scrollContent:SetPoint("TOPLEFT")
scrollContent:SetWidth(scrollFrame:GetWidth() - 20) -- Adjust width to fit within the scroll frame
scrollFrame:SetScrollChild(scrollContent)

-- Function to dynamically update content height
local function UpdateContentHeight()
    local totalHeight = 100
    for _, child in ipairs({scrollContent:GetChildren()}) do
        local _, childHeight = child:GetSize()
        totalHeight = totalHeight + (childHeight or 0)
    end
    scrollContent:SetHeight(math.max(totalHeight+30, scrollFrame:GetHeight())) -- Ensure content is at least as tall as the frame
end

textBoxes = {}
--Function to clear out content
function clearContent()
	for _, child in ipairs({scrollContent:GetChildren()}) do
		child:Hide()
		child:SetParent(nil)
	end
	
	for _, text in ipairs(textBoxes) do
		text:Hide()
		text:SetParent(nil)
		textBoxes[text]=nil
	end
	
	UpdateContentHeight()
end

function addContent()
	clearContent()

	if(not zas_ArmorList[UnitName("player")]) then
		zas_ArmorList[UnitName("player")] = {}
	end
	idx=1
	lastPosition = -10
	for key, _ in pairs(zas_ArmorList[UnitName("player")]) do	
		
		local text = scrollContent:CreateFontString("TXT", "OVERLAY", "GameFontNormalLarge")
		text:SetPoint("TOP", scrollContent, "TOP", 0, lastPosition) -- Center the text within the frame
		text:SetText(key) -- Set the text content
		
		table.insert(textBoxes, text)
		
		local saveBtn = CreateFrame("Button", "zanArmorExtension", scrollContent, "UIPanelButtonTemplate")
		saveBtn:SetSize(60,20)
		saveBtn:SetText("Save")
		saveBtn:SetPoint("TOP", scrollContent, "TOP", -40, lastPosition-20)
		
		local loadBtn = CreateFrame("Button", "zanArmorExtension", scrollContent, "UIPanelButtonTemplate")
		loadBtn:SetSize(60,20)
		loadBtn:SetText("Load")
		loadBtn:SetPoint("TOP", scrollContent, "TOP", 20, lastPosition-20)
		
		local delBtn = CreateFrame("Button", "zanArmorExtension", scrollContent, "UIPanelButtonTemplate")
		delBtn:SetSize(40,20)
		delBtn:SetText("DEL")
		delBtn:SetPoint("TOP", scrollContent, "TOP", 70, lastPosition-20)
		
		
		local helmBox = CreateFrame("CheckButton", "zanArmorExtension", scrollContent, "ChatConfigCheckButtonTemplate")
		helmBox:SetPoint("CENTER", scrollContent, "TOP", -30, lastPosition-60) -- Position it in the center of the frame
		helmBox.Text:SetText("Show Helm") -- Text next to the checkbox
		
		local capeBox = CreateFrame("CheckButton", "zanArmorExtension", scrollContent, "ChatConfigCheckButtonTemplate")
		capeBox:SetPoint("CENTER", scrollContent, "TOP", -30, lastPosition-75) -- Position it in the center of the frame
		capeBox.Text:SetText("Show Cape") -- Text next to the checkbox
		
		capeBox:SetChecked(zas_ArmorList[UnitName("player")][key]["cloakShown"])
		helmBox:SetChecked(zas_ArmorList[UnitName("player")][key]["helmShown"])
		------- SCRIPTS ------------
		
		capeBox:SetScript("OnClick", function(self)
			local isChecked = self:GetChecked()

			zas_ArmorList[UnitName("player")][key]["cloakShown"] = isChecked
			
		end)

		helmBox:SetScript("OnClick", function(self)
			local isChecked = self:GetChecked()

			zas_ArmorList[UnitName("player")][key]["helmShown"] = isChecked
		end)
		
		saveBtn:SetScript("OnClick", function(self) 
			saveArmorSet(key)
			zas_ArmorList[UnitName("player")][key]["cape"] = capeBox:GetChecked()
			zas_ArmorList[UnitName("player")][key]["hat"] = helmBox:GetChecked()
			addContent()
		end)
		
		loadBtn:SetScript("OnClick", function(self) 
			loadArmorSet(key)
		end)
		
		delBtn:SetScript("OnClick", function(self)
			deleteArmorSet(key)
			addContent()
		end)
		
		idx = idx+1
		lastPosition = lastPosition - 90
	end

end







-------------------------------










-- Ensure the button appears when the character panel is shown
PaperDollFrame:HookScript("OnShow", function()
    armorButton:Show()
end)

-- Add a click event handler for the main armor button
armorButton:SetScript("OnClick", function(self, button)
    if(zan_ArmorPanel:IsShown()) then
		zan_ArmorPanel:Hide()
	else
		zan_ArmorPanel:Show()
	end
end)



-- Add a click event handler for the 'new set creator' button
newSetButton:SetScript("OnClick", function()
    -- Prevent multiple popups
    if zanCreateSetFrame then return end
	

    local popup = CreateFrame("Frame", "zanCreateSetFrame", UIParent, "BackdropTemplate")
    popup:SetSize(300, 120)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    zanCreateSetFrame = popup

    -- Title text
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Create New Set")

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    editBox:SetSize(200, 20)
    editBox:SetPoint("TOP", title, "BOTTOM", 0, -15)
    editBox:SetAutoFocus(true)
	
	local function DestroyPopup()
        popup:Hide()
        popup:SetParent(nil)
        zanCreateSetFrame = nil
    end
	
	local function AcceptFunc()
        local text = editBox:GetText()

        -- Trim whitespace
        text = text and text:match("^%s*(.-)%s*$")

        if not text or text == "" then
            return
        end

        saveArmorSet(text)
		addContent()

        DestroyPopup()
    end
	

    editBox:SetScript("OnEscapePressed", function()
        popup:Hide()
        popup:SetParent(nil)
        zanCreateSetFrame = nil
    end)

    editBox:SetScript("OnEnterPressed", function()
        AcceptFunc()
    end)

    -- Accept Button
    local accept = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    accept:SetSize(80, 22)
    accept:SetPoint("BOTTOMLEFT", 30, 15)
    accept:SetText("Accept")

    -- Cancel Button
    local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("BOTTOMRIGHT", -30, 15)
    cancel:SetText("Cancel")    

    accept:SetScript("OnClick", AcceptFunc)

    cancel:SetScript("OnClick", DestroyPopup)
end)