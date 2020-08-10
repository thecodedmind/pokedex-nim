import httpclient, strutils, json, tables, os
export json, tables

const AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0"
const BASEURL = "https://pokeapi.co/api/v2/"

type
    Species* = object
        name*, shape*, colour*, color*: string
        id*, captureRate*, baseHappiness*: int
        baby*: bool
        text*: seq[Table[string, string]]
        json*: JsonNode
        evolvesTo*: seq[Table[string, string]]
        evolvesFrom*: string
        
    Move* = object
        name*, moveType*, damageClass*: string
        id*, accuracy*, power*, pp*, priority*, effectChance*: int
        text*, effects*: seq[Table[string, string]]
        json*: JsonNode
        
    Game* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Ability* = object
        name*: string
        hidden*: bool
        id*: int
        text*, effects*: seq[Table[string, string]]
        json*: JsonNode

    Generation* = object
        name*: string
        id*: int
        json*: JsonNode

    Region* = object
        name*, gen*: string
        id*: int
        games*, locations*: seq[string]
        json*: JsonNode

    Encounter* = object
        name*, version*, encmethod*: string
        chance*, maxchance*, maxlvl*, minlvl*: int
        conditions*: seq[string]
            
    LocationArea* = object
        name*, location*: string
        id*: int
        encounters*: seq[Encounter]
        json*: JsonNode
        
    Location* = object
        name*, region*: string
        id*: int
        gen*, areas*: seq[string]
        json*: JsonNode

    
    Berry* = object
        name*: string
        id*: int
        json*: JsonNode

    Item* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Type* = object
        name*: string
        id*: int
        json*: JsonNode
        noDamageTo*: seq[string]
        noDamageFrom*: seq[string]
        halfDamageTo*: seq[string]
        halfDamageFrom*: seq[string]
        doubleDamageTo*: seq[string]
        doubleDamageFrom*: seq[string]
        
    Pokemon* = object
        name*, species*: string
        id*, height*: int
        types*: seq[Type]
        abilities*: seq[Ability]
        sprites*: Table[string, string]
        json*: JsonNode
        
proc isNum(s:string): bool =
    try:
        discard s.parseInt()
        return true
    except:
        return false

proc pokedexCacheDir*(): string =
    if getEnv("POKEDEX_CACHE_DIR", "") != "":
        return getEnv("POKEDEX_CACHE_DIR")
    else:
        if not dirExists(getHomeDir()&"/.cache/pokedex/"):
            createDir getHomeDir()&"/.cache/pokedex/"
            
        return getHomeDir()&"/.cache/pokedex/"

proc putCache(group, key:string, data:JsonNode) =
    if not dirExists(pokedexCacheDir()&"/"&group&"/"):
        createDir pokedexCacheDir()&"/"&group&"/"   
    writeFile(pokedexCacheDir()&"/"&group&"/"&key&".json", data.pretty())

proc getCache(group, key:string): JsonNode =
    if not fileExists(pokedexCacheDir()&"/"&group&"/"&key&".json"):
        return %*{}
                 
    return parseFile(pokedexCacheDir()&"/"&group&"/"&key&".json")
    
proc existsCache(group, key:string): bool =
    if not fileExists(pokedexCacheDir()&"/"&group&"/"&key&".json"):
        return false
                 
    return true

proc getObjectIndex(endpoint:string): Table[int, string] =
    if fileExists(pokedexCacheDir()&"index_"&endpoint&".pkmn"):
        let ln = readFile(pokedexCacheDir()&"index_"&endpoint&".pkmn").split("\n")
        for line in ln:
            if ":" in line:
                result[line.split(":")[0].parseInt] = line.split(":")[1]
        
proc putObjectIndex(d:Table[int, string], endpoint:string) =
    var body = ""
    for k, v in d.pairs:
        body.add k.intToStr&":"&v&"\n"
    writeFile(pokedexCacheDir()&"index_"&endpoint&".pkmn", body)
            
proc api*(endpoint, value: string): JsonNode =
    var name = value
    var updateIndex = false
    
    if name.isNum and endpoint != "evolution-chain":
        let index = getObjectIndex(endpoint)
        echo index
        if index.hasKey(name.parseInt):
            name = index[name.parseInt]
        else:
            updateIndex = true

    if existsCache(endpoint, name):
        return getCache(endpoint, name)
    else:
        result = newHttpClient(AGENT).getContent(BASEURL&endpoint&"/"&name).parseJson()

        putCache(endpoint, name, result)
        
    if updateIndex:
        var index = getObjectIndex(endpoint)
        index[name.parseInt] = result["name"].getStr
        index.putObjectIndex(endpoint)

