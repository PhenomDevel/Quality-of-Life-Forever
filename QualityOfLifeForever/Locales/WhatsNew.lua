local _, ns = ...

-- Notes for the "What's new" window, newest first. One entry per minor/major
-- version (patch releases extend their version's entry); keep them short, the
-- full list is CHANGELOG.md. Lines starting with "# " are section headings.
ns.whatsNew = {
	{
		version = "1.4",
		enUS = {
			"# Reminders",
			"Missing self-buffs: Thorns (druid) and Divine Spirit (priest, once learned) count as buffs",
			"# Widgets",
			"XP widget: rested XP is visible on the bar again when you also have quest XP",
		},
		deDE = {
			"# Erinnerungen",
			"Fehlende Selbst-Buffs: Dornen (Druide) und Göttlicher Willen (Priester, sobald erlernt) zählen als Buffs",
			"# Widgets",
			"EP-Widget: erholte EP sind wieder auf der Leiste sichtbar, wenn du auch Quest-EP hast",
		},
	},
	{
		version = "1.3",
		enUS = {
			"# Widgets",
			"Junk widget: right-click an item to never list it again (reset under Show)",
			"Junk widget: the white items option never lists fishing poles, profession tools, bags, ammo or reagents",
		},
		deDE = {
			"# Widgets",
			"Plunder-Widget: Rechtsklick auf einen Gegenstand blendet ihn dauerhaft aus (zurücksetzen unter Anzeigen)",
			"Plunder-Widget: bei weißen Gegenständen werden Angeln, Berufswerkzeuge, Taschen, Munition und Reagenzien nie aufgelistet",
		},
	},
	{
		version = "1.2",
		enUS = {
			"# Widgets",
			"Junk widget: can also list white items that sell to a vendor (option Include white items, off by default)",
		},
		deDE = {
			"# Widgets",
			"Plunder-Widget: listet auf Wunsch auch weiße Gegenstände, die ein Händler ankauft (Option Weiße Gegenstände einbeziehen, standardmäßig aus)",
		},
	},
	{
		version = "1.1",
		enUS = {
			"# Widgets",
			"XP widget: shows how long you have been on your current level (played time); can be turned off under Show",
		},
		deDE = {
			"# Widgets",
			"EP-Widget: zeigt, wie lange du schon auf deiner aktuellen Stufe bist (gespielte Zeit); abschaltbar unter Anzeigen",
		},
	},
	{
		version = "1.0",
		enUS = {
			"First stable release, just in time for the launch of WoW Forever",
			"All features from the beta versions, each one can still be turned on and off on its own",
			"Thanks for testing! Ideas and bug reports are welcome on CurseForge, Wago or GitHub",
		},
		deDE = {
			"Erste stabile Version, pünktlich zum Start von WoW Forever",
			"Alle Funktionen aus den Beta-Versionen, jede weiterhin einzeln ein- und ausschaltbar",
			"Danke fürs Testen! Ideen und Fehlermeldungen gerne auf CurseForge, Wago oder GitHub",
		},
	},
	{
		version = "0.13",
		enUS = {
			"# Options",
			"Features that are off run no code at all; turning one off offers a reload to unload it completely",
			"# Bags & items",
			"Bag slots: show free or used slots on the backpack button",
			"# Downloads",
			"Now also on Wago Addons",
		},
		deDE = {
			"# Optionen",
			"Ausgeschaltete Funktionen führen keinerlei Code aus; beim Ausschalten wird ein Neuladen angeboten, um sie ganz zu entladen",
			"# Taschen & Gegenstände",
			"Taschenplätze: freie oder belegte Plätze am Rucksack-Button anzeigen",
			"# Downloads",
			"Jetzt auch auf Wago Addons",
		},
	},
	{
		version = "0.12",
		enUS = {
			"# Options",
			"This window: after updates it shows what's new once; turn it off under General, open it again with /qol news",
			"Preview switch in the title bar of the options: turn the sample widgets and reminders off while the options are open",
		},
		deDE = {
			"# Optionen",
			"Dieses Fenster: zeigt nach Updates einmal die Neuerungen; abschaltbar unter Allgemein, wieder öffnen mit /qol news",
			"Vorschau-Schalter in der Titelleiste der Optionen: Beispiel-Widgets und -Erinnerungen bei offenen Optionen ausblenden",
		},
	},
	{
		version = "0.11",
		enUS = {
			"# Options",
			"New category Action bars; Interface is now Interface & Misc",
			"Widget options are in the same order on every widget",
			"# Action bars & cooldown manager",
			"Move the cooldown numbers on action bars and cooldown manager icons",
			"Cooldown manager: keybind turns red and the icon gray while out of range",
			"# Character",
			"Text size for health and mana on the player and target frames",
			"# Widgets",
			"Optional title per widget; while the options are open, every frame shows its name",
			"Text outline and shadow for every widget",
			"XP widget: bar length and thickness",
			"# Reminders",
			"Missing self-buffs as an icon bar, click to cast",
			"While the options are open, a sample reminder shows where reminders appear; drag it to move them",
		},
		deDE = {
			"# Optionen",
			"Neue Kategorie Aktionsleisten; Oberfläche heißt jetzt Oberfläche & Sonstiges",
			"Die Optionen stehen bei jedem Widget in derselben Reihenfolge",
			"# Aktionsleisten & Cooldown Manager",
			"Abklingzeit-Zahlen auf Aktionsleisten und Cooldown-Manager-Symbolen verschieben",
			"Cooldown Manager: Tastenbelegung rot und Symbol grau außer Reichweite",
			"# Charakter",
			"Textgröße für Gesundheit und Mana am Spieler- und Zielrahmen",
			"# Widgets",
			"Titel pro Widget einblendbar; bei offenen Optionen zeigt jeder Rahmen seinen Namen",
			"Textumrandung und -schatten für jedes Widget",
			"EP-Widget: Länge und Dicke des Balkens",
			"# Erinnerungen",
			"Fehlende Selbst-Buffs als Symbolleiste, Klick wirkt den Buff",
			"Bei offenen Optionen zeigt eine Beispiel-Erinnerung, wo Erinnerungen erscheinen; zum Verschieben ziehen",
		},
	},
}
