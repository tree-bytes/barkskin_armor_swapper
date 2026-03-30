--Updated on 2/15/2026 to fix a small bug, where sometimes when the user had two weapons, only one would be de-equipped. [Function: loadArmorSet()]

--Updated on 3/30/2026 to make the item link comparions less restrictive. This behavior
--would sometimes cause the addon not to 'know' when you had an item in your bag. [Function: FindExactItemInBags(), ParseItemString(), loadArmorSet(), updateSpecialItems(), OnTooltipSetItem()]

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
--
-- PARAMETERS
-- itemSlots: All of the bag slots for our user.
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

    -- 2. Iterate through target slots and unequip
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

--Slash command functionality, handles things like /help, /save, /load, etc.
--
--PARAMETERS
--str: the command that the user wants to try and run
function cmdFunc(str)
	if str=="" then
		print(YELLOW.."HELP DESK")
		print(RED.."Save set: |r/bskin save {name}")
		print(RED.."Load set: |r/bskin load {name}")
		print(RED.."Delete set: |r/bskin delete {name} "..YELLOW.."or |r/bskin remove {name}")
		print(RED.."View armor sets: |r/bskin list")
		print(RED.."Change helm visibility: |r/bskin helm {set} {bool}")
		print(RED.."Change cloak visibility: |r/bskin cloak {set} {bool}")
		print(BLUE.."Note: {bool} can either be 1, 0, true, or false!")
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
	elseif containsWord(words[1], "helm") and words[2] and words[3] then
		helm_visibility(words[2], words[3])
		addContent()
	elseif containsWord(words[1], "cloak") and words[2] and words[3] then
		cloak_visibility(words[2], words[3])
		addContent()
	else
        print("Invalid command")
    end
end

--Deletes an armor set from our save data.
--
--PARAMETERS
--s_name: The name of the set to delete.
function deleteArmorSet(s_name)
	if zas_ArmorList[UnitName("player")][s_name] then
		zas_ArmorList[UnitName("player")][s_name] = nil
		print("Armor set "..PURPLE..s_name.."|r has been removed for ".. YELLOW..UnitName("player"))
		updateSpecialItems()
	end
end

-- Changes the visibility of the helmet for the player based on save data.
--
--PARAMETERS
--s_name: The name of the set to change the visibility on
--value: the value of the visibility
function helm_visibility(s_name, value)
	if zas_ArmorList[UnitName("player")][s_name] then
	
		if value=="1" or value=="true" then
			zas_ArmorList[UnitName("player")][s_name]["helmShown"] = true
		else
			zas_ArmorList[UnitName("player")][s_name]["helmShown"] = false
		end
	end
end

-- Changes the visibility of the cloak for the player based on save data.
--
--PARAMETERS
--s_name: The name of the set to change the visibility on
--value: the value of the visibility
function cloak_visibility(s_name, value)

	if zas_ArmorList[UnitName("player")][s_name] then
	
		if value=="1" or value=="true" then
			zas_ArmorList[UnitName("player")][s_name]["cloakShown"] = true
		else
			zas_ArmorList[UnitName("player")][s_name]["cloakShown"] = false
		end
	end
end


--Given our character, lists out all of the armor sets. Does so
--with a print(), so that the player sees in the chat.
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

--Saves an armor set to our save data.
--
--PARAMETERS
--s_name: the save name of our new set (exisitng names will be overriden)
function saveArmorSet(s_name)
    local characterName = UnitName("player")


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

--New logic for finding our 'exact' item link. Instead of using the entire, exact link,
--we separate it and look for only pieces that we need to make an 'exact' match. This method
--avoids being overly strict about which piece we are trying to find.
--
--PARAMETERS
--link: the link of the item string that we are trying to parse.
local function ParseItemString(link)
    if not link then return nil end
    -- Captures: itemID, unknown1, enchantID (positions in the item string)
    local itemID, unk1, enchantID = string.match(link, "item:(%d+):(%d*):(%d*)")
    return itemID, enchantID
end

