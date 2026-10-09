# Context: Storyline „Eine Frage, ein Weg“ im Schadenkontext

Diese Datei beschreibt die Storyline für die Genie-Demo im Bereich Schaden (Claims).
Sie ist die gemeinsame Grundlage für Beispieldaten, Wissensseiten und den Ablauf am Stand.
Aufbau und Kernbotschaft folgen der Vorlage `Storyline_Market_Stand_Genie_EN.pdf`.

Alle Daten, Namen und Dokumente sind frei erfunden.

## Die Story in einem Satz

Petra stellt Genie eine Frage zu Schäden. Genie holt die Zahlen aus dem **Data Management**
(Tabellen im Databricks Catalog) und die Erklärung aus dem **Knowledge Hub** (Databricks Pages)
und antwortet mit Quellen. Danach zeigen wir, was passiert, wenn im Hintergrund etwas nicht gepflegt ist.

> Kernbotschaft: KI ist nur so gut wie das, was dahinter gepflegt wird.

## Die Personen

| Wer | Rolle |
|---|---|
| Petra | Teamleiterin Schaden bei der fiktiven „Nordlicht Versicherung“. Sie stellt die Frage. |
| Genie | Der KI-Assistent in Databricks. Er beantwortet die Frage. |

## Die Frage

> „Wie hat sich die Bearbeitungsdauer von Leitungswasserschäden in den letzten 12 Monaten entwickelt, und warum?“

Die Frage hat bewusst zwei Teile:

- **„Wie hat sie sich entwickelt?“** braucht Zahlen. Die liefert das Data Management.
- **„Warum?“** braucht eine Erklärung. Die liefert der Knowledge Hub.

Warum dieses Beispiel: Ein Leitungswasserschaden (geplatztes Rohr, nasse Wand) ist für jeden
sofort verständlich, und „Wie lange dauert es, bis ein Schaden erledigt ist?“ ist eine Frage,
die Kunden wie Mitarbeitende kennen.

## Die 4 Schritte

| Schritt | Was passiert | Wer hilft |
|---|---|---|
| 1. Frage | Petra fragt Genie in normaler Sprache. | Genie |
| 2. Zahlen holen | Genie findet die richtige Tabelle, prüft, ob Petra sie sehen darf, und berechnet die Bearbeitungsdauer pro Monat. | Data Management (Databricks Catalog) |
| 3. Erklärung finden | Genie liest die Wissensseiten und findet, was den Verlauf erklärt: eine neue Regulierungsrichtlinie seit März. | Knowledge Hub (Databricks Pages) |
| 4. Antwort | Genie zeigt Zahlen und Erklärung und nennt für beides die Quelle. | beide |

## Die gute Antwort

So soll Genie antworten, wenn alles gepflegt ist:

> Die durchschnittliche Bearbeitungsdauer von Leitungswasserschäden ist in den letzten 12 Monaten
> von rund 18 Tagen auf rund 30 Tage gestiegen. Der Anstieg beginnt im März 2026.
>
> Grund: Seit dem 1. März 2026 gilt eine neue Regulierungsrichtlinie. Bei Leitungswasserschäden
> über 3.000 € muss vor der Auszahlung ein Gutachter den Schaden besichtigen. Das verlängert
> die Bearbeitung dieser Schäden um etwa zwei bis drei Wochen.
>
> Quellen: Tabelle `claims_demo.claims.claims` (Zahlen),
> Seite „Regulierungsrichtlinie Leitungswasser“, Stand 01.03.2026 (Erklärung).

## Data Management: Tabellen im Databricks Catalog

Katalog `claims_demo`, Schema `claims`. Vier Tabellen, bewusst klein gehalten.

### `customers` (Kunden)

| Spalte | Typ | Bedeutung |
|---|---|---|
| `customer_id` | STRING | Kundennummer (Schlüssel) |
| `first_name` | STRING | Vorname (personenbezogen) |
| `last_name` | STRING | Nachname (personenbezogen) |
| `postal_code` | STRING | Postleitzahl |
| `city` | STRING | Ort |

### `policies` (Verträge)

