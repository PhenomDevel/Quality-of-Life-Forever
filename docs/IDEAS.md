# Ideen-Backlog

Abgestimmte Liste der Module, sortiert nach **Machbarkeit und Aufwand**: Wir
arbeiten von oben nach unten. Die Einschätzung beruht auf der modernen
WoW-API. Jede Annahme (z. B. „CVar existiert“) wird vor der Umsetzung im
Forever-Client geprüft, weil Forever eigene Grenzen und die
Midnight-Addon-Einschränkungen (Secret Values, geschützte Funktionen) hat.

Alle Module werden **eigenständig geschrieben** – kein Code und keine Daten aus
anderen Addons (siehe `CLAUDE.md`).

`[x]` = umgesetzt, `[ ]` = geplant

## Bereits umgesetzt
- [x] Automatisch reparieren (`AutoRepair`)
- [x] Plunder automatisch verkaufen (`AutoSellJunk`)
- [x] Schnelles Plündern (`FastLoot`)
- [x] Duelle automatisch ablehnen (`AutoDeclineDuels`)

## Stufe 1 – Sehr einfach
Eine Spieleinstellung (CVar) oder ein einzelnes Event, kaum eigene Oberfläche.

| # | Idee | Bereich | Ansatz | Risiko |
|---|------|---------|--------|--------|
| 1 | [ ] Automatisches Plündern | EasySettings | CVar `autoLootDefault` als Schalter | gering |
| 2 | [ ] Automatisch reparieren | EasySettings | Schalter für das bestehende Modul `AutoRepair` | gering |
| 3 | [ ] Eigenen Namen ein-/ausblenden | Charakter | CVar für den eigenen Namen | gering |
| 4 | [ ] Maximale Zoomdistanz (Vorgabe 4.0) | Kamera | CVar für den Zoomfaktor | mittel: der Client begrenzt den Wert evtl. unter 4.0 |
| 5 | [ ] Versteckte Grafikeinstellungen | Grafik | CVars setzen, alte Werte speichern und beim Ausschalten wiederherstellen | gering: einzelne Werte evtl. gesperrt |
| 6 | [ ] Klassenfarben im Chat | Chat | vorhandene Spieleinstellung als Schalter, falls in Forever verfügbar | gering |
| 7 | [ ] Questtext sofort anzeigen | Quests | Spieleinstellung für das Einblenden des Questtexts, falls vorhanden | mittel: sonst Stufe 2 |
| 8 | [ ] Gildeneinladungen/Petitionen ablehnen | Soziales | Event abfangen und ablehnen | gering |
| 9 | [ ] „Beim Aufheben gebunden“ solo bestätigen | Beute | Event abfangen, nur ohne Gruppe bestätigen | gering |
| 10 | [ ] Beschwörung/Wiederbelebung annehmen | Soziales | Events abfangen, nur außerhalb des Kampfes | gering |
| 11 | [ ] Tooltip an der Maus verankern | Tooltip | Standard-Ankerfunktion per Secure Hook umsetzen | gering |

Grafik-Vorgabewerte für #5:
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

## Stufe 2 – Einfach
Ein Hook oder Event, etwas Logik oder eine kleine Anzeige.

| # | Idee | Bereich | Ansatz | Risiko |
|---|------|---------|--------|--------|
| 12 | [ ] Tooltip-Schriftgröße | Tooltip | Schriftobjekte des Tooltips skalieren | gering |
| 13 | [ ] Tooltip-Transparenz | Tooltip | Hintergrund-Alpha des Tooltips setzen | gering |
| 14 | [ ] Händlerpreis im Tooltip | Händler | Tooltip-Erweiterung für Gegenstände, Verkaufspreis × Stapel | gering |
| 15 | [ ] Gruppeneinladungen von Freunden/Gilde annehmen | Soziales | Einladung abfangen, Absender gegen Freundesliste/Gilde prüfen | gering |
| 16 | [ ] Zwischensequenzen überspringen | Oberfläche | beim Start abbrechen, optional nur bereits gesehene | mittel: manche Sequenzen nicht abbrechbar |
| 17 | [ ] Stapelkauf mit Shift | Händler | Klick auf Händlerware abfangen, vollen Stapel kaufen | gering |
| 18 | [ ] Questfortschritt im Chat | Quests | Fortschrittsmeldungen abfangen und im Chat ausgeben | gering |
| 19 | [ ] Haltbarkeit im Charakterfenster | Oberfläche | Prozentwert an jedem Ausrüstungsfeld | gering |
| 20 | [ ] Stufenbereiche der Zonen | Weltkarte | Stufenbereich aus der Karten-API anzeigen | mittel: nur machbar, wenn die API in Forever Daten liefert |

## Stufe 3 – Mittel
Mehrere Hooks, eigene Oberfläche oder spürbare Forever-Einschränkungen.

| # | Idee | Bereich | Ansatz | Risiko |
|---|------|---------|--------|--------|
| 21 | [ ] Gegenstandsstufe (Ausrüstung + Taschen) | Oberfläche | Charakterfenster einfach, Taschen aufwendiger | gering |
| 22 | [ ] Post: alles einsammeln | Händler | Knopf im Briefkasten, Briefe gedrosselt abarbeiten, volle Taschen beachten | mittel |
| 23 | [ ] Kanal-Präfixe kürzen | Chat | Kanalnamen in Chatnachrichten ersetzen | mittel: Chat-Einschränkungen in Instanzen |
| 24 | [ ] URLs kopierbar | Chat | URLs als Link markieren, Klick öffnet Kopierfeld | mittel: Chat-Einschränkungen in Instanzen |
| 25 | [ ] Cooldown-Manager: Tastenbelegungen anzeigen, Position, Größe, Schriftart | Cooldown-Manager | Zauber den Aktionsleisten-Tasten zuordnen, Text auf die Symbole legen; Position/Größe/Schriftart als Optionen desselben Moduls | mittel: Aufbau des Cooldown-Managers in Forever prüfen |
| 26 | [ ] Spielernotizen | Soziales | Notizen speichern, im Tooltip zeigen, Eingabe per Rechtsklickmenü | mittel: Spielernamen evtl. als Secret Value |
| 27 | [ ] Spam-Filter (optional Gildenwerbung in eigenen Tab) | Chat | Nachrichtenfilter mit eigener Schlagwortliste | mittel: Chat-Einschränkungen, Fehlalarme |
| 28 | [ ] Weltkarte verkleinern/verschiebbar | Weltkarte | Größe und Position der Karte ändern und speichern | mittel |

## Stufe 4 – Aufwendig oder unklar

| # | Idee | Bereich | Warum aufwendig |
|---|------|---------|-----------------|
| 29 | [ ] Blizzard-Fenster verschieben/skalieren | Oberfläche | viele Fenster einzeln, teils geschützt im Kampf, teils erst bei Bedarf geladen, Positionen speichern |
| 30 | [ ] Halbtransparenter Nebel des Krieges | Weltkarte | Die API liefert nur die *erkundeten* Kartenteile. Für unerforschte Bereiche bräuchten wir eigene Kartendaten, die wir selbst im Spiel erheben müssten (Daten aus anderen Addons sind tabu). Machbarkeit offen. |
| 31 | [ ] Charakter umbenennen | Charakter | Anforderung noch unklar, vor der Umsetzung klären |
