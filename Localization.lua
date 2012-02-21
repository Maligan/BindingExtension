local prompt, create, clear 
local locale = GetLocale()

if locale == "ruRU" then
	-- [Russian] mother tongue first ;-)
	prompt = "Назначьте клавишу для %s" 
	create = "Назначить %s для %s" 
	clear = "Сбросить клавишу для %s"
elseif locale == "frFR" then
	-- [French]
	prompt = "Créer raccourci clavier pour %s"
	create = "Créer %s pour %s"
	clear = "Effacer raccourci clavier pour %s"
elseif locale == "deDE" then
	-- [German] I studied German in 5th class! Hellow Germany!
	prompt = "Satz Tastenkombination für %s"
	create = "Satz %s für %s"
	clear = "Klarer Tastenkombination für %s"
elseif locale == "esES" then
	-- [Spanish (Spain)]
	prompt = "Asignar atajo de teclado para %s"
	create = "Asignar %s para %s"
	clear = "Borrar atajo de teclado para %s"
else
	-- [English] is default
	prompt = "Set keybinding for %s" 
	create = "Set %s for %s" 
	clear = "Clear keybinding for %s"
end

-- Apply Locale
BINDING_EXTENSION_PROMPT_BINDING = prompt 
BINDING_EXTENSION_CREATE_BINDING = create
BINDING_EXTENSION_CLEAR_BINDING = clear