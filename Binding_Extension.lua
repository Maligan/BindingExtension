BE = {}

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

	-- Note about hooking 
	self.TipHooked = true
end 

-- Append keybind text to first tooltip line
function BE.AddTip(toolTip, bindingKey)
	if bindingKey then
		keyTip = NORMAL_FONT_COLOR_CODE.."("..bindingKey..")"..FONT_COLOR_CODE_CLOSE 
		local nameLine = _G[toolTip:GetName().."TextLeft1"]
		nameLine:SetText(nameLine:GetText().." "..keyTip)
	end
end

-- Static Popup initialization 
StaticPopupDialogs["BINDING_EXTENSION"] = {
	button1 = TEXT(ACCEPT), 
	button2 = TEXT(CANCEL), 
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	-- Save origin script hsndlers
	OnShow = function (self, ...)
		self.data = {}
		self.data.OriginOnKeyDown = self:GetScript("OnKeyDown")
		self.data.OriginOnMouseDown = self:GetScript("OnMouseDown")
		self:SetScript("OnKeyDown", BE.KeyboardHandler)
		self:SetScript("OnMouseDown", BE.MouseHandler)
	end,
	-- Return origin script handlers
	OnHide = function (self, ...)
		self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
		self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
		self.data = nil
	end,
	-- Disable accept button in combat
	OnUpdate = function(self, ...)
		if self.data.combat ~= UnitAffectingCombat("player") then
			self.data.combat = UnitAffectingCombat("player")
			if self.data.combat then
				self.button1:Disable();
				self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
				self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
			else
				self.button1:Enable();
				self:SetScript("OnKeyDown", BE.KeyboardHandler)
				self:SetScript("OnMouseDown", BE.MouseHandler)
			end
		end
	end,
	-- Create binding
	OnAccept = function (self, ...)
		BE.SafelySetBinding(self.data.key, self.data.kind.." "..self.data.entity)
	end,
}

-- Attach to Spell button
SpellButton_OriginOnModifiedClick = SpellButton_OnModifiedClick 	
SpellButton_OnModifiedClick = function (self, button)
	if BE.IsModifiedPress() and button == "LeftButton" then 
		local slot = SpellBook_GetSpellBookSlot(self)
		local spellName = GetSpellBookItemName(slot, SpellBookFrame.bookType)
		if spellName and not IsPassiveSpell(slot, SpellBookFrame.bookType) then
			BE:Popup("SPELL", spellName) 
		end
	else
		SpellButton_OriginOnModifiedClick(self, button)
	end
end

-- Attach to Container button 
ContainerFrameItemButton_OriginOnModifiedClick = ContainerFrameItemButton_OnModifiedClick 	
ContainerFrameItemButton_OnModifiedClick = function (self, button)
	if BE.IsModifiedPress() and button == "LeftButton" then 
		local itemName = GetItemInfo(GetContainerItemID(self:GetParent():GetID(), self:GetID()))
		if itemName ~= nil and GetItemSpell(itemName) ~= null then
			BE:Popup("ITEM", itemName) 
		end
	else
		ContainerFrameItemButton_OriginOnModifiedClick(self, button)
	end
end

-- Attach to Macro
MacroFrame_SelectMacro = function (...)
	print "Select"
end


--button:HookScript("OnEnter", function () BindingExtension.UpdateCursor() end)
--button:HookScript("OnEnter", function () BindingExtension.UpdateCursor() end)
--button:HookScript("OnKeyUp", function () BindingExtension.UpdateCursor() end)
--button:HookScript("OnLeave", function () ResetCursor() end)

function BE.IsModifiedPress() return IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() end

BE_BIND_TEXT = "Назначить "..NORMAL_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE.." для |cff71d5ff[%s]|r" 
BE_PROMPT_TEXT = "Назначьте клавишу для |cff71d5ff%s|r" 
BE_CLEAR_TEXT = "Сбросить клавишу для |cff71d5ff%s|r"


function BE.KeyboardHandler(popup, key)
	if key == "UNKNOWN" 
		or string.find(key, "SHIFT") 
		or string.find(key, "CTRL") 
		or string.find(key, "ALT") then return nil; end
	key = BE.AddModifiers(key)
	if key ~= nil then
		popup.data.key = key
		_G[popup:GetName().."Text"]:SetText(format(BE_BIND_TEXT, popup.data.key, popup.data.entity))
	end
end

function BE:Popup(kind, entity)
	-- Override binding or create new?
	key = GetBindingKey(kind.." "..entity)
	if key == nil then StaticPopupDialogs["BINDING_EXTENSION"].text = format(BE_PROMPT_TEXT, "["..entity.."]") 
	else StaticPopupDialogs["BINDING_EXTENSION"].text = format(BE_CLEAR_TEXT, "["..entity.."]") end
	-- Show standart popup
	local frame = StaticPopup_Show("BINDING_EXTENSION")
	frame.data.kind = kind
	frame.data.entity = entity
end

function BE.KeyTransform(key)
	-- Non-bindable keys
	if key == "PRINTSCREEN" then Screenshot(); return; end
	--[[
	local Map = {
		"LeftButton" = "BUTTON1",
		"RightButton" = "BUTTON2",
		"MiddleButton" = "BUTTON3",
		"Button4" = "BUTTON4",
		"Button5" = "BUTTON5"
	}]]
end

function BE.AddModifiers(key)
	if ( IsShiftKeyDown() ) then key = "SHIFT-"..key; end
	if ( IsControlKeyDown() ) then key = "CTRL-"..key; end
	if ( IsAltKeyDown() ) then key = "ALT-"..key; end
	return key;
end

function BE.SafelySetBinding(key, command)
	local oldKey = GetBindingKey(command)
	-- Reset old binding
	if oldKey ~= nil then SetBinding(oldKey); end
	-- Create binding, else return binding
	if key ~= nil and not SetBinding(key, command) and oldKey then
		SetBinding(oldKey, command)
	end
end















BE:EnableTip(true)
