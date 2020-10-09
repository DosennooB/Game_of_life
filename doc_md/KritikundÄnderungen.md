# Kritik und Änderungen

## Limitationen
Das Prgramm ist in drei großen Punkten limitiert

- **Dimension:** Durch die Nutzung von Buttons als Feld des Zellautomaten ist das Pogramm in der Dimension beschränkt eine ab einer gewissen Zahl an Button stürzt das Grafik Framework ab.

- **Aktualisierung:** Es ist mir kein Weg bekannt gewesen eine Callback Methode in der 
Nutzeroberfläche zu implementieren. Dadurch kann der Server des Zellautomaten keine Aktualisierung
der Nutzeroberfläche anstoßen.

- **Anpassbarkeit** Das Programm ist nur auf eine Fenstergröße ausgerichtet. Diese kann nicht verändert werden.

## Kritik
Ein Programm zu erstellen mit einem Framwork das man erst wärend des versteht, birgt einige 
Risiken. Vorallem wenn Limitationen erst nach und nach bekannt werden.

## Änderungen
Für eine Zükünftige weitere Entwicklung des Pogramms währen folgende Dinge möglich.

- **Button ersetzen:** Um mehr Zellen in der Benutzeroberflächen anzeigen zu können. Müssen die Button durch z.B. Rechtecke (Rect) ersetzt werden. Diese können in höheren Stückzahlen erscheinen.

- **Aktualisierung:** Eine Möglichkeit finden die einen Oberflächenaktualisierung in Intervallen ermöglicht.

- **Testerweiterung:** Die Tests in der Aktuellen Version decken nur einen kleinen Teil des Pogramms ab.
Diese sollten in Zukunft ausgebaut werden.

- **Fensteränderung:** Zukünftick sollte man in der ersten Ansicht die Möglichkeit haben die Größe des Fensters ein zustellen oder zu mindest einen Skalierungsfaktor zu nutzen. 