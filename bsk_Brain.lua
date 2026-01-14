-------------------------------------
	RED = "|cFFFF0000"
	GREEN = "|cFF00FF00"
	BLUE = "|cFFADD8E6"
	YELLOW = "|cFFFFFF00"
	ORANGE = "|cFFFFA500"
	PURPLE = "|cFF800080"
	CYAN = "|cFF00FFFF"
	MAGENTA = "|cFFFF00FF"
	WHITE = "|cFFFFFFFF"
	BLACK = "|cFF000000"
	GRAY = "|cFF808080"
-------------------------------------



--Functionality for loading, saving, and deleting armor sets, as well as macro functionality
local function UnequipItems(itemSlots)
    -- 1. Find all available empty slots in the bags (0-4)
    local emptySlots = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if not itemID then
                table.insert(emptySlots, {bag = bag, slot = slot})
            end
        end
    end

    -- 2. Iterate through your target slots and unequip
    for i, inventorySlotID in ipairs(itemSlots) do
        -- Check if we still have empty slots available
        if #emptySlots > 0 then
            local target = table.remove(emptySlots, 1) -- Take the first available slot
            
            -- Ensure there is actually an item in the inventory slot
            if GetInventoryItemID("player", inventorySlotID) then
                ClearCursor() -- Safety check
                PickupInventoryItem(inventorySlotID)
                C_Container.PickupContainerItem(target.bag, target.slot)
                ClearCursor()
            end
        else
            print("Not enough bag space to unequip all items!")
            break
        end
    end
end

function cmdFunc(str)
	if str=="" then
		print(YELLOW.."HELP DESK")
		print(RED.."Save set: |r/bskin save {name}")
		print(RED.."Load set: |r/bskin load {name}")
		print(RED.."Delete set: |r/bskin delete {name} "..YELLOW.."or |r/za remove {name}")
		print(RED.."View armor sets: |r/bskin list")
		print(BLUE.."Note: addon can be used with macros!")
		return
	end
	
	
	local words = {}
    for word in str:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Check for "save" or "load" and extract the third word
    if containsWord(words[1], "save") and words[2] then
        saveArmorSet(words[2])
		addContent()
    elseif containsWord(words[1], "load") and words[2] then
        loadArmorSet(words[2])
	elseif containsWord(words[1], "list") then
		listArmorSets()
    elseif (containsWord(words[1], "delete") or containsWord(words[1], "remove"))and words[2] then
		deleteArmorSet(words[2])
		addContent()
	else
        print("Invalid command")
    end
end

function deleteArmorSet(s_name)
	if zas_ArmorList[UnitName("player")][s_name] then
		zas_ArmorList[UnitName("player")][s_name] = nil
		print("Armor set "..PURPLE..s_name.."|r has been removed for ".. YELLOW..UnitName("player"))
		updateSpecialItems()
	end
end

function listArmorSets()
	armorLists = ""
	if not zas_ArmorList[UnitName("player")] then
		print("No armors currently listed.")
		return
	end
	
	for key, _ in pairs(zas_ArmorList[UnitName("player")]) do
		armorLists = key..","..armorLists
	end
	
	lastLt = string.sub(UnitName("player"), -1)
	if(lastLt == "s") then
		print(YELLOW..UnitName("player").."'".."|r armor sets: " .. armorLists)
	else
		print(YELLOW..UnitName("player").."'s".."|r armor sets: " .. armorLists)
	end
end

function saveArmorSet(s_name)
    local characterName = UnitName("player")
    -- (Initializing tables logic remains the same)

    local gearSet = {}

    for slot = INVSLOT_HEAD, INVSLOT_TABARD do
        local itemLink = GetInventoryItemLink("player", slot)

        if itemLink then
            -- We save the full link to capture enchants/suffixes
            gearSet[slot] = {
                link = itemLink,
            }
        else
            gearSet[slot] = false
        end
    end

    -- Save visibility
    gearSet.helmShown  = ShowingHelm()
    gearSet.cloakShown = ShowingCloak()

    zas_ArmorList[characterName][s_name] = gearSet
	updateSpecialItems()
    print("Armor set "..PURPLE..s_name.."|r has been saved for ".. YELLOW..UnitName("player"))
end

