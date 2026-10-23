local _, ns = ...

-- Notes for the "What's new" window, newest first. One entry per minor/major
-- version (patch releases extend their version's entry); keep them short, the
-- full list is CHANGELOG.md. Lines starting with "# " are section headings.
ns.whatsNew = {
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
