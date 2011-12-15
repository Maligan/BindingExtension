--
-- BindingExtension
-- Модуль аддона отвечающий за подсказки в GameToolTip
-- Единственная публичная функция отсюда: BindingExtension:SetToolTip(enabe)
--

--
-- Инициализация переменных аддона
--
if not BindingExtension then BindingExtension = {} end
if not BindingExtension.Setting then BindingExtension.Setting = {} end
BindingExtension.Settings.ToolTipEnable = false
BindingExtension.Attached = true

--
-- Прикрепление функций к событиям отрисовки ToolTip
--
function BindingExtension:SetToolTip(enable)
	if enable and self.Attached then self:AttachToolTip end
	self.ToolTipEnable = enable
end

-- Вставка функций в скрипты GameToolTip
function BindingExtension:AttachToGameToolTip()
	-- Для заклинаний строчка вставляется в конце 
	GameTooltip:HookScript("OnTooltipSetSpell",
	function (self) 
		if BindingExtension.Settings.EnableToolTip then 
			local name = self:GetSpell()
			local line = BindingExtension.GetBindingString("SPELL", name)
			self:AddLine(line)
		end
	end)

	-- Для предметов вставка осуществляется ДО строки стоимости
	BindingExtension.OriginalOnToolTipAddMoney = GameTooltip:GetScript("OnTooltipAddMoney")
	GameTooltip:SetScript("OnTooltipAddMoney", 
	function (self, ...)
		if BindingExtension.Settings.EnableToolTip then 
			local name = self:GetItem()
			local line = BindingExtension.GetBindingString("ITEM", name)
			self:AddLine(line)
		end
		BindingExtension.OriginalOnToolTipAddMoney(self, ...) 
	end)

	-- Записть о том что скрипты GameToolTip были изменены
	self.Attached = true
end 

--
-- Строковые функции
--
-- Карта переименований
BindingExtension.RenameMap = {
	["SHIFT"] = "<Shift>",
	["CTRL"] = "<Ctrl>",
	["ALT"] = "<Alt>",
	["SPACE"] = "Space",	
}
-- Кэш преобразований
BindingExtension.RenameCache = {}
-- Переименование клавиш (пример: SHIFT-SPACE в <Shift>-Space)
function BindingExtension.RenameKey(key)
	local newKey = BindingExtension.RenameCache[key]
	if not newKey then 
		newKey = key
		for from, to in pairs(BindingExtension.RenameMap) do newKey = newKey:gsub(from, to) end
		BindingExtension.RenameCache[key] = newKey
	end
	return newKey
end
-- Вычисление строчки привязки к ToolTip
function BindingExtension.GetBindingString(kind, name)
	local key = GetBindingKey(kind.." "..name) 
	if key then key = "Клавиша: |cffffffff"..BindingExtension.RenameKey(key).."|r" end
	return key
end
