BE = {}

-- Constants
local BE_PROMPT_BINDING = "Назначьте клавишу для %s" 
local BE_CREATE_BINDING = "Назначить "..NORMAL_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE.." для %s" 
local BE_CLEAR_BINDING = "Сбросить клавишу для %s"
-- Why it does not exist?
local FONT_COLOR_CODE_OPEN = "|c"

-- Switch on/off binding text in ToolTip 
function BE:EnableTip(bool)
	if bool and not self.TipHooked then 
		BE:HookTip() 
	end
	self.TipEnable = bool 
end

-- Hooking BE tips to GameToolTip
function BE:HookTip()
	-- Spells 
	GameTooltip:HookScript("OnTooltipSetSpell",
	function (self, ...) 
		if BE.TipEnable then 
			local name = self:GetSpell()
			local key = GetBindingKey("SPELL "..name) 
			BE.AddTip(self, key) 
		end
	end)

	-- Items 
	GameTooltip:HookScript("OnTooltipSetItem", 
	function (self, ...)
		if BE.TipEnable then 
			local name = self:GetItem()
			local key = GetBindingKey("ITEM "..name) 
			BE.AddTip(self, key) 
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

	-- Note about hooking 
	self.TipHooked = true
end 

-- Append keybind text to first tooltip line
function BE.AddTip(toolTip, bindingKey)
	if bindingKey then
		keyTip = NORMAL_FONT_COLOR_CODE.."("..BE.GetLocalizedKey(bindingKey)..")"..FONT_COLOR_CODE_CLOSE 
		local nameLine = _G[toolTip:GetName().."TextLeft1"]
		nameLine:SetText(nameLine:GetText().." "..keyTip)
	end
end

-- Static Popup definition 
StaticPopupDialogs["BINDING_EXTENSION"] = {
	text = "",
	button1 = TEXT(ACCEPT), 
	button2 = TEXT(CANCEL), 
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	-- Initialize dialog
	OnShow = function (self, ...) 
		self.data.info = StaticPopupDialogs["BINDING_EXTENSION"]
		self.data.colorizeEntity = BE.GetColored(self.data.kind, self.data.entity)
		-- New or Owerride?
		local key = GetBindingKey(self.data.kind.." "..self.data.entity)
		if key == nil then
			self.text:SetFormattedText(BE_PROMPT_BINDING, self.data.colorizeEntity)
			self.button1:Disable()
		else
			self.text:SetFormattedText(BE_CLEAR_BINDING, self.data.colorizeEntity)
		end	
		-- Change script handlers
		self.data.OriginOnKeyDown = self:GetScript("OnKeyDown")
		self.data.OriginOnMouseDown = self:GetScript("OnMouseDown")
		self.data.OriginOnMouseWheel = self:GetScript("OnMouseDown")
		self:SetScript("OnKeyDown", self.data.info.keyboardHandler)
		self:SetScript("OnMouseDown", self.data.info.mouseHandler)
		self:SetScript("OnMouseWheel", self.data.info.wheelHandler)
	end,
	-- Return origin script handlers
	OnHide = function (self, ...)
		self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
		self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
		self:SetScript("OnMouseWheel", self.data.OriginOnMouseWheel)
		self.data = nil
	end,
	-- Disable accept button in combat
	OnUpdate = function(self, ...)
		if self.data.combat ~= UnitAffectingCombat("player") then
			self.data.combat = UnitAffectingCombat("player")
			if self.data.combat then
				self.button1:Disable()
				self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
				self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
				self:SetScript("OnMouseWheel", self.data.OriginOnMouseWheel)
			else
				self.button1:Enable()
				self:SetScript("OnKeyDown", self.data.info.keyboardHandler)
				self:SetScript("OnMouseDown", self.data.info.mouseHandler)
				self:SetScript("OnMouseWheel", self.data.info.wheelHandler)
			end
		end
	end,
	-- Create binding
	OnAccept = function (self, ...)
		BE.SafelySetBinding(self.data.key, self.data.kind.." "..self.data.entity)
	end,
	-- Handle keyboard input
	keyboardHandler = function(dialog, key)
		if key == "UNKNOWN" 
			or string.find(key, "SHIFT") 
			or string.find(key, "CTRL") 
			or string.find(key, "ALT") then return end
	
		key = BE.GetModifiers()..key
		dialog.data.info.change(dialog, key)
	end,	
	-- Handle mouse input
	mouseHandler = function(dialog, key)
		if key == "UNKNOWN" then return
		elseif key == "LeftButton" then key = "BUTTON1" 
		elseif key == "RightButton" then key = "BUTTON2"
		elseif key == "MiddleButton" then key = "BUTTON3"
		else key = key:upper() end

		key = BE.GetModifiers()..key
		dialog.data.info.change(dialog, key)
	end,
	wheelHandler = function(dialog, arg)
		local key
		if arg > 0 then 
			key = "MOUSEWHEELUP"
		else 
			key = "MOUSEWHEELDOWN" 
		end
		key = BE.GetModifiers()..key
		dialog.data.info.change(dialog, key)
	end,
	-- Change input key
	change = function(dialog, key)
		if key ~= nil then
			dialog.data.key = key 
			-- Change text
			local localizedKey = BE.GetLocalizedKey(key)
			local coloredName = BE.GetColored(dialog.data.kind,dialog.data.entity)
			_G[dialog:GetName().."Text"]:SetFormattedText(BE_CREATE_BINDING, localizedKey, coloredName)
			dialog.button1:Enable()
			-- Resizing
			dialog.maxWidthSoFar = nil 
			dialog.maxHeightSoFar = nil 
			StaticPopup_Resize(dialog, "BINDING_EXTENSION")
		end
	end
}

-- Code sugar :-)
function BE.PopupDialog(kind, entity) StaticPopup_Show("BINDING_EXTENSION", nil, nil, { kind = kind, entity = entity }) end

