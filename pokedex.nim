import pokeapi, lib/strplus, lib/opthandler, strutils

proc main() =
    var
        b = newOptHandler()
    #b.link("json", "j")
    
    let
        exportJson = b.flag("json").boolify or b.flag("j").boolify
        lang = b.flag("lang", "en")
        
    case b.command("help"):
        of "help":
            echo "$ pokemon <name/id> - basic info"
            echo "$ move <name/id> - move details"
            echo "$ ability <name/id> - ability details"
            echo "$ species <name/id> - species details"
            echo "$ type <name/id> - type details and effectiveness"
            echo "$ <pokemon name/id> - various detailed information"
            
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

        of "move":
            echo ""
            let mv = getMove(b.command(1))
            echo mv.name&" ["&mv.damageClass&"/"&mv.moveType&"]"
            echo "Accuracy: "&mv.accuracy.intToStr&"%"
            echo "Power: "&mv.power.intToStr
            echo "PP: "&mv.pp.intToStr
            
            for ty in mv.effects:
                if ty["lang"] == lang:
                    echo ty["body"].replace("$effect_chance", mv.effectChance.intToStr)
            echo ""
            for ty in mv.text:
                if ty["lang"] == lang:
                    if b.flag("dv") != "":
                        if b.flag("dv") in ty["version"]:
                            echo ty["body"]
                            echo " - "&ty["lang"]&" "&ty["version"]
                            echo ""
                            break
                    else:
                        echo ty["body"]
                        echo " - "&ty["lang"]&" "&ty["version"]
                        echo ""
                        break

        of "area":
            echo ""
            let ar = getLocationArea(b.command(1))
            echo "#"&ar.id.intToStr&": "&ar.name
            echo "An area inside "&ar.location
            echo "\nEncounters:"
            for enc in ar.encounters:
                var doit = false
                if b.flag("name") != "":
                    if b.flag("name") == enc.name:
                        doit = true
                       
                if b.flag("version") != "":
                    if b.flag("version") == enc.version:
                        doit = true
                    
                if b.flag("name") == "" and b.flag("version") == "":
                    doit = true
                    
                if doit:
                    var t = "["&enc.version&"] "&enc.name
                    t.add " | Method: "&enc.encmethod
                    t.add " | Odds: "&enc.chance.intToStr&"%-"&enc.maxchance.intToStr&"%"
                    t.add " | Level Range: "&enc.minlvl.intToStr&"-"&enc.maxlvl.intToStr
                    if enc.conditions.len > 0:
                        t.add " | Conditions: "&enc.conditions.join("; ")
                    echo t 
            echo ""
                
        of "location":
            echo ""
            let lo = getLocation(b.command(1))
            echo "#"&lo.id.intToStr&": "&lo.name&" in the "&lo.region&" region ["&lo.gen.join(";")&"]"
            echo "Areas: \n"&lo.areas.join("\n")
            
        of "ability":
            echo ""
            let ab = getAbility(b.command(1))
            echo "#"&ab.id.intToStr&": "&ab.name
            for a in ab.effects:
                if a["lang"] == lang:
                    echo a["body"].replace("\n", " ")
                    echo ""
                    break
                    
        of "species":
            echo ""
            let sp = getSpecies(b.command(1))

            if exportJson:
                echo sp.json.pretty()
            else:   
                echo "#"&sp.id.intToStr&": "&sp.name
                echo sp.colour

                if sp.evolvesFrom != "":
                    echo "Evolves from "&sp.evolvesFrom&"\n"
                    
                for ev in sp.evolvesTo:
                    echo ev["name"]
                    if ev.hasKey("level"):
                        echo " at level "&ev["level"]&"\n"
                echo ""
                
                for ty in sp.text:
                    if ty["lang"] == lang:
                        if b.flag("version") != "":
                            if b.flag("version") in ty["version"]:
                                echo ty["body"]
                                echo " - "&ty["lang"]&" "&ty["version"]
                                echo ""
                        else:
                            echo ty["body"]
                            echo " - "&ty["lang"]&" "&ty["version"]
                            echo ""
                
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
            if b.commands.len == 0:
                echo "No command given."
                return
                
            let pkm = getPokemon(b.command(0))
            let sp = pkm.getSpecies()
            let types = pkm.types
            echo ""
            echo "#"&pkm.id.intToStr&": "&pkm.name
            echo sp.colour
            echo ""

            if sp.evolvesFrom != "":
                echo "Evolves from "&sp.evolvesFrom&"\n"
                
            var t:string
            
            for ev in sp.evolvesTo:
                if ev["baby"] != "true":
                    t = "Evolves to "&ev["name"]
                    if ev.hasKey("level"):
                        t.add " at LVL "&ev["level"]

                    if ev.hasKey("item"):
                        t.add " using item "&ev["item"]

                    if ev.hasKey("happiness"):
                        t.add " at happiness "&ev["happiness"]

                    if ev.hasKey("effection"):
                        t.add " at effection "&ev["effection"]
                        
                    if ev.hasKey("known_move_type"):
                        t.add " while knowing a move of type "&ev["known_move_type"]
                        
                    if ev.hasKey("time"):
                        t.add " during "&ev["time"]    

                    if ev.hasKey("location"):
                        t.add " in location "&ev["location"]
                        
                    t.add " (TRIGGER: "&ev["trigger"]&")"
                    echo t
                        
                    
            echo ""
                
            for ty in sp.text:
                if ty["lang"] == lang:
                    if b.flag("dv") != "":
                        if ty["version"] == b.flag("dv"):
                            echo ty["body"].replace("\n", " ")
                            echo " - "&ty["lang"]&" "&ty["version"]
                            echo ""
                            break
                    else:
                        echo ty["body"].replace("\n", " ")
                        echo " - "&ty["lang"]&" "&ty["version"]
                        echo ""
                        break

            echo "Abilities:"
            for ab in pkm.abilities:
                echo ab.name
                for a in ab.effects:
                    if a["lang"] == lang:
                        echo a["body"].replace("\n", " ")
                        echo ""
                        break
            echo ""        
            for pkmt in types:
                echo "Type: "&pkmt.name
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
                echo ""
                                                                        

main()
