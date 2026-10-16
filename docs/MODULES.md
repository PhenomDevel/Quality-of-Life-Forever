# Module entwickeln

Jede Komfortfunktion ist ein eigenständiges **Modul**. Module lassen sich im
Einstellungsfenster (*Optionen → AddOns → Quality of Life Forever*) oder per
`/qol enable|disable|toggle <Modul>` einzeln ein- und ausschalten.

## Neues Modul

Ein Modul ist in sich geschlossen: Code, Texte (enUS + deDE) und
luacheck-Globals stehen in **einer** Datei. Dadurch kollidieren parallele
Modul-PRs nicht in gemeinsamen Dateien.

1. `docs/ModuleTemplate.lua` nach `QualityOfLifeForever/Modules/<Kategorie>/<Name>.lua` kopieren.
2. In der `.toc` im Abschnitt der Kategorie eintragen (alphabetisch).
3. Texte per `ns.NewLocale({ enUS = {...}, deDE = {...} })` in der Moduldatei
   (Fallback: Client-Sprache → enUS → Schlüssel).
4. Genutzte WoW-API in der ersten Zeile deklarieren:
   `-- luacheck: read globals SomeApi C_Something`
5. `luacheck .` ausführen, im Spiel testen.

## `ns:NewModule(name, info)`

| Feld              | Typ     | Beschreibung |
|-------------------|---------|--------------|
| `title`           | string  | Name im Einstellungsfenster (lokalisiert) |
| `description`     | string  | Tooltip der Aktivieren-Checkbox (lokalisiert) |
| `category`        | string  | `EASYSETTINGS`, `INTERFACE`, `CHARACTER`, `TOOLTIP`, `CAMERA`, `GRAPHICS`, `MERCHANT`, `LOOT`, `QUESTS`, `SOCIAL`, `CHAT`, `MAP`, `GENERAL` |
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
{ type = "button", label = L.X, buttonText = L.APPLY, tooltip = L.X_DESC,
  onClick = function(module) ... end }   -- kein key/default, nur bei aktivem Modul
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
| `self:SetCVar(name, value)`               | CVar setzen; Originalwert wird im Modul-DB gesichert und beim Ausschalten automatisch wiederhergestellt. `false` bei unbekanntem CVar. |
| `self:RestoreCVars()`                     | Gesicherte CVars sofort wiederherstellen |
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
