# Ideen-Backlog

Mögliche weitere Module. Vor der Umsetzung im Beta-Client prüfen, ob die
benötigte API in Forever verfügbar und nicht durch die Addon-Einschränkungen
(Secret Values, geschützte Funktionen) blockiert ist.

## Händler & Gold
- [x] Automatisch reparieren (`AutoRepair`)
- [x] Plunder automatisch verkaufen (`AutoSellJunk`)
- [ ] Händlerpreis im Gegenstands-Tooltip anzeigen
- [ ] Stapelkauf mit Shift-Klick ohne Mengendialog

## Beute
- [x] Schnelles Plündern (`FastLoot`)
- [ ] „Beim Aufheben gebunden“-Dialog im Solospiel automatisch bestätigen

## Quests
- [ ] Quests automatisch annehmen und abgeben (mit Modifikatortaste zum Aussetzen)
- [ ] Questlevel im Questlog anzeigen
- [ ] Questfortschritt im Chat melden

## Soziales & Gruppe
- [x] Duelle automatisch ablehnen (`AutoDeclineDuels`)
- [ ] Gruppeneinladungen von Freunden/Gilde automatisch annehmen
- [ ] Gildeneinladungen/Petitionen automatisch ablehnen

## Oberfläche
- [ ] Zwischensequenzen mit Escape/Leertaste sofort überspringen
- [ ] Haltbarkeit der Ausrüstung im Charakterfenster anzeigen
- [ ] Gegenstandsstufe im Charakterfenster/Tooltip
- [ ] Greifen/Deko der Aktionsleiste ausblenden
- [ ] Automatisch absteigen/aufstehen beim Zaubern

## Chat
- [ ] Klassenfarben für Namen im Chat
- [ ] Links/URLs im Chat kopierbar machen
- [ ] Kanal-Präfixe kürzen ([1. Allgemein] → [1])

## Karte & Minimap
- [ ] Spielerkoordinaten auf der Weltkarte
- [ ] Minimap-Zoom per Mausrad
- [ ] Minimap-Knöpfe aufräumen
- [ ] Halbtransparenter Nebel des Krieges (unerforschte Gebiete abgedunkelt statt verborgen)
- [ ] Stufenbereich jeder Zone auf der Karte anzeigen

## Charakter
- [ ] Umbenennen
- [ ] Namen ein-/ausblenden

## Cooldown-Manager
- [ ] Tastenbelegungen anzeigen
- [ ] Position der Tastenbelegungen
- [ ] Größe der Tastenbelegungen
- [ ] Schriftart der Tastenbelegungen

## Tooltip
- [ ] An der Maus verankern
- [ ] Schriftgröße ändern
- [ ] Transparenz ändern

## Kamera
- [ ] Maximale Zoomdistanz einstellen (4.0)

## Grafik
- [ ] Versteckte Grafikeinstellungen setzen (Werte als Vorgabe):
  ```
  /console groundEffectDensity 256
  /console groundEffectFade 370
  /console groundEffectDist 500
  /console lodObjectFadeScale 200
  /console lodObjectCullSize 8
  /console terrainLodDist 1000
  /console ResampleAlwaysSharpen 1
  /console reflectionMode 3
  /console weatherdensity 3
  ```

## EasySettings
Einfacher Zugriff auf bestimmte Einstellungen, ohne sie in den WoW-Optionen
suchen zu müssen:
- [ ] Automatisches Plündern
- [ ] Automatisch reparieren (Schalter für das bestehende Modul `AutoRepair`)
