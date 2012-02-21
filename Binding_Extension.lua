-- Name: Binding Extension
-- Version: 1.0
-- Date: January 2012
-- Note: World of WarCraft addon to provide binding interface for spells/items/macros
-- Author: Maligan (maligan@rambler.ru)

--
-- Initialization 
--
BE = {}
-- Code sugar
function BE.IsModifiedClick() return IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() end
function BE.PopupDialog(kind, name) StaticPopup_Show("BINDING_EXTENSION", nil, nil, { kind = kind, name = name }) end

--
-- Popup dialog 
--
-- Switch on/off dialog call 
function BE:EnableDialog(enabled)
	if enabled and not self.DialogAttached then BE:AttachDialogCall() end
	self.DialogEnable = enabled 
end

-- Attach popup dialog to different game button
function BE:AttachDialogCall()
	-- I can't override standart handler for Blizzard security reasons
	for id = 1, 12 do
		local button = _G["SpellButton"..id]
		button:HookScript("OnMouseDown", self.SpellButtonHandler)
	end

	-- Attach to Container button (Bag item)
	ContainerFrameItemButton_OriginOnModifiedClick = ContainerFrameItemButton_OnModifiedClick
	ContainerFrameItemButton_OnModifiedClick = function (self, button)
		if BE.DialogEnable and BE.IsModifiedClick() and button == "LeftButton" then 
			local itemName = GetItemInfo(GetContainerItemLink(self:GetParent():GetID(), self:GetID()))
			if itemName ~= nil then
				BE.PopupDialog("ITEM", itemName)
			end
		else
			ContainerFrameItemButton_OriginOnModifiedClick(self, button)
		end
	end

	-- Attach to Macro button
	MacroButton_OriginOnClick = MacroButton_OnClick
	MacroButton_OnClick  = function (self, button)
		MacroButton_OriginOnClick(self, button)
		if BE.DialogEnable and BE.IsModifiedClick() and button == "LeftButton" then 
			local name = _G[self:GetName().."Name"]:GetText()
			BE.PopupDialog("MACRO", name)
		end
	end

	-- Note about attach
	self.DialogAttached = true
end

-- Script hooked to Spellbutton
function BE.SpellButtonHandler(self, button)
	if BE.DialogEnable and BE.IsModifiedClick() and button == "LeftButton" then 
		local slot = SpellBook_GetSpellBookSlot(self)
		local spellName = GetSpellBookItemName(slot, SpellBookFrame.bookType)
		if spellName and not IsPassiveSpell(slot, SpellBookFrame.bookType) then
			BE.PopupDialog("SPELL", spellName) 
		end
	end
end

--
-- GameToolTip
--
-- Switch on/off binding text in ToolTip 
function BE:EnableTip(enabled)
	if enabled and not self.TipAttached then BE:AttachTip() end
	self.TipEnable = enabled 
end

-- Attach tips to GameToolTip
function BE:AttachTip()
	-- Spells 
	GameTooltip:HookScript("OnTooltipSetSpell",
	function (self, ...) 
		if BE.TipEnable then 
			local name = self:GetSpell()
			if name ~= nil then BE.AddTip(self, GetBindingKey("SPELL "..name)) end
		end
	end)
	-- Items 
	GameTooltip:HookScript("OnTooltipSetItem", 
	function (self, ...)
		if BE.TipEnable then 
			local name = self:GetItem()
			if name ~= nil then BE.AddTip(self, GetBindingKey("ITEM "..name)) end
		end
	end)
	-- Macro (There is not OnTooltipSetMacro)
	GameTooltip:HookScript("OnShow", function(self)
		action = self:GetOwner().action
		if action ~= nil then
			actionType, id, subType = GetActionInfo(action)
			if actionType == "macro" then
				local name = GetMacroInfo(id) 
				local key = GetBindingKey("MACRO "..name) 
				BE.AddTip(self, key)
				-- For resize
				self:Show()
			end
		end
	end)
	-- Note about attach
	self.TipAttached = true
end 

-- Append keybind text to first tooltip line
function BE.AddTip(toolTip, bindingKey)
	if bindingKey then
		keyTip = NORMAL_FONT_COLOR_CODE.."("..GetBindingText(bindingKey, "KEY_")..")"..FONT_COLOR_CODE_CLOSE 
		local nameLine = _G[toolTip:GetName().."TextLeft1"]
		nameLine:SetText(nameLine:GetText().." "..keyTip)
	end
end

--
-- Startup
--
BE:EnableDialog(true)
BE:EnableTip(true)