local function FindExactItemInBags(targetLink)
    if not targetLink then return nil end
    
    -- Extract the raw item string (contains ID, Enchants, Suffixes)
    -- This looks like "item:1234:56:0:0:0:0:789:..."
    local _, _, targetString = string.find(targetLink, "(item:[%d:]+)")

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local currentLink = C_Container.GetContainerItemLink(bag, slot)
            if currentLink then
                local _, _, currentString = string.find(currentLink, "(item:[%d:]+)")
                if targetString == currentString then
                    return bag, slot
                end
            end
        end
    end
    return nil
end


function loadArmorSet(s_name)
    local characterName = UnitName("player")
    local gearSet = zas_ArmorList and zas_ArmorList[characterName] and zas_ArmorList[characterName][s_name]

    if not gearSet then
        print("Gear set not found.")
        return
    end

    local unequipQueue = {}

    for slot = INVSLOT_HEAD, INVSLOT_TABARD do
        local slotData = gearSet[slot]

        if slotData and slotData.link then
            -- 1. Check if we're already wearing the EXACT item
            local currentLink = GetInventoryItemLink("player", slot)
            local _, _, savedStr = string.find(slotData.link, "(item:[%d:]+)")
            local currentStr = currentLink and select(3, string.find(currentLink, "(item:[%d:]+)"))

            if savedStr ~= currentStr then
                -- 2. Find the exact item in bags
                local bag, bagSlot = FindExactItemInBags(slotData.link)
                
                if bag and bagSlot then
                    ClearCursor()
                    C_Container.PickupContainerItem(bag, bagSlot)
                    EquipCursorItem(slot) 
                    ClearCursor()
                else
                    print("Could not find item: " .. slotData.link)
                end
            end
        else
            -- Queue for unequipping if the slot should be empty
            if GetInventoryItemID("player", slot) then
                table.insert(unequipQueue, slot)
            end
        end
    end

    -- Run your unequip logic for the empty slots
    if #unequipQueue > 0 then
        UnequipItems(unequipQueue)
    end

    -- Restore visibility
    if gearSet.cloakShown ~= nil then ShowCloak(gearSet.cloakShown) end
    if gearSet.helmShown ~= nil then ShowHelm(gearSet.helmShown) end
end
-----------


-- Define the items for which to add custom text
local specialItems = {
}

function updateSpecialItems()
    specialItems = {}

    local characterName = UnitName("player")
    if not (zas_ArmorList and zas_ArmorList[characterName]) then return end

    for setName, gearSet in pairs(zas_ArmorList[characterName]) do
        for slotId, slotData in pairs(gearSet) do
            -- Ensure we are looking at an actual gear slot and it's not empty
            if type(slotId) == "number" and type(slotData) == "table" and slotData.link then
                
                -- Extract the raw item string to use as a unique key
                local _, _, itemString = string.find(slotData.link, "(item:[%d:]+)")
                
                if itemString then
                    if specialItems[itemString] then
                        -- Append the set name if the item is in multiple sets
                        if not string.find(specialItems[itemString], setName) then
                            specialItems[itemString] = specialItems[itemString] .. ", " .. setName
                        end
                    else
                        specialItems[itemString] = setName
                    end
                end
            end
        end
    end
end


--Simple helper function
function containsWord(s_string, s_word)
    -- Make both strings lowercase for case-insensitive matching
    local lowerString = string.lower(s_string)
    local lowerWord = string.lower(s_word)

    -- Split the string into words
    for word in lowerString:gmatch("%w+") do
        if word == lowerWord then
            return true
        end
    end

    return false
end


SLASH_commands1 = "/bskin"
SlashCmdList.commands = cmdFunc;



------------------------------------------

	local function OnAddonLoaded(event, addonName, ...)
		-- Check if the loaded addon is your addon
		local str=...

			if not zas_ArmorList then
				zas_ArmorList = {}
			end
			
			addContent()
			updateSpecialItems()
	end
	
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)




local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    if not link then return end

    -- Extract the string from the item currently being hovered
    local _, _, itemString = string.find(link, "(item:[%d:]+)")
    if not itemString then return end

    -- Direct lookup in our new table
    if specialItems and specialItems[itemString] then
        tooltip:AddLine(specialItems[itemString], 1, 1, 0)
        tooltip:Show()
    end
end
GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
