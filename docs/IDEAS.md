# Ideen-Backlog

Abgestimmte Liste der Module, die umgesetzt werden sollen. Vor der Umsetzung im
Beta-Client prüfen, ob die benötigte API in Forever verfügbar und nicht durch
die Addon-Einschränkungen (Secret Values, geschützte Funktionen) blockiert ist.

`[x]` = umgesetzt, `[ ]` = geplant

## Händler, Beute & Post
- [x] Automatisch reparieren (`AutoRepair`)
- [x] Plunder automatisch verkaufen (`AutoSellJunk`)
- [x] Schnelles Plündern (`FastLoot`)
- [ ] Händlerpreis (auch Stapelwert) im Gegenstands-Tooltip anzeigen
- [ ] Stapelkauf mit Shift-Klick ohne Mengendialog
- [ ] „Beim Aufheben gebunden“-Dialog im Solospiel automatisch bestätigen
- [ ] Post: Gold und Gegenstände aller Briefe mit einem Knopf einsammeln

## Quests
- [ ] Quests automatisch annehmen und abgeben (Modifikatortaste setzt aus, keine automatische Belohnungswahl)
- [ ] Questfortschritt im Chat melden
- [ ] Questtext sofort statt Buchstabe für Buchstabe anzeigen

## Soziales & Gruppe
- [x] Duelle automatisch ablehnen (`AutoDeclineDuels`)
- [ ] Gruppeneinladungen von Freunden/Gilde automatisch annehmen
- [ ] Gildeneinladungen/Petitionen automatisch ablehnen
- [ ] Beschwörungen und Wiederbelebungen außerhalb des Kampfes automatisch annehmen
- [ ] Eigene Notizen zu Spielern, im Tooltip angezeigt

## Chat
- [ ] Klassenfarben für Namen im Chat
- [ ] Links/URLs im Chat kopierbar machen
- [ ] Kanal-Präfixe kürzen ([1. Allgemein] → [1])
- [ ] Spam-/Goldverkäufer-Filter, optional Gildenwerbung in eigenen Tab

## Oberfläche
- [ ] Zwischensequenzen und Filme sofort überspringen
- [ ] Haltbarkeit der Ausrüstung im Charakterfenster anzeigen
- [ ] Gegenstandsstufe an Ausrüstungsfeldern und in Taschen
- [ ] Blizzard-Fenster frei verschieben und skalieren

## Weltkarte
- [ ] Halbtransparenter Nebel des Krieges (unerforschte Gebiete abgedunkelt statt verborgen)
- [ ] Stufenbereich jeder Zone auf der Karte anzeigen
- [ ] Weltkarte verkleinern und frei verschiebbar machen

## Charakter
- [ ] Umbenennen (genaue Bedeutung bei der Umsetzung klären)
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
- [ ] Maximale Zoomdistanz einstellen (Vorgabe 4.0)

## Grafik
- [ ] Versteckte Grafikeinstellungen per Schalter setzen und wiederherstellen (Werte als Vorgabe):
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
- [ ] Automatisches Plündern (CVar `autoLootDefault`)
- [ ] Automatisch reparieren (Schalter für das bestehende Modul `AutoRepair`)
