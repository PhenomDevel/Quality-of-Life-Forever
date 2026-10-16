# Module entwickeln

Jede Komfortfunktion ist ein eigenständiges **Modul**. Module lassen sich im
Einstellungsfenster (*Optionen → AddOns → Quality of Life Forever*) oder per
`/qol enable|disable|toggle <Modul>` einzeln ein- und ausschalten.

## Neues Modul in 4 Schritten

1. `docs/ModuleTemplate.lua` nach `QualityOfLifeForever/Modules/<Kategorie>/<Name>.lua` kopieren.
2. Datei in `QualityOfLifeForever/QualityOfLifeForever.toc` unter `# Modules`
   eintragen – **oberhalb** von `Core\Bootstrap.lua`.
3. Texte in `Locales/enUS.lua` **und** `Locales/deDE.lua` ergänzen
   (Schlüssel-Präfix = Modulname in `UPPER_SNAKE_CASE`).
4. `luacheck .` ausführen und das Modul im Spiel testen.
   Neue WoW-API-Funktionen müssen in `.luacheckrc` unter `read_globals` stehen.

## `ns:NewModule(name, info)`

| Feld              | Typ     | Beschreibung |
|-------------------|---------|--------------|
| `title`           | string  | Name im Einstellungsfenster (lokalisiert) |
| `description`     | string  | Tooltip der Aktivieren-Checkbox (lokalisiert) |
| `category`        | string  | `INTERFACE`, `MERCHANT`, `LOOT`, `QUESTS`, `SOCIAL`, `CHAT`, `MAP`, `GENERAL` |
| `defaultEnabled`  | boolean | Standardzustand für neue Nutzer (Standard: `false`) |
| `defaults`        | table   | Standardwerte der Moduloptionen, landen in `self.db` |
| `options`         | table   | Liste von Optionsbeschreibungen fürs Einstellungsfenster (siehe unten) |
| `combatProtected` | boolean | Ein-/Ausschalten wird bis nach dem Kampf verzögert (für geschützte Frames) |
| `requiresReload`  | boolean | Nach dem Ausschalten wird ein `/reload` angeboten |

Der Modulname ist gleichzeitig der Schlüssel in den SavedVariables – **nach
einem Release nicht mehr umbenennen**, sonst gehen Nutzereinstellungen verloren
(oder eine Migration in `Core/Database.lua` schreiben).

### Optionen

```lua
{ key = "showSummary", type = "checkbox", label = L.X, tooltip = L.X_DESC }
{ key = "amount", type = "slider", label = L.X, tooltip = L.X_DESC, min = 1, max = 10, step = 1 }
{ key = "mode", type = "dropdown", label = L.X, tooltip = L.X_DESC,
  values = { { value = "a", label = L.A }, { value = "b", label = L.B } } }
```

Jede Option braucht einen Eintrag in `defaults`. Optionen sind im
Einstellungsfenster nur bedienbar, solange das Modul aktiv ist.

## Lebenszyklus

| Callback                        | Wann |
|---------------------------------|------|
| `OnInitialize()`                | einmal, nachdem die SavedVariables geladen sind (`ADDON_LOADED`) |
| `OnEnable()`                    | beim Login (falls aktiv) und bei jedem Einschalten |
| `OnDisable()`                   | bei jedem Ausschalten – alles rückgängig machen, was das Modul verändert hat |
| `OnOptionChanged(key, value)`   | wenn sich eine Option ändert, während das Modul aktiv ist |

Fehler in Callbacks werden abgefangen und an den Fehlerhandler gemeldet, damit
ein defektes Modul die anderen nicht mitreißt.

## Hilfsfunktionen

| Methode                                   | Beschreibung |
|-------------------------------------------|--------------|
| `self:RegisterEvent(event[, handler])`    | Ohne Handler wird `self:<EVENT>(...)` aufgerufen. Beim Ausschalten werden alle Events automatisch abgemeldet. |
| `self:UnregisterEvent(event)`             | Einzelnes Event abmelden |
| `self:SecureHook([tabelle,] "Funktion", handler)` | `hooksecurefunc`, der nur bei aktivem Modul feuert |
| `self:HookScript(frame, "OnShow", handler)` | `frame:HookScript`, der nur bei aktivem Modul feuert |
| `self:Print(...)`                         | Chatausgabe (respektiert die globale Option „Chatnachrichten anzeigen“) |
| `self:Debug(...)`                         | Ausgabe nur im Debug-Modus (`/qol debug`) |
| `self:GetOption(key)` / `self:SetOption(key, value)` | Optionen lesen/schreiben (hält das Einstellungsfenster synchron) |
| `self.db`                                 | Gespeicherte Daten des Moduls (accountweit) |
| `ns.Utils.FormatMoney(kupfer)`            | Goldbetrag mit Münzsymbolen |
| `ns.Utils.IsSecret(wert)`                 | Prüft auf „Secret Values“ (siehe unten) |

## Besonderheiten von WoW Forever

* Forever nutzt die **moderne Retail-API** (Midnight-Basis, `C_*`-Namespaces),
  nicht die alte Classic-Era-API. Classic-Code also nicht blind übernehmen.
* Die **Addon-Einschränkungen aus Midnight** gelten auch in Forever: Bestimmte
  Kampfdaten (z. B. Lebenspunkte anderer Einheiten) sind *Secret Values* – sie
  dürfen angezeigt, aber nicht gelesen, verglichen oder verrechnet werden.
  Vor Logik mit solchen Werten `ns.Utils.IsSecret(wert)` prüfen.
* Geschützte Frames (Aktionsleisten, Einheitenrahmen, …) dürfen im Kampf nicht
  verändert werden → `combatProtected = true` setzen.
