#!/usr/bin/env -S nim --hints:off

mode = ScriptMode.Silent

echo "Pokedex Shell Script 1.1"
echo "Enter commands here. [q/quit/empty to end]"

while true:
    echo "Input:"
    let cmd = readLineFromStdin()
    if cmd == "" or cmd == "q" or cmd == "quit":
        break
    
    try:
        exec "./pokedex "&cmd
        exec "END"
    except:
        echo "error"
