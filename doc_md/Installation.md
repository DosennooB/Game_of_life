# Installation

Um dieses Programm kompilieren und ausführen zu können, 
sind ein paar Besonderheiten zu beachten.

-**Betriebssystem:** Aufgrund des Frameworks wird entweder 
eine Linux oder MacOS Distribution vorausgesetzt. Alternativ ist es 
möglich das Programm in Windows und WSL zu starten.

-**Erlang und Elixir:** Für das Ausführen des Programms ist eine Installation der Erlang- VM
und von Elixir nötig.

-**Bibliotheken:** Scenic setzt GLFW und GLEW Bibliotheken voraus.
Installationsanleitungen finden Sie [hier](https://hexdocs.pm/scenic/install_dependencies.html).
## Für Ubuntu 20
```bash
sudo apt-get update
sudo apt-get install pkgconf libglfw3 libglfw3-dev libglew2.1 libglew-dev
```
## Für WSL unter Windows 10
Zum Nutzen von Scenic unter WSL folgen Sie dieser [Anleitung](https://medium.com/@jeffborch/running-the-scenic-elixir-gui-framework-on-windows-10-using-wsl-f9c01fd276f6).

-**Vor dem Kompilieren:** Nach dem clonen des Git-Repositorys werden mit dem Befehle 
```bash
mix do deps.get
```
die restlichen Abhängigkeiten heruntergeladen.

Mit 
```bash
mix scenic.run
```
wird das Programm gestartet.