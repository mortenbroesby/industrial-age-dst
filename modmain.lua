-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Assets and Prefabs: 

PrefabFiles = {
    "energy_cell",
    "generator",
    "heat_lamp",
    "range_checker",
}

Assets = {
	Asset("ATLAS", "images/inventoryimages/energy_cell/energy_cell.xml"),
	Asset("ATLAS", "images/inventoryimages/generator/generator.xml"),
	Asset("ATLAS", "images/inventoryimages/heat_lamp/heat_lamp.xml"),
	Asset("IMAGE", "energy_cell.tex"),
	Asset("ATLAS", "energy_cell.xml"),
}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Rebound Global Scopes:

STRINGS = GLOBAL.STRINGS
RECIPETABS = GLOBAL.RECIPETABS
Recipe = GLOBAL.Recipe
Ingredient = GLOBAL.Ingredient
TECH = GLOBAL.TECH

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

RECIPETABS['Industrial']  = {str = "Industrial", sort=999, icon = "energy_cell.tex", icon_atlas = "energy_cell.xml"}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.GENERATOR = "Generator"
STRINGS.RECIPE_DESC.GENERATOR = "Generates electricity."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR = {	
	"Let's fill this thing with fuel!", 
	"More fuel, less talking.", 
}

STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR.EMBERS = "I should really add some fuel."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR.LOW = "This is barely generating anything."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR.NORMAL = "Now we're talking electricity!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR.HIGH = "This thing is running on overdrive!"

local generator = Recipe("generator", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "generator_placer")
generator.atlas = "images/inventoryimages/generator/generator.xml"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.ENERGY_CELL = "Energy Cell"
STRINGS.RECIPE_DESC.ENERGY_CELL = "Stores electricity."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL = {	
	"Interesting. It stores electricity.", 
	"Electro-rific!", 
}

STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL.EMPTY = "This cell is empty."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL.LOW = "There's almost no charge in this cell."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL.MEDIUM = "This cell contains an acceptable charge."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL.HIGH = "There's almost a full charge in this cell."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL.FULL = "This energy cell is full."

local energy_cell = Recipe("energy_cell", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "energy_cell_placer")
energy_cell.atlas = "images/inventoryimages/energy_cell/energy_cell.xml"
--local energy_cell = GLOBAL.Recipe("energy_cell",{ Ingredient("goldnugget", 1), Ingredient("gears", 1), Ingredient("lightbulb", 1) },

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.HEAT_LAMP = "Heat Lamp"
STRINGS.RECIPE_DESC.HEAT_LAMP = "Creates light and heat."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEAT_LAMP = {	
	"Edison would be proud.", 
	"Light AND heat? How nice.",
}

STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEAT_LAMP.ACTIVE = "Light AND heat? How nice."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEAT_LAMP.PASSIVE = "This thing is turned off."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEAT_LAMP.DISABLED = "I should recharge a nearby energy cell."

local heat_lamp = Recipe("heat_lamp", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "heat_lamp_placer")
heat_lamp.atlas = "images/inventoryimages/heat_lamp/heat_lamp.xml"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Tuning values: 

TUNING.CELL_ENERGY_MAX = 21
TUNING.CELL_DEPLETION_MULTIPLIER = 33
TUNING.GENERATOR_EFFICIENCY_BASE_VALUE = 5
TUNING.GENERATOR_FUEL_MAX = 270 -- 270 = value of firepit
TUNING.GENERATOR_FUEL_RATE = 1
TUNING.GENERATOR_RANGE = 225
TUNING.HEAT_LAMP_RANGE = 225

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- DEBUGGING PARAMETERS:

GLOBAL.CHEATS_ENABLED = true
GLOBAL.require( 'debugkeys' )