--Loops through the bag, attempting to find the item that we are trying to equip.
--
--PARAMETERS
--targetLink: The link of the item that we are trying to get.
local function FindExactItemInBags(targetLink)
    if not targetLink then return nil end

    local _, _, targetString = string.find(targetLink, "(item:[%d:]+)")
    local targetItemID, targetEnchantID = ParseItemString(targetLink)

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local currentLink = C_Container.GetContainerItemLink(bag, slot)
            if currentLink then
                local _, _, currentString = string.find(currentLink, "(item:[%d:]+)")

                -- First try: exact full string match
                if targetString == currentString then
                    return bag, slot
                end

                -- Fallback: match on item ID + enchant ID only
                local currentItemID, currentEnchantID = ParseItemString(currentLink)
                if targetItemID and targetItemID == currentItemID
                   and targetEnchantID == currentEnchantID then
                    return bag, slot
                end
            end
        end
    end
    return nil
end

-- Loads the armor set, placing each item on the player, and de-equiping items if needed to match
-- exactly what the player was wearing in their saved set.
--
--PARAMETERS
--s_name: the name of the set to load.
function loadArmorSet(s_name)
    local characterName = UnitName("player")
    local gearSet = zas_ArmorList and zas_ArmorList[characterName] and zas_ArmorList[characterName][s_name]

    if not gearSet then
        print("Gear set not found.")
        return
    end

    local unequipQueue = {}

	-- Pass 1: Handle weapons first
	for slot = INVSLOT_MAINHAND, INVSLOT_OFFHAND do
		local slotData = gearSet[slot]

		if slotData and slotData.link then
			local currentLink = GetInventoryItemLink("player", slot)

			local savedItemID, savedEnchantID = ParseItemString(slotData.link)
			local currentItemID, currentEnchantID = ParseItemString(currentLink)

			if savedItemID ~= currentItemID or savedEnchantID ~= currentEnchantID then
				local bag, bagSlot = FindExactItemInBags(slotData.link)

				if bag then
					ClearCursor()
					C_Container.PickupContainerItem(bag, bagSlot)
					EquipCursorItem(slot)
					ClearCursor()
				else
					print("Could not find weapon: "..slotData.link)
				end
			end
		end
	end

	-- Pass 2: Handle everything else
	for slot = INVSLOT_HEAD, INVSLOT_TABARD do
		if slot ~= INVSLOT_MAINHAND and slot ~= INVSLOT_OFFHAND then
			local slotData = gearSet[slot]

			if slotData and slotData.link then
				local currentLink = GetInventoryItemLink("player", slot)

				local savedItemID, savedEnchantID = ParseItemString(slotData.link)
				local currentItemID, currentEnchantID = ParseItemString(currentLink)

				if savedItemID ~= currentItemID or savedEnchantID ~= currentEnchantID then
					local bag, bagSlot = FindExactItemInBags(slotData.link)

					if bag then
						ClearCursor()
						C_Container.PickupContainerItem(bag, bagSlot)
						EquipCursorItem(slot)
						ClearCursor()
					else
						print("Could not find item: "..slotData.link)
					end
				end

			else
				if GetInventoryItemID("player", slot) then
					table.insert(unequipQueue, slot)
				end
			end
		end
	end



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

--This function 'updates' the tooltips of items that are currently in a set.
function updateSpecialItems()
    specialItems = {}

    local characterName = UnitName("player")
    if not (zas_ArmorList and zas_ArmorList[characterName]) then return end

    for setName, gearSet in pairs(zas_ArmorList[characterName]) do
        for slotId, slotData in pairs(gearSet) do
            if type(slotId) == "number" and type(slotData) == "table" and slotData.link then
                
                -- Use itemID+enchantID as the key instead of the full string
                local itemID, enchantID = ParseItemString(slotData.link)
                local key = itemID and (itemID .. ":" .. (enchantID or "0"))

                if key then
                    if specialItems[key] then
                        if not string.find(specialItems[key], setName) then
                            specialItems[key] = specialItems[key] .. ", " .. setName
                        end
                    else
                        specialItems[key] = setName
                    end
                end
            end
        end
    end
end


--Simple helper function. Given a string, check to see if a word is inside it.
--
--PARAMETERS
--s_string: string we are searching
--s_word: string we are looking for
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



--Function that runs whenever the tooltip is set.
local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    if not link then return end

    local itemID, enchantID = ParseItemString(link)
    local key = itemID and (itemID .. ":" .. (enchantID or "0"))
    if not key then return end

    if specialItems and specialItems[key] then
        tooltip:AddLine(specialItems[key], 1, 1, 0)
        tooltip:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
