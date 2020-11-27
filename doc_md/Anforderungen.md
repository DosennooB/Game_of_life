# Anforderungen und Überlegungen

## Anforderungen

Für mich gab es zu diesem Projekt ein paar Anforderungen,
die ich mir im Vorhinein aufgeschrieben hatte.

* 1.) Das Programm soll eine grafische Nutzeroberfläche haben, in der der Zellautomat dargestellt wird. 
* 2.) Der Zellautomat muss mit verschiedenen Dimensionen initialisiert werden können.
* 3.) Ein Feld im Zellautomaten kann durch anklicken ihren Zustand wechseln.
* 4.) Der Nutzer soll die Möglichkeit haben durch eine Eingabe den nächsten Zustand berechnen zu lassen.
* 5.) Der Nutzer soll die Möglichkeit haben durch eine Eingabe die nächsten Zustände in einem Intervall berechnen zu lassen.


## Auswahl der Programmiersprache

Die Wahl der Programmiersprache ist in diesem Fall aus persönlichen Gründen gefallen.
Ich habe vor kurzem angefangen mit Elixir zu beschäftigen und habe gedacht das dies eine
weitere gute Übung für mich in dieser Sprache sein kann. Allerdings habe ich zuvor nicht mit 
Oberflächen in dieser Sprache gearbeitet. Die Wahl des Grafik Frameworks fiel auf Scenic.
Dies schien mir als die beste Lösung um es in der kurzen Zeit so weit zu verstehen, dass ich das
Projekt damit umsetzten könnte. Allerdings bin ich bei der Ausarbeitung auf Limitationen gestoßen.

## Struktur des Programms

Das Programm ist in drei Schichten aufgebaut.
Frontend, Logik und Datenhaltung. Jeder dieser Schichten ist in einzelnen Prozessen ausgefürt.
Die Prozesse werden vom Supervisor überwacht und neu gestartet sobalt einer aufgrund eines Fehlers abstürtzen sollte.

Das Programm besteht im weitesten Sinne aus Frontend und Backend.
Das Frontend hier die Nutzeroberfläche reagiert auf Nutzereingaben und schick diese als Elixir Massage
an die Logik. Der Zellautomat ist in diesem Fall die Logik verarbeitet Massages und berechnet den neuen Zustand. Die nötigen Informationen und der Zustand des Zellautomaten werden in der Datenhaltung gespeichert. Das Frontend hat eine dedizierte callback Methode, die aufgerufen wird wenn der Zellautomat einen neuen Zustand errechnet hat. Dieser aktualisiert die Oberfläche auf der der Zustand des Zellautomaten angezeigt wird.

### Besonderheiten der Nutzeroberfläche

Das Feld des Zellautomaten in der Nutzeroberfläche ist über Primitive Rechtecke realisiert.
Nach dem clicken in das Feld wird ein Struct der Zelle angefertigt, auf die geclickt wurde. Dieses wird auch im Server zur Adressierung genutzt. 

### Besonderheiten der Logik

Die Logik ist ein separater Prozess. Die Datenspeicherung übernehmen weitere Prozesse. Die sogenannten Agents. Da die Elixir Standard Bibliothek keine Arrays anbietet, habe ich beschlossen die Werte als Key Value Paare zu speichern, wobei der Key das Struct vom Typ Zelle ist.
Um Speicher zu sparen werden nach Möglichkeit nur Zellen mit dem Value 1 (also lebende) gespeichert.
Um Rechenleistung zu sparen werden für den nächsten Zustand nur die lebenden Zellen und deren Nachbarn 
berechnet. 