proc getLocationArea*(name:string):LocationArea =
    result.json = api("location-area", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.location = result.json["location"]["name"].getstr
    
    for enc in result.json["pokemon_encounters"]:
        for d in enc["version_details"]:
            for m in d["encounter_details"]:
                var e = Encounter(name: enc["pokemon"]["name"].getStr, encmethod: m["method"]["name"].getStr)
                e.version = d["version"]["name"].getStr
                e.maxchance = d["max_chance"].getInt
                e.chance = m["chance"].getInt
                e.maxlvl = m["max_level"].getInt
                e.minlvl = m["min_level"].getInt
                for cond in m["condition_values"]:
                    e.conditions.add cond["name"].getStr
                result.encounters.add e
                
proc getLocation*(name:string):Location =
    result.json = api("location", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.region = result.json["region"]["name"].getstr
    for area in result.json["areas"]:
        result.areas.add area["name"].getStr
    for game in result.json["game_indices"]:
        result.gen.add game["generation"]["name"].getStr
        
proc getSpecies*(name:string):Species =
    result.json = api("pokemon-species", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.colour = result.json["color"]["name"].getStr
    result.color = result.json["color"]["name"].getStr

    let evo = api("evolution-chain", result.json["evolution_chain"]["url"].getStr().split("evolution-chain/")[1].replace("/", ""))

    #var t = {}.toTable
    
    for e in evo["chain"]["evolves_to"]:        
        if e["evolution_details"].getElems.len > 0:
            for details in e["evolution_details"]:
                var t = {"name": e["species"]["name"].getStr, "baby": $e["is_baby"].getBool}.toTable
                if details["min_level"].kind != JNull:
                    t["level"] = details["min_level"].getStr

                if details["item"].kind != JNull:
                    t["item"] = details["item"]["name"].getStr

                if details["min_happiness"].kind != JNull:
                    t["happiness"] = details["min_happiness"].getInt.intToStr
                    
                if details["min_affection"].kind != JNull:
                    t["affection"] = details["min_affection"].getInt.intToStr
    
                if details["time_of_day"].getStr != "":
                    t["time"] = details["time_of_day"].getStr

                if details["location"].kind != JNull:
                    t["location"] = details["location"]["name"].getStr
                    
                if details["known_move_type"].kind != JNull:
                    t["known_move_type"] = details["known_move_type"]["name"].getStr

                t["trigger"] = details["trigger"]["name"].getStr

                result.evolvesTo.add t

    if result.json["evolves_from_species"].kind != JNull:
        result.evolvesFrom = result.json["evolves_from_species"]["name"].getStr
    
    for text in result.json["flavor_text_entries"]:
        result.text.add {"body": text["flavor_text"].getStr,
                          "lang": text["language"]["name"].getStr,
                          "version": text["version"]["name"].getStr}.toTable
        
proc getSpecies*(pkmn:Pokemon):Species =
    return getSpecies(pkmn.species)
    
proc getType*(name:string): Type =
    result.json = api("type", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    
    for t in result.json["damage_relations"]["double_damage_from"]:
        result.doubleDamageFrom.add t["name"].getStr
        
    for t in result.json["damage_relations"]["double_damage_to"]:
        result.doubleDamageTo.add t["name"].getStr
        
    for t in result.json["damage_relations"]["half_damage_to"]:
        result.halfDamageTo.add t["name"].getStr
        
    for t in result.json["damage_relations"]["half_damage_from"]:
        result.halfDamageFrom.add t["name"].getStr
        
    for t in result.json["damage_relations"]["no_damage_from"]:
        result.noDamageFrom.add t["name"].getStr
        
    for t in result.json["damage_relations"]["no_damage_to"]:
        result.noDamageTo.add t["name"].getStr

proc getTypes*(pkmn:Pokemon): seq[Type] =
    for t in pkmn.types:
        result.add getType(t.name)

proc getAbility*(name:string): Ability =
    result.json = api("ability", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    
    for text in result.json["flavor_text_entries"]:
        result.text.add {"body": text["flavor_text"].getStr,
                          "lang": text["language"]["name"].getStr,
                          "version": text["version_group"]["name"].getStr}.toTable
        
    for text in result.json["effect_entries"]:
        result.effects.add {"body": text["effect"].getStr,
                          "lang": text["language"]["name"].getStr,
                          "short": text["short_effect"].getStr}.toTable
        
proc getMove*(name:string): Move =
    result.json = api("move", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.moveType = result.json["type"]["name"].getStr
    result.damageclass = result.json["damage_class"]["name"].getStr
    result.effectChance = result.json["effect_chance"].getInt
    result.accuracy = result.json["accuracy"].getInt
    result.power = result.json["power"].getInt
    result.pp = result.json["pp"].getInt
    for text in result.json["flavor_text_entries"]:
        result.text.add {"body": text["flavor_text"].getStr,
                          "lang": text["language"]["name"].getStr,
                          "version": text["version_group"]["name"].getStr}.toTable
        
    for text in result.json["effect_entries"]:
        result.effects.add {"body": text["effect"].getStr,
                          "lang": text["language"]["name"].getStr,
                          "short": text["short_effect"].getStr}.toTable
        
proc getPokemon*(n:string):Pokemon =    
    result.json = api("pokemon", n)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.height = result.json["height"].getInt
    result.species = result.json["species"]["name"].getStr
    for t in result.json["types"]:
        result.types.add getType(t["type"]["name"].getStr)

    var a:Ability
    
    for t in result.json["abilities"]:
        a = getAbility(t["ability"]["name"].getStr)
        a.hidden = t["is_hidden"].getBool
        result.abilities.add a
