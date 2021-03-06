# Kritik und Änderungen

## Limitationen
Das Programm ist in drei großen Punkten limitiert

- **Dimension:** Durch die Nutzung von Buttons im Feld des Zellautomaten, ist das Programm in der Dimension beschränkt. Ab einer gewissen Zahl an Button stürzt das Grafik Framework ab.

- Note: in v0.3.0 werde Primitive Rechtecke statt Buttons genutzt so ist es jetzt möglich eine größere Dimension zu nutzen.

- Note: in v0.3.1 wurde es noch effizenter umgesetzt.

- **Aktualisierung:** Es ist mir kein Weg bekannt gewesen eine Callback Methode in der 
Nutzeroberfläche zu implementieren. Dadurch kann der Server des Zellautomaten keine Aktualisierung
der Nutzeroberfläche anstoßen.

- Note: in v0.2.5 kann der Zellautomat auch die Nutzeroberfläche aktualisieren.

- **Anpassbarkeit** Das Programm ist nur auf eine Fenstergröße ausgerichtet. Diese kann nicht verändert werden.

## Kritik
Ein Programm zu erstellen mit einem Framwork, das man erst während des versteht, birgt einige 
Risiken. Vor allem, wenn Limitationen erst nach und nach bekannt werden.

## Änderungen
Für eine Zukünftige weitere Entwicklung des Programms währen folgende Dinge möglich.

- **Button ersetzen:** Um mehr Zellen in der Benutzeroberflächen anzeigen zu können. Müssen die Button durch z.B. Rechtecke (Rect) ersetzt werden. Diese können in höheren Stückzahlen erscheinen. (In v0.3.0 umgesetzt)

- **Aktualisierung:** Eine Möglichkeit finden die einen Oberflächenaktualisierung in Intervallen ermöglicht. (In v0.2.5 behoben)

- **Testerweiterung:** Die Tests in der aktuellen Version decken nur einen kleinen Teil des Programms ab.
Diese sollten in Zukunft ausgebaut werden.

- **Fensteränderung:** Zukünftig sollte man in der ersten Ansicht die Möglichkeit haben die Größe des Fensters einzustellen oder zumindest einen Skalierungsfaktor zu nutzen. 

- **Dynamisches ändern von Parametern:** Es sollen zur Laufzeit die Dimesionen wie auch Parameter wie 
Aktualisierungsrate und Torisch verändert werden können.

- **Platzieren von Gleitern:** Es soll ein Dropdown Menü geben in dem man aus verschiedenen Gleitern
auswählen kann. Diese können mit einem click auf dem Feld platziert werden.  

- **Ändern der Weltregeln:** Es soll möglich sein zur Laufzeit die Regeln Welt zu ändern.