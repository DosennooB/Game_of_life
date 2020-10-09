# Anforderungen und Überlegungen

## Anforderungen

Für mich gab es zu diesem Projekt ein Paar Anforderungen
die ich mir im Vorhinein aufgeschrieben hatte.

* 1.) Das Programm soll eine grafische Nutzeroberfläche haben in der der Zellautomat dagestell wird. 
* 2.) Der Zellautomat muss mit Verschiedenen Dimensionen initialisiert werden können.
* 3.) Ein Feld im Zellautomaten kann durch anklicken ihren Zustand wechseln.
* 4.) Der Nutzer soll die Möglichkeit haben durch eine Eingabe den nächsten Zustand berechnen zu lassen.
* 5.) Der Nutzer soll die Möglichkeit haben durch eine Eingabe die nächsten Zustände in einem Intervall berechnen zu lassen.

Anforderung 5.) werde ich nicht ohne große Änderungen am Code umsetzte können.

## Auswahl der Programmiersprache

Die Wahl der Programmiersprache ist in diesem Fall aus persönlichen Gründen gefallen.
Ich habe vor kurzem angefangen mit Elixir zu beschäfftigen und habe gedacht das dies eine
weitere gute Übung für mich in dieser Sprache sein kann. Allerdings habe ich zuvor nicht mit 
Oberflächen in dieser Sprache gearbeitet. Die Wahl des Grafik Frameworks fiel auf Scenic.
Dies schien mir als die beste Lösung um es in der kurzen Zeit soweit zu verstehen, dass ich das
Projekt damit umsetzten könnte. Allerdings bin ich bei der Ausarbeitung auf Limitationen gestoßen.

## Struktur des Programms

Das Programm besteht im weitesten Sinne aus einer Client Server Architektur.
Der Client hier die Nutzeroberfläche reagiert auf Nutzereingaben und schick diese als Elixir Massage
an den Server weiter der diese Beantwortet.

### Besonderheiten der Nutzeroberfläche

Das Feld des Zellautomaten in der Nutzteroberfläche ist mit Buttons realisiert.
Jeder dieser Button hat als Id ein Struct vom Typ Zelle. Dieses wird auch im Server zur adressierung
genutz. Es ist also keine spezielle zu Ordnung nötig.

### Besonderheiten des Servers 

Der Server ist ein seperater Prozess. Enthält nur die Logik. Die Datenspeicherung übernehmen weitere Prozesse. Die sogenanten Agents. Da die Elixir standart Bibliotehk keine Arrays an bietet, habe ich beschlossen die Werte als Key Value Paare zu speichern wobei der Key das Struct vom Typ Zelle ist.
Um Speicher zu sparen werden nach möglichkeit nur Zellen mit dem Value 1 (also Lebende) gespeichert.
Um Rechenleistung zu sparen werden für den nächsten Zustand nur die Lebenden Zellen und deren Nachtbarn 
berechnet. 