| Spalte | Typ | Bedeutung |
|---|---|---|
| `policy_id` | STRING | Vertragsnummer (Schlüssel) |
| `customer_id` | STRING | Verweis auf `customers` |
| `product` | STRING | Produkt, z. B. „Wohngebäude Komfort“, „Hausrat Plus“ |
| `start_date` | DATE | Vertragsbeginn |
| `end_date` | DATE | Vertragsende, leer bei laufenden Verträgen |

### `claims` (Schäden)

Die zentrale Tabelle für die Frage.

| Spalte | Typ | Bedeutung |
|---|---|---|
| `claim_id` | STRING | Schadennummer (Schlüssel) |
| `policy_id` | STRING | Verweis auf `policies` |
| `damage_type` | STRING | Schadenart: „Leitungswasser“, „Sturm/Hagel“, „Feuer“, „Glasbruch“ |
| `loss_date` | DATE | Schadentag |
| `reported_date` | DATE | Meldedatum |
| `closed_date` | DATE | Abschlussdatum, leer bei offenen Schäden |
| `status` | STRING | „offen“, „abgeschlossen“, „abgelehnt“ |
| `estimated_amount` | DECIMAL(10,2) | Geschätzte Schadenhöhe in Euro |
| `assessor_required` | BOOLEAN | Gutachter nötig (ja/nein) |

### `claim_payments` (Zahlungen)

| Spalte | Typ | Bedeutung |
|---|---|---|
| `payment_id` | STRING | Zahlungsnummer (Schlüssel) |
| `claim_id` | STRING | Verweis auf `claims` |
| `payment_date` | DATE | Auszahlungsdatum |
| `amount` | DECIMAL(10,2) | Ausgezahlter Betrag in Euro |

### Beziehungen

`customers` 1:n `policies` 1:n `claims` 1:n `claim_payments`

### Definition der Kennzahl

**Bearbeitungsdauer** = Anzahl Tage zwischen `reported_date` und `closed_date`.
Es zählen nur abgeschlossene Schäden. Ausgewertet wird der Durchschnitt pro Meldemonat.

Diese Definition steht zusätzlich als Tabellen- und Spaltenkommentar im Catalog und im Glossar
des Knowledge Hub, damit Genie sie findet.

### Zielwerte für die Beispieldaten

Die Beispieldaten für Leitungswasserschäden sollen diesen Verlauf ergeben:

| Meldemonat | Anzahl Schäden | Ø Bearbeitungsdauer (Tage) |
|---|---|---|
| Okt 2025 | 38 | 18 |
| Nov 2025 | 41 | 17 |
| Dez 2025 | 44 | 18 |
| Jan 2026 | 96 | 21 |
| Feb 2026 | 52 | 19 |
| Mär 2026 | 40 | 24 |
| Apr 2026 | 37 | 27 |
| Mai 2026 | 39 | 29 |
| Jun 2026 | 36 | 30 |
| Jul 2026 | 38 | 31 |
| Aug 2026 | 35 | 30 |
| Sep 2026 | 37 | 31 |

Hinweise zu den Daten:

- Ab März 2026 haben Schäden mit `estimated_amount` über 3.000 € `assessor_required = true`
  und dauern rund 38 Tage. Schäden ohne Gutachter dauern weiterhin rund 19 Tage.
- Der Januar 2026 hat wegen einer Frostperiode mehr als doppelt so viele Schäden.
  Das ist eine gute Anschlussfrage („Warum gab es im Januar so viele Schäden?“).
- Die anderen Schadenarten bleiben über das Jahr unauffällig (zusammen etwa 1.000 Schäden).
- Vereinfachung: Im guten Datensatz sind alle Schäden abgeschlossen.
- Der Zeitraum ist auf eine Demo im Oktober 2026 ausgelegt. Bei einem späteren Termin
  die Daten verschieben, damit „die letzten 12 Monate“ weiter passt.

## Knowledge Hub: Seiten in Databricks Pages

Jede Seite hat oben einen kleinen Kopf: **Titel, Stand (Datum), Verantwortliche Person, Gültig ab**.
Genau diese Angaben braucht Genie, um eine Quelle sauber zu nennen.

