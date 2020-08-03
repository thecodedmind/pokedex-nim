import httpclient, strutils, json, tables, os
export json, tables

const AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0"
const BASEURL = "https://pokeapi.co/api/v2/"

type
    Species* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Move* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Game* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Ability* = object
        name*: string
        hidden*: bool
        id*: int
        json*: JsonNode

    Location* = object
        name*: string
        id*: int
        json*: JsonNode
        
    Berry* = object
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
        name*: string
        id*, height*: int
        species*: Species
        types*: seq[Type]
        abilities*: seq[Ability]
        sprites*: Table[string, string]
        json*: JsonNode

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
  
proc api*(endpoint, value: string): JsonNode =
    if existsCache(endpoint, value):
        return getCache(endpoint, value)
    else:
        result = newHttpClient().getContent(BASEURL&endpoint&"/"&value).parseJson()
        putCache(endpoint, value, result)

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
        
proc getPokemon*(name:string):Pokemon =
    result.json = api("pokemon", name)
    result.name = result.json["name"].getStr
    result.id = result.json["id"].getInt
    result.height = result.json["height"].getInt

    for t in result.json["types"]:
        result.types.add getType(t["type"]["name"].getStr)
        
