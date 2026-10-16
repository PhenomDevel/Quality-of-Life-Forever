# Quality of Life Forever

Ein World-of-Warcraft-**Forever**-Addon, das viele kleine Komfortverbesserungen
bündelt. Jede Verbesserung ist ein eigenes Modul und lässt sich einzeln ein-
und ausschalten.

## Module

| Modul                         | Kategorie | Standard | Beschreibung |
|-------------------------------|-----------|----------|--------------|
| Automatisch reparieren        | Händler   | an       | Repariert beim Händler alles, optional mit Gildengold |
| Plunder automatisch verkaufen | Händler   | an       | Verkauft graue Gegenstände beim Händler |
| Schnelles Plündern            | Beute     | aus      | Plündert bei Auto-Loot sofort alle Gegenstände |
| Duelle automatisch ablehnen   | Soziales  | aus      | Lehnt Duellanfragen ab |

Weitere Ideen: [`docs/IDEAS.md`](docs/IDEAS.md)

## Bedienung

* **Optionen:** *Esc → Optionen → AddOns → Quality of Life Forever*, über das
  Addon-Menü an der Minimap oder mit `/qol`.
* **Slash-Befehle:**

  | Befehl                    | Wirkung |
  |---------------------------|---------|
  | `/qol`                    | Optionen öffnen |
  | `/qol list`               | Alle Module mit Status auflisten |
  | `/qol enable <Modul>`     | Modul aktivieren (z. B. `/qol enable fastloot`) |
  | `/qol disable <Modul>`    | Modul deaktivieren |
  | `/qol toggle <Modul>`     | Modul umschalten |
  | `/qol debug`              | Debug-Ausgaben umschalten |
  | `/qol reset`              | Alle Einstellungen zurücksetzen |

Einstellungen werden accountweit in `QualityOfLifeForeverDB` gespeichert.

## Installation

Ordner `QualityOfLifeForever` (nicht das ganze Repository!) kopieren nach:

* **Beta:** `World of Warcraft/_classic_beta_/Interface/AddOns/`
* **Live (ab 4. November 2026):** Ordner des Forever-Clients unter `Interface/AddOns/`

Für die Entwicklung bietet sich ein Symlink an:

```powershell
# Windows (PowerShell als Administrator)
New-Item -ItemType SymbolicLink `
  -Path "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\QualityOfLifeForever" `
  -Target "C:\Pfad\zu\Quality-of-Life-Forever\QualityOfLifeForever"
```

```bash
# macOS / Linux
ln -s "$PWD/QualityOfLifeForever" "/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/QualityOfLifeForever"
```

## Entwicklung

```
QualityOfLifeForever/        ← der eigentliche Addon-Ordner
  QualityOfLifeForever.toc   ← Ladereihenfolge, Interface-Version, SavedVariables
  Locales/                   ← enUS (Basis) + deDE
  Core/                      ← Framework: Datenbank, Modulverwaltung, Einstellungen, Slash-Befehle
  Modules/<Kategorie>/       ← ein File pro Modul
docs/                        ← Modul-API, Vorlage, Ideen
tests/                       ← WoW-API-Mock + Tests (laufen ohne Spielclient)
tools/package.sh             ← baut ein installierbares Zip
```

* Neues Modul anlegen: [`docs/MODULES.md`](docs/MODULES.md)
* Lint & Tests (Lua 5.1 + [luacheck](https://github.com/lunarmodules/luacheck)):

  ```bash
  luacheck .
  lua5.1 tests/run.lua
  ```

  Beides läuft auch automatisch per GitHub Actions bei jedem Push.
* Release: Tag pushen (`git tag v0.1.0 && git push --tags`) – die Action baut
  das Zip und hängt es an ein GitHub-Release. Lokal: `tools/package.sh 0.1.0`.

### Interface-Version

Die `.toc` deklariert `## Interface: 16001` (Forever-Beta). Sollte sich die
Nummer zum Launch ändern, im Spiel mit `/dump select(4, GetBuildInfo())`
auslesen und in der `.toc` anpassen – sonst wird das Addon als „veraltet“
markiert.