function BE.IsModifiedPress() return IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() end

function BE.GetModifiers()
	local mods = "" 
	if IsShiftKeyDown() then mods = "SHIFT-" end
	if IsControlKeyDown() then mods = "CTRL-"..mods end
	if IsAltKeyDown() then mods = "ALT-"..mods end
	return mods
end

-- Safely set binding
function BE.SafelySetBinding(key, command)
	local oldKey = GetBindingKey(command)
	-- If there is not change
	if oldKey == key then return; end
	-- Clear key for binding
	if oldKey ~= nil then SetBinding(oldKey); end
	-- Create binding, else return binding
	if key ~= nil and not SetBinding(key, command) and oldKey then SetBinding(oldKey, command) end
	-- Save current binding set
	SaveBindings(GetCurrentBindingSet())
end

-- Nice view of item/spell/macro
function BE.GetColored(kind, entity)
	-- Default color 
	local color = "FFFFD200"
	-- Switch
	if kind == "ITEM" then
		_, _, quality = GetItemInfo(entity)
		_, _, _, color = GetItemQualityColor(quality)
	elseif kind == "SPELL" then
		color = "FF71D5FF"
	end	
	-- Combine
	return FONT_COLOR_CODE_OPEN..color.."["..entity.."]"..FONT_COLOR_CODE_CLOSE
end

-- Localized name of key
function BE.GetLocalizedKey(key) 
	-- Parsing
	local modKeys = ""
	local dashIndex = key:reverse():find("-")
	if dashIndex then
		modKeys = key:sub(1, -dashIndex)
		key = key:sub(-dashIndex+1)
	end
	-- Localization
	if IsMacClient() then suffix = "_MAC" else suffix = "" end
	localized = _G["KEY_"..key..suffix]
	if not localized then localized = key end
	-- Result
	return modKeys..localized 
end

-- Attach popup to different game button
-- Attach to Spell button
SpellButton_OriginOnModifiedClick = SpellButton_OnModifiedClick 	
SpellButton_OnModifiedClick = function (self, button)
	if BE.IsModifiedPress() and button == "LeftButton" then 
		local slot = SpellBook_GetSpellBookSlot(self)
		local spellName = GetSpellBookItemName(slot, SpellBookFrame.bookType)
		if spellName and not IsPassiveSpell(slot, SpellBookFrame.bookType) then
			BE.PopupDialog("SPELL", spellName) 
		end
	else
		SpellButton_OriginOnModifiedClick(self, button)
	end
end

-- Attach to Container button (Bag item)
ContainerFrameItemButton_OriginOnModifiedClick = ContainerFrameItemButton_OnModifiedClick 	
ContainerFrameItemButton_OnModifiedClick = function (self, button)
	if BE.IsModifiedPress() and button == "LeftButton" then 
		local itemName = GetItemInfo(GetContainerItemID(self:GetParent():GetID(), self:GetID()))
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
	if BE.IsModifiedPress() and button == "LeftButton" then 
		local name = _G[self:GetName().."Name"]:GetText()
		BE.PopupDialog("MACRO", name)
	end
end

BE:EnableTip(true)
