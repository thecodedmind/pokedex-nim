import pokeapi, lib/strplus, lib/opthandler, strutils

proc main() =
    var
        b = newOptHandler()
    #b.link("json", "j")
    
    let exportJson = b.flag("json").boolify or b.flag("j").boolify
    case b.command("help"):
        of "help":
            echo "TODO"
            
        of "pokemon":
            let pkm = getPokemon(b.command(1))

            if exportJson:
                echo pkm.json.pretty()
            else:   
                echo "#"&pkm.id.intToStr&": "&pkm.name
                var t = "Types: "
                for ty in pkm.types:
                    t.add ty.name&" "
                echo t

        of "type":
            let pkmt = getType(b.command(1))
            if exportJson:
                echo pkmt.json.pretty()
            else:
                echo "#"&pkmt.id.intToStr&": "&pkmt.name

                if pkmt.doubleDamageTo.len > 0:
                    echo "Deals Super Effective damage against "&pkmt.doubleDamageTo.join(", ")
                if pkmt.halfDamageTo.len > 0:
                    echo "Deals half damage against "&pkmt.halfDamageTo.join(", ")
                if pkmt.noDamageTo.len > 0:
                    echo "Deals no damage against "&pkmt.noDamageTo.join(", ")
                if pkmt.doubleDamageFrom.len > 0:
                    echo "Takes Super Effective damage from "&pkmt.doubleDamageFrom.join(", ")
                if pkmt.halfDamageFrom.len > 0:
                    echo "Takes half damage from "&pkmt.halfDamageFrom.join(", ")
                if pkmt.noDamageFrom.len > 0:
                    echo "Takes no damage from "&pkmt.noDamageFrom.join(", ")


                
        else:
            echo "Command unrecognized."
main()