| Seite | Inhalt | Rolle in der Story |
|---|---|---|
| Regulierungsrichtlinie Leitungswasser | Seit 01.03.2026: Gutachterpflicht bei Schäden über 3.000 €. Vorher lag die Grenze bei 10.000 €. Wartezeit auf einen Gutachtertermin etwa zwei Wochen. | Liefert das „Warum“ |
| Glossar Schaden | Erklärt Begriffe wie Bearbeitungsdauer, Meldedatum, Abschlussdatum, Schadenart. | Sorgt dafür, dass Genie die Kennzahl richtig berechnet |
| Ereignisbericht Frost Januar 2026 | Frostperiode vom 8. bis 19. Januar 2026, viele geplatzte Rohre, vor allem im Norden. | Erklärt die Spitze im Januar (Anschlussfrage) |
| Ablauf Schadenbearbeitung | Die Schritte von der Meldung bis zur Auszahlung in einfachen Worten. | Hintergrund für Besucher |

## Der Höhepunkt: „Was, wenn etwas fehlt?“

Dieselbe Frage wird noch einmal gestellt, aber diesmal ist eine Sache kaputt.
Besucher wählen eine von drei Karten:

| Fehlerfall | Beispiel | Wirkung auf Genies Antwort |
|---|---|---|
| Daten sind schlecht | Bei 15 % der Schäden fehlt das Abschlussdatum, vor allem bei den langen Fällen. | Genie nennt 24 statt 30 Tage. Die Zahl ist falsch, oder Genie warnt vor Lücken. |
| Dokument ist veraltet | Die neue Richtlinie wurde nie abgelegt. Im Knowledge Hub liegt nur die alte Fassung von 2023. | Genie sieht den Anstieg, findet aber keine oder eine falsche Erklärung. |
| Keine Berechtigung | Petra darf die Schadentabelle nicht sehen. | Genie lehnt sauber ab, statt zu raten. |

Besucher sehen sofort, wie die Antwort schlechter wird, und verstehen: Die Qualität kommt nicht
aus der KI selbst, sondern aus den Daten und dem Wissen dahinter.

### Umsetzung der Fehlerfälle

| Fehlerfall | Umsetzung in Databricks |
|---|---|
| Daten sind schlecht | Zweites Schema `claims_demo.claims_poor_quality` mit derselben Tabelle `claims`, aber ohne `closed_date` bei 15 % der Zeilen. |
| Dokument ist veraltet | Zweiter Seitenbereich, in dem nur die alte Richtlinie (Stand 2023, Grenze 10.000 €) liegt. |
| Keine Berechtigung | Zweite Gruppe ohne `SELECT`-Recht auf `claims_demo.claims.claims`. |

## Ablauf am Stand (ca. 5 Minuten)

| Block | Dauer | Inhalt |
|---|---|---|
| Einstieg | 30 Sek. | „Früher hätte Petra drei Tage auf eine Excel-Auswertung gewartet. Heute fragt sie Genie.“ |
| Durchlauf | 2 Min. | Die vier Schritte am Bildschirm, jeweils mit einem kurzen Hinweis, was im Hintergrund passiert. |
| Fehlerfall | 2 Min. | Der Besucher wählt eine Karte und sieht die Wirkung. |
| Mitnehmen | 30 Sek. | „Was kann ich morgen tun?“ Dokumente mit Datum und Verantwortlichem versehen, Datenfehler melden. |

## Was wir brauchen

- Katalog `claims_demo` mit den vier Tabellen und den Beispieldaten
- Vier Seiten im Knowledge Hub (Databricks Pages)
- Einen Genie Space mit der Frage und vier vorbereiteten Antworten
  (gut, schlechte Daten, veraltetes Dokument, keine Berechtigung)
- Drei Fehlerfall-Karten zum Anfassen oder Klicken
- Poster mit den vier Schritten für Laufpublikum

## Für den Deep Dive (nur auf Nachfrage)

- Glossar: Was genau heißt „Bearbeitungsdauer“?
- Catalog und Lineage: Woher kommen die Zahlen?
- Routing: Wann nutzt Genie Tabellen, wann Seiten?
- Prüfung der erzeugten Abfrage und Plausibilitätschecks
- Rollen, Berechtigungen und Zweckbindung bei Schadendaten (z. B. Kundennamen maskieren)
