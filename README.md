# pokedex-nim
A CLI Pokemon Pokedex app, and companion library written in Nim, with full caching.<br>
Cache default directory is $HOME/.cache/pokedex
I don't know how that works on Windows, I only have Linux to work with, but you can define a custom cache directory with POKEDEX_CACHE_DIR environment variable.
Compiling only needs standard library, and my library files from [here](https://github.com/Kaiz0r/nim-libs).

# pokedex.nim
Source file for the commandline application.<br>
Basic functionality for now, will be expanded later.<br>
Directly calls functions from the pokenim.nim library and parses them in to human-readable formats.

$ pokedex pokemon <name/id>
Shows a pokemon basic details.

$ pokedex type <name/id>
Shows a type and its damage relations. 

$ pokedex move <name/id>
Shows a moves details.

$ pokedex ability <name/id>
Shows an abilities details.

$ pokedex <pokemon name>
If no sub-command given, defaults to showing detailed information about pokemon

More functionality eventually.

# pokeapi.nim
Contains functions for calling directly to the API, returning json objects, and parsed Objects for convenience.

```nim
proc pokedexCacheDir*()
# shows the directory the application is currently using to store the cached json files (and sprites, when i get around to that)

proc api*(endpoint, value: string): JsonNode
# Direct library interface to the API server. Handles caching automatically.
# If cache directory doesn't exist, creates it.
# If the object exists in the cache, returns that json
# Else calls the API server, saves the response to cache (if response is found), then returns that.

proc getSpecies*(name:string):Species

proc getSpecies*(pkmn:Pokemon):Species

proc getType*(name:string): Type
# Returns a formatted Type object
# Only contains name, id and damage relations for now, more coming soon, along with convenience and wrapper functions.

proc getTypes*(pkmn:Pokemon): seq[Type]

proc getAbility*(name:string): Ability
proc getMove*(name:string): Move

proc getPokemon*(name:string):Pokemon
# Returns a formatted Pokemon object
# Only contains basic details more coming soon, along with convenience and wrapper functions.
```

# Todo
- [ ] functions to quickly check if pokemon type effectiveness against eachother
- [ ] everything to do with moves, wether a pokemon can learn them, what levels, type effectiveness etc.
- [ ] locations for where to catch pokemon
- [ ] many other things, to expand later
