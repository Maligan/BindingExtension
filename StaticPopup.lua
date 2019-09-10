--
-- Built-in interface for key binding, for call use:
-- StaticPopup_Show("BINDING_EXTENSION", nil, nil, { kind = ["SPELL", "ITEM" or "MACRO"], name = [Name of spell, item or macro] }) 
--
-- There are dependencies from global:
-- BINDING_EXTENSION_PROMPT_BINDING
-- BINDING_EXTENSION_CREATE_BINDING
-- BINDING_EXTENSION_CLEAR_BINDING
--
-- by Maligan (maligan@rambler.ru) 
--

StaticPopupDialogs["BINDING_EXTENSION"] = {
	--
	-- StaticPopup standard variables
	--
	text = "",
	button1 = GetText("ACCEPT"), 
	button2 = GetText("CANCEL"), 
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,

	--
	-- StaticPopup standard handlers
	--
	-- Initialize dialog
	OnShow = function (self, ...)
		self.data.info = StaticPopupDialogs["BINDING_EXTENSION"]
		self.data.colorizedName = self.data.info.GetColored(self.data.kind, self.data.name)

		-- New or Override?
		local key = GetBindingKey(self.data.kind.." "..self.data.name)
		self.data.info.Refresh(self, key, key ~= nil)

		-- Change script handlers
		self.data.OriginOnKeyDown = self:GetScript("OnKeyDown")
		self.data.OriginOnMouseDown = self:GetScript("OnMouseDown")
		self.data.OriginOnMouseWheel = self:GetScript("OnMouseDown")
		self:SetScript("OnKeyDown", self.data.info.KeyboardHandler)
		self:SetScript("OnMouseDown", self.data.info.MouseHandler)
		self:SetScript("OnMouseWheel", self.data.info.WheelHandler)
	end,
	-- Return origin script handlers
	OnHide = function (self, ...)
		self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
		self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
		self:SetScript("OnMouseWheel", self.data.OriginOnMouseWheel)
		self.data = nil
	end,
	-- Disable accept button in combat
	OnUpdate = function (self, ...)
		combat = UnitAffectingCombat("player")
		if self.data.combat ~= combat then
			self.data.combat = combat
			if self.data.combat then
				self.button1:Disable()
				self:SetScript("OnKeyDown", self.data.OriginOnKeyDown)
				self:SetScript("OnMouseDown", self.data.OriginOnMouseDown)
				self:SetScript("OnMouseWheel", self.data.OriginOnMouseWheel)
			else
				self.button1:Enable()
				self:SetScript("OnKeyDown", self.data.info.KeyboardHandler)
				self:SetScript("OnMouseDown", self.data.info.MouseHandler)
				self:SetScript("OnMouseWheel", self.data.info.WheelHandler)
			end
		end
	end,
	-- Create binding
	OnAccept = function (self, ...)
		local command = self.data.kind.." "..self.data.name

		if self.data.clear then
			self.data.info.SafelySetBinding(nil, command)
		else
			self.data.info.SafelySetBinding(self.data.key, command)
		end
	end,
	-- 
	-- Input handlers
	--
	-- Handle keyboard input
	KeyboardHandler = function (self, key)
		if key == "UNKNOWN" 
			or string.find(key, "SHIFT") 
			or string.find(key, "CTRL") 
			or string.find(key, "ALT") then return end
	
		self.data.info.Refresh(self, self.data.info.GetModifiers()..key, false)
	end,	
	-- Handle mouse input
	MouseHandler = function (self, key)
		if key == "UNKNOWN" then return
		elseif key == "LeftButton" then key = "BUTTON1" 
		elseif key == "RightButton" then key = "BUTTON2"
		elseif key == "MiddleButton" then key = "BUTTON3"
		else key = key:upper() end

		self.data.info.Refresh(self.data.info.GetModifiers()..key, false)
	end,
	-- Handle mouse wheel
	WheelHandler = function (self, arg)
		local key
		if arg > 0 then key = "MOUSEWHEELUP" else key = "MOUSEWHEELDOWN" end
		self.data.info.Refresh(self.data.info.GetModifiers()..key, false)
	end,
	-- Change status key
	Refresh = function (self, key, clear)
		self.data.key = key
		self.data.clear = clear;

		-- Change text & button
		if clear == true then
		 	self.text:SetFormattedText(BINDING_EXTENSION_CLEAR_BINDING, self.data.colorizedName)
			self.button1:Enable()
		elseif key == nil then
			self.text:SetFormattedText(BINDING_EXTENSION_PROMPT_BINDING, self.data.colorizedName)
			self.button1:Disable()
		else
			local localizedKey = NORMAL_FONT_COLOR_CODE..GetBindingText(key, "KEY_")..FONT_COLOR_CODE_CLOSE
			self.text:SetFormattedText(BINDING_EXTENSION_CREATE_BINDING, localizedKey, self.data.colorizedName)
			self.button1:Enable()
		end

		-- Resizing
		self.maxWidthSoFar = nil 
		self.maxHeightSoFar = nil 
		StaticPopup_Resize(self, "BINDING_EXTENSION")
	end,
	--
	-- Misc
	--
	-- Safely set binding
	SafelySetBinding = function (key, command)
		local oldKey = GetBindingKey(command)
		-- If there is not change
		if oldKey == key then return; end
		-- Clear old binding
		if oldKey ~= nil then SetBinding(oldKey) end
		-- Create binding
		if key ~= nil and not SetBinding(key, command) and oldKey ~= nil then 
			-- If error then return old binding
			SetBinding(oldKey, command)
		else
			-- Save current binding set	
			local which = GetCurrentBindingSet()

			-- For actual & classic WoW versions this methods are different
			local flush = nil
			if SaveBindings ~= nil then flush = SaveBindings
			elseif AttemptToSaveBindings ~= nil then flush = AttemptToSaveBindings end 

			flush(which)
		end
	end,
	-- Colored view of item/spell/macro
	GetColored = function (kind, name)
		-- Default color 
		local color = "FFFFD200"
		-- Switch
		if kind == "ITEM" then
			_, _, quality = GetItemInfo(name)
			_, _, _, color = GetItemQualityColor(quality)
		elseif kind == "SPELL" then
			color = "FF71D5FF"
		end	
		-- Combine
		return "|c"..color.."["..name.."]".."|r"
	end,
	-- Return pressed modifiers
	GetModifiers = function ()
		local mods = "" 
		if IsShiftKeyDown() then mods = "SHIFT-" end
		if IsControlKeyDown() then mods = "CTRL-"..mods end
		if IsAltKeyDown() then mods = "ALT-"..mods end
		return mods
	end
}
