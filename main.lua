-- name: (WIP) kirby moveset 
-- description: Kirby moveset by wereyoshi
-- category: moveset,cs

gPlayerSyncTable[0].kirby = false --this variable is for if you are kirby or not
--gPlayerSyncTable[0].kirbypower = kirbyability_none  --this variable stores kirby's current ability if he has no power it will be equal to kirbyability_none
gGlobalSyncTable.loseability = false --whether kirby should lose his ability on hit
gPlayerSyncTable[0].gaincoin = 0 --coins to add to the coin counter for a player
gPlayerSyncTable[0].kirbyjumps = 0 -- number of midair jumps remaining
local maxkirbyjumps = 5 --the max amount of kirby midair jumps before hitting the ground
gPlayerSyncTable[0].canexhale = false  -- whether kirby can use his exhale move in the air 
gPlayerSyncTable[0].canfloat = false  -- whether kirby can float in the air 
gPlayerSyncTable[0].losingability = false  -- whether kirby is in the middle of losing his ability 
local kirbymaxfloattime = 150 --the max amount of time kirby can float before touching the ground
local kirbyfloattime = 0 --amount of kirby float time remaining
local kirbyhasvanish = false --whether kirby has the vanish cap
local kirbyhaswing = false --whether kirby has the wing cap
local kirbyissuper = false --whether kirby went super through the sonic health mod
local version = "0.9.9 beta test"
local forcetoggle = 0
local instarselect = false
local movingui = false
gGlobalSyncTable.abilitychoose = false --whether kirby can choose his ability on level change
local servermodsync = false
local bool_to_str = {[false] = "\\#A02200\\off\\#ffffff\\",[true] = "\\#00C7FF\\on\\#ffffff\\"} --table for converting boolean into string
local E_MODEL_KIRBY  = E_MODEL_MARIO --smlua_model_util_get_id("kirby_geo") commented out until i add a custom kirby model
local E_KIRBY_LIFE_ICON = nil
local kirbyfreechoose = false --whether the player can currently change their ability anywhere
local settingswallowbutton = false
gGlobalSyncTable.projectilehurtallies = false --whether kirby projectiles hurt other players when the interaction is solid(can be overwritten by external mods)
local set2ndswallowbutton = false
gPlayerSyncTable[0].inhaledplayer = 0 --whether a player was grabbed by kirby's inhale 0 for no player was grabbed, 1 for a player is held, 2 for the player is being swallowed, 3 for the player being thrown, and 4 for the player being dropped 
gPlayerSyncTable[0].livingprojectile = false --used for checking if a player is acting as a projectile
gPlayerSyncTable[0].inhaleescape = 0 --counter used for escaping a player grab
gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex --global index of player that grabbed you
local possessed = false
local kirbyaltmovesetcheck --function used for checking if the local player has kirby on when character select is on
local kirbyaltmovesettoggle --function used for some mods that have their own character selection feature like character select
local modmenuopen = false

local kirbyconfig_command -- --this is the function for save server settings or loading them
local kirbyloseability_command ----this is the function for enabling or disabling kirby losing his ability on hit
local kirbyabilitychoose_command ----this is the function for enabling or disabling kirby losing his ability on hit
local kirbysolidprojectiles_command --this is the function for controlling  how kirby projectiles affect other players when player interaction is solid
local kirby_command --this is the function for enabling or disabling kirby moveset, getting moveset info, and getting the list of available kirby abilities
local object_set_model --Called when a behavior changes models. Also runs when a behavior spawns.


local usingcoopdx = 0 --variable used to check for coopdx if 0 then the local player isn't using coopdx,1 for coopdx with coop compatibility on ,and 2 for coopdx with coop compatibility off
if  get_coop_compatibility_enabled ~= nil then --if the local user is using coopdx
    if get_coop_compatibility_enabled() == true then --if the local user is using coopdx's coop compatibility mode
        usingcoopdx = 1 --coop compatibility is on
    elseif SM64COOPDX_VERSION >= "1.0.0" then --excoop and coopdx merger
        usingcoopdx = 3
    else
        usingcoopdx = 2 --coop compatibility is off
    end
elseif SM64COOPDX_VERSION ~= nil then--if the local user is using a version of coopdx without the get_coop_compatibility_enabled function
	if gControllers == nil then --sm64coopdx v0.1 and sm64coopdx  v0.1.2 check
		usingcoopdx = 1
	else --versions of sm64coopdx after sm64coopdx v0.2 would use this since coop compatability would be deprecated
		usingcoopdx = 3 --coop compatibility is off
	end
end

if INTERACT_UNKNOWN_08 == nil then --code for if legacy variable INTERACT_UNKNOWN_08 was removed INTERACT_UNKNOWN_08 = INTERACT_SPINY_WALKING 
	INTERACT_UNKNOWN_08 = INTERACT_SPINY_WALKING
end

local inhalingtable = {} --used for checking that remote players using the kirby inhale move have spawned id_bhvkirbyinhalehitbox on the local player's side 
local possessingtable = {} --used for checking if a player is possessing something
for i = 0,MAX_PLAYERS - 1,1 do
    inhalingtable[i] = false
    possessingtable[i] = false
end

function toboolean(s)
    if s == "false" then
        return false
    else
        return true
    end
end

if (mod_storage_load("kirbyability_ui_x") == nil) or (mod_storage_load("kirbyability_ui_y") == nil) then
	mod_storage_save("kirbyability_ui_x", "0")
	mod_storage_save("kirbyability_ui_y", "0")
end

if not(mod_storage_load("swallowbutton1") or mod_storage_load("swallowbutton2")) then
    mod_storage_save("swallowbutton1", tostring(X_BUTTON))
    mod_storage_save("swallowbutton2", tostring(X_BUTTON))
end

local kirbyui_x = tonumber(mod_storage_load("kirbyability_ui_x"))
local kirbyui_y = tonumber(mod_storage_load("kirbyability_ui_y"))
local swallowbutton1 = tonumber(mod_storage_load("swallowbutton1"))--1st button of the swallowbutton combo used for swallowing enemies
local swallowbutton2 = tonumber(mod_storage_load("swallowbutton2"))--2nd button of the swallowbutton combo used for swallowing enemies

if network_is_server() then
    if (mod_storage_load("kirbyloseability") == nil) or (mod_storage_load("kirbyabilitychoose") == nil) or (mod_storage_load("projectilehurtallies") == nil) then
        mod_storage_save("kirbyloseability", "false")
	    mod_storage_save("kirbyabilitychoose", "false")
        mod_storage_save("projectilehurtallies", "false")
    else
        gGlobalSyncTable.loseability = toboolean(mod_storage_load("kirbyloseability"))
        gGlobalSyncTable.abilitychoose = toboolean(mod_storage_load("kirbyabilitychoose"))
        gGlobalSyncTable.projectilehurtallies = toboolean(mod_storage_load("projectilehurtallies"))
    end

end

local buttons = { --table of buttons where each entry has the key to the next and prev entries
    [A_BUTTON] = {name = "A ",prev = nil ,next = B_BUTTON},
    [B_BUTTON] = {name = "B ",prev = A_BUTTON ,next = Z_TRIG},
    [Z_TRIG] = {name = "Z ",prev = B_BUTTON ,next = L_TRIG},
    [L_TRIG] = {name = "L ",prev = Z_TRIG ,next = R_TRIG},
    [R_TRIG] = {name = "R ",prev = L_TRIG ,next = X_BUTTON},
    [X_BUTTON] = {name = "X ",prev = R_TRIG ,next = Y_BUTTON},
    [Y_BUTTON] = {name = "Y ",prev = X_BUTTON ,next = L_JPAD},
    [L_JPAD] = {name = "dpad left ",prev = Y_BUTTON ,next = R_JPAD},
    [R_JPAD] = {name = "dpad right ",prev = L_JPAD ,next = U_JPAD},
    [U_JPAD] = {name = "dpad up ",prev = R_JPAD ,next = D_JPAD},
    [D_JPAD] = {name = "dpad down ",prev = U_JPAD ,next = L_CBUTTONS},
    [L_CBUTTONS] = {name = "c left ",prev = D_JPAD ,next = R_CBUTTONS},
    [R_CBUTTONS] = {name = "c right ",prev = L_CBUTTONS ,next = U_CBUTTONS},
    [U_CBUTTONS] = {name = "c up ",prev = R_CBUTTONS ,next = D_CBUTTONS},
    [D_CBUTTONS] = {name = "c down ",prev = U_CBUTTONS ,next = nil}
}

--variables used by id_bhvkirbyinhalehitbox for player grabs
local inhaledtable = {
    held_none = 0,--no player was grabbed
    held_held = 1,--a player was grabbed
    held_swallow = 2,--the held player was swallowed
    held_throw = 3,--the held player was thrown
    held_drop = 4,--the held player was dropped
    held_owner_left = 5,--the inhalehitbox owner left the level or area
    warp_to_owner = 6,--starting to move the held player to the inhalehitbox owner
    finish_warp = 7, --finish moving held player to inhalehitbox owner
}

ACT_KIRBY_BOMB_JUMP =			  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_WHEEL_ROLL =			  allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_MOVING| ACT_FLAG_ATTACKING|ACT_FLAG_RIDING_SHELL)
ACT_KIRBY_WHEEL_FALL =			  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_RIDING_SHELL)
ACT_KIRBY_WHEEL_DOWNSHIFT =		  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION )
ACT_KIRBY_WHEEL_JUMP =			  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_RIDING_SHELL)
ACT_KIRBY_ROCK_FALL =			  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_ROCK_SLIDING =		  allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_MOVING | ACT_FLAG_ATTACKING|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_ROCK_IDLE =		      allocate_mario_action(ACT_GROUP_STATIONARY|ACT_FLAG_STATIONARY|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_ROCK_WATER_SINK =		  allocate_mario_action(ACT_GROUP_SUBMERGED|ACT_FLAG_METAL_WATER | ACT_FLAG_ATTACKING|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_ROCK_WATER_SLIDING =	  allocate_mario_action(ACT_GROUP_SUBMERGED|ACT_FLAG_MOVING | ACT_FLAG_ATTACKING|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_ROCK_WATER_IDLE =		  allocate_mario_action(ACT_GROUP_SUBMERGED|ACT_FLAG_STATIONARY|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_JUMP =                  allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_EXHALE =                allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_INHALE =                allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING| ACT_FLAG_ATTACKING)
ACT_KIRBY_INHALE_FALL =           allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_NEEDLE_IDLE =           allocate_mario_action(ACT_GROUP_STATIONARY|ACT_FLAG_STATIONARY|ACT_FLAG_ATTACKING)
ACT_KIRBY_NEEDLE_SLIDING =		  allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_KIRBY_NEEDLE_FALL =			  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_KIRBY_NEEDLE_FALLING_SPINE =  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND = allocate_mario_action(ACT_GROUP_STATIONARY|ACT_FLAG_STATIONARY)
ACT_KIRBY_FIRE_BREATH =           allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)
ACT_KIRBY_FIRE_BREATH_FALL =      allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_FIRE_BALL =             allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_FIRE_BALL_SPIN =		  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION )
ACT_KIRBY_FIRE_BALL_ROLL =        allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_FIRE_BALL_ROLL_JUMP =   allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_FIRE_BALL_ROLL_CLIMB =   allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_SPECIAL_FALL =          allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_GHOST_DASH =            allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_WING_FLAP =             allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR |ACT_FLAG_ATTACKING| ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_WING_FEATHER_GUN =      allocate_mario_action(ACT_GROUP_STATIONARY|ACT_FLAG_STATIONARY)
ACT_KIRBY_WING_FEATHER_GUN_FALL = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_KIRBY_WING_CONDOR_HEAD =      allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR| ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_WING_CONDOR_BOMB =	  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION )
ACT_KIRBY_WING_CONDOR_DIVE =	  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR | ACT_FLAG_ATTACKING|ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION )
ACT_KIRBY_POSSESS_BOBOMB_FUSELIT =      allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_KIRBY_POSSESS_BULLET_BILL =      allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_KIRBY_SLEEP =      allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_KIRBY_LAND =  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_STATIONARY|ACT_FLAG_ATTACKING)
ACT_KIRBY_LAND_INVULNERABLE =  allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_STATIONARY|ACT_FLAG_ATTACKING|ACT_FLAG_INVULNERABLE)
ACT_KIRBY_LIVING_PROJECTILE =             allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR |ACT_FLAG_INTANGIBLE| ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_KIRBY_STAR_SPIT_AIR = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR |ACT_FLAG_THROWING| ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)



--kirby ability variables
local kirbyability_none = 1
local kirbyability_bomb = 2
local kirbyability_fire = 3
local kirbyability_wheel = 4
local kirbyability_needle = 5
local kirbyability_wrestler = 6
local kirbyability_stone = 7
local kirbyability_ghost = 8
local kirbyability_wing = 9
local kirbyability_sleep = 10
local kirbyability_max = 11



--tables of enemies that give abilities
local enemytable = {
[kirbyability_none] = {[id_bhvGoomba] = ' non giant goomba',[id_bhvScuttlebug] = 'scuttlebug',[id_bhvSpindrift] = 'spindrift',[id_bhvSkeeter] = 'skeeter',[id_bhvSnufit] = 'snufit'},
[kirbyability_bomb] = {[id_bhvBobomb] = 'bobomb',[id_bhvWaterBomb] = 'waterbomb',[id_bhvBulletBill] = 'bulletbill'},
[kirbyability_fire] = {[id_bhvFlyGuy] = 'flyguy',[id_bhvFirePiranhaPlant] = 'non giant fire piranha plant',[id_bhvFlyguyFlame] = 'flyguy flame',[id_bhvSmallPiranhaFlame] = 'piranha flame',[id_bhvBouncingFireballFlame] = 'bouncing fireball',[id_bhvFlameBowser] = 'bowser flame', [id_bhvFlameLargeBurningOut] = 'bowser red flame burning out'},
[kirbyability_wheel] = {[id_bhvKoopaShell] = 'koopashell',[id_bhvKoopaShellUnderwater] = 'koopashell underwater',[id_bhvKoopa] = 'koopa',[id_bhvMips] = 'mips'},
[kirbyability_needle] = {[id_bhvPokeyBodyPart] = 'pokey',[id_bhvSpiny] = 'spiny',[id_bhvEnemyLakitu] = 'lakitu'},
[kirbyability_wrestler] = {[id_bhvSmallBully] = 'small bully',[id_bhvSmallChillBully] = 'small chill bully',[id_bhvChuckya] = 'chuckya'},
[kirbyability_stone] = {[id_bhvMontyMole] = 'monty mole',[id_bhvMoneybag] = 'money bag',[id_bhvBreakableBoxSmall] = 'breakable box small',[id_bhvMontyMole] = 'monty mole',[id_bhvMetalCap] = 'metal cap',[id_bhvMontyMoleRock] = 'monty mole rock'},
[kirbyability_ghost] = {[id_bhvHauntedChair] = 'haunted chair',[id_bhvFlyingBookend] = 'haunted flying book',[id_bhvVanishCap] = 'vanish cap'},
[kirbyability_wing] = {[id_bhvSwoop] = 'swoop',[id_bhvWingCap] = 'wing cap'},
[kirbyability_sleep] = {[id_bhvPiranhaPlant] = 'piranhaplant'}
}

local bool_to_num = {[false] = 0,[true] = 1} --table for converting boolean into numbers
local kirbyabilitylist = {[kirbyability_none] = 'none',[kirbyability_bomb] = 'bomb',[kirbyability_fire] = 'fire',[kirbyability_wheel] = 'wheel',[kirbyability_needle] = 'needle',[kirbyability_wrestler] = 'wrestler',[kirbyability_stone] = 'stone',[kirbyability_ghost] = 'ghost',[kirbyability_wing] = 'wing',[kirbyability_sleep] = 'sleep'} --table of kirby abilities
local kirbyabilitymovelist = {[ACT_KIRBY_EXHALE] = 2,[ACT_KIRBY_BOMB_JUMP] = 2,[ACT_KIRBY_WHEEL_ROLL] = 1,[ACT_KIRBY_WHEEL_FALL] = 1,[ACT_KIRBY_WHEEL_DOWNSHIFT] = 1,[ACT_KIRBY_WHEEL_JUMP] = 1,[ACT_KIRBY_ROCK_FALL] = 1,[ACT_KIRBY_ROCK_SLIDING] = 1,[ACT_KIRBY_ROCK_IDLE] = 2,[ACT_KIRBY_ROCK_WATER_SINK] = 1,[ACT_KIRBY_ROCK_WATER_SLIDING] = 1,[ACT_KIRBY_ROCK_WATER_IDLE] = 2,[ACT_KIRBY_NEEDLE_FALL] = 1,[ACT_KIRBY_NEEDLE_FALLING_SPINE] = 1,[ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND] = 2,[ACT_KIRBY_NEEDLE_SLIDING] = 1,[ACT_KIRBY_NEEDLE_IDLE] = 1,[ACT_KIRBY_FIRE_BALL] = 1,[ACT_KIRBY_FIRE_BREATH] = 2,[ACT_KIRBY_FIRE_BREATH_FALL] = 2,[ACT_KIRBY_FIRE_BALL_SPIN] = 1,[ACT_KIRBY_FIRE_BALL_ROLL] = 1,[ACT_KIRBY_FIRE_BALL_ROLL_JUMP] = 1,[ACT_KIRBY_FIRE_BALL_ROLL_CLIMB] = 1, [ACT_KIRBY_GHOST_DASH] = 1,[ACT_KIRBY_WING_FLAP] = 1,[ACT_KIRBY_WING_FEATHER_GUN] = 2,[ACT_KIRBY_WING_FEATHER_GUN_FALL] = 2, [ACT_KIRBY_WING_CONDOR_HEAD] = 1, [ACT_KIRBY_WING_CONDOR_BOMB] = 1 , [ACT_KIRBY_WING_CONDOR_DIVE] = 1,[ACT_KIRBY_SLEEP] = 2,[ACT_KIRBY_LAND] = 1,[ACT_KIRBY_LAND_INVULNERABLE] = 1, [ACT_KIRBY_LIVING_PROJECTILE] = 2,[ACT_KIRBY_STAR_SPIT_AIR] = 2} --1 is for moves that deal damage while  2 is for moves that don't deal damage
local projectilehurtableenemy = {[id_bhvBobomb] = "id_bhvBobomb",[id_bhvGoomba] = "ground_pound",[id_bhvKoopa] = "generic_attack",[id_bhvScuttlebug] = "generic_attack",[id_bhvSpindrift] = "generic_attack",[id_bhvSkeeter] = "generic_attack",[id_bhvPiranhaPlant] = "generic_attack",[id_bhvSwoop] = "generic_attack",[id_bhvSnufit] = "generic_attack",[id_bhvBreakableBox] = "ground_pound",[id_bhvFlyGuy] = "ground_pound",[id_bhvPokeyBodyPart] = "ground_pound",[id_bhvEnemyLakitu] = "generic_attack",[id_bhvChuckya] = "id_bhvChuckya",[id_bhvMontyMole] = "generic_attack",[id_bhvMoneybag] = "ground_pound",[id_bhvKingBobomb] = "id_bhvKingBobomb",[id_bhvBowser] = "id_bhvBowser",[id_bhvChainChomp] = "generic_attack",[id_bhvEyerokHand] = "id_bhvEyerokHand",[id_bhvWigglerHead] = "id_bhvWigglerHead",[id_bhvFirePiranhaPlant] = "id_bhvFirePiranhaPlant",[id_bhvKlepto] = "generic_attack",[id_bhvMips] = "id_bhvMips",[id_bhvSmallBully] = 'id_bhvSmallBully',[id_bhvSmallChillBully] = 'id_bhvSmallBully',[id_bhvBigBully] = "id_bhvSmallBully",[id_bhvBigBullyWithMinions] = "id_bhvSmallBully",[id_bhvBigChillBully] = "id_bhvSmallBully" ,[id_bhvExclamationBox] = "id_bhvExclamationBox",[id_bhvBlueCoinSwitch] = "id_bhvBlueCoinSwitch",[id_bhvTowerDoor] = "generic_attack",[id_bhvHiddenObject] = "id_bhvHiddenObject",[id_bhvWhompKingBoss] = "id_bhvWhompKingBoss",[id_bhvSmallWhomp] = "id_bhvSmallWhomp",[id_bhvBoo] = "id_bhvBoo",[id_bhvGhostHuntBoo] = "id_bhvBoo",[id_bhvBooWithCage]="id_bhvBoo",[id_bhvMerryGoRoundBoo] = "id_bhvBoo",[id_bhvMerryGoRoundBigBoo] = "id_bhvBoo",[id_bhvBalconyBigBoo] = "id_bhvBoo",[id_bhvGhostHuntBigBoo] = "id_bhvBoo",[id_bhvThiTinyIslandTop] = "id_bhvThiTinyIslandTop",[id_bhvKickableBoard] = "id_bhvKickableBoard",[id_bhvWaterLevelPillar] = "id_bhvWaterLevelPillar"} --generic_attack for the damage to be a generic attack , ground_pound for ground pound,a specfic behavior id for a unique interaction
local kirbynosync = {[id_bhvPokeyBodyPart] = true,[id_bhvWaterBomb] = true,[id_bhvMontyMole] = true,[id_bhvMontyMoleRock] = true,[id_bhvMetalCap] = true,[id_bhvSmallPiranhaFlame] = true,[id_bhvBouncingFireballFlame] = true,[id_bhvFlyguyFlame] = true,[id_bhvBouncingFireballFlame] = true,[id_bhvVanishCap] = true,[id_bhvWingCap] = true , [id_bhvFlameBowser] = true,[id_bhvFlameLargeBurningOut] =true} 
local kirbycustomfoodbehavior = {[id_bhvSmallBully] = "bully",[id_bhvSmallChillBully] = "bully", [id_bhvWaterBomb] = "waterbomb",[id_bhvBobomb] = "bobomb",[id_bhvBreakableBoxSmall] = "id_bhvBreakableBoxSmall",[id_bhvFlyingBookend] = "5coinenemy",[id_bhvKoopa] = "koopa",[id_bhvPokeyBodyPart] = "pokey",[id_bhvMontyMole] = "montymole",[id_bhvBulletBill] = "bulletbill", [id_bhvEnemyLakitu] = "enemylakitu",[id_bhvFirePiranhaPlant] = "firepiranhaplant" } --used for custom objects that won't die properly with obj_mark_for_deletion
local projectilefunctions = {} --list of projectile functions for custom objects that each return true for projectile deletion false otherwise
local projectilehurtableenemycustomcollision = {} --table of custom hitbox check functions for some projectile hurtable objects
local kirbycustomfoodfunctions = {} --used for custom objects that won't die properly with just obj_mark_for_deletion
local directattackfunctions = {} --list of functions for custom objects reacting to kirby moves
local directattackableenemy = {} ---tables of strings such as "id_bhvKingBobomb" to determine what happens on interaction with kirby move gets set to custom if a function is passed in
local directattackablenointeracttable = {} -- for directattableenemies with interacttype 0
local possessableenemytable = {[id_bhvGoomba] = "goomba",[id_bhvBobomb] = "bobomb",[id_bhvBulletBill] = "bulletbill",[id_bhvSwoop] = "Swoop"} --enemies that can be possessed by ghost kirby
local possessfunctions = {} -- functions for ghost kirby possessing enemies
local possessablemoveset = {[id_bhvGoomba] = "goomba",[id_bhvBobomb] = "bobomb",[id_bhvBulletBill] = "bulletbill",[id_bhvSwoop] = "Swoop"} --used for possable enemies to use a preexisting possable moveset
local possessablemovesetfunction = {} --used for possable enemies to use a custommoveset
local possessablenametable = {[id_bhvGoomba] = "goomba",[id_bhvBobomb] = "bobomb",[id_bhvBulletBill] = "bullet bill",[id_bhvSwoop] = "Swoop"} --table of possessable enemy names for printing
local eatabletype0 = {} --used for eatable objects that use type 0
local allycheck --function used for checking if a player is on the same team as the local player
local romhackchange --function for changing kirby's moveset in some hacks
local modsupporthelperfunctions = {} --local references to functions from other mods
local kirbyvoicetable = {} -- a table of kirby sounds

--tables of kirbymodels
local kirbymodeltable = {
    abilitystar = E_MODEL_TRANSPARENT_STAR,
    airbullet = E_MODEL_BLACK_BOBOMB,
    kirbybomb = E_MODEL_BLACK_BOBOMB,
    kirbyflame = E_MODEL_RED_FLAME,
    kirbywingfeather = E_MODEL_BLACK_BOBOMB,
    livingprojectile = E_MODEL_TRANSPARENT_STAR
}

---@param m MarioState
--- @param sound CharacterSound
--function used for kirby sounds
local function kirbyvoicesound(m,sound)
    return 0
end

---@param m MarioState
--function used for kirby snoring
local function kirbyvoicesnore(m)
    return
end

define_custom_obj_fields({
    oKirbyAbilitytype = 'u32',
    oSpawnedAbilityessence = 'u32',
    oKirbyProjectileOwner = 'u32',
    oKirbyLivingProjectileLaunchedby = 'u32',
})

---@param victim integer local playerindex of player hit by projectile
---@param projectileowner integer local playerindex of projectile's owner
---@param o Object the projectile hurting the victim
---this function is for the default kirby projectile interaction 
local function genericallycheck(projectileowner,victim,o)
    local m = gMarioStates[victim]
    if gServerSettings.playerInteractions == 0 then --if player interaction is disabled
        return true
    elseif gServerSettings.playerInteractions == 1 then --if player interaction is solid
        if gGlobalSyncTable.projectilehurtallies == false then
            return true
        else
            if m.invincTimer <= 0 and (obj_has_behavior_id(o,id_bhvkirbyflame) == 0) then
                m.healCounter = m.healCounter + (o.oDamageOrCoinValue * 4)
            end
            return false
        end
    else
        return false
    end
end

--variable used for showing/hiding the kirby ui
local toggleui = true

--- @param o Object
--this sets up an ability star
function bhv_abilitystar_init(o)
    bhv_breakable_box_small_init()
    cur_obj_scale(1.0)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_HOLDABLE | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_GRABBABLE
	o.hitboxDownOffset = 100
	o.oDamageOrCoinValue = 2
	o.oHealth = 0
	o.oNumLootCoins = 0
    o.hitboxRadius = 150
    o.hitboxHeight = 250
    o.hurtboxRadius= 0
	o.hurtboxHeight = 0
	network_init_object(o, true, {'oKirbyAbilitytype'})

end

--- @param o Object
--this sets up the copyessence
function bhv_copyessence_init(o)
	obj_set_billboard(o)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
	o.hitboxDownOffset = 0
	o.oDamageOrCoinValue = 0
	o.oHealth = 0
	o.oNumLootCoins = 0
    o.hitboxRadius = 100
    o.hitboxHeight = 64
    o.hurtboxRadius= 0
	o.hurtboxHeight = 0
    network_init_object(o, true, {'oKirbyAbilitytype'})
	cur_obj_update_floor_and_walls()

end

--- @param o Object
--this sets up the bombs from kirby's bomb ability
function bhv_kirbybomb_init(o)
    bhv_bobomb_init()
    o.oFlags = OBJ_FLAG_HOLDABLE | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.hitboxDownOffset = 0
    o.oDamageOrCoinValue = 0
    o.oHealth = 0
    o.oNumLootCoins = 0
    o.oBobombFuseLit = 1
    o.oBobombFuseTimer = 0
    o.oBehParams = 0x100
    o.oBehParams2ndByte = BOBOMB_BP_STYPE_STATIONARY
    cur_obj_set_hitbox_radius_and_height(65, 113)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()

end

--- @param o Object
--this sets up an wing kirby projectile
function bhv_wingfeather_init(o)
    cur_obj_scale(1.0)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_DAMAGE
	o.hitboxDownOffset = 0
	o.oDamageOrCoinValue = 2
	o.oHealth = 0
	o.oNumLootCoins = 0
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()
	network_init_object(o, true, {'oKirbyAbilitytype'})
end

--- @param o Object
--this sets up an fire kirby's breath
function bhv_kirbyflame_init(o)
    obj_set_billboard(o)
    cur_obj_scale(10.0)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_FLAME
	o.hitboxDownOffset = 25
	o.oDamageOrCoinValue = 3
	o.oHealth = 0
	o.oNumLootCoins = 0
    cur_obj_set_hitbox_radius_and_height(100, 100)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()
	network_init_object(o, true, nil)

end

--- @param o Object
--this sets up an kirby's inhale hitbox for players
function bhv_kirbyinhalehitbox_init(o)
    obj_set_billboard(o)
    cur_obj_scale(10.0)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_GRABBABLE
    o.oInteractionSubtype = INT_SUBTYPE_NOT_GRABBABLE |INT_SUBTYPE_GRABS_MARIO
	o.hitboxDownOffset = 80
	o.oHealth = 0
	o.oNumLootCoins = 0
    o.allowRemoteInteractions = false
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()

end

--- @param o Object
--this sets up the hitbox for being thrown by kirby
function bhv_kirbylivingprojectile_init(o)
    obj_set_billboard(o)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_DAMAGE
	o.hitboxDownOffset = 20
	o.oDamageOrCoinValue = 3
	o.oHealth = 0
	o.oNumLootCoins = 0
    cur_obj_set_hitbox_radius_and_height(150, 250)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()
	network_init_object(o, true, nil)

end

--- @param o Object
--this sets up a kirby explosion
function bhv_kirbyexplosion_init(o)
    bhv_explosion_init()
    obj_set_billboard(o)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_DAMAGE
    o.oDamageOrCoinValue = 3
    cur_obj_update_floor_and_walls()
    cur_obj_set_hitbox_radius_and_height(o.hitboxRadius + 60,  o.hitboxHeight + 60)
	network_init_object(o, true, {'oKirbyAbilitytype'})

end

--- @param o Object
--this sets up kirby's air gun projectile
function bhv_airbullet_init(o)
    cur_obj_scale(1.0)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_DAMAGE
	o.hitboxDownOffset = 0
	o.oDamageOrCoinValue = 1
	o.oHealth = 0
	o.oNumLootCoins = 0
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    cur_obj_update_floor_and_walls()
	network_init_object(o, true, {'oKirbyAbilitytype'})
end

--- @param o Object
--this sets up the model used when kirby is possessing something
function bhv_kirbypossessmodel_init(o)
    cur_obj_scale(1.0)
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

--- @param o Object
--this sets an object used for making sure bowser dies when he is set to 0 or less health by a kirby move or projectile
function bhv_kirbybowserdeathconfirm_init(o)
    cur_obj_scale(1.0)
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

--- @param o Object
--this sets an object used for making king whomp spawn ability stars on whiffed attacks
function bhv_kirbykingwhompabilitystar_init(o)
    cur_obj_scale(1.0)
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

--- @param o Object
--this is the loop for the bombs from kirby's bomb ability
function bhv_kirbybomb_loop(o)
    if ((o.oAction == BOBOMB_ACT_EXPLODE and (o.oHeldState ~= HELD_HELD)) or o.oAction == BOBOMB_ACT_DEATH_PLANE_DEATH or o.oAction == BOBOMB_ACT_LAVA_DEATH)  then
        kirbybomb_act_explode(o)
    elseif (o.oAction == BOBOMB_ACT_PATROL or o.oAction == BOBOMB_ACT_CHASE_MARIO) and o.oHeldState == HELD_FREE and o.oFloorHeight ~= o.oPosY then
        cur_obj_change_action(BOBOMB_ACT_LAUNCHED)
        bhv_bobomb_loop()
    else

        bhv_bobomb_loop()
    end
    if (o.oHeldState ~= HELD_HELD) and kirbyprojectileattack(o) then
        o.oAction = BOBOMB_ACT_EXPLODE
    elseif (o.oHeldState == HELD_HELD) then
        o.oKirbyProjectileOwner = gNetworkPlayers[o.heldByPlayerIndex].globalIndex
    end

end

--- @param o Object
--this function is used for kirby bombs exploding
function kirbybomb_act_explode(o)
    local explosion
    if (o.oTimer < 5) then
        local x = 1.0 + ( o.oTimer / 5.0)
        cur_obj_scale(x)
        cur_obj_set_hitbox_radius_and_height(65 *x, 113 *x)

    else 
        local projectileowner = o.oKirbyProjectileOwner
        explosion = spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY,o.oPosZ,function(obj)
            obj.oKirbyProjectileOwner = projectileowner
        end)
        if (explosion ~= nil) then
            explosion.oGraphYOffset = explosion.oGraphYOffset + 100.0
        end

        obj_mark_for_deletion(o)
    end
end

--- @param obj Object
--this is the loop for copyessence
function bhv_copyessence_loop(obj)
    local m = gMarioStates[0]
	if  ((m.action & ACT_GROUP_CUTSCENE) ~= 0) or ((m.action & ACT_GROUP_AUTOMATIC) ~= 0)  then
		return
	elseif (nearest_interacting_mario_state_to_object(obj)).playerIndex == 0 and is_within_100_units_of_mario(obj.oPosX, obj.oPosY, obj.oPosZ) == 1 and gPlayerSyncTable[0].kirby == true then
		if obj.oKirbyAbilitytype ~= nil and gPlayerSyncTable[0].kirbypower ~= obj.oKirbyAbilitytype and gPlayerSyncTable[0].kirby  then
            gPlayerSyncTable[0].kirbypower = obj.oKirbyAbilitytype
            gPlayerSyncTable[0].kirbypossess = 0
            gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
            gPlayerSyncTable[0].possessedmodelId = nil
            if gPlayerSyncTable[0].inhaledplayer > 0 then
                gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
            end
            
            if (m.action & ACT_FLAG_WATER_OR_TEXT) ~= 0 then
                set_mario_action(m, ACT_WATER_IDLE, 0)
            elseif m.pos.y ~= m.floorHeight then
                set_mario_action(m,ACT_FREEFALL,0)
            else
                set_mario_action(m,ACT_IDLE,0)
            end
        end
	end
end


--- @param obj Object
--this is the loop for copy ability stars
function bhv_abilitystar_loop(obj)
    local starthrow = 1
    local starbounce = 2
    local sp1E = 0
    local breakStatus =  INT_STATUS_WAS_ATTACKED |INT_STATUS_TOUCHED_BOB_OMB |INT_STATUS_MARIO_UNK1|INT_STATUS_ATTACKED_MARIO
    cur_obj_update_floor_and_walls()
    if obj.oHeldState == HELD_HELD then
        obj.oTimer = 0
        obj.oKirbyProjectileOwner = gNetworkPlayers[obj.heldByPlayerIndex].globalIndex
        obj.oIntangibleTimer = 2
        cur_obj_change_action(0)
        cur_obj_disable_rendering()
        cur_obj_become_intangible()
        player = gMarioStates[obj.heldByPlayerIndex].marioObj
        cur_obj_set_pos_relative(player, 0, 60.0, 100.0)
    elseif   obj.oTimer > 300 then
        obj_mark_for_deletion(obj)
    elseif obj.oHeldState == HELD_FREE and obj.oAction == 0 then
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        splE= object_step()
        obj_check_floor_death(sp1E, obj.oFloor)

    elseif obj.oHeldState == HELD_FREE and obj.oAction == starbounce then
        splE= object_step()
        obj_check_floor_death(sp1E, obj.oFloor)
        if obj.oFloorHeight ==  obj.oPosY then
            obj.oVelY = 40
        end
    elseif obj.oHeldState == HELD_THROWN and obj.oAction ~= starthrow then
        obj.oIntangibleTimer = 0
        obj.oGravity = 0
        cur_obj_get_thrown_or_placed(80.0,0.0,starthrow)
        object_step()
        obj.oFlags =obj.oFlags & ~0x08
        obj.activeFlags = obj.activeFlags & ~ACTIVE_FLAG_UNK9
        obj.oInteractStatus = 0
        obj.oTimer = 0
    elseif obj.oAction == starthrow then
        obj.oIntangibleTimer = 0
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        if obj.oInteractType ~= INTERACT_DAMAGE then
            obj.oInteractType = INTERACT_DAMAGE
        end
        obj.oVelY = 0
        sp1E = object_step()

        if ( (obj.oInteractStatus & breakStatus) ~= 0) or ((collision_find_surface_on_ray(obj.oPosX,obj.oPosY,obj.oPosZ,obj.oVelX,obj.oVelY,obj.oVelZ)).surface) ~= nil or (sp1E & OBJ_COL_FLAG_HIT_WALL) ~= 0 or kirbyprojectileattack(obj)  then
                obj_mark_for_deletion(obj)
        end
        obj_check_floor_death(sp1E, obj.oFloor)

    elseif  obj.oHeldState == HELD_DROPPED then
        obj.oIntangibleTimer = 0
        obj.oGravity = 2.5
        cur_obj_get_dropped()
        obj.oInteractStatus = 0
    end
end

--- @param obj Object
--this is the loop for the feathers from kirby's wing ability
function bhv_wingfeather_loop(obj)
    local breakStatus =  INT_STATUS_WAS_ATTACKED |INT_STATUS_TOUCHED_BOB_OMB |INT_STATUS_MARIO_UNK1|INT_STATUS_ATTACKED_MARIO
    cur_obj_update_floor_and_walls()
    cur_obj_enable_rendering()
    cur_obj_become_tangible()
    local sp1E = object_step()
    obj.oVelY = 0
    obj_compute_vel_from_move_pitch(40.0)
    cur_obj_move_standard(78)
    if (kirbyprojectileattack(obj) or (obj.oInteractStatus & breakStatus) ~= 0) or (sp1E & OBJ_COL_FLAG_HIT_WALL) ~= 0 or (obj.oTimer == 60)  then
        obj_mark_for_deletion(obj)
    else
        obj.oInteractStatus = 0
    end

end

--- @param obj Object
--this is the loop for the air bullet from kirby's exhale move
function bhv_airbullet_loop(obj)
    local breakStatus =  INT_STATUS_WAS_ATTACKED |INT_STATUS_TOUCHED_BOB_OMB |INT_STATUS_MARIO_UNK1|INT_STATUS_ATTACKED_MARIO
    cur_obj_update_floor_and_walls()
    cur_obj_enable_rendering()
    cur_obj_become_tangible()
    local sp1E = object_step()
    obj.oVelY = 0
    obj_compute_vel_from_move_pitch(40.0)
    cur_obj_move_standard(78)
    if (kirbyprojectileattack(obj) or (obj.oInteractStatus & breakStatus) ~= 0) or (sp1E & OBJ_COL_FLAG_HIT_WALL) ~= 0 or (obj.oTimer == 10)  then
        obj_mark_for_deletion(obj)
    else
        obj.oInteractStatus = 0
    end

end


--- @param o Object
--this is the loop for the firebreath from kirby's fire ability
function bhv_kirbyflame_loop(o)
    local playerindex = network_local_index_from_global(o.oKirbyProjectileOwner)
    if ((gNetworkPlayers[playerindex].connected) and (gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex == gNetworkPlayers[0].currAreaIndex) and (gNetworkPlayers[playerindex].currCourseNum == gNetworkPlayers[0].currCourseNum)) and ((gMarioStates[playerindex].action == nil or gMarioStates[playerindex].action == ACT_KIRBY_FIRE_BREATH) or ((gMarioStates[playerindex].action == ACT_KIRBY_FIRE_BREATH_FALL)) )  then
        obj_set_pos_relative(o,gMarioStates[playerindex].marioObj,0,0,181 )
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        kirbyprojectileattack(o)
    elseif (gPlayerSyncTable[playerindex].breathingfire == false and gNetworkPlayers[0].globalIndex == o.oKirbyProjectileOwner) or ((gNetworkPlayers[0].globalIndex ~= o.oKirbyProjectileOwner and gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex ~= gNetworkPlayers[0].currAreaIndex)) or (gNetworkPlayers[0].globalIndex == o.oKirbyProjectileOwner and gNetworkPlayers[playerindex].currCourseNum ~= gNetworkPlayers[0].currCourseNum) then
        obj_mark_for_deletion(o)
    else
        kirbyprojectileattack(o)
        o.oInteractStatus = 0
    end

end

--- @param o Object
--this is the loop for the kirby's inhale hitbox for other players
function bhv_kirbyinhalehitbox_loop(o)
    local playerindexglobal = o.oKirbyProjectileOwner
    local playerindex = network_local_index_from_global(o.oKirbyProjectileOwner)
    local power
    local m = gMarioStates[0]
    local mglobal = gNetworkPlayers[0].globalIndex
    if ( (gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex == gNetworkPlayers[0].currAreaIndex) and (gNetworkPlayers[playerindex].currCourseNum == gNetworkPlayers[0].currCourseNum)) and (((gMarioStates[playerindex].action == nil or gMarioStates[playerindex].action == ACT_KIRBY_INHALE) or ((gMarioStates[playerindex].action == ACT_KIRBY_INHALE_FALL)) or gPlayerSyncTable[playerindex].inhaledplayer > 0) )  then
        if (o.oInteractStatus & INT_STATUS_GRABBED_MARIO) ~= 0 or gPlayerSyncTable[playerindex].inhaledplayer > 0 then     
            obj_set_pos_relative(o,gMarioStates[playerindex].marioObj,0,260,64 )
            cur_obj_disable_rendering_and_become_intangible(o)
            obj_set_move_angle(o,gMarioStates[playerindex].marioObj.oMoveAnglePitch,gMarioStates[playerindex].marioObj.oMoveAngleYaw,gMarioStates[playerindex].marioObj.oMoveAngleRoll)
            if gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_none and (m.heldByObj == o) then
                gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_held --player was grabbed
                gPlayerSyncTable[0].grabbedby = playerindexglobal
            elseif (gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_swallow) and (m.heldByObj == o) then --if the owner of the inhale hitbox swallows
                    m.hurtCounter = m.hurtCounter + 8
                    if (gPlayerSyncTable[playerindex].kirbypossess == 0) and (gPlayerSyncTable[0].kirbypower >= kirbyability_none) and (gPlayerSyncTable[0].kirbypower < kirbyability_max) then
                        power = gPlayerSyncTable[0].kirbypower
                        gPlayerSyncTable[playerindex].kirbypower = power
                        gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_none
                        if gPlayerSyncTable[0].kirby == true then --if the local player is kirby
                            gPlayerSyncTable[0].kirbypower = kirbyability_none
                            gPlayerSyncTable[0].kirbypossess = 0
                            gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                            gPlayerSyncTable[0].possessedmodelId = nil
                        end
                    end
                o.oInteractStatus = o.oInteractStatus  & ~(INT_STATUS_GRABBED_MARIO)
                o.usingObj = nil
                gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
            elseif gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_throw and (m.heldByObj == o) then --if the owner of the inhale hitbox throws the held player
                o.oInteractStatus = o.oInteractStatus  &~(INT_STATUS_GRABBED_MARIO)
                o.usingObj = nil
                gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_none
                gPlayerSyncTable[0].livingprojectile = true
                spawn_sync_object(id_bhvkirbylivingprojectile, kirbymodeltable.livingprojectile, m.pos.x, m.pos.y - 260, m.pos.z,function(obj)
                    obj.oKirbyProjectileOwner = mglobal
                    obj.oKirbyLivingProjectileLaunchedby = playerindexglobal
                    obj.oForwardVel = 80
                end)
                set_mario_action(m, ACT_KIRBY_LIVING_PROJECTILE, 0)
            elseif (m.heldByObj == o) and ((gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_drop) or (gNetworkPlayers[playerindex].connected ~= true)) then --if the owner of the inhale hitbox drops the held player
                o.oInteractStatus = o.oInteractStatus  &~(INT_STATUS_GRABBED_MARIO)
                o.usingObj = nil
                m.heldByObj = nil
                gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_none
                gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
            elseif gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_held and (m.heldByObj == o) then
                if (m.health <= 0xff) or (gPlayerSyncTable[0].inhaleescape > 11) then
                    gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_drop
                elseif (gPlayerSyncTable[0].inhaleescape == 0) then
                    gPlayerSyncTable[0].inhaleescape = 1
                end
            end
        else
            obj_set_pos_relative(o,gMarioStates[playerindex].marioObj,0,0,121)
            cur_obj_enable_rendering()
            cur_obj_become_tangible()
        end
    elseif (gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_none and ((  (gPlayerSyncTable[playerindex].inhaling == false)) )) or ((gNetworkPlayers[0].globalIndex ~= o.oKirbyProjectileOwner) and (gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex ~= gNetworkPlayers[0].currAreaIndex)) or (gNetworkPlayers[0].globalIndex ~= o.oKirbyProjectileOwner and gNetworkPlayers[playerindex].currCourseNum ~= gNetworkPlayers[0].currCourseNum) then
        o.oInteractStatus = 0
        o.usingObj = nil
        obj_mark_for_deletion(o)
    elseif (gPlayerSyncTable[playerindex].inhaledplayer == inhaledtable.held_none )then
        obj_set_pos_relative(o,gMarioStates[playerindex].marioObj,0,0,101)
        obj_turn_toward_object(o,m.marioObj,o.oMoveAngleYaw,obj_angle_to_object(o, m.marioObj))
         if obj_check_hitbox_overlap(o, m.marioObj) and (m.action ~= ACT_KIRBY_LIVING_PROJECTILE and (m.action ~= ACT_GRABBED)) and (((allycheck ~= nil) and (allycheck(playerindex,m.playerIndex,o) == true)) or ((allycheck == nil) and genericallycheck(playerindex,m.playerIndex,o) == true)) then
            o.oInteractStatus = INT_STATUS_GRABBED_MARIO | INT_STATUS_INTERACTED
            o.usingObj = m.marioObj
            m.usedObj = o
            m.interactObj = o
            m.heldByObj = o
            m.pos.x = m.usedObj.oPosX
            m.pos.y = m.usedObj.oPosY
            m.pos.z = m.usedObj.oPosZ
            set_mario_action(m,ACT_GRABBED,0)
            gPlayerSyncTable[playerindex].inhaledplayer = inhaledtable.held_held
        end
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
    end

end

--- @param o Object
--this is the loop for the hitbox when being a living projectile
function bhv_kirbylivingprojectile_loop(o)
    local playerindex = network_local_index_from_global(o.oKirbyProjectileOwner)
    cur_obj_enable_rendering()
    cur_obj_become_tangible()
    cur_obj_update_floor_and_walls()
    local sp1E = object_step()
    o.oVelY = 0
    obj_compute_vel_from_move_pitch(80.0)
    cur_obj_move_standard(78)

    if (gPlayerSyncTable[playerindex].livingprojectile == true) and kirbyprojectileattack(o) then
        gPlayerSyncTable[playerindex].livingprojectile = false
        o.oInteractStatus = 0
    elseif (gPlayerSyncTable[playerindex].livingprojectile == false) or ((gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex ~= gNetworkPlayers[0].currAreaIndex)) or (gNetworkPlayers[playerindex].currCourseNum ~= gNetworkPlayers[0].currCourseNum) then
        obj_mark_for_deletion(o)

    end

end

--- @param o Object
--this is a loop for an object used for making sure bowser dies when he is set to 0 or less health by a kirby move or projectile
function bhv_kirbybowserdeathconfirm_loop(o)
    if (o.parentObj == nil) or (o.parentObj.oAction ~= 4) then
        obj_mark_for_deletion(o)
    elseif o.parentObj.oAction == 4 and (o.parentObj.oPosY < o.parentObj.oHomeY - 100.0 )then --check for bowser falling off stage while dead
        o.parentObj.oPosX = o.parentObj.oHomeX
        o.parentObj.oPosY = o.parentObj.oHomeY
        o.parentObj.oPosZ = o.parentObj.oHomeZ
    else
        o.oPosX = o.parentObj.oPosX
        o.oPosY = o.parentObj.oPosY
        o.oPosZ = o.parentObj.oPosZ
    end
end

--- @param o Object
--this is a loop for an object used for making king whomp spawn ability stars on whiffed attacks
function bhv_kirbykingwhompabilitystar_loop(o)
    local kingwhomp = o.parentObj
    if (kingwhomp == nil) or (kingwhomp.oAction == 8) or (kingwhomp.oAction == 9) then
        obj_mark_for_deletion(o)
    elseif kingwhomp.oBehParams2ndByte ~= 0 and kingwhomp.oAction == 6 and kingwhomp.oTimer == 100  then
        spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,kingwhomp.oPosX, kingwhomp.oPosY, kingwhomp.oPosZ,function(newobj)
            newobj.oKirbyAbilitytype = kirbyability_stone
        end)
    else
        o.oPosX = kingwhomp.oPosX
        o.oPosY = kingwhomp.oPosY
        o.oPosZ = kingwhomp.oPosZ
        if o.oAction ~= kingwhomp.oAction then
            if (o.oAction == 2) and (kingwhomp.oAction == 0) then
                obj_mark_for_deletion(o)
            else
                o.oAction = kingwhomp.oAction
            end
        end 
    end
end

--- @param o Object
---@param playerindex integer local player index of the player possessing the object
--this is an animation function for a possessed object
local function animcheck(o,playerindex)
    local objectanim --an object's animation table
    local enemypossessed = gPlayerSyncTable[playerindex].kirbypossess --the enemy possessed
    local animindex --object animation index
    local m = gMarioStates[playerindex]
    if (possessablemoveset[enemypossessed] == "custom") and ((possessablemovesetfunction[enemypossessed] ~= nil)) and (possessablemovesetfunction[enemypossessed].animfunction ~= nil) then --call an external function to determine interaction
        local customfunc = possessablemovesetfunction[enemypossessed].animfunction
        if customfunc ~= nil then
            objectanim,animindex = customfunc(o,playerindex)    --a function for changing the animation of o
        end 
    elseif (possessablemoveset[enemypossessed] == "goomba") then
        animindex = 0
        objectanim = gObjectAnimations.goomba_seg8_anims_0801DA4C
    elseif (possessablemoveset[enemypossessed] == "Swoop") then
        if m.action == ACT_HANGING then
            animindex = 1
        else
            animindex = 0
        end
        objectanim = gObjectAnimations.swoop_seg6_anims_060070D0
    elseif (possessablemoveset[enemypossessed] == "bobomb") then
        animindex = 0
        objectanim = gObjectAnimations.bobomb_seg8_anims_0802396C
    elseif (possessablemoveset[enemypossessed] == "bulletbill") then
        return
    end
    if objectanim ~= nil and objectanim ~= o.oAnimations then
        o.oAnimations = objectanim
        obj_init_animation(o,animindex)
    elseif objectanim ~= nil and o.header.gfx.animInfo.animID ~= animindex then
        obj_init_animation(o,animindex)
    else
        return
    end
end

--- @param o Object
--this is the loop for the possessed object
function bhv_kirbypossessmodel_loop(o)
    local playerindex = network_local_index_from_global(o.oKirbyProjectileOwner)
    local m = gMarioStates[playerindex]
    animcheck(o,playerindex)
    obj_set_pos_relative(o,m.marioObj,0,0,0 )
    obj_set_face_angle(o,m.marioObj.oFaceAnglePitch,m.marioObj.oFaceAngleYaw,m.marioObj.oFaceAngleRoll)
    if (gPlayerSyncTable[playerindex].livingprojectile == true) or (gPlayerSyncTable[playerindex].grabbedby ~= gNetworkPlayers[playerindex].globalIndex) then
        cur_obj_disable_rendering()
    else
        cur_obj_enable_rendering()
    end
    if (gPlayerSyncTable[playerindex].kirbypossess == 0) or (possessingtable[playerindex] ~= true) or ((gNetworkPlayers[playerindex].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[playerindex].currAreaIndex ~= gNetworkPlayers[0].currAreaIndex)) or (gNetworkPlayers[playerindex].currCourseNum ~= gNetworkPlayers[0].currCourseNum) then
        obj_mark_for_deletion(o)
    end
end

--- @param o Object
--this is the loop for a kirby explosion
function bhv_kirbyexplosion_loop(o)
    cur_obj_enable_rendering()
    cur_obj_become_tangible()
    object_step()
    bhv_explosion_loop()
    kirbyprojectileattack(o)
end


--- @param obj Object
--this is the function is used for custom kirby objects hurting enemies
function kirbyprojectileattack(obj)
    local hurtenemy = false
    local enemyobj
    local childobj
    local hitobj = false
    local enemyhitboxoverlap
    --[[ local colsurface = (collision_find_surface_on_ray(obj.oPosX,obj.oPosY,obj.oPosZ,obj.oVelX,obj.oVelY,obj.oVelZ))
    local wallobj --the projectile collided with this object's collision model
    if (colsurface ~= nil) and (colsurface.surface ~= nil) and (colsurface.surface.object ~= nil) then
        wallobj = colsurface.surface.object
    end ]]
    for key,value in pairs(projectilehurtableenemy)do
        
        enemyobj = obj_get_nearest_object_with_behavior_id(obj,key)
        if enemyobj ~= nil then
            if (projectilehurtableenemycustomcollision[key] ~= nil) then
                enemyhitboxoverlap = projectilehurtableenemycustomcollision[key](enemyobj,obj)
            else
                enemyhitboxoverlap = obj_check_hitbox_overlap(obj, enemyobj)
            end
        else
            enemyhitboxoverlap = false
        end
        if enemyhitboxoverlap then
            hurtenemy = true
            if (projectilehurtableenemy[key] == "custom") and (projectilefunctions[key] ~= nil) then --call an external function to determine interaction
                local customfunc = projectilefunctions[key]
                if customfunc ~= nil then
                    hurtenemy = customfunc(enemyobj,obj)--enemyobj being hit by kirby projectile and obj the kirby projectile
                end
            elseif projectilehurtableenemy[key] == "generic_attack" then
                enemyobj.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
            elseif projectilehurtableenemy[key] == "ground_pound" then
                enemyobj.oInteractStatus =  ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
            elseif projectilehurtableenemy[key] == "id_bhvChuckya" and (abs_angle_diff( (obj_angle_to_object(enemyobj,obj)), enemyobj.oFaceAngleYaw) > 0x3000) then
                if (obj_has_behavior_id(obj,id_bhvkirbyflame) ~= 0 ) and (abs_angle_diff( (obj_angle_to_object(enemyobj,gMarioStates[network_local_index_from_global(obj.oKirbyProjectileOwner)].marioObj)), enemyobj.oFaceAngleYaw) <= 0x3000) then

                else
                    enemyobj.oInteractStatus = enemyobj.oInteractStatus & ~INT_STATUS_GRABBED_MARIO
                    enemyobj.usingObj = nil
                    enemyobj.oAction = 2
                    enemyobj.oMoveFlags = enemyobj.oMoveFlags & OBJ_MOVE_LANDED
                end
            elseif projectilehurtableenemy[key] == "id_bhvKingBobomb" and (enemyobj.oAction ~= 0 and enemyobj.oAction ~= 4 and enemyobj.oAction ~= 5 and enemyobj.oAction ~= 6 and enemyobj.oAction ~= 7 and enemyobj.oAction ~= 8) and (abs_angle_diff( (obj_angle_to_object(enemyobj,obj)), enemyobj.oFaceAngleYaw) > 0x3000) then
                if ((obj_has_behavior_id(obj,id_bhvkirbyairbullet) == 0) and (obj_has_behavior_id(obj,id_bhvkirbyflame) == 0 )) or (  (obj_has_behavior_id(obj,id_bhvkirbyflame) ~= 0 ) and (abs_angle_diff( (obj_angle_to_object(enemyobj,gMarioStates[network_local_index_from_global(obj.oKirbyProjectileOwner)].marioObj)), enemyobj.oFaceAngleYaw) > 0x3000)) then
                    enemyobj.oInteractStatus = enemyobj.oInteractStatus & ~INT_STATUS_GRABBED_MARIO
                    enemyobj.usingObj = nil
                    enemyobj.oPosY = enemyobj.oPosY + 20
                    enemyobj.oVelY = 50
                    enemyobj.oForwardVel = 20
                    enemyobj.oAction = 4
                end
            elseif projectilehurtableenemy[key] == "id_bhvBowser" and(enemyobj.oAction ~= 0 and enemyobj.oAction ~= 4 and enemyobj.oAction ~= 5 and enemyobj.oAction ~= 6 and enemyobj.oAction ~= 12 and enemyobj.oAction ~= 20 )  then
                childobj = obj_get_nearest_object_with_behavior_id(obj,id_bhvBowserTailAnchor)
                if (obj_has_behavior_id(obj,id_bhvkirbyairbullet) ~= 0 ) then
                    hurtenemy = true
                elseif  childobj ~= nil and obj_check_hitbox_overlap(obj, childobj) or childobj == nil then
                    if (obj_has_behavior_id(obj,id_bhvkirbyflame) ~= 0 ) and (abs_angle_diff( (obj_angle_to_object(enemyobj,gMarioStates[network_local_index_from_global(obj.oKirbyProjectileOwner)].marioObj)), enemyobj.oFaceAngleYaw) <= 0x3000) then

                    else
                        enemyobj.oHealth = enemyobj.oHealth - 1
                        if enemyobj.oHealth  <= 0 then
                            enemyobj.oMoveAngleYaw = enemyobj.oBowserAngleToCentre + 0x8000
                            enemyobj.oAction = 4
                            spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,enemyobj.oPosX,enemyobj.oPosY,enemyobj.oPosZ,function(newobj)
                                newobj.parentObj = enemyobj
                            end)
                        else
                            enemyobj.oAction = 12
                        end
                    end
                elseif (abs_angle_diff( (obj_angle_to_object(enemyobj,obj)), enemyobj.oFaceAngleYaw) > 0x3000) then
                    hurtenemy = false
                end
            elseif projectilehurtableenemy[key] == "id_bhvEyerokHand" and (enemyobj.oAction == EYEROK_HAND_ACT_SHOW_EYE) and (abs_angle_diff( (obj_angle_to_object(enemyobj,obj)), enemyobj.oFaceAngleYaw) < 0x3000) then
                if (obj_has_behavior_id(obj,id_bhvkirbyairbullet) == 0 ) then
                    enemyobj.oHealth = enemyobj.oHealth - 1
                    cur_obj_play_sound_2(SOUND_OBJ2_EYEROK_SOUND_SHORT)
                    if (enemyobj.oHealth >= 2 )then
                        enemyobj.oAction = EYEROK_HAND_ACT_ATTACKED
                        enemyobj.oVelY = 30.0
                    else 
                        enemyobj.parentObj.oEyerokBossNumHands = enemyobj.parentObj.oEyerokBossNumHands - 1
                        enemyobj.oAction = EYEROK_HAND_ACT_DIE
                        enemyobj.oVelY = 50.0
                    end
                    enemyobj.oForwardVel = enemyobj.oForwardVel * 0.2
                    enemyobj.oMoveAngleYaw = enemyobj.oFaceAngleYaw + 0x8000
                    enemyobj.oMoveFlags = 0
                    enemyobj.oGravity = -4.0
                    enemyobj.oAnimState = 3
                end
            elseif projectilehurtableenemy[key] == "id_bhvWigglerHead" and (enemyobj.oAction == WIGGLER_ACT_WALK) and enemyobj.oWigglerTextStatus >= WIGGLER_TEXT_STATUS_COMPLETED_DIALOG and (enemyobj.oTimer >= 60) then
                if (obj_has_behavior_id(obj,id_bhvkirbyairbullet) == 0 ) then
                    cur_obj_play_sound_2(SOUND_OBJ_WIGGLER_ATTACKED)
                    enemyobj.oAction = WIGGLER_ACT_JUMPED_ON
                    enemyobj.oForwardVel = 0.0
                    enemyobj.oVelY = 0.0
                    enemyobj.oWigglerSquishSpeed = 0.4
                end
            elseif projectilehurtableenemy[key] == "id_bhvFirePiranhaPlant"  then
                if (enemyobj.oAction == FIRE_PIRANHA_PLANT_ACT_GROW) then
                    enemyobj.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
                else
                    hurtenemy = false
                end
            elseif projectilehurtableenemy[key] == "id_bhvMips" and (enemyobj.oMipsStarStatus == MIPS_STAR_STATUS_HAVENT_SPAWNED_STAR or enemyobj.oMipsStarStatus == MIPS_STAR_STATUS_SHOULD_SPAWN_STAR) then
                bhv_spawn_star_no_level_exit(enemyobj, enemyobj.oBehParams2ndByte + 3, bool_to_num[true])
                obj_init_animation(enemyobj,0)
                enemyobj.oAction = MIPS_ACT_IDLE
                enemyobj.oMipsStarStatus = MIPS_STAR_STATUS_ALREADY_SPAWNED_STAR
            elseif projectilehurtableenemy[key] == "id_bhvSmallBully" then
                if (enemyobj.oBehParams2ndByte == BULLY_BP_SIZE_SMALL) then
                    cur_obj_play_sound_2(SOUND_OBJ2_BULLY_ATTACKED)
                else
                    cur_obj_play_sound_2(SOUND_OBJ2_LARGE_BULLY_ATTACKED)
                end
                enemyobj.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
			    enemyobj.oAction = BULLY_ACT_KNOCKBACK
			    enemyobj.oFlags = enemyobj.oFlags & ~0x8
			    enemyobj.oMoveAngleYaw = obj.oFaceAngleYaw
			    enemyobj.oForwardVel = 3392 / enemyobj.hitboxRadius
			    enemyobj.oBullyMarioCollisionAngle = enemyobj.oMoveAngleYaw
		    	enemyobj.oBullyLastNetworkPlayerIndex = network_global_index_from_local(nearest_possible_mario_state_to_object(enemyobj).playerIndex)
			elseif projectilehurtableenemy[key] == "id_bhvExclamationBox" then
                if (enemyobj.oAction ~= 2) then
                    hurtenemy = false
                else
                    enemyobj.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
                end
            elseif projectilehurtableenemy[key] == "id_bhvBobomb" then
                enemyobj.oAction = BOBOMB_ACT_EXPLODE
            elseif projectilehurtableenemy[key] == "id_bhvBlueCoinSwitch" and (enemyobj.oAction == 0) then
                cur_obj_play_sound_2(SOUND_GENERAL_SWITCH_DOOR_OPEN)
                enemyobj.oAction = enemyobj.oAction + 1
                enemyobj.oVelY = -20.0
                enemyobj.oGravity = 0.0
            elseif projectilehurtableenemy[key] == "id_bhvHiddenObject" and (enemyobj.oAction == 1) and (enemyobj.oBehParams2ndByte == 0) then
                enemyobj.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
            elseif projectilehurtableenemy[key] == "id_bhvWhompKingBoss" then
                if (enemyobj.oAction == 6) and (enemyobj.oSubAction < 10) then
                    enemyobj.oHealth = enemyobj.oHealth - 1
                    if enemyobj.oHealth <= 0 then
                        enemyobj.oAction = 8
                    else
                        enemyobj.oSubAction = 10
                        cur_obj_play_sound_2(SOUND_OBJ2_WHOMP_SOUND_SHORT)
                        cur_obj_play_sound_2(SOUND_OBJ_KING_WHOMP_DEATH)
                    end

                end
            elseif projectilehurtableenemy[key] == "id_bhvSmallWhomp" then
                if (enemyobj.oAction == 6) and (enemyobj.oSubAction < 10) then
                    enemyobj.oNumLootCoins = 5
                    obj_spawn_loot_yellow_coins(enemyobj, 5, 20.0)
                    enemyobj.oAction = 8
                end
            elseif projectilehurtableenemy[key] == "id_bhvThiTinyIslandTop" then
                if (enemyobj.oAction == 0) then
                    enemyobj.oAction = 1
                    spawn_triangle_break_particles(20, 138, 0.3, 3)
                    cur_obj_play_sound_2(SOUND_GENERAL_ACTIVATE_CAP_SWITCH)
                    enemyobj.header.gfx.node.flags = enemyobj.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
                    network_send_object(enemyobj,true)
                else
                    hurtenemy = false
                end
            elseif projectilehurtableenemy[key] =="id_bhvKickableBoard" then
                if (enemyobj.oAction == 0) then
                    enemyobj.oKickableBoardF8 = 1600
                    enemyobj.oKickableBoardF4 = 0
                    enemyobj.oAction = 1
                elseif (enemyobj.oAction == 1) and (enemyobj.oTimer) then
                    if obj.oPosY > (enemyobj.oPosY + 160.0) then
                        enemyobj.oAction = 2
                        cur_obj_play_sound_2(SOUND_GENERAL_BUTTON_PRESS_2)
                    else
                        enemyobj.oTimer = 0
                    end
                end

            elseif projectilehurtableenemy[key] == "id_bhvBoo" then
                if enemyobj.oInteractType == 0 then --can't hurt boo when its hiding
                    hurtenemy = false
                else
                    enemyobj.oInteractStatus =  ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
                end
            elseif projectilehurtableenemy[key] =="id_bhvWaterLevelPillar" then
                if (enemyobj.oWaterLevelPillarDrained == 0) and (enemyobj.oAction == 0) then --when the moat isn't drained and the pillar wasn't pounded by mario
                    enemyobj.oAction = 1
                    spawn_mist_particles()
                    network_send_object(enemyobj,true)
                else
                    hurtenemy = false
                end
            end
            if hitobj == false and hurtenemy == true then
                hitobj = true
            end
        end
    end
    return hitobj
end


---@param m MarioState
--Called once per player per frame at the end of a mario update
local function mario_update(m)
    local owner = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    local escapegrab
    local o
    local otherowner
    if m.playerIndex ~= 0 then
        if m.action == ACT_GRABBED and (gPlayerSyncTable[m.playerIndex].grabbedby ~= gNetworkPlayers[m.playerIndex].globalIndex) and gPlayerSyncTable[m.playerIndex].inhaleescape > 0 then
            otherowner = network_local_index_from_global(gNetworkPlayers[m.playerIndex].globalIndex)
            obj_set_pos_relative(m.marioObj,gMarioStates[otherowner].marioObj,0,260,64 )
            m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE --make mario's model invisible
        elseif gPlayerSyncTable[m.playerIndex].livingprojectile == true then
            m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE --make mario's model invisible
        elseif (m.prevAction == ACT_GRABBED or m.prevAction == ACT_KIRBY_LIVING_PROJECTILE) and (m.marioObj.header.gfx.node.flags & GRAPH_RENDER_ACTIVE ~= true) then
            m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE --make mario's model visible
        end

        if inhalingtable[m.playerIndex] == true and ((gPlayerSyncTable[m.playerIndex].inhaling ~= true) or ( (gNetworkPlayers[0].currActNum ~= gNetworkPlayers[m.playerIndex].currActNum) or (gNetworkPlayers[0].currAreaIndex ~= gNetworkPlayers[m.playerIndex].currAreaIndex) or (gNetworkPlayers[0].currLevelNum ~= gNetworkPlayers[m.playerIndex].currLevelNum) )) then
            inhalingtable[m.playerIndex] = false
        elseif (instarselect == false) and inhalingtable[m.playerIndex] ~= true and (gPlayerSyncTable[m.playerIndex].inhaling == true) and ( (gNetworkPlayers[0].currActNum == gNetworkPlayers[m.playerIndex].currActNum) and (gNetworkPlayers[0].currAreaIndex == gNetworkPlayers[m.playerIndex].currAreaIndex) and (gNetworkPlayers[0].currLevelNum == gNetworkPlayers[m.playerIndex].currLevelNum) )then
            
            if spawn_non_sync_object(id_bhvkirbyinhalehitbox, E_MODEL_NONE, m.pos.x, m.pos.y, m.pos.z,function(obj)
                    obj.oKirbyProjectileOwner = gNetworkPlayers[m.playerIndex].globalIndex
                end) ~= nil then
                inhalingtable[m.playerIndex] = true
            end
        end
        if (possessingtable[m.playerIndex] == true) and ((gPlayerSyncTable[m.playerIndex].kirbypossess == 0) or ( (gNetworkPlayers[0].currActNum ~= gNetworkPlayers[m.playerIndex].currActNum) or (gNetworkPlayers[0].currAreaIndex ~= gNetworkPlayers[m.playerIndex].currAreaIndex) or (gNetworkPlayers[0].currLevelNum ~= gNetworkPlayers[m.playerIndex].currLevelNum) )) then
            possessingtable[m.playerIndex] = false
        elseif (instarselect == false) and possessingtable[m.playerIndex] ~= true and ((gPlayerSyncTable[m.playerIndex].kirbypossess ~= 0) and (type(gPlayerSyncTable[m.playerIndex].possessedmodelId) ~= "nil")) and ( (gNetworkPlayers[0].currActNum == gNetworkPlayers[m.playerIndex].currActNum) and (gNetworkPlayers[0].currAreaIndex == gNetworkPlayers[m.playerIndex].currAreaIndex) and (gNetworkPlayers[0].currLevelNum == gNetworkPlayers[m.playerIndex].currLevelNum) )then
            possessingtable[m.playerIndex] = true
            spawn_non_sync_object(id_bhvkirbypossessmodel, gPlayerSyncTable[m.playerIndex].possessedmodelId, m.pos.x, m.pos.y, m.pos.z,function(obj)
                obj.oKirbyProjectileOwner = gNetworkPlayers[m.playerIndex].globalIndex
            end)
        end
        if (gPlayerSyncTable[m.playerIndex].kirby ~= false) then
            kirbyvoicesnore(m)
        end
        return
    elseif (gPlayerSyncTable[0].kirby == false) or ((owner > 0) and ((m.action == ACT_GRABBED) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.warp_to_owner) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.held_owner_left) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.finish_warp))) then
        if (m.action == ACT_GRABBED and m.heldByObj ~= nil and obj_has_behavior_id(m.heldByObj, id_bhvkirbyinhalehitbox) ~= 0) or (owner > 0 and (m.heldByObj == nil) and ((gPlayerSyncTable[owner].inhaledplayer == inhaledtable.warp_to_owner) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.finish_warp))) then
            if (m.heldByObj ~= nil) then
                m.pos.x = m.heldByObj.oPosX
                m.pos.y = m.heldByObj.oPosY
                m.pos.z = m.heldByObj.oPosZ
                m.intendedYaw = gMarioStates[owner].intendedYaw
                m.faceAngle.x = gMarioStates[owner].faceAngle.x
                m.faceAngle.y = gMarioStates[owner].faceAngle.y
                m.faceAngle.z = gMarioStates[owner].faceAngle.z
                obj_set_gfx_pos_at_obj_pos(m.marioObj,m.heldByObj)
                escapegrab = player_performed_grab_escape_action()
                if escapegrab then
                    gPlayerSyncTable[0].inhaleescape = gPlayerSyncTable[0].inhaleescape + escapegrab
                end
            end
            if (m.heldByObj ~= nil) and gPlayerSyncTable[owner].inhaledplayer == inhaledtable.warp_to_owner and (instarselect == false) then
                if ( (gNetworkPlayers[0].currActNum ~= gNetworkPlayers[owner].currActNum) or (gNetworkPlayers[0].currAreaIndex ~= gNetworkPlayers[owner].currAreaIndex) or (gNetworkPlayers[0].currLevelNum ~= gNetworkPlayers[owner].currLevelNum) ) then
                    m.heldByObj.oInteractStatus = m.heldByObj.oInteractStatus  &~(INT_STATUS_GRABBED_MARIO)
                    m.heldByObj.usingObj = nil
                    o = m.heldByObj
                    --[[ if((m.interactObj == nil and m.usedObj == nil) or (m.interactObj ~= nil and m.interactObj.oInteractType ~= INTERACT_WARP) or (m.usedObj ~= nil and m.usedObj.oInteractType ~= INTERACT_WARP)) and o ~= nil then
                        network_send_object(o, true)
                    end ]]
                    m.heldByObj = nil
                    warp_to_level(gNetworkPlayers[owner].currLevelNum, gNetworkPlayers[owner].currAreaIndex, gNetworkPlayers[owner].currActNum)
                end
            elseif (m.heldByObj == nil) and gPlayerSyncTable[owner].inhaledplayer == inhaledtable.warp_to_owner and (instarselect == false) then
                if ( (gNetworkPlayers[0].currActNum ~= gNetworkPlayers[owner].currActNum) or (gNetworkPlayers[0].currAreaIndex ~= gNetworkPlayers[owner].currAreaIndex) or (gNetworkPlayers[0].currLevelNum ~= gNetworkPlayers[owner].currLevelNum) ) then
                    warp_to_level(gNetworkPlayers[owner].currLevelNum, gNetworkPlayers[owner].currAreaIndex, gNetworkPlayers[owner].currActNum)
                else
                    gPlayerSyncTable[owner].inhaledplayer = inhaledtable.finish_warp
                end
            elseif (m.heldByObj == nil) and gPlayerSyncTable[owner].inhaledplayer == inhaledtable.finish_warp then
                if (instarselect == false) and ( (gNetworkPlayers[owner].currActNum == gNetworkPlayers[0].currActNum) and (gNetworkPlayers[owner].currAreaIndex == gNetworkPlayers[0].currAreaIndex) and (gNetworkPlayers[owner].currLevelNum == gNetworkPlayers[0].currLevelNum)) then
                    o = spawn_non_sync_object(id_bhvkirbyinhalehitbox, E_MODEL_NONE, gMarioStates[owner].pos.x, gMarioStates[owner].pos.y, gMarioStates[owner].pos.z,function(obj)
                            obj.oKirbyProjectileOwner = gNetworkPlayers[owner].globalIndex
                            obj.oInteractStatus = INT_STATUS_GRABBED_MARIO | INT_STATUS_INTERACTED
                            obj.usingObj = m.marioObj
                    end)

                    if o ~= nil then
                        m.usedObj = o
                        m.interactObj = o
                        m.heldByObj = o
                        m.pos.x = m.usedObj.oPosX
                        m.pos.y = m.usedObj.oPosY
                        m.pos.z = m.usedObj.oPosZ
                        set_mario_action(m,ACT_GRABBED,0)
                        gPlayerSyncTable[owner].inhaledplayer = inhaledtable.held_held
                    else
                        gPlayerSyncTable[owner].inhaledplayer = inhaledtable.held_none
                        gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
                    end
                elseif (instarselect == false) and (gNetworkPlayers[owner].connected ~= true)then
                    gPlayerSyncTable[owner].inhaledplayer = inhaledtable.held_none
                    gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
                end
            end
        end
        if (m.action == ACT_DISAPPEARED or m.action == ACT_BBH_ENTER_SPIN) and (obj_get_first_with_behavior_id(id_bhvActSelector)~= 0) then
            instarselect = true
        else
            instarselect = false
            if gPlayerSyncTable[owner].inhaledplayer == inhaledtable.held_owner_left then
                gPlayerSyncTable[owner].inhaledplayer = inhaledtable.warp_to_owner
            end
        end
        if gPlayerSyncTable[0].gaincoin ~= 0 then --adding coins to current player's coin count if their gaincoin field > 0
            if (course_is_main_course(gNetworkPlayers[0].currCourseNum)) and (m.numCoins < gLevelValues.coinsRequiredForCoinStar) and ((m.numCoins + gPlayerSyncTable[0].gaincoin) >= gLevelValues.coinsRequiredForCoinStar)then
                bhv_spawn_star_no_level_exit(m.marioObj, 6, bool_to_num[false])
            end
            m.numCoins = m.numCoins + gPlayerSyncTable[0].gaincoin
            gPlayerSyncTable[0].gaincoin = 0
            gPlayerSyncTable[0].numCoins = m.numCoins
            hud_set_value(HUD_DISPLAY_COINS, m.numCoins)
        end
        return
    end

    if (possessingtable[0] == true) and (gPlayerSyncTable[0].kirbypossess == 0) then
        possessingtable[0] = false
    elseif (instarselect == false) and possessingtable[0] ~= true and (gPlayerSyncTable[0].kirbypossess ~= 0) then
        possessingtable[0] = true
        spawn_non_sync_object(id_bhvkirbypossessmodel, gPlayerSyncTable[0].possessedmodelId, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = gNetworkPlayers[0].globalIndex
        end)
    end

    if (m.action == ACT_DISAPPEARED or m.action == ACT_BBH_ENTER_SPIN) and (obj_get_first_with_behavior_id(id_bhvActSelector)~= 0) then
        instarselect = true
    else
        instarselect = false
    end
    if (gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held) and (m.hurtCounter <= 0) then
        if m.action == ACT_JUMP then
            set_mario_action(m,ACT_HOLD_JUMP,0)
        elseif m.action  == ACT_FREEFALL then
            set_mario_action(m,ACT_HOLD_FREEFALL,0)
        elseif m.action  == ACT_WALKING then
            set_mario_action(m,ACT_HOLD_WALKING,0)
        elseif m.action  == ACT_BEGIN_SLIDING then
            set_mario_action(m,ACT_HOLD_BEGIN_SLIDING,0)
        elseif m.action  == ACT_BUTT_SLIDE then
            set_mario_action(m,ACT_HOLD_BUTT_SLIDE,0)
        elseif m.action  == ACT_BUTT_SLIDE_AIR then
            set_mario_action(m,ACT_HOLD_BUTT_SLIDE_AIR,0)
        elseif m.action  == ACT_DECELERATING then
            set_mario_action(m,ACT_HOLD_DECELERATING,0)
        end
    elseif (gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_none) and (m.heldObj == nil) then
        if m.action == ACT_HOLD_JUMP then
            set_mario_action(m,ACT_JUMP,0)
        elseif m.action  == ACT_HOLD_FREEFALL then
            set_mario_action(m,ACT_FREEFALL,0)
        elseif m.action  == ACT_HOLD_WALKING then
            set_mario_action(m,ACT_WALKING,0)
        elseif m.action  == ACT_HOLD_BEGIN_SLIDING then
            set_mario_action(m,ACT_BEGIN_SLIDING,0)
        elseif m.action  == ACT_HOLD_BUTT_SLIDE then
            set_mario_action(m,ACT_BUTT_SLIDE,0)
        elseif m.action  == ACT_HOLD_BUTT_SLIDE_AIR then
            set_mario_action(m,ACT_BUTT_SLIDE_AIR,0)
        elseif m.action  == ACT_HOLD_DECELERATING then
            set_mario_action(m,ACT_DECELERATING,0)
        end
    end
    if m.capTimer == 0 then
        kirbyhasvanish = false
        kirbyhaswing = false
    end
    if kirbyissuper then
        if (m.flags &  MARIO_WING_CAP) == 0 then
            m.flags = m.flags | MARIO_WING_CAP
        end
    end

    if gPlayerSyncTable[0].kirbypossess == 0 then
        if m.prevAction == ACT_KIRBY_JUMP and (m.actionTimer < 5) then
            m.marioObj.header.gfx.scale.y = 1.5
            m.marioObj.header.gfx.scale.z = 1.5
            m.marioObj.header.gfx.scale.x = 1.5
            m.actionTimer = m.actionTimer + 1
        elseif m.prevAction == ACT_KIRBY_JUMP then
            m.marioObj.header.gfx.scale.y = 1.25
            m.marioObj.header.gfx.scale.z = 1.25
            m.marioObj.header.gfx.scale.x = 1.25
        else
            m.marioObj.header.gfx.scale.y = 1
            m.marioObj.header.gfx.scale.z = 1
            m.marioObj.header.gfx.scale.x = 1
        end
    end


    if m.hurtCounter <= 0 then
        gPlayerSyncTable[0].losingability = false
    end

    if m.collidedObjInteractTypes == INTERACT_TEXT or m.action == ACT_READING_NPC_DIALOG then

    elseif (gPlayerSyncTable[0].kirbypower ~= kirbyability_none) and ( ( (m.controller.buttonPressed & swallowbutton1) ~= 0) and ( (m.controller.buttonPressed & swallowbutton2) ~= 0) )  and m.heldObj == nil and kirbyabilitymovelist[m.action] == nil then
            kirbypowerrelease(m)
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_none) then
        if  (( (m.controller.buttonPressed & swallowbutton1) ~= 0) and ( (m.controller.buttonPressed & swallowbutton2) ~= 0)) and m.heldObj ~= nil then
            gPlayerSyncTable[0].kirbypower = kirbyswallow(m.heldObj)
            if gPlayerSyncTable[0].kirbypower == 0 then
                gPlayerSyncTable[0].kirbypower = kirbyability_none
            end

            if (m.action & ACT_FLAG_AIR) ~= 0 then
                drop_and_set_mario_action(m, ACT_FREEFALL, 0)
            elseif (m.action & ACT_FLAG_WATER_OR_TEXT) ~= 0 then
                drop_and_set_mario_action(m, ACT_WATER_IDLE, 0)
            elseif (m.action & ACT_FLAG_AIR) == 0 then
                drop_and_set_mario_action(m, ACT_IDLE, 0)
            end
        elseif gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then        
            if (( (m.controller.buttonPressed & swallowbutton1) ~= 0) and ( (m.controller.buttonPressed & swallowbutton2) ~= 0)) and m.heldObj == nil then
                gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_swallow
                if (m.action & ACT_FLAG_AIR) ~= 0 then
                    drop_and_set_mario_action(m, ACT_FREEFALL, 0)
                elseif (m.action & ACT_FLAG_WATER_OR_TEXT) ~= 0 then
                    drop_and_set_mario_action(m, ACT_WATER_IDLE, 0)
                elseif (m.action & ACT_FLAG_AIR) == 0 then
                    drop_and_set_mario_action(m, ACT_IDLE, 0)
                end
            elseif (m.controller.buttonPressed & Z_TRIG) ~= 0 then
                gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                mario_drop_held_object(m) 
            end
        end
    end

    if m.pos.y == m.floorHeight then
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        gPlayerSyncTable[0].canexhale = false
        kirbyfloattime = kirbymaxfloattime
    end

    if m.action == ACT_FLYING and gPlayerSyncTable[0].kirbypower ~= kirbyability_wing then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.action == ACT_JUMP or m.action == ACT_STEEP_JUMP or m.action == ACT_TOP_OF_POLE_JUMP  or m.action == ACT_SIDE_FLIP or ((m.action == ACT_WALL_KICK_AIR) and ((m.prevAction == ACT_HOLDING_POLE) or (m.prevAction == ACT_CLIMBING_POLE))))and m.vel.y < 0 then
        set_mario_action(m, ACT_FREEFALL, 0)

    elseif m.action == ACT_WATER_JUMP and m.vel.y < 0 then
        set_camera_mode(m.area.camera, m.area.camera.defMode, 1)
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        kirbyfloattime = kirbymaxfloattime
        gPlayerSyncTable[0].canexhale = false
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif ((m.action == ACT_FREEFALL and (m.controller.buttonPressed & A_BUTTON) ~= 0) or (m.action == ACT_LONG_JUMP and (m.controller.buttonPressed & B_BUTTON) ~= 0) ) and gPlayerSyncTable[0].kirbyjumps > 0  then
       if gPlayerSyncTable[0].kirbypower == kirbyability_wing then
            set_mario_action(m, ACT_KIRBY_WING_FLAP, 0)
       else
            set_mario_action(m, ACT_KIRBY_JUMP, 0)
       end

    end

    kirbyvoicesnore(m)

    if gPlayerSyncTable[0].gaincoin ~= 0 then --adding coins to current player's coin count if their gaincoin field > 0
        if (course_is_main_course(gNetworkPlayers[0].currCourseNum)) and (m.numCoins < gLevelValues.coinsRequiredForCoinStar) and ((m.numCoins + gPlayerSyncTable[0].gaincoin) >= gLevelValues.coinsRequiredForCoinStar)then
            bhv_spawn_star_no_level_exit(m.marioObj, 6, bool_to_num[false])
        end
		m.numCoins = m.numCoins + gPlayerSyncTable[0].gaincoin
		gPlayerSyncTable[0].gaincoin = 0
		gPlayerSyncTable[0].numCoins = m.numCoins
		hud_set_value(HUD_DISPLAY_COINS, m.numCoins)
	end

end

--- @param o Object
--this function handles objects held by kirby that he tries to swallow
function kirbyswallow(o)
    local objdelete = kirbyenemydelete(o,INTERACT_GRABBABLE)
    local enemypower = 0
    if objdelete >= 2 then
        return kirbyability_none
    elseif  o.oKirbyAbilitytype ~= nil  then
        enemypower = o.oKirbyAbilitytype
    end

    if enemypower ~= 0 then --Here i give the kirby player any coins the swallowed enemy has before deleting it
        for i = 0,MAX_PLAYERS - 1,1 do
			if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
				gPlayerSyncTable[i].gaincoin = gPlayerSyncTable[i].gaincoin + o.oNumLootCoins
			end
		end
        if objdelete == bool_to_num[true] then
            obj_mark_for_deletion(o)
        end
        if o ~= nil then
            network_send_object(o, true)
        end
    end
    return enemypower
end

---@param m MarioState
--this function handles forming the ability stars kirby makes when he loses an ability
function kirbypowerrelease(m)
    if gPlayerSyncTable[0].kirbypossess == 0 then
        spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,m.pos.x, m.pos.y, m.pos.z,generateabilitystar)
        djui_chat_message_create('you dropped an ability')
        gPlayerSyncTable[0].kirbypower = kirbyability_none
        return
    else
        gPlayerSyncTable[0].kirbypossess = 0
        gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
        gPlayerSyncTable[0].possessedmodelId = nil
        if (m.action & ACT_FLAG_WATER_OR_TEXT) ~= 0 then
            set_mario_action(m, ACT_WATER_IDLE, 0)
        elseif m.pos.y ~= m.floorHeight then
            set_mario_action(m,ACT_FREEFALL,0)
        else
            set_mario_action(m,ACT_IDLE,0)
        end
        return
    end

end

--- @param obj Object
--this function sets the ability stored in an ability star
function generateabilitystar(obj)
    obj.oKirbyAbilitytype = gPlayerSyncTable[0].kirbypower
    obj.oVelY = math.random(30, 50)
	obj.oForwardVel = math.random(5, 10)
	obj.oMoveAngleYaw = math.random(0x0000, 0x10000)
    obj.oAction = 2
    obj.oIntangibleTimer = 2
end


--- @param obj Object
--this function sets what happens on boss death
function boss_death(obj)
    djui_chat_message_create('boss generating essence')
    local abilitytype = generatecopyessence(obj)
    spawn_sync_object(id_bhvcopyessence,E_MODEL_TRANSPARENT_STAR, obj.oPosX, obj.oPosY + 220, obj.oPosZ,function(newobj)
        newobj.oKirbyAbilitytype = abilitytype
    end)
end

--- @param obj Object
--this function sets the ability stored in a copy essence
function generatecopyessence(obj)
    local enemypower = 0
    if (obj_has_behavior_id(obj,id_bhvKingBobomb) ~= 0) then

        enemypower = kirbyability_bomb
        djui_chat_message_create('boss generated bomb ability essence')


    elseif (obj_has_behavior_id(obj,id_bhvBowser) ~= 0) then

        enemypower = kirbyability_fire
        djui_chat_message_create('boss generated fire ability essence')

    elseif (obj_has_behavior_id(obj,id_bhvWhompKingBoss) ~= 0) or (obj_has_behavior_id(obj,id_bhvEyerokBoss) ~= 0) then

        enemypower = kirbyability_stone
        djui_chat_message_create('boss generated stone ability essence')

    elseif (obj_has_behavior_id(obj,id_bhvWigglerHead) ~= 0) then

        enemypower = kirbyability_wrestler
        djui_chat_message_create('boss generated wrestler ability essence')
    end
    return enemypower
end


---@param m MarioState
--this is the function for bomb kirby's bomb jump
local function act_kirbybombjump(m)

    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    m.vel.y = 20
    if (m.flags &  MARIO_WING_CAP) ~= 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    else
        return set_mario_action(m, ACT_KIRBY_SPECIAL_FALL, 0)
    end
end

---@param m MarioState
--this is the function for wheel kirby rolling on the ground
local function act_kirbywheelroll(m)
    local maxspeed = 80
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,maxspeed)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_wheel)  then
        set_mario_action(m, ACT_DECELERATING, 0)
    elseif (m.controller.buttonPressed & A_BUTTON) ~= 0  then
            m.actionTimer = 0
           return set_mario_action(m, ACT_KIRBY_WHEEL_JUMP, 0)

    elseif (m.floor.type == SURFACE_BURNING) and (m.floorHeight == m.pos.y) and ((m.flags & MARIO_METAL_CAP) == 0) and (kirbyissuper == false) or (gPlayerSyncTable[0].kirbypower ~= kirbyability_wheel and m.floorHeight == m.pos.y)then
        set_mario_action(m, ACT_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then 
        set_mario_action(m, ACT_KIRBY_WHEEL_FALL, 0)
    elseif (ground_step == GROUND_STEP_HIT_WALL) then 
        set_mario_action(m, ACT_GROUND_BONK, 0)      
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for wheel kirby falling in wheel form
local function act_kirbywheelrollfall(m)
    local maxspeed = 80
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,maxspeed)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local air_step = perform_air_step(m,0)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_wheel) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
            set_mario_action(m, ACT_KIRBY_WHEEL_DOWNSHIFT, 0)
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        end 
    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_WHEEL_ROLL, 0)

    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for wheel kirby falling while downshifting in wheel form
local function act_kirbywheeldownshift(m)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,0)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local air_step = perform_air_step(m,0)
    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_wheel) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        end 
    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_LAND, 0)

    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for wheel kirby jumping in wheel form
local function act_kirbywheelrolljump(m)
    local maxspeed = 80
    if m.actionTimer == 0 then
        m.vel.y = 42 + m.forwardVel/4
    elseif (m.controller.buttonDown & A_BUTTON ~= 0) then
        m.vel.y = m.vel.y + 4.0
    end
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,maxspeed)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local air_step = perform_air_step(m,0)
    m.actionTimer = m.actionTimer + 1


    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_wheel) then
        set_mario_action(m, ACT_FREEFALL, 0)

    elseif ((m.floorHeight ~= m.pos.y) ) then
        set_mario_action(m, ACT_KIRBY_WHEEL_FALL, 0)  
    elseif (m.floorHeight ~= m.pos.y) then
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        end     
    end
end

---@param m MarioState
--this is the function for rock kirby falling in rock form
local function act_kirbyrockfall(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    m.actionState = 0
    if m.vel.y > -50 then
            m.vel.y = -50
    end
    local air_step = perform_air_step(m,0)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    elseif (air_step == AIR_STEP_LANDED) then
        set_mario_action(m, ACT_KIRBY_LAND_INVULNERABLE, 0)
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for rock kirby sliding in rock form
local function act_kirbyrocksliding(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    update_sliding(m,4.0)
    apply_landing_accel(m,0.99)
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) then
        set_mario_action(m, ACT_DECELERATING, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_ROCK_FALL, 0)
    elseif (m.forwardVel == 0) then 
        set_mario_action(m, ACT_KIRBY_ROCK_IDLE, 0)
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for rock kirby not moving in rock form
local function act_kirbyrockidle(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    update_sliding(m,4.0)
    apply_landing_accel(m,0.99)
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) then
        set_mario_action(m, ACT_DECELERATING, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_ROCK_FALL, 0)
    elseif (m.forwardVel ~= 0) then 
        set_mario_action(m, ACT_KIRBY_ROCK_SLIDING, 0)         
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for rock kirby falling in rock form underwater
local function act_kirbyrockwatersink(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    m.actionState = 0
    if m.vel.y > -50 then
            m.vel.y = -50
    end
    local water_step = perform_water_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) or (m.health == 0xff) then
        set_mario_action(m, ACT_WATER_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    elseif (water_step == WATER_STEP_HIT_FLOOR) then
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_SLIDING, 0)
    end
    if  ((m.flags & MARIO_METAL_CAP) == 0) and (m.healCounter == 0) and (m.hurtCounter == 0) then
        if (m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW then
            m.health = m.health - 3
        else
            m.health = m.health - 1
        end
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for rock kirby sliding in rock form underwater
local function act_kirbyrockwatersliding(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    update_sliding(m,4.0)
    apply_landing_accel(m,0.99)
    local water_step = perform_water_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) or (m.health == 0xff) then
        set_mario_action(m, ACT_WATER_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_SINK, 0)
    elseif (m.forwardVel == 0) then 
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_IDLE, 0)
    elseif water_step == WATER_STEP_NONE then
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_SLIDING, 0)
    end
    if  ((m.flags & MARIO_METAL_CAP) == 0) and (m.healCounter == 0) and (m.hurtCounter == 0) then
        if (m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW then
            m.health = m.health - 3
        else
            m.health = m.health - 1
        end
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for rock kirby not moving in rock form underwater
local function act_kirbyrockwateridle(m)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    update_sliding(m,4.0)
    apply_landing_accel(m,0.99)
    local water_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_stone) or (m.health == 0xff) then
        set_mario_action(m, ACT_WATER_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_SINK, 0)
    elseif (m.forwardVel ~= 0) then 
        set_mario_action(m, ACT_KIRBY_ROCK_WATER_SLIDING, 0)         
    end
    if  ((m.flags & MARIO_METAL_CAP) == 0) and (m.healCounter == 0) and (m.hurtCounter == 0) then
        if (m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW then
            m.health = m.health - 3
        else
            m.health = m.health - 1
        end
    end
    set_character_animation(m, CHAR_ANIM_STAR_DANCE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for needle kirby falling in needle form
local function act_kirbyneedlefall(m)

    local air_step = perform_air_step(m,0)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_needle) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif gPlayerSyncTable[0].kirbyjumps > 0 and (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        set_mario_action(m, ACT_KIRBY_JUMP, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        if air_step == AIR_STEP_HIT_WALL or m.wall ~= nil then
            m.vel.x = 0
            m.vel.y = 0
            m.vel.z = 0
        else
            m.vel.y = m.vel.y - 4.0
            if m.vel.y < -75.0 then
                m.vel.y = -75.0
            end
        end

    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_NEEDLE_SLIDING, 0)

    end
    set_character_animation(m, CHAR_ANIM_SLEEP_IDLE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for needle kirby sliding in needle form
local function act_kirbyneedlesliding(m)
    if m.wall == nil then
        update_sliding(m,4.0)
        apply_landing_accel(m,0.75)
    else
        m.vel.x = 0
        m.vel.y = 0
        m.vel.z = 0
    end
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_needle) then
        set_mario_action(m, ACT_DECELERATING, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_NEEDLE_FALL, 0)
    elseif (m.forwardVel == 0) and m.wall == nil then 
        set_mario_action(m, ACT_KIRBY_NEEDLE_IDLE, 0)    
    end
    set_character_animation(m, CHAR_ANIM_SLEEP_IDLE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for needle kirby not moving in needle form
local function act_kirbyneedleidle(m)
    if m.wall == nil then
        update_sliding(m,4.0)
        apply_landing_accel(m,0.75)
    else
        m.vel.x = 0
        m.vel.y = 0
        m.vel.z = 0
    end
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 or (gPlayerSyncTable[0].kirbypower ~= kirbyability_needle) then
        set_mario_action(m, ACT_DECELERATING, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_NEEDLE_FALL, 0)
    elseif (m.forwardVel ~= 0) then 
        set_mario_action(m, ACT_KIRBY_NEEDLE_SLIDING, 0)         
    end
    set_character_animation(m, CHAR_ANIM_SLEEP_IDLE)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for needle kirby using falling spine
local function act_kirbyneedlefallingspine(m)
    mario_set_forward_vel(m,0)
    local air_step = perform_air_step(m,0)

    if (m.floorHeight ~= m.pos.y) then
         m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
             m.vel.y = -75.0
        end

    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_LAND, 0)

    end
    set_character_animation(m, CHAR_ANIM_GROUND_POUND)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for needle kirby using falling spine on the ground
local function act_kirbyneedlefallingspineland(m)
    mario_set_forward_vel(m,0)
    local ground_step = perform_ground_step(m)

    if (m.controller.buttonDown & Z_TRIG == 0) or (gPlayerSyncTable[0].kirbypower ~= kirbyability_needle) then
        set_mario_action(m, ACT_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_NEEDLE_FALLING_SPINE, 0)         
    end
    set_character_animation(m, CHAR_ANIM_GROUND_POUND)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's midair jumps
local function act_kirbyjump(m)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    m.vel.y = 40
    if (m.playerIndex == 0) and (m.flags &  MARIO_WING_CAP) ~= 0 then
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        kirbyfloattime = kirbymaxfloattime
        gPlayerSyncTable[0].canexhale = true
    elseif (m.playerIndex == 0) then
        gPlayerSyncTable[0].kirbyjumps = gPlayerSyncTable[0].kirbyjumps - 1
        gPlayerSyncTable[0].canexhale = true
    end
    set_character_animation(m, CHAR_ANIM_DOUBLE_JUMP_RISE)
    set_mario_action(m, ACT_FREEFALL, 0)
end

---@param m MarioState
--this is the function for kirby's midair air gun attack
local function act_kirbyexhale(m)
    local np = gNetworkPlayers[m.playerIndex]
    update_air_with_turn(m)
    set_character_animation(m, CHAR_ANIM_AIR_KICK)
    gPlayerSyncTable[0].canexhale = false
    if m.actionTimer <= 20 then
        if m.actionTimer == 0 and m.playerIndex == 0 then
            spawn_sync_object(id_bhvkirbyairbullet,kirbymodeltable.airbullet,m.pos.x, m.pos.y,m.pos.z,function (obj)
                obj_set_pos_relative(obj,m.marioObj,0,10,0)
                obj.oKirbyProjectileOwner = np.globalIndex
                obj.oForwardVel = 40
            end)
        end
    elseif m.actionTimer > 20 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's inhale
local function act_kirbyinhale(m)
    spawn_non_sync_object(id_bhvSmallParticleSnow, E_MODEL_WHITE_PARTICLE_SMALL, m.pos.x, m.pos.y, m.pos.z,function(obj)
        obj_scale(obj, 1/2)
        obj_set_pos_relative(obj,m.marioObj,0,60,60)
    end)
    update_sliding(m,8.0)
    apply_landing_accel(m,0.9)
    perform_ground_step(m)
    if  (m.playerIndex == 0) and (m.actionTimer == 0) then
        gPlayerSyncTable[0].inhaling = true
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_none 
    end
    if m.playerIndex == 0 and (m.heldObj ~= nil or gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held) then
        set_mario_action(m, ACT_HOLD_IDLE, 0)
    elseif m.playerIndex == 0 and (m.controller.buttonDown & B_BUTTON == 0) and (m.framesSinceB > 20) then
        set_mario_action(m, ACT_IDLE, 0)
    elseif m.playerIndex == 0 and (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_INHALE_FALL, 1)

    end
    if mario_check_object_grab(m) ~= 0 then
        mario_grab_used_object(m)
    else
        local obj
        if (eatabletype0 ~= nil) and m.playerIndex == 0 then
            for key,value in pairs(eatabletype0)do
                obj = obj_get_nearest_object_with_behavior_id(m.marioObj,key)
                if obj ~= nil and ((nearest_mario_state_to_object(obj)).playerIndex == 0) and obj_check_hitbox_overlap(m.marioObj,obj) then

                    local objdelete = kirbyenemydelete(obj,0)
                    if ( objdelete == bool_to_num[true] or objdelete == bool_to_num[false] ) and (obj.oKirbyAbilitytype ~= 0 ) then
                        local abilitytype = obj.oKirbyAbilitytype
                        if objdelete == bool_to_num[true]then
                            obj_mark_for_deletion(obj)
                        end
                        if kirbynosync[get_id_from_behavior(obj.behavior)] ~= true then
                            network_send_object(obj, true)
                        end
                        m.interactObj =  spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,m.pos.x, m.pos.y, m.pos.z,function(obj)
                            obj.oKirbyAbilitytype = abilitytype
                            obj.oHeldState = HELD_HELD
                        end)
                        m.heldObj = m.interactObj
                        set_mario_action(m, ACT_HOLD_IDLE, 0)
                    end
                    break
                end
            end
        end
    end
    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1  
end

---@param m MarioState
--this is the function for kirby's inhale in the air
local function act_kirbyinhalefall(m)
    spawn_non_sync_object(id_bhvSmallParticleSnow, E_MODEL_WHITE_PARTICLE_SMALL, m.pos.x, m.pos.y, m.pos.z,function(obj)
        obj_scale(obj, 1/2)
        obj_set_pos_relative(obj,m.marioObj,0,60,60)
    end)
    if  (m.playerIndex == 0) and (m.actionTimer == 0) then
        gPlayerSyncTable[0].inhaling = true
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_none 
    end
    if m.playerIndex == 0 and (m.heldObj ~= nil or gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held) then
        set_mario_action(m, ACT_HOLD_FREEFALL, 0)
    elseif m.playerIndex == 0 and (m.controller.buttonDown & B_BUTTON == 0) and (m.framesSinceB > 20) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif m.playerIndex == 0 and (m.floorHeight == m.pos.y) then
        if should_begin_sliding(m) == true then
            set_mario_action(m, ACT_JUMP_LAND, 0)
        else
            set_mario_action(m, ACT_KIRBY_INHALE, 1)
        end
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    end
    perform_air_step(m,0)
    if mario_check_object_grab(m) ~= 0 then
        mario_grab_used_object(m)
    else
        local obj
        if (eatabletype0 ~= nil) and m.playerIndex == 0 then
            for key,value in pairs(eatabletype0)do
                obj = obj_get_nearest_object_with_behavior_id(m.marioObj,key)
                if obj ~= nil and ((nearest_mario_state_to_object(obj)).playerIndex == 0) and obj_check_hitbox_overlap(m.marioObj,obj) then

                    local objdelete = kirbyenemydelete(obj,0)
                    if ( objdelete == bool_to_num[true] or objdelete == bool_to_num[false] ) and (obj.oKirbyAbilitytype ~= 0 ) then
                        local abilitytype = obj.oKirbyAbilitytype
                        if objdelete == bool_to_num[true]then
                            obj_mark_for_deletion(obj)
                        end
                        if kirbynosync[get_id_from_behavior(obj.behavior)] ~= true then
                            network_send_object(obj, true)
                        end
                        m.interactObj =  spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,m.pos.x, m.pos.y, m.pos.z,function(obj)
                            obj.oKirbyAbilitytype = abilitytype
                            obj.oHeldState = HELD_HELD
                        end)
                        m.heldObj = m.interactObj
                        set_mario_action(m, ACT_HOLD_FREEFALL, 0)
                    end
                    break
                end
            end
        end
    end

    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for fire kirby's fire breath
local function act_kirbyfirebreath(m)
    local np = gNetworkPlayers[m.playerIndex]
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    if m.playerIndex ~= 0 then
        set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
        set_anim_to_frame(m, 30)
        mario_set_forward_vel(m,0)
        perform_ground_step(m)
        return
    end
    if (m.actionTimer == 0) and (m.actionArg == 0) and m.playerIndex == 0 then
        gPlayerSyncTable[0].breathingfire = true 
        spawn_sync_object(id_bhvkirbyflame, kirbymodeltable.kirbyflame, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
    end
    mario_set_forward_vel(m,0)
    perform_ground_step(m)
    if ((m.controller.buttonDown & B_BUTTON == 0) and (m.framesSinceB > 20)) or (gPlayerSyncTable[0].kirbypower ~= kirbyability_fire) then
        if m.playerIndex == 0 then
            gPlayerSyncTable[0].breathingfire = false
        end
        set_mario_action(m, ACT_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        return set_mario_action(m, ACT_KIRBY_FIRE_BREATH_FALL, 1)

    end
    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1  
end

---@param m MarioState
--this is the function for kirby's fire breath in the air
local function act_kirbyfirebreathfall(m)
    local np = gNetworkPlayers[m.playerIndex]
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    if m.playerIndex ~= 0 then
        set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
        set_anim_to_frame(m, 30)
        if (m.floorHeight ~= m.pos.y) then
            m.vel.y = m.vel.y - 4.0
            if m.vel.y < -75.0 then
                m.vel.y = -75.0
            end
        end
        perform_air_step(m,0)
        return
    end
    if m.actionTimer == 0 and m.actionArg == 0 and m.playerIndex == 0 then
        gPlayerSyncTable[0].breathingfire = true
        spawn_sync_object(id_bhvkirbyflame, kirbymodeltable.kirbyflame, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
    end
    if ((m.controller.buttonDown & B_BUTTON == 0) and (m.framesSinceB > 20)) or (gPlayerSyncTable[0].kirbypower ~= kirbyability_fire) then
        if m.playerIndex == 0 then
            gPlayerSyncTable[0].breathingfire = false
        end
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight == m.pos.y) then
        return set_mario_action(m, ACT_KIRBY_FIRE_BREATH, 1)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    end
    perform_air_step(m,0)
    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for kirby's fireball in the air
local function act_kirbyfireball(m)
    m.vel.y = 0
    local maxspeed = 40
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    mario_set_forward_vel(m,maxspeed)
    spawn_non_sync_object(id_bhvSparkle, E_MODEL_RED_FLAME, m.pos.x, m.pos.y, m.pos.z,function(obj)
        obj_scale(obj, 2)
    end)
    if (m.actionTimer > 15) and (m.floorHeight ~= m.pos.y) then
        if (m.flags &  MARIO_WING_CAP) ~= 0 then
            return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_KIRBY_SPECIAL_FALL, 0)
        end
    elseif (m.actionTimer > 15) and (m.floorHeight == m.pos.y) then
        set_mario_action(m, ACT_IDLE, 0)
    end
    if m.floorHeight == m.pos.y then
        perform_ground_step(m)
    else
        perform_air_step(m,0)
    end


    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for fire kirby falling doing a fireball spin
local function act_kirbyfireballspin(m)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,0)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local air_step = perform_air_step(m,0)
    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_fire) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, 0)
        end 
    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_LAND, 0)
         
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's fireball roll in the air
local function act_kirbyfireballroll(m)
    m.vel.y = 0
    local maxspeed = 80
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local step
    if m.actionTimer == 0 then
        mario_set_forward_vel(m,maxspeed)
    elseif m.forwardVel > 0 then
        mario_set_forward_vel(m,m.forwardVel - 2)
    end
    spawn_non_sync_object(id_bhvSparkle, E_MODEL_RED_FLAME, m.pos.x, m.pos.y, m.pos.z,function(obj)
        obj_scale(obj, 2)
    end)
    if ((m.controller.buttonDown & A_BUTTON) ~= 0) then
        return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL_JUMP, 0)
    elseif (m.forwardVel <= 0) and (m.floorHeight ~= m.pos.y) then
        return set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.forwardVel <= 0) and (m.floorHeight == m.pos.y) then
        return set_mario_action(m, ACT_IDLE, 0)
    end
    if m.floorHeight == m.pos.y then
        step = perform_ground_step(m)
        if (step == GROUND_STEP_HIT_WALL) then 
            return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, 0)
        end 
    else
        step = perform_air_step(m,0)
        if (step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (step == AIR_STEP_HIT_WALL) then 
            return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, 0)
        end 
    end


    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for kirby's fireball roll jumping
local function act_kirbyfireballrolljump(m)
    if m.actionTimer == 0 then
        m.vel.y = 42 + m.forwardVel/4
    end
    mario_set_forward_vel(m,m.forwardVel - 2)
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    local air_step = perform_air_step(m,0)
    m.actionTimer = m.actionTimer + 1


    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_fire) then
        set_mario_action(m, ACT_FREEFALL, 0)

    elseif ((m.floorHeight ~= m.pos.y) ) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, 0)
        end
    elseif (m.floorHeight == m.pos.y) and (m.vel.y < 0) then
        return set_mario_action(m, ACT_IDLE, 0)
    end
end

 ---@param m MarioState
--this is the function for kirby's fireball roll jumping
local function act_kirbyfireballclimb(m)
    if m.actionTimer == 0 then
        m.vel.y = m.forwardVel/2
        m.forwardVel = 0
    end
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    local air_step = perform_air_step(m,0)
    m.actionTimer = m.actionTimer + 1


    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_fire) then
        set_mario_action(m, ACT_FREEFALL, 0)

    elseif ((m.floorHeight ~= m.pos.y) ) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    elseif (m.floorHeight == m.pos.y) and (m.vel.y < 0) then
        return set_mario_action(m, ACT_IDLE, 0)
    end
end

---@param m MarioState
--this is the function for midair action endlag
local function act_kirbyspecialfall(m)

    local air_step = common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_GENERAL_FALL, AIR_STEP_CHECK_LEDGE_GRAB)

    if (m.floorHeight ~= m.pos.y) and m.actionTimer > 10 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    elseif m.actionTimer < 10 then
            spawn_non_sync_object(id_bhvSparkle, E_MODEL_SMOKE, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj_scale(obj, 2)
        end)
    end

    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's fireball in the air
local function act_kirbyghostdash(m)
    m.flags = m.flags | MARIO_VANISH_CAP
    m.vel.y = 0
    local maxspeed = 40
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    mario_set_forward_vel(m,maxspeed)
    if ((m.actionTimer > 8)) and (m.floorHeight ~= m.pos.y) then
        if (m.flags &  MARIO_WING_CAP) ~= 0 then
            return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_KIRBY_SPECIAL_FALL, 0)
        end
    elseif ((m.actionTimer > 8) ) and (m.floorHeight == m.pos.y) then
        set_mario_action(m, ACT_IDLE, 0)
    end
    if m.floorHeight == m.pos.y then
        perform_ground_step(m)
    else
        perform_air_step(m,0)
    end


    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for wing kirby's midair jumps
local function act_kirbywingflap(m)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    m.vel.y = 40
    if (m.playerIndex == 0) and (m.flags &  MARIO_WING_CAP) ~= 0 then
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        kirbyfloattime = kirbymaxfloattime
        gPlayerSyncTable[0].canexhale = true
    elseif (m.playerIndex == 0) then
        gPlayerSyncTable[0].kirbyjumps = gPlayerSyncTable[0].kirbyjumps - 1
        gPlayerSyncTable[0].canexhale = true
    end
    set_character_animation(m, CHAR_ANIM_DOUBLE_JUMP_RISE)
    set_mario_action(m, ACT_FREEFALL, 0)
end

---@param m MarioState
--this is the function for kirby's feather gun move
local function act_kirbywingfeathergun(m)
    local np = gNetworkPlayers[m.playerIndex]
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    if m.actionTimer % 30 == 0 and m.playerIndex == 0 then
        spawn_sync_object(id_bhvkirbywingfeather,kirbymodeltable.kirbywingfeather,m.pos.x, m.pos.y,m.pos.z,function (obj)
            obj_set_pos_relative(obj,m.marioObj,0,10,0)
            obj.oKirbyProjectileOwner = np.globalIndex
            obj.oForwardVel = 60
        end)
    end
    update_sliding(m,8.0)
    apply_landing_accel(m,0.9)
    perform_ground_step(m)
    if (m.framesSinceB > 20) then
        set_mario_action(m, ACT_IDLE, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        set_mario_action(m, ACT_KIRBY_WING_FEATHER_GUN_FALL, 0)

    end

    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's feathergun in the air
local function act_kirbywingfeathergunfall(m)
    local np = gNetworkPlayers[m.playerIndex]
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    if m.actionTimer % 30 == 0 and m.playerIndex == 0 then
        spawn_sync_object(id_bhvkirbywingfeather,kirbymodeltable.kirbywingfeather,m.pos.x, m.pos.y,m.pos.z,function (obj)
            obj_set_pos_relative(obj,m.marioObj,0,10,0)
            obj.oKirbyProjectileOwner = np.globalIndex
            obj.oForwardVel = 60
        end)
    end
    if (m.framesSinceB > 20) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight == m.pos.y) then
        if should_begin_sliding(m) == true then
            set_mario_action(m, ACT_JUMP_LAND, 0)
        else
            set_mario_action(m, ACT_KIRBY_WING_FEATHER_GUN, 0)
        end
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    end
    perform_air_step(m,0)
    set_character_animation(m, CHAR_ANIM_FIRST_PUNCH)
    set_anim_to_frame(m, 30)
    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for kirby's condor head move
local function act_kirbywingcondorhead(m)
    m.vel.y = 0
    set_character_animation(m, CHAR_ANIM_DIVE)
    set_anim_to_frame(m, 30)
    if ((m.controller.buttonDown & Z_TRIG) ~= 0) then
        if (m.controller.buttonDown & A_BUTTON ~= 0) then
            m.vel.y = 60
            return set_mario_action(m, ACT_KIRBY_WING_CONDOR_DIVE, 0)
        else
            return set_mario_action(m, ACT_KIRBY_WING_CONDOR_BOMB, 0)
        end        
    elseif (m.actionTimer > 15) and (m.floorHeight ~= m.pos.y) then
        if (m.flags &  MARIO_WING_CAP) ~= 0 then
            return set_mario_action(m, ACT_FLYING, 0)
        else
            return set_mario_action(m, ACT_KIRBY_SPECIAL_FALL, 0)
        end
    elseif (m.actionTimer > 15) and (m.floorHeight == m.pos.y) then
        set_mario_action(m, ACT_IDLE, 0)
    end
    if m.floorHeight == m.pos.y then
        perform_ground_step(m)
    else
        perform_air_step(m,0)
    end


    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for wing kirby's condor bomb move
local function act_kirbywingcondorbomb(m)
    set_character_animation(m, CHAR_ANIM_DIVE)
    set_anim_to_frame(m, 30)

    local air_step = perform_air_step(m,0)
    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_wing) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif m.actionTimer < 14 then
        local angle = m.actionTimer * 15 * math.pi / 180
        mario_set_forward_vel(m,40 *(math.cos(angle)))
        m.marioObj.header.gfx.angle.x  = ((360 - (19.29 * m.actionTimer)) * 182)
        m.vel.y = 40 * (math.sin(angle))
    elseif (m.floorHeight ~= m.pos.y) then
        m.marioObj.header.gfx.angle.x  = 16380
        mario_set_forward_vel(m,0)
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
           return lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            return set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        end 
    elseif (air_step == AIR_STEP_LANDED) then 
       return set_mario_action(m, ACT_KIRBY_LAND, 0)

    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for wing kirby falling doing a condor dive
local function act_kirbywingcondordive(m)
    set_character_animation(m, CHAR_ANIM_DIVE)
    set_anim_to_frame(m, 30)
    local air_step = perform_air_step(m,0)
    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_wing) then
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.prevAction == ACT_KIRBY_WING_CONDOR_HEAD then
            if m.vel.y < 0 then
                m.marioObj.header.gfx.angle.x  = 8190
            else
                m.marioObj.header.gfx.angle.x  = 57330
            end
        else
            m.marioObj.header.gfx.angle.x  = 16380
        end
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (air_step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (air_step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        end 
    elseif (air_step == AIR_STEP_LANDED) then 
        set_mario_action(m, ACT_KIRBY_LAND, 0)
         
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for sleep kirby sleeping
local function act_kirbysleep(m)
    set_character_animation(m, CHAR_ANIM_SLEEP_IDLE)
    m.marioBodyState.eyeState = MARIO_EYES_CLOSED
    local step
    if (m.floorHeight ~= m.pos.y) then
        step = perform_air_step(m,0)
    else
        update_sliding(m,4.0)
        perform_ground_step(m)
    end
    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_sleep) or (m.actionTimer > 150) then
        if (gPlayerSyncTable[0].kirbypower == kirbyability_sleep) then
            gPlayerSyncTable[0].kirbypower = kirbyability_none
        end 
        set_mario_action(m, ACT_FREEFALL, 0)
    elseif (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        if (step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        end 

    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby throwing other players
local function act_kirbylivingprojectile(m)
    m.vel.y = 0
    local maxspeed = 80
    local np = gNetworkPlayers[m.playerIndex]
    local livingprojectilelaunchedby = gPlayerSyncTable[0].grabbedby
    set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    mario_set_forward_vel(m,maxspeed)
    local step
    if m.actionTimer == 0 and m.actionArg == 0 and m.playerIndex == 0 then
        m.faceAngle.y = gMarioStates[gPlayerSyncTable[0].grabbedby].marioObj.oMoveAngleYaw
    end
    if m.actionTimer == 0 then
        m.pos.y = m.pos.y - 260
    elseif ((m.actionTimer > 20) or (gPlayerSyncTable[0].livingprojectile == false)) and (m.floorHeight ~= m.pos.y) then
            return set_mario_action(m, ACT_FREEFALL, 0)
    elseif ((m.actionTimer > 20) or (gPlayerSyncTable[0].livingprojectile == false)) and (m.floorHeight == m.pos.y) then
        set_mario_action(m, ACT_DECELERATING, 0)
    end
    if m.floorHeight == m.pos.y then
       step = perform_ground_step(m)
        if (step == GROUND_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_AIR_HIT_WALL, 0)
        end
    else
        step = perform_air_step(m,0)
        if (step == AIR_STEP_HIT_LAVA_WALL) then 
            lava_boost_on_wall(m)
        elseif (step == AIR_STEP_HIT_WALL) then 
            set_mario_action(m, ACT_AIR_HIT_WALL, 0)
        end
    end


    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for kirby's star spit in the air
local function act_kirbystarspitair(m)
    local step
    if m.actionTimer == 4 then
        mario_throw_held_object(m)
    elseif m.actionTimer > 4 then
        if ((m.flags &  MARIO_WING_CAP) == 0) and (gPlayerSyncTable[m.playerIndex].kirbypower == kirbyability_bomb) then
            return set_mario_action(m, ACT_KIRBY_SPECIAL_FALL, 0)
        else
            return set_mario_action(m, ACT_FREEFALL, 0)
        end
    end

    set_character_animation(m, CHAR_ANIM_THROW_LIGHT_OBJECT)
    update_air_without_turn(m)
    step = perform_air_step(m,0)
    if step == AIR_STEP_LANDED then
        if (not check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB))then
            return set_mario_action(m, ACT_AIR_THROW_LAND, 0)
        end
    elseif step == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, 0)
    elseif step == AIR_STEP_HIT_LAVA_WALL then
        lava_boost_on_wall(m)
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for landing a ground pound move that wasn't invincible
local function act_kirbyland(m)
    local invalidfloor = {[SURFACE_BURNING] = true,[SURFACE_INSTANT_QUICKSAND] = true,[SURFACE_INSTANT_MOVING_QUICKSAND] = true}
    if (invalidfloor[m.floor.type] ~= true) and ((m.pos.y + m.vel.y) <= m.floorHeight) and m.actionTimer > 1  then
        if (gPlayerSyncTable[0].kirbypower == kirbyability_stone) then
            return set_mario_action(m, ACT_KIRBY_ROCK_SLIDING, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wheel) then
            return set_mario_action(m, ACT_KIRBY_WHEEL_ROLL, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_needle) then
            return set_mario_action(m, ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_fire) and ((m.input & INPUT_ABOVE_SLIDE) == 0)  then
            return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL, 0)
        elseif gPlayerSyncTable[0].kirbypower == kirbyability_wing then
            m.vel.y = 20
            return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_IDLE, 0)

        end
    elseif (m.pos.y ~= m.floorHeight) and m.actionTimer > 1 then
        if (gPlayerSyncTable[0].kirbypower == kirbyability_stone) then
                return set_mario_action(m, ACT_KIRBY_ROCK_FALL, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wheel) then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_WHEEL_DOWNSHIFT, 0)
            else
                return set_mario_action(m, ACT_KIRBY_WHEEL_FALL, 0)
            end
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_needle) then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_NEEDLE_FALLING_SPINE, 0)
            else
                return set_mario_action(m, ACT_FREEFALL, 0)
            end
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_fire) and ((m.input & INPUT_ABOVE_SLIDE) == 0)  then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_FIRE_BALL_SPIN, 0)
            else
               return  set_mario_action(m, ACT_FREEFALL, 0)
            end
        elseif gPlayerSyncTable[0].kirbypower == kirbyability_wing then
                m.vel.y = 20
                return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_FREEFALL, 0)

        end
    elseif m.actionTimer > 1 then
        return set_mario_action(m, ACT_IDLE, 0)
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for landing a ground pound move that was invincible
local function act_kirbylandinvulnerable(m)
    local invalidfloor = {[SURFACE_BURNING] = true,[SURFACE_INSTANT_QUICKSAND] = true,[SURFACE_INSTANT_MOVING_QUICKSAND] = true}
    if (invalidfloor[m.floor.type] ~= true) and ((m.pos.y + m.vel.y) <= m.floorHeight) and m.actionTimer > 1  then
        if (gPlayerSyncTable[0].kirbypower == kirbyability_stone) then
            return set_mario_action(m, ACT_KIRBY_ROCK_SLIDING, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wheel) then
            return set_mario_action(m, ACT_KIRBY_WHEEL_ROLL, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_needle) then
            return set_mario_action(m, ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_fire) and ((m.input & INPUT_ABOVE_SLIDE) == 0)  then
            return set_mario_action(m, ACT_KIRBY_FIRE_BALL_ROLL, 0)
        elseif gPlayerSyncTable[0].kirbypower == kirbyability_wing then
            m.vel.y = 20
            return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_IDLE, 0)

        end
    elseif (m.pos.y ~= m.floorHeight) and m.actionTimer > 1 then
        if (gPlayerSyncTable[0].kirbypower == kirbyability_stone) then
                return set_mario_action(m, ACT_KIRBY_ROCK_FALL, 0)
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wheel) then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_WHEEL_DOWNSHIFT, 0)
            else
                return set_mario_action(m, ACT_KIRBY_WHEEL_FALL, 0)
            end
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_needle) then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_NEEDLE_FALLING_SPINE, 0)
            else
                return set_mario_action(m, ACT_FREEFALL, 0)
            end
        elseif (gPlayerSyncTable[0].kirbypower == kirbyability_fire) and ((m.input & INPUT_ABOVE_SLIDE) == 0)  then
            if (m.controller.buttonDown & Z_TRIG ~= 0) then
                return set_mario_action(m, ACT_KIRBY_FIRE_BALL_SPIN, 0)
            else
               return  set_mario_action(m, ACT_FREEFALL, 0)
            end
        elseif gPlayerSyncTable[0].kirbypower == kirbyability_wing then
                m.vel.y = 20
                return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_FREEFALL, 0)

        end
    elseif m.actionTimer > 1 then
        return set_mario_action(m, ACT_IDLE, 0)
    end
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
--this is the function for kirby's possessing a bobomb
local function act_kirbypossessbobombfuselit(m)
    local np = gNetworkPlayers[m.playerIndex]
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    mario_set_forward_vel(m,40)
    spawn_non_sync_object(id_bhvBobombFuseSmoke,E_MODEL_SMOKE,m.pos.x,m.pos.y,m.pos.z,nil)
    if (m.framesSinceB > 151) or (m.controller.buttonPressed & B_BUTTON ~= 0) and (m.playerIndex == 0) then
        spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
        kirbypowerrelease(m)
    end
    if (m.floorHeight ~= m.pos.y) then
        m.vel.y = m.vel.y - 4.0
        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
        perform_air_step(m,0)
    else
        perform_ground_step(m)
    end

    m.actionTimer = m.actionTimer + 1

end

---@param m MarioState
--this is the function for kirby possessing a bullet bill
local function act_kirbypossessbulletbill(m)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw

    local np = gNetworkPlayers[m.playerIndex]
    local speed
    local step
    local vsped
    if (m.controller.buttonDown & B_BUTTON ~= 0) then
        speed = 80
    else
        speed = 40
    end
    if (m.controller.buttonDown & A_BUTTON ~= 0) then
        vspeed = 40
    elseif (m.controller.buttonDown & Z_TRIG ~= 0) then
        vspeed = -40
    else
        vspeed = 0
    end
    m.vel.y = vspeed
    mario_set_forward_vel(m,speed)
    spawn_non_sync_object(id_bhvBobombFuseSmoke,E_MODEL_SMOKE,m.pos.x,m.pos.y,m.pos.z,nil)
    if (m.actionTimer > 301) and (m.playerIndex == 0) then
        spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
        kirbypowerrelease(m)
    end
    step = perform_air_step(m,0)
    if (step == AIR_STEP_HIT_LAVA_WALL) then 
        lava_boost_on_wall(m)
    elseif (step == AIR_STEP_HIT_WALL) then 
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
---@param o Object
---@param interactType InteractionType
--this function is for allowing kirby to interact with objects.
local function allow_interact(m, o, interactType)
    if m.playerIndex ~= 0 then
        return
    end
    local owner = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    local abilitytype
    local objdelete
    local np = gNetworkPlayers[m.playerIndex]
    local kirbyprojectile = {[id_bhvkirbyairbullet]= true,[id_bhvkirbyexplosion] = true, [id_bhvkirbyflame] = true, [id_bhvkirbywingfeather] = true, [id_bhvkirbyinhalehitbox] = true, [id_bhvkirbylivingprojectile] = true}
    local stargrabmoves = {[ACT_KIRBY_INHALE] = true,[ACT_KIRBY_INHALE_FALL] = true, [ACT_PUNCHING] = true,[ACT_MOVE_PUNCHING] = true,[ACT_DIVE] = true}
    local livingprojectileuninteractables = {[INTERACT_KOOPA_SHELL] = true,[INTERACT_BOUNCE_TOP] = true,[INTERACT_BOUNCE_TOP2] = true}
    if  ((  (kirbyprojectile[get_id_from_behavior(o.behavior)] == true) or (((obj_has_behavior_id(o,id_bhvabilitystar) ~= 0 )) and (interactType == INTERACT_DAMAGE))) and ((network_local_index_from_global(o.oKirbyProjectileOwner) == 0) or ((obj_has_behavior_id(o,id_bhvkirbylivingprojectile) ~= 0) and (network_local_index_from_global(o.oKirbyLivingProjectileLaunchedby) == 0)) or (((allycheck ~= nil) and (allycheck((network_local_index_from_global(o.oKirbyProjectileOwner)),m.playerIndex,o) == true)) or ((allycheck == nil) and genericallycheck(network_local_index_from_global(o.oKirbyProjectileOwner),m.playerIndex,o) == true))) ) then
        o.oInteractStatus = 0
        return false
    elseif (owner > 0) then
        if (interactType == INTERACT_CANNON_BASE )then
            return false
        elseif m.action == ACT_KIRBY_LIVING_PROJECTILE then
            if livingprojectileuninteractables[interactType] == true or (gMarioStates[owner].marioObj == o) then
                return false
            end
        elseif m.action == ACT_GRABBED and (m.heldByObj ~= o) then
            if (interactType == INTERACT_WARP) and ( (gNetworkPlayers[0].currActNum ~= gNetworkPlayers[owner].currActNum) or (gNetworkPlayers[0].currAreaIndex ~= gNetworkPlayers[owner].currAreaIndex) or (gNetworkPlayers[0].currLevelNum ~= gNetworkPlayers[owner].currLevelNum) ) then
                gPlayerSyncTable[owner].inhaledplayer = inhaledtable.warp_to_owner
            end
            return false
        end
    end
    if gPlayerSyncTable[0].kirby == false then
        return
    end
    if gPlayerSyncTable[0].inhaledplayer > 0 and gPlayerSyncTable[0].inhaledplayer ~= inhaledtable.held_drop then
        if interactType == INTERACT_STAR_OR_KEY then
            gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
        end
    end

    if (obj_has_behavior_id(o,id_bhvabilitystar) ~= 0) and (interactType == INTERACT_GRABBABLE) and (stargrabmoves[m.action] == nil) then --make kirby unable to be pushed by grabbable abilitystars
        return false
    elseif possessed and (possessableenemytable[get_id_from_behavior(o.behavior)] ~= nil) then
        return false
    end
    local itypes = {[INTERACT_MR_BLIZZARD] = true, [ INTERACT_HIT_FROM_BELOW] = true, [INTERACT_UNKNOWN_08] = true, [INTERACT_GRABBABLE] = true, [INTERACT_KOOPA_SHELL] = true,[INTERACT_BOUNCE_TOP] = true, [INTERACT_BOUNCE_TOP2] = true, [INTERACT_BULLY] = true, [INTERACT_KOOPA] = true, [INTERACT_CAP] = true,[INTERACT_FLAME] = true, [INTERACT_SHOCK] = true,[INTERACT_SNUFIT_BULLET] = true,[INTERACT_HOOT] = true,[INTERACT_COIN] = true}
    local facingDYaw = mario_obj_angle_to_object(m, o) - m.faceAngle.y --used for checking if kirby is facing the object
    if (m.action == ACT_KIRBY_INHALE or m.action == ACT_KIRBY_INHALE_FALL) and ((facingDYaw >= -0x2AAA) and (facingDYaw <= 0x2AAA)) and ( ( interactType == INTERACT_DAMAGE and obj_has_behavior_id(o,id_bhvabilitystar) == 0) or itypes[interactType] == true ) then
        m.interactObj = o
        if interactType ~= INTERACT_GRABBABLE then
            objdelete = kirbyenemydelete(o,interactType)
        else
            objdelete = 2
        end

        if ( objdelete == bool_to_num[true] or objdelete == bool_to_num[false] ) and (o.oKirbyAbilitytype ~= 0 ) then
            abilitytype = o.oKirbyAbilitytype
            for i = 0,MAX_PLAYERS - 1,1 do
                if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
                    gPlayerSyncTable[i].gaincoin = gPlayerSyncTable[i].gaincoin + o.oNumLootCoins
                end
            end
            if objdelete == bool_to_num[true]then
                obj_mark_for_deletion(o)
            end
            if kirbynosync[get_id_from_behavior(o.behavior)] ~= true then
                network_send_object(o, true)
            end
            m.interactObj =  spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,m.pos.x, m.pos.y, m.pos.z,function(obj)
                obj.oKirbyAbilitytype = abilitytype
                obj.oHeldState = HELD_HELD
            end)
            m.heldObj = m.interactObj

            if m.heldObj.oSyncID ~= 0 then
            end
            return false
        elseif (interactType ~= INTERACT_GRABBABLE) and (objdelete == 2 ) then
            return true
        elseif (interactType ~= INTERACT_GRABBABLE) and (objdelete == 3 ) then
            return false
        elseif (interactType ~= INTERACT_GRABBABLE) then
            return
        else
            if (o.oInteractionSubtype & INT_SUBTYPE_NOT_GRABBABLE) == 0 then
                m.input = m.input | INPUT_INTERACT_OBJ_GRABBABLE
            end
            if o.oSyncID ~= 0 then
                network_send_object(o, true)
            end
            return true
        end
    elseif ((m.action == ACT_KIRBY_ROCK_FALL or m.action == ACT_KIRBY_ROCK_IDLE or m.action == ACT_KIRBY_ROCK_SLIDING) and interactType == INTERACT_STRONG_WIND) or (m.prevAction == ACT_KIRBY_ROCK_FALL and m.action == ACT_KIRBY_LAND_INVULNERABLE) then
        return false
    elseif m.action == ACT_KIRBY_POSSESS_BULLET_BILL and interactType == INTERACT_PLAYER then
        spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
        kirbypowerrelease(m)
        return false
    end

end

---@param o Object
---@param interactType InteractionType
--this function sets objects up for deletion by kirby
function kirbyenemydelete(o,interactType)
    local x = get_id_from_behavior(o.behavior)
    local deleteobj = bool_to_num[false] --whether the obj should be deleted 0 for false, 1 for true , 2 if its invalid and allow interaction,and 3 if its invalid and don't allow interaction.
    local enemyinlist = false
    for key,value in pairs(enemytable) do
        if value[x] ~= nil then
            o.oKirbyAbilitytype = key
            enemyinlist = true
            break
        end

    end
    if obj_has_behavior_id(o,id_bhvabilitystar) ~= 0 then
        return bool_to_num[true]
    elseif enemyinlist == false then
        return 2 
    end

    if  o.oKirbyAbilitytype ~= 0  then
        if (kirbycustomfoodbehavior[x] == "custom") and (kirbycustomfoodfunctions[x] ~= nil) then
        local customfunc = kirbycustomfoodfunctions[x]
            if customfunc ~= nil then
                deleteobj = customfunc(o,interactType)--whether the obj should be deleted 0 for false, 1 for true ,and 2 if its currently invalid
            end
        elseif (kirbycustomfoodbehavior[x] == "bully" )then
            if o.oBehParams2ndByte ~= BULLY_BP_SIZE_BIG then
                if o.parentObj ~= nil then
                    o.parentObj.oBullyKBTimerAndMinionKOCounter = o.parentObj.oBullyKBTimerAndMinionKOCounter + 1
                end
                o.oNumLootCoins = 1
                deleteobj = bool_to_num[true]
            else
                deleteobj = 2
            end     
        elseif (kirbycustomfoodbehavior[x] == "generic_attack") then
            o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        elseif  (kirbycustomfoodbehavior[x] == "waterbomb") then
            obj_become_tangible(o)
            o.parentObj.oWaterBombSpawnerBombActive = bool_to_num[false]
            deleteobj = bool_to_num[true]
        elseif (kirbycustomfoodbehavior[x] == "bobomb" ) then
            if o.oBehParams ~= 0x100 then
                o.oNumLootCoins = 1
            end
            deleteobj = bool_to_num[true]
        elseif (kirbycustomfoodbehavior[x] == "id_bhvBreakableBoxSmall") then
            o.oNumLootCoins = 3
            deleteobj = bool_to_num[true]
        elseif (kirbycustomfoodbehavior[x] == "5coinenemy") then
            o.oNumLootCoins = 5
            deleteobj = bool_to_num[true]
       elseif (kirbycustomfoodbehavior[x] == "koopa") then
            if (o.oKoopaMovementType < KOOPA_BP_KOOPA_THE_QUICK_BASE) then
                o.oNumLootCoins = 5
                deleteobj = bool_to_num[true]
            else
                deleteobj = 2
            end
        elseif (kirbycustomfoodbehavior[x] == "pokey") then
            if o.oBehParams2ndByte == 0 then
                o.oNumLootCoins = 4
                o.parentObj.oPokeyHeadWasKilled = bool_to_num[true]
            else
                o.oNumLootCoins = 0
                o.parentObj.oPokeyNumAliveBodyParts = o.parentObj.oPokeyNumAliveBodyParts - 1
                deleteobj = bool_to_num[true]
            end
        elseif (kirbycustomfoodbehavior[x] == "montymole") then
            o.oAction = MONTY_MOLE_ACT_HIDE
        elseif (kirbycustomfoodbehavior[x] == "bulletbill") then
            o.oAction = 0
        elseif (kirbycustomfoodbehavior[x] == "enemylakitu") then
            o.prevObj = nil
            deleteobj = bool_to_num[true]

        elseif (kirbycustomfoodbehavior[x] == "firepiranhaplant") then
            if (o.oFirePiranhaPlantScale < 2.0 and ((o.oBehParams >> 16) == 0))  then
                deleteobj = bool_to_num[true]
            else
                hurt_and_set_mario_action(gMarioStates[0],ACT_HARD_BACKWARD_AIR_KB,0,8)
                deleteobj = 2
            end
        elseif (interactType == INTERACT_BOUNCE_TOP) or (interactType == INTERACT_BOUNCE_TOP2) then
            if (o.oBehParams2ndByte ~= nil) and ((o.oBehParams2ndByte & GOOMBA_BP_SIZE_MASK ) ~= GOOMBA_SIZE_HUGE) then
                deleteobj = bool_to_num[true]
            else
                deleteobj = 2
            end
        else 
            deleteobj = bool_to_num[true]
        end

    end
    if deleteobj < 2 and modsupporthelperfunctions.sonichealth ~= nil then
        modsupporthelperfunctions.sonichealth.increaseringcount(o.oNumLootCoins)
    end
    return deleteobj
end

---@param m MarioState
--this function is called every time a player's current action is changed
local function on_set_mario_action(m)
    if m.playerIndex ~= 0 then
        return

    elseif gPlayerSyncTable[0].kirby == false then
        if gPlayerSyncTable[0].livingprojectile == true and (m.action ~= ACT_KIRBY_LIVING_PROJECTILE) then
            gPlayerSyncTable[0].livingprojectile = false
            gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
        end
        return
    end


    if gPlayerSyncTable[0].livingprojectile == true and (m.action ~= ACT_KIRBY_LIVING_PROJECTILE) then
        gPlayerSyncTable[0].livingprojectile = false
        gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
    end

    if m.action == ACT_START_HANGING then
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        kirbyfloattime = kirbymaxfloattime
        gPlayerSyncTable[0].canexhale = false
    elseif possessed and m.prevAction == ACT_KIRBY_GHOST_DASH then
        possessed = false
    end

    if (gPlayerSyncTable[0].kirbypower ~= kirbyability_wrestler) then
    --Here i make kirby unable to wallkick
        m.wallKickTimer = 0
        if m.action == ACT_AIR_HIT_WALL then
            if m.actionTimer < 3 then
                m.actionTimer = 3
            end
        end
    end

end

---@param m MarioState
---@param incomingAction integer
--this function is called before every time a player's current action is changed
local function before_set_mario_action(m,incomingAction)
    local grabbed = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    local othermario
    if m.playerIndex ~= 0 then 
        return
    elseif (gPlayerSyncTable[0].kirby == false) or ((grabbed > 0) and ((m.action == ACT_GRABBED) or (incomingAction == ACT_GRABBED)))then
        if grabbed > 0 and (m.action == ACT_KIRBY_LIVING_PROJECTILE) and (gPlayerSyncTable[0].livingprojectile == false) and ((incomingAction ~= ACT_GRABBED) or ((incomingAction == ACT_GRABBED) and (m.usedObj ~= nil) and ((obj_has_behavior_id(m.usedObj,id_bhvkirbyinhalehitbox) == 0))) ) then
            gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
        elseif incomingAction == ACT_GRABBED then
            gPlayerSyncTable[0].inhaleescape = 0
        elseif incomingAction == ACT_THROWN_FORWARD and (gPlayerSyncTable[0].inhaleescape > 0) and (grabbed == 0) then
            m.vel.y = m.vel.y + 40
        end
        if romhackchange ~= nil then
            romhackchange(m,incomingAction)
        end
        return
    end
    local np = gNetworkPlayers[m.playerIndex]
    local romhackchangereturn
    if m.action == ACT_KIRBY_GHOST_DASH and (kirbyhasvanish == false) then
        m.flags = m.flags & ~MARIO_VANISH_CAP
    end

    if romhackchange ~= nil then
        romhackchangereturn = romhackchange(m,incomingAction)
        if type(romhackchangereturn) ~= "nil" then
            return romhackchangereturn
        end
    end

    if m.action == ACT_GETTING_BLOWN and gGlobalSyncTable.loseability == true and gPlayerSyncTable[0].kirbypower ~= kirbyability_none then --make kirby able to lose ability to strong wind
        m.cap = MARIO_CAP_ON_HEAD
        m.flags = m.flags | MARIO_NORMAL_CAP | MARIO_CAP_ON_HEAD
        kirbypowerrelease(m)
    end

    if incomingAction == ACT_GRABBED then
        gPlayerSyncTable[0].inhaleescape = 0
    elseif incomingAction == ACT_THROWN_FORWARD and (gPlayerSyncTable[0].inhaleescape > 0) and (grabbed == 0) then
        m.vel.y = m.vel.y + 40   
    end

    if (gPlayerSyncTable[0].breathingfire == true) and ((incomingAction ~= ACT_KIRBY_FIRE_BREATH) or (incomingAction ~= ACT_KIRBY_FIRE_BREATH_FALL)) then
        gPlayerSyncTable[0].breathingfire = false
    elseif grabbed > 0 and (m.action == ACT_KIRBY_LIVING_PROJECTILE) and (gPlayerSyncTable[0].livingprojectile == false) and ((incomingAction ~= ACT_GRABBED) or ((incomingAction == ACT_GRABBED) and (m.usedObj ~= nil) and ((obj_has_behavior_id(m.usedObj,id_bhvkirbyinhalehitbox) == 0))) ) then
        gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex

    end

    if (gPlayerSyncTable[0].inhaling == true) and ((incomingAction ~= ACT_KIRBY_INHALE) or (incomingAction ~= ACT_KIRBY_INHALE_FALL)) then
        gPlayerSyncTable[0].inhaling = false
    end


    if gGlobalSyncTable.loseability == true and m.hurtCounter > 0 and gPlayerSyncTable[0].kirbypower ~= kirbyability_none and gPlayerSyncTable[0].losingability == false then
        kirbypowerrelease(m)
        gPlayerSyncTable[0].losingability = true
    elseif gGlobalSyncTable.loseability == true and (incomingAction == ACT_BURNING_FALL or incomingAction == ACT_BURNING_GROUND) and gPlayerSyncTable[0].kirbypower ~= kirbyability_none and gPlayerSyncTable[0].losingability == false then
        kirbypowerrelease(m)
        gPlayerSyncTable[0].losingability = true
    elseif gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held and ((incomingAction & ACT_FLAG_THROWING) ~= 0) then --if kirby is throwing a player
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_throw
    elseif (gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held) or (gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_owner_left) or (gPlayerSyncTable[0].inhaledplayer == inhaledtable.warp_to_owner) or (gPlayerSyncTable[0].inhaledplayer == inhaledtable.finish_warp) then
        if (m.hurtCounter > 0) or ((m.prevAction == ACT_IN_CANNON) and (m.action == ACT_SHOT_FROM_CANNON) and (incomingAction ~= ACT_IN_CANNON)) or (incomingAction == ACT_FEET_STUCK_IN_GROUND) or (incomingAction == ACT_LEDGE_GRAB) or (incomingAction == ACT_AIR_HIT_WALL) or (incomingAction == ACT_BACKWARD_AIR_KB) or (incomingAction == ACT_SQUISHED) or (incomingAction == ACT_VERTICAL_WIND) or (incomingAction == ACT_HEAD_STUCK_IN_GROUND) or (incomingAction == ACT_BURNING_FALL or incomingAction == ACT_BURNING_GROUND or incomingAction == ACT_GRABBED or (incomingAction & ACT_FLAG_WATER_OR_TEXT ~= 0)) then
            gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
        elseif incomingAction == ACT_JUMP then
            return ACT_HOLD_JUMP
        elseif incomingAction == ACT_FREEFALL then
            return ACT_HOLD_FREEFALL
        elseif incomingAction == ACT_WALKING then
            return ACT_HOLD_WALKING
        elseif incomingAction == ACT_BEGIN_SLIDING then
            return ACT_HOLD_BEGIN_SLIDING
        end

    end

    if incomingAction == ACT_DOUBLE_JUMP or incomingAction == ACT_TRIPLE_JUMP or incomingAction == ACT_SPECIAL_TRIPLE_JUMP or incomingAction == ACT_BACKFLIP then
        return ACT_JUMP
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wheel) then
        if incomingAction == ACT_GROUND_POUND then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return 1
            end
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
                return ACT_KIRBY_WHEEL_FALL
            end
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
            return ACT_KIRBY_WHEEL_ROLL
        end

    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_stone) then
        if incomingAction == ACT_GROUND_POUND then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return ACT_KIRBY_ROCK_FALL
            end
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
                mario_set_forward_vel(m,0.0)
                return ACT_KIRBY_ROCK_FALL
            end
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
            return ACT_KIRBY_ROCK_SLIDING
        elseif (incomingAction == ACT_WATER_PLUNGE) and (m.action == ACT_KIRBY_ROCK_FALL or m.action == ACT_KIRBY_ROCK_SLIDING or m.action == ACT_KIRBY_ROCK_IDLE) then
            return ACT_KIRBY_ROCK_WATER_SINK
        elseif (m.action == ACT_KIRBY_ROCK_WATER_SINK or m.action == ACT_KIRBY_ROCK_WATER_SLIDING or m.action == ACT_KIRBY_ROCK_WATER_IDLE) and ((incomingAction == ACT_WALKING) or (incomingAction == ACT_HOLD_WALKING)) then
            return ACT_KIRBY_ROCK_SLIDING
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_none) then
        if incomingAction == ACT_GROUND_POUND then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return 1
            end
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil and gPlayerSyncTable[0].canexhale == true then
            return ACT_KIRBY_EXHALE
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil then
            return ACT_KIRBY_INHALE_FALL
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            return ACT_KIRBY_INHALE
        elseif incomingAction == ACT_AIR_THROW then
            return ACT_KIRBY_STAR_SPIT_AIR
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_needle) then
        if incomingAction == ACT_GROUND_POUND then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return ACT_KIRBY_NEEDLE_FALLING_SPINE
            end
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
                return ACT_KIRBY_NEEDLE_FALL
            end
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
            return ACT_KIRBY_NEEDLE_SLIDING

        end

    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_fire) then
        if incomingAction == ACT_GROUND_POUND then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return ACT_KIRBY_FIRE_BALL_SPIN
            end
        elseif (incomingAction == ACT_JUMP_KICK or ((incomingAction == ACT_DIVE) and (m.forwardVel <= 28) and (m.pos.y ~= m.floorHeight) and ( (m.prevAction == ACT_JUMP) or (m.prevAction == ACT_KIRBY_JUMP) or (m.prevAction == ACT_KIRBY_WING_FLAP)) and (m.action == ACT_FREEFALL))) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return ACT_KIRBY_FIRE_BREATH_FALL
            end
        elseif (incomingAction == ACT_DIVE) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                return ACT_KIRBY_FIRE_BALL
            end
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            return ACT_KIRBY_FIRE_BREATH
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_bomb) then
        if incomingAction == ACT_GROUND_POUND then
            if (m.action == ACT_HOLD_FREEFALL or m.action == ACT_HOLD_JUMP) then
                return ACT_KIRBY_BOMB_JUMP
            elseif gPlayerSyncTable[0].canexhale == true and m.heldObj == nil then
                    return ACT_KIRBY_EXHALE
            else
                return 1
            end
        elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK) and m.heldObj == nil then
            if gPlayerSyncTable[0].canexhale == true then
                return ACT_KIRBY_EXHALE
            else
                m.input = m.input & ~INPUT_B_PRESSED
                m.heldObj = spawn_sync_object(id_bhvkirbybomb,kirbymodeltable.kirbybomb,m.pos.x, m.pos.y,m.pos.z,nil)
                if m.heldObj ~= nil then
                    m.heldObj.heldByPlayerIndex = m.playerIndex
                    m.heldObj.oHeldState = HELD_HELD
                    m.heldObj.oFlags = OBJ_FLAG_HOLDABLE
                    m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
                    return ACT_HOLD_FREEFALL
                else
                    return ACT_FREEFALL
                end
            end
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            m.input = m.input & ~INPUT_B_PRESSED
            m.heldObj = spawn_sync_object(id_bhvkirbybomb,kirbymodeltable.kirbybomb,m.pos.x, m.pos.y,m.pos.z,nil)
            if m.heldObj ~= nil then
                m.heldObj.heldByPlayerIndex = m.playerIndex
                m.heldObj.oHeldState = HELD_HELD
                m.heldObj.oFlags = OBJ_FLAG_HOLDABLE
                m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
                return ACT_HOLD_IDLE
            else
                return ACT_IDLE
            end
        elseif incomingAction == ACT_AIR_THROW then
            return ACT_KIRBY_STAR_SPIT_AIR
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_ghost) then
        local key = gPlayerSyncTable[0].kirbypossess
        if key == 0 then
            if incomingAction == ACT_GROUND_POUND then
                return 1
            elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK or incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
                return ACT_KIRBY_GHOST_DASH
            end
        else
            if (possessablemoveset[key] == "custom") and (possessablemovesetfunction[key] ~= nil) and (possessablemovesetfunction[key].movesetfunction ~= nil) then --call an external function to determine interaction
                local customfunc = possessablemovesetfunction[key].movesetfunction
                if customfunc ~= nil then
                    hurtenemy = customfunc(m)--function for specific possession's moveset
                end
            elseif possessablemoveset[key] == "goomba" or key == id_bhvGoomba then
                if (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK or incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING or incomingAction == ACT_GROUND_POUND or incomingAction == ACT_LONG_JUMP or incomingAction == ACT_SIDE_FLIP or incomingAction == ACT_SLIDE_KICK) and m.heldObj == nil then
                    return 1
                end
            elseif possessablemoveset[key] == "Swoop" or key == id_bhvSwoop then
                if (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK or incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING or incomingAction == ACT_GROUND_POUND or incomingAction == ACT_LONG_JUMP or incomingAction == ACT_SIDE_FLIP or incomingAction == ACT_SLIDE_KICK or incomingAction == ACT_HANG_MOVING) and m.heldObj == nil then
                    return 1
                end
            elseif possessablemoveset[key] == "bobomb" or key == id_bhvBobomb then
                if (m.hurtCounter > 0) and (m.action == ACT_KIRBY_POSSESS_BOBOMB_FUSELIT) then
                    m.hurtCounter = 0
                    spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
                        obj.oKirbyProjectileOwner = np.globalIndex
                    end)
                    kirbypowerrelease(m)
                    m.invincTimer = 2
                    return 1
                elseif ( incomingAction == ACT_LONG_JUMP or incomingAction == ACT_SIDE_FLIP) and m.heldObj == nil then
                    return 1
                elseif (incomingAction == ACT_DIVE or incomingAction == ACT_JUMP_KICK or incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING or incomingAction == ACT_GROUND_POUND) then
                    m.controller.buttonPressed = m.controller.buttonPressed & ~B_BUTTON
                    return ACT_KIRBY_POSSESS_BOBOMB_FUSELIT
                end
            elseif possessablemoveset[key] == "bulletbill" or key == id_bhvBulletBill then
                if (m.action == ACT_KIRBY_GHOST_DASH) and (incomingAction ~= ACT_KIRBY_POSSESS_BULLET_BILL) then
                    return ACT_KIRBY_POSSESS_BULLET_BILL
                elseif (m.action == ACT_KIRBY_POSSESS_BULLET_BILL) and (m.hurtCounter > 0)  then
                    m.hurtCounter = 0
                    spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
                        obj.oKirbyProjectileOwner = np.globalIndex
                    end)
                    return kirbypowerrelease(m)
                elseif (m.action == ACT_KIRBY_POSSESS_BULLET_BILL) then
                    spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
                        obj.oKirbyProjectileOwner = np.globalIndex
                    end)
                    return kirbypowerrelease(m)
                elseif m.action ~= ACT_KIRBY_POSSESS_BULLET_BILL and incomingAction ~= ACT_KIRBY_POSSESS_BULLET_BILL then
                    spawn_sync_object(id_bhvkirbyexplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z,function(obj)
                        obj.oKirbyProjectileOwner = np.globalIndex
                    end)
                    return kirbypowerrelease(m)
                end
            end
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wing) then
        if incomingAction == ACT_GROUND_POUND then
            if (m.controller.buttonDown & A_BUTTON ~= 0) then
                return ACT_KIRBY_WING_CONDOR_DIVE
            else
                return ACT_KIRBY_WING_CONDOR_BOMB
            end
        elseif ((incomingAction == ACT_JUMP_KICK ) or ((incomingAction == ACT_DIVE) and (m.forwardVel <= 28)and (m.pos.y ~= m.floorHeight) and((m.prevAction == ACT_JUMP) or (m.prevAction == ACT_KIRBY_WING_FLAP) or (m.prevAction == ACT_KIRBY_JUMP)) and (m.action == ACT_FREEFALL))) and m.heldObj == nil then
            return ACT_KIRBY_WING_FEATHER_GUN_FALL
        elseif (incomingAction == ACT_DIVE) and m.heldObj == nil then
            return ACT_KIRBY_WING_CONDOR_HEAD
        elseif (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.heldObj == nil then
            return ACT_KIRBY_WING_FEATHER_GUN
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_wrestler) then
        if incomingAction == ACT_GROUND_POUND then
            return
        elseif (incomingAction == ACT_DIVE) and (m.pos.y ~= m.floorHeight) and (m.heldObj == nil) and ((m.prevAction == ACT_JUMP) or (m.prevAction == ACT_KIRBY_JUMP) or (m.prevAction == ACT_KIRBY_WING_FLAP)) and (m.action == ACT_FREEFALL) then
            if m.forwardVel <= 28 then
                return ACT_JUMP_KICK
            else
                return
            end
        end
    elseif (gPlayerSyncTable[0].kirbypower == kirbyability_sleep) then
        if m.action == ACT_KIRBY_SLEEP and ((m.hurtCounter > 0) or (incomingAction & ACT_FLAG_WATER_OR_TEXT) ~= 0) then
            gPlayerSyncTable[0].kirbypower = kirbyability_none
            return
        else
            return ACT_KIRBY_SLEEP
        end
    end
end
---@param attacker MarioState --attacking player's MarioState 
---@param victim MarioState -- attacked player's MarioState
--determines what happens for kirby pvp interactions
local function on_pvp_attack(attacker, victim)
    local damage = 8
    local fireaction = { [ACT_KIRBY_FIRE_BALL]= true,[ACT_KIRBY_FIRE_BALL_SPIN] = true,[ACT_KIRBY_FIRE_BALL_ROLL]= true,[ACT_KIRBY_FIRE_BALL_ROLL_JUMP] = true,[ACT_KIRBY_FIRE_BALL_ROLL_CLIMB] = true}
    if victim.playerIndex ~= 0 then
        return
    elseif ((victim.flags & MARIO_METAL_CAP) ~= 0) then
        damage = 0
    end	
	if (fireaction[attacker.action] == true) then
        if victim.pos.y == victim.floorHeight then
            hurt_and_set_mario_action(victim,ACT_BURNING_GROUND,0,damage)
        elseif victim.vel.y <= 0 then
            hurt_and_set_mario_action(victim,ACT_BURNING_FALL,0,damage)
        else
            hurt_and_set_mario_action(victim,ACT_BURNING_JUMP,0,damage)
        end
    end

end

---@param m MarioState
--Called when the player dies
local function on_death(m)
    local owner = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    if m.playerIndex ~= 0 then
        return
    elseif gPlayerSyncTable[0].kirby == false or gGlobalSyncTable.loseability ~= true then
        if owner > 0 then
            gPlayerSyncTable[owner].inhaledplayer = inhaledtable.held_drop
            gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
        end
        return
    end
    if owner > 0 then
        gPlayerSyncTable[owner].inhaledplayer = inhaledtable.held_drop
        gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
    end
    if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
    end
    gPlayerSyncTable[0].kirbypower = kirbyability_none
    gPlayerSyncTable[0].kirbypossess = 0
    gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
    gPlayerSyncTable[0].possessedmodelId = nil
end

---@param bool boolean
--this function toggles kirby super form for sonic health mod
function kirbysuper(bool)
    local str
    if bool == false then
        str = 'kirby stopped being super'
    else
        str = 'kirby went super'
    end
    kirbyissuper = bool
    if gPlayerSyncTable[0].kirby == true then
        djui_chat_message_create(str)
        if (kirbyissuper == false) and (kirbyhaswing == false) then
            gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
        end
    end
end

--- @param obj Object
--this function is for kirby attacking the breakable windows in star road
local function bhvSMSRBreakableWindowdirect(obj)
    m = gMarioStates[0]
    if (kirbyabilitymovelist[m.action]) == 1 then
        play_sound(SOUND_GENERAL_WALL_EXPLOSION, obj.header.gfx.cameraToObject)
        spawn_triangle_break_particles(30, 138, 1, 4)
        obj_mark_for_deletion(obj)
        obj.oInteractStatus = 0
        return true
    else
        return true
    end
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking the breakable windows in star road with projectiles
local function bhvSMSRBreakableWindowbyprojectile(obj,kirbyprojectile)
    play_sound(SOUND_GENERAL_WALL_EXPLOSION, obj.header.gfx.cameraToObject)
    spawn_triangle_break_particles(30, 138, 1, 4)
    obj_mark_for_deletion(obj)
    obj.oInteractStatus = 0
    return true
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking the apparation in Super Mario 64: The Underworld with projectiles
local function bhvSM64underworldapparation(obj,kirbyprojectile)
    if obj.oHealth > 0 and obj.oHealth <= 2048 then
        if (obj.oAction == 2) or (obj.oAction == 3) or (obj.oAction == 5) then
            if (obj_has_behavior_id(kirbyprojectile,id_bhvkirbyflame) ~= 0) then
                obj.oHealth = obj.oHealth - 2
            else
                obj.oHealth = obj.oHealth - 10
            end
            obj.oInteractStatus = 0
            if obj.oAction == 2 then
                obj.oVelY = 100
                obj.oAction = 3
            elseif obj.oAction == 3 then
                obj.oAction = math.random(3, 6)
            elseif obj.oAction == 5 then
                obj.oAction = 3
            end
        elseif (obj.oAction == 6) then
            if (obj_has_behavior_id(kirbyprojectile,id_bhvkirbyflame) ~= 0) then
                obj.oHealth = obj.oHealth - 4
            else
                obj.oHealth = obj.oHealth - 20
            end
        end
    end
    return true
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking ULTRA IRIOS in ULTRA IRIOS romhack with projectiles
local function bhvULTRAIRIOSprojectile(obj,kirbyprojectile)
    if obj.oAction ~= 3 then
        if (obj_has_behavior_id(kirbyprojectile,id_bhvkirbyflame) ~= 0) then
            obj.oHealth = obj.oHealth - 4
        else
            obj.oHealth = obj.oHealth - 10
        end
    end

end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby destroying doors in the door bust mod  by using kirby projectiles
local function destroy_Door_by_projectile(obj,kirbyprojectile)
    local model = E_MODEL_CASTLE_CASTLE_DOOR

    if get_id_from_behavior(obj.behavior) ~= id_bhvStarDoor then
        if obj_has_model_extended(obj, E_MODEL_CASTLE_DOOR_1_STAR) ~= 0 then
            model = E_MODEL_CASTLE_DOOR_1_STAR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_DOOR_3_STARS) ~= 0 then
            model = E_MODEL_CASTLE_DOOR_3_STARS
        elseif obj_has_model_extended(obj, E_MODEL_CCM_CABIN_DOOR) ~= 0 then
            model = E_MODEL_CCM_CABIN_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_METAL_DOOR) ~= 0 then
            model = E_MODEL_HMC_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_WOODEN_DOOR) ~= 0 then
            model = E_MODEL_HMC_WOODEN_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_BBH_HAUNTED_DOOR) ~= 0 then
            model = E_MODEL_BBH_HAUNTED_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_METAL_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_CASTLE_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_CASTLE_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_HAZY_MAZE_DOOR) ~= 0 then
            model = E_MODEL_HMC_HAZY_MAZE_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_GROUNDS_METAL_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_GROUNDS_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_KEY_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_KEY_DOOR
        end
    else
        model = E_MODEL_CASTLE_STAR_DOOR_8_STARS
    end

    local projectileowner = modsupporthelperfunctions.kirby.getkirbyprojectileowner(kirbyprojectile,"launchedby") --getting the player who launched the kirby projectile
    obj.oTimer = 0
    obj.oPosY = 9999
    play_sound(SOUND_GENERAL_BREAK_BOX, obj.header.gfx.cameraToObject)
    spawn_triangle_break_particles(30, 138, 1, 4)
    spawn_non_sync_object(
        bhvDoorBustCustom001,
        model,
        obj.oPosX, obj.oHomeY, obj.oPosZ,
        --- @param o Object
        function(o)
            o.globalPlayerIndex = projectileowner
            o.oForwardVel = 80
            play_sound(SOUND_ACTION_HIT_2, obj.header.gfx.cameraToObject)
        end
    )
    return true
end

--- @param obj Object
--this function is for kirby destroying doors in the door bust mod  by using kirby attacks
local function destroy_Door(obj)
    if kirbyabilitymovelist[gMarioStates[0].action] ~= 1 then return end
    local model = E_MODEL_CASTLE_CASTLE_DOOR

    if get_id_from_behavior(obj.behavior) ~= id_bhvStarDoor then
        if obj_has_model_extended(obj, E_MODEL_CASTLE_DOOR_1_STAR) ~= 0 then
            model = E_MODEL_CASTLE_DOOR_1_STAR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_DOOR_3_STARS) ~= 0 then
            model = E_MODEL_CASTLE_DOOR_3_STARS
        elseif obj_has_model_extended(obj, E_MODEL_CCM_CABIN_DOOR) ~= 0 then
            model = E_MODEL_CCM_CABIN_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_METAL_DOOR) ~= 0 then
            model = E_MODEL_HMC_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_WOODEN_DOOR) ~= 0 then
            model = E_MODEL_HMC_WOODEN_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_BBH_HAUNTED_DOOR) ~= 0 then
            model = E_MODEL_BBH_HAUNTED_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_METAL_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_CASTLE_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_CASTLE_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_HMC_HAZY_MAZE_DOOR) ~= 0 then
            model = E_MODEL_HMC_HAZY_MAZE_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_GROUNDS_METAL_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_GROUNDS_METAL_DOOR
        elseif obj_has_model_extended(obj, E_MODEL_CASTLE_KEY_DOOR) ~= 0 then
            model = E_MODEL_CASTLE_KEY_DOOR
        end
    else
        model = E_MODEL_CASTLE_STAR_DOOR_8_STARS
    end

    obj.oTimer = 0
    obj.oPosY = 9999
    play_sound(SOUND_GENERAL_BREAK_BOX, obj.header.gfx.cameraToObject)
    network_send_object(obj, false)
    spawn_triangle_break_particles(30, 138, 1, 4)
    spawn_non_sync_object(
        bhvDoorBustCustom001,
        model,
        obj.oPosX, obj.oHomeY, obj.oPosZ,
        --- @param o Object
        function(o)
            o.oForwardVel = 80
            play_sound(SOUND_ACTION_HIT_2, obj.header.gfx.cameraToObject)
        end
    )
end


--- @param o Object
--- @param interactType InteractionType
--function for kirby eating cappy
function kirbycappy(o,interactType)
    return 0
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking the pswitch MOP with projectiles
local function kirbybhvPSwitch_MOP(obj,kirbyprojectile)
    if obj.oAction == PURPLE_SWITCH_IDLE then
        obj.oAction = PURPLE_SWITCH_PRESSED
        return true
    end
    return false
end

---@param victim integer local playerindex of player hit by projectile
---@param projectileowner integer local playerindex of projectile's owner
---@param o Object the projectile that hit the victim
---this function is for kirby projectile interaction in the mariohunt mod
local function kirbymariohuntallycheck(projectileowner,victim,o)

    if (modsupporthelperfunctions.mhApi.getGlobalField("anarchy") == 0) and modsupporthelperfunctions.mhApi.getTeam(projectileowner) == modsupporthelperfunctions.mhApi.getTeam(victim) and (obj_has_behavior_id(o,id_bhvkirbylivingprojectile) == 0)  then --if team attack if off
         return true
    elseif (modsupporthelperfunctions.mhApi.getGlobalField("anarchy") == 1) and (modsupporthelperfunctions.mhApi.getTeam(projectileowner) == modsupporthelperfunctions.mhApi.getTeam(victim) and (modsupporthelperfunctions.mhApi.getTeam(victim) == 0)) and (obj_has_behavior_id(o,id_bhvkirbylivingprojectile) == 0)  then --if team attack is only on for runners
        return true
    elseif (modsupporthelperfunctions.mhApi.getGlobalField("anarchy") == 2) and (modsupporthelperfunctions.mhApi.getTeam(projectileowner) == modsupporthelperfunctions.mhApi.getTeam(victim) and (modsupporthelperfunctions.mhApi.getTeam(victim) == 1)) and (obj_has_behavior_id(o,id_bhvkirbylivingprojectile) == 0) then --if team attack is only on for hunters
        return true
    elseif modsupporthelperfunctions.mhApi.isSpectator(victim) == true then
        return true
    else
        return false
    end
end

---@param victim integer local playerindex of player hit by projectile
---@param projectileowner integer local playerindex of projectile's owner
---@param o Object the projectile that hit the victim
---this function is for kirby projectile interaction in the arena mod
local function kirbyarenaallycheck(projectileowner,victim,o)

    local attacker = modsupporthelperfunctions.kirby.getkirbyprojectileowner(o,"launchedbylocal")

    if (modsupporthelperfunctions.Arena.get_player_team(0) == modsupporthelperfunctions.Arena.get_player_team(attacker)) and (modsupporthelperfunctions.Arena.get_player_team(0) ~= 0) then
        return true
    else
        return false
     end
end

---@param victim integer local playerindex of player hit by projectile
---@param projectileowner integer local playerindex of projectile's owner
---@param o Object the projectile that hit the victim
---this function is for kirby projectile interaction in the shine thief mod
local function kirbyshinethiefallycheck(projectileowner,victim,o)

    local attacker = modsupporthelperfunctions.kirby.getkirbyprojectileowner(o,"launchedbylocal")

    if ((modsupporthelperfunctions.ShineThief.get_team(0) == modsupporthelperfunctions.ShineThief.get_team(attacker)) and (modsupporthelperfunctions.ShineThief.get_team(attacker) ~= 0)) then
        return true
    elseif (modsupporthelperfunctions.ShineThief.get_spectator(victim) or modsupporthelperfunctions.ShineThief.get_spectator(attacker)) then
        return true
    elseif (modsupporthelperfunctions.ShineThief.star_active(victim) ) then
        return true
    else
        modsupporthelperfunctions.ShineThief.set_shine_attacker(attacker)
        return false
    end

end

---@param victim integer local playerindex of player hit by projectile
---@param projectileowner integer local playerindex of projectile's owner
---@param o Object the projectile that hit the victim
---this function is for kirby projectile interaction in hide and seek mod
local function kirbyhideandseekallycheck(projectileowner,victim,o)
    local attacker = modsupporthelperfunctions.kirby.getkirbyprojectileowner(o,"launchedbylocal")
    if (modsupporthelperfunctions.HideAndSeek.is_player_seeker(attacker)) == (modsupporthelperfunctions.HideAndSeek.is_player_seeker(victim)) then
        return true
    else
        if (modsupporthelperfunctions.HideAndSeek.is_player_seeker(attacker)) == true then
            modsupporthelperfunctions.HideAndSeek.set_player_seeker(victim,true)
        end
        return false
    end

end

---@param m MarioState
---@param incomingAction integer
--this function is called before every time the local kirby player's current action is changed in star revenge 7
local function starrevenge7romhackchange(m,incomingAction)
    if (modsupporthelperfunctions.hasromhackbadgetable['TB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('TB') == "1") then --if kirby has the triple jump badge
        maxkirbyjumps = maxkirbyjumps + 1
        modsupporthelperfunctions.hasromhackbadgetable['TB'] = 1
        djui_chat_message_create(string.format("Kirby's max midair jumps has increased to %d due to Triple Jump badge", maxkirbyjumps))
    end
    if (modsupporthelperfunctions.hasromhackbadgetable['WB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('WB') == "1") then --if kirby has the wall jump badge
        maxkirbyjumps = maxkirbyjumps + 3
        modsupporthelperfunctions.hasromhackbadgetable['WB'] = 1
        djui_chat_message_create(string.format("Kirby's max midair jumps has increased to %d due to Wall Jump badge", maxkirbyjumps))
    end
    if (modsupporthelperfunctions.hasromhackbadgetable['SB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('SB') == "1") then --if kirby has the super stomp badge
        modsupporthelperfunctions.hasromhackbadgetable['SB'] = 1
    end
    if (modsupporthelperfunctions.hasromhackbadgetable['UB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('UB') == "1") then --if kirby has the ultra stomp badge
        modsupporthelperfunctions.hasromhackbadgetable['UB'] = 1
    end
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking the super block in star revenge 7
local function kirbybhv_superblock_revenge7(obj,kirbyprojectile)
    if (modsupporthelperfunctions.hasromhackbadgetable['SB'] ~= nil) then
        obj_mark_for_deletion(obj)
        spawn_mist_particles()
    end
    return true
end

--- @param obj Object
--- @param kirbyprojectile Object
--this function is for kirby attacking the super block in star revenge 7
local function kirbybhv_ultrablock_revenge7(obj,kirbyprojectile)
    if (modsupporthelperfunctions.hasromhackbadgetable['UB'] ~= nil) then
        obj_mark_for_deletion(obj)
        spawn_mist_particles()
    end
    return true
end


--this function is setting up eatable enemies for the gorehardmode mod
function goremodehardmodesetup(table)
    local behaviorname 
    local gorename
    for key,value in pairs(table)do
        for subkey,subvalue in pairs(table[key])do
            behaviorname = get_behavior_name_from_id(subkey)
            
            if (behaviorname ~= nil) then
                gorename = "bhvGore" .. behaviorname:sub(4)
                
                if _G[gorename] ~= nil then--if a variable exists with this gorename
                    modsupporthelperfunctions.kirby.add_eatable_enemy(kirbyabilitylist[key],_G[gorename],subvalue .."(gore mod version)")--adding the gore mod version of an enemy already in enemytable[key] to said table  
                end
            end
        end
    end
end

--[[ ---@param modname string
---returns part of the name for a mod's custom behavior name if modname is my-great_MOD then it will return bhvMyGreatMODCustom
local function modnametobhvname(modname)
    local modnameconvert
    local bhvname = "bhv".. modnameconvert
    return 
end ]]

--function used for built in support for some external mods
local function modsupport()
    local kirbyactiontable = modsupporthelperfunctions.kirby.getkirbymoves("table") --table of kirbyactions
    hook_event(HOOK_ALLOW_INTERACT, allow_interact) --Called before mario interacts with an object, return true to allow the interaction
    hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action) --hook which is called before every time a player's current action is changed.Return an action to change the incoming action or 1 to cancel the action change.
    local kirbydescription = "playable kirby from dreamland"
    local projectiletable = {}
    if _G.charSelect ~= nil then --if the character select mod is on
        modsupporthelperfunctions.charSelect = _G.charSelect --local reference for _G.charSelect
        modsupporthelperfunctions.kirbyindex = modsupporthelperfunctions.charSelect.character_add("Kirby", kirbydescription , "wereyoshi", nil, E_MODEL_KIRBY, CT_MARIO, E_KIRBY_LIFE_ICON) --kirby's index in the character select mod
        modsupporthelperfunctions.kirby.kirbyaltsetmodelfunction = function()
            if (gPlayerSyncTable[0].modelId ~= nil) and (gPlayerSyncTable[0].modelId ~= ((modsupporthelperfunctions.charSelect.character_get_current_table()).model)) then
                modsupporthelperfunctions.charSelect.character_edit(modsupporthelperfunctions.kirbyindex,nil,nil,nil,nil,gPlayerSyncTable[0].modelId)
            end
        end 
        modsupporthelperfunctions.charSelect.character_add_voice(E_MODEL_KIRBY,kirbyvoicetable)
        modsupporthelperfunctions.charSelect.character_add_voice(E_MODEL_NONE,{}) --used when kirby is possessing enemies
        kirbyvoicesound = modsupporthelperfunctions.charSelect.voice.sound
        --kirbyvoicesnore = modsupporthelperfunctions.charSelect.voice.snore
        if modsupporthelperfunctions.charSelect.get_options_status ~= nil then
            modsupporthelperfunctions.kirbycharselectoptions = {}
            if (modsupporthelperfunctions.charSelect.optionTableRef ~= nil) and (modsupporthelperfunctions.charSelect.restrict_movesets ~= nil) then
                modsupporthelperfunctions.kirbycharselectoptions.localmodeltogglepos = modsupporthelperfunctions.charSelect.optionTableRef.localModels --for char select versions 1.1 and up
                modsupporthelperfunctions.kirbycharselectoptions.localmovesettogglepos =modsupporthelperfunctions.charSelect.optionTableRef.localMoveset --for char select versions 1.1 and up
            else
                modsupporthelperfunctions.kirbycharselectoptions.localmodeltogglepos = modsupporthelperfunctions.charSelect.optionTableRef.localModels --for char select versions before 1.1 
            end
            hook_event(HOOK_OBJECT_SET_MODEL,function(o)
                if (modsupporthelperfunctions.charSelect.get_options_status(modsupporthelperfunctions.kirbycharselectoptions.localmodeltogglepos) ~= 0) then
                    return
                end
                if obj_has_behavior_id(o, id_bhvMario) ~= 0 then
                    local i = network_local_index_from_global(o.globalPlayerIndex)
                    if (gPlayerSyncTable[i].modelId ~= nil) and (gPlayerSyncTable[i].kirby == true) and (gPlayerSyncTable[i].modelId == E_MODEL_NONE) and (obj_has_model_extended(o, gPlayerSyncTable[i].modelId) == 0) then
                        return obj_set_model_extended(o, gPlayerSyncTable[i].modelId)
                    end
                end
            end) -- Called when a behavior changes models. Also runs when a behavior spawns.
        end
        if modsupporthelperfunctions.charSelect.credit_add ~= nil then
            modsupporthelperfunctions.charSelect.credit_add(string.format("kirby moveset version %s", version),"wereyoshi","moveset maker")
        else
            if usingcoopdx == 0 then
                kirbydescription = kirbydescription .."\n To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases or if using the outdated excoop android port then instead use the coopdx port at https://github.com/ManIsCat2/sm64coopdx/releases"
            end
            kirbydescription = kirbydescription .. string.format("\n version %s \n credits", version)
            kirbydescription = kirbydescription .. "\n wereyoshi moveset maker"
            modsupporthelperfunctions.charSelect.character_edit(modsupporthelperfunctions.kirbyindex,nil,kirbydescription,nil,nil,nil)
        end
        if modsupporthelperfunctions.charSelect.are_movesets_restricted ~= nil then

            kirbyaltmovesetcheck = function()
                if (gPlayerSyncTable[0].kirby == false)  and (not modsupporthelperfunctions.charSelect.are_movesets_restricted()) and (modsupporthelperfunctions.charSelect.get_options_status(modsupporthelperfunctions.kirbycharselectoptions.localmovesettogglepos) == 1) and (modsupporthelperfunctions.kirbyindex == modsupporthelperfunctions.charSelect.character_get_current_number()) then
                    gPlayerSyncTable[0].kirby = true
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    gPlayerSyncTable[0].kirbypossess = 0
                    gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                elseif (gPlayerSyncTable[0].kirby == true) and ((modsupporthelperfunctions.kirbyindex ~= modsupporthelperfunctions.charSelect.character_get_current_number()) or (modsupporthelperfunctions.charSelect.get_options_status(modsupporthelperfunctions.kirbycharselectoptions.localmovesettogglepos) == 0) or (modsupporthelperfunctions.charSelect.are_movesets_restricted())) then
                    gPlayerSyncTable[0].kirby = false
                    possessed = false
                    gPlayerSyncTable[0].kirbypossess = 0
                    if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                    end
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    if kirbyissuper and kirbyhaswing == false then
                        gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
                    end
                elseif (gPlayerSyncTable[0].kirby == true) then
                    modmenuopen = modsupporthelperfunctions.charSelect.is_menu_open()
                    modsupporthelperfunctions.kirby.kirbyaltsetmodelfunction()
                elseif (gPlayerSyncTable[0].kirby == false) and (modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()] ~= nil) and (gPlayerSyncTable[0].kirbypower ~= modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]) then
                    gPlayerSyncTable[0].kirbypower = modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]
                end
            end
            modsupporthelperfunctions.charSelect.character_hook_moveset(modsupporthelperfunctions.kirbyindex,HOOK_ON_MODS_LOADED,function ()

            end)--making kirby show up as having a moveset in character select
        elseif modsupporthelperfunctions.charSelect.restrict_movesets ~= nil then

            kirbyaltmovesetcheck = function()
                if (gPlayerSyncTable[0].kirby == false) and (modsupporthelperfunctions.charSelect.get_options_status(modsupporthelperfunctions.kirbycharselectoptions.localmovesettogglepos) == 1) and (modsupporthelperfunctions.kirbyindex == modsupporthelperfunctions.charSelect.character_get_current_number()) then
                    gPlayerSyncTable[0].kirby = true
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    gPlayerSyncTable[0].kirbypossess = 0
                    gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                elseif (gPlayerSyncTable[0].kirby == true) and ((modsupporthelperfunctions.kirbyindex ~= modsupporthelperfunctions.charSelect.character_get_current_number()) or (modsupporthelperfunctions.charSelect.get_options_status(modsupporthelperfunctions.kirbycharselectoptions.localmovesettogglepos) == 0)) then
                    gPlayerSyncTable[0].kirby = false
                    possessed = false
                    gPlayerSyncTable[0].kirbypossess = 0
                    if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                    end
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    if kirbyissuper and kirbyhaswing == false then
                        gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
                    end
                elseif (gPlayerSyncTable[0].kirby == true) then
                    modmenuopen = modsupporthelperfunctions.charSelect.is_menu_open()
                    modsupporthelperfunctions.kirby.kirbyaltsetmodelfunction()
                elseif (gPlayerSyncTable[0].kirby == false) and (modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()] ~= nil) and (gPlayerSyncTable[0].kirbypower ~= modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]) then
                    gPlayerSyncTable[0].kirbypower = modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]
                end
            end
            modsupporthelperfunctions.charSelect.character_hook_moveset(modsupporthelperfunctions.kirbyindex,HOOK_ON_MODS_LOADED,function ()

            end)--making kirby show up as having a moveset in character select
        else
            kirbyaltmovesetcheck = function()
                if (gPlayerSyncTable[0].kirby == false) and (modsupporthelperfunctions.kirbyindex == modsupporthelperfunctions.charSelect.character_get_current_number()) then
                    gPlayerSyncTable[0].kirby = true
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    gPlayerSyncTable[0].kirbypossess = 0
                    gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                elseif (gPlayerSyncTable[0].kirby == true) and (modsupporthelperfunctions.kirbyindex ~= modsupporthelperfunctions.charSelect.character_get_current_number()) then
                    gPlayerSyncTable[0].kirby = false
                    possessed = false
                    gPlayerSyncTable[0].kirbypossess = 0
                    if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                    end
                    gPlayerSyncTable[0].kirbypower = kirbyability_none
                    if kirbyissuper and kirbyhaswing == false then
                        gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
                    end
                elseif (gPlayerSyncTable[0].kirby == true) then
                    modmenuopen = modsupporthelperfunctions.charSelect.is_menu_open()
                    modsupporthelperfunctions.kirby.kirbyaltsetmodelfunction()
                elseif (gPlayerSyncTable[0].kirby == false) and (modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()] ~= nil) and (gPlayerSyncTable[0].kirbypower ~= modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]) then
                    gPlayerSyncTable[0].kirbypower = modsupporthelperfunctions.charSelecteatablechar[modsupporthelperfunctions.charSelect.character_get_current_number()]
                end
            end
        end
        kirbyaltmovesettoggle = function(bool)
            modsupporthelperfunctions.charSelect.set_menu_open(true)
            djui_chat_message_create('The character select mod is on opening menu where kirby can be toggled')
            return true
        end
    end
    if _G.sonichealth ~= nil then
        modsupporthelperfunctions.sonichealth = _G.sonichealth --local reference for _G.sonichealth
        modsupporthelperfunctions.sonichealth.supermoveset(kirbysuper) --adding a super form for kirby through sonic health's api
    end

    if bhvPSwitch_MOP ~= nil then
        modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvPSwitch_MOP,kirbybhvPSwitch_MOP)--making the pswitch mop able to be hit by kirby projectiles
    end

    if _G.bowsMoveset ~= nil then
        modsupporthelperfunctions.kirby.add_eatable_enemy("fire",bhvBowserPlayerFireball,"playable bowser fireball")--adding the Coop Bowser Moveset (by wibblus)'s fireball to the fire enemy table  
    end

    if _G.mhApi ~= nil and (allycheck == nil) then
        modsupporthelperfunctions.mhApi = _G.mhApi --local reference for _G.mhApi
        modsupporthelperfunctions.kirby.addallycheck(kirbymariohuntallycheck)
    elseif (_G.ShineThief ~= nil) then
        if (allycheck == nil) then
            modsupporthelperfunctions.ShineThief = _G.ShineThief --local reference for _G.ShineThief
            modsupporthelperfunctions.kirby.addallycheck(kirbyshinethiefallycheck)
        end
        modsupporthelperfunctions.kirby.add_eatable_enemy("fire",bhvFireBall,"shine thief fireball")--adding the shine thief's fireball projectile to the fire enemy table  
        modsupporthelperfunctions.kirby.add_eatable_enemy("bomb",bhvThrownBobomb,"shine thief bomb")--adding the shine thief's bomb projectile to the bomb enemy table  
        modsupporthelperfunctions.kirby.add_eatable_enemy("none",bhvBoomerang,"shine thief bomerrang")--adding the shine thief's bomerrang projectile to the bomb enemy table  
    elseif _G.HideAndSeek ~= nil and (allycheck == nil) then
        modsupporthelperfunctions.HideAndSeek = _G.HideAndSeek --local reference for _G.HideAndSeek
        modsupporthelperfunctions.kirby.addallycheck(kirbyhideandseekallycheck)
    end

    if _G.ktools_act_name ~= nil then --adding kirby moves to the action table in the king's dev tools mod
        modsupporthelperfunctions.ktools_act_name = _G.ktools_act_name
        for key,value in pairs(kirbyactiontable) do
            modsupporthelperfunctions.ktools_act_name(value,key)
        end
    end

    for key,value in pairs(gActiveMods) do
        if (value.incompatible ~= nil) and string.match((value.incompatible), "romhack") then
            if value.name == nil then

            elseif ((value.name == "Star Road") or (value.name == "Scrooge 64")) then --star road support
                modsupporthelperfunctions.kirby.add_directattackabletableenemy(bhvSMSRBreakableWindow,"nointeract",bhvSMSRBreakableWindowdirect) --making star road's breakable window to be broken by kirby attacks
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRBreakableWindow,bhvSMSRBreakableWindowbyprojectile)--making star road's breakable window able to be broken by kirby projectiles
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRBreakableFloor,bhvSMSRBreakableWindowbyprojectile) --making star road's breakable floor able to be broken by kirby attacks
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRBreakableRock,bhvSMSRBreakableWindowbyprojectile) --making star road's breakable rock able to be broken by kirby attacks
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRSmallBee,"generic_attack") --making star road's bee enemy killable by kirby attacks
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRShyGuy,"generic_attack") --making star road's shy guy enemy killable by kirby attacks
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSMSRWigglerHead,"id_bhvWigglerHead") --making star road's wiggler enemy killable by kirby attacks
                if bhvBowser ~= nil then
                    modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvBowser,function(enemyobj,obj)
                       local hurtenemy = true
                        if (enemyobj.oAction ~= 0 and enemyobj.oAction ~= 4 and enemyobj.oAction ~= 5 and enemyobj.oAction ~= 6 and enemyobj.oAction ~= 12 and enemyobj.oAction ~= 20 )  then
                            childobj = obj_get_nearest_object_with_behavior_id(obj,id_bhvBowserTailAnchor)
                            if (obj_has_behavior_id(obj,id_bhvkirbyairbullet) ~= 0 ) then
                                hurtenemy = true
                            elseif  childobj ~= nil and obj_check_hitbox_overlap(obj, childobj) or childobj == nil then
                                if (obj_has_behavior_id(obj,id_bhvkirbyflame) ~= 0 ) and (abs_angle_diff( (obj_angle_to_object(enemyobj,gMarioStates[network_local_index_from_global(obj.oKirbyProjectileOwner)].marioObj)), enemyobj.oFaceAngleYaw) <= 0x3000) then
            
                                else
                                    enemyobj.oHealth = enemyobj.oHealth - 1
                                    if enemyobj.oHealth  <= 0 then
                                        enemyobj.oMoveAngleYaw = enemyobj.oBowserAngleToCentre + 0x8000
                                        enemyobj.oAction = 4
                                        spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,enemyobj.oPosX,enemyobj.oPosY,enemyobj.oPosZ,function(newobj)
                                            newobj.parentObj = enemyobj
                                        end)
                                    else
                                        enemyobj.oAction = 12
                                    end
                                end
                            elseif (abs_angle_diff( (obj_angle_to_object(enemyobj,obj)), enemyobj.oFaceAngleYaw) > 0x3000) then
                                hurtenemy = false
                            end
                        elseif enemyobj.oAction == 4 and enemyobj.oSubAction == 11 and enemyobj.oHealth  > 0 then
							enemyobj.oHealth = enemyobj.oHealth - 1
							enemyobj.oAction = 12
                        end
                        return hurtenemy
                    end) --making star road's bowser enemy killable by kirby attacks
                end
                modsupporthelperfunctions.kirby.add_eatable_enemy("wing",bhvSMSRSmallBee,"small bee")--adding the star road's bee enemy to the wing enemy table  
                modsupporthelperfunctions.kirby.add_eatable_enemy("none",bhvSMSRShyGuy,"star road shy guy")--adding the star road's shy guy enemy to the wing enemy table  
            elseif ((value.name == "Super Mario 64: The Underworld")) then --Super Mario 64: The Underworld support
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvSuperMario64TheUnderworldCustom010,bhvSM64underworldapparation) --making the underworld's apparation enemy killable by kirby projectiles
            elseif ((value.name == "Star Revenge 4 - The Kedama Takeover 64")) then --Star Revenge 4 - The Kedama Takeover 64 support
                modsupporthelperfunctions.kirby.add_eatable_enemy("none",bhvGoomba,"kedama goomba")--adding the Star Revenge 4's kedama goomba enemy to the none enemy table  
            elseif ((value.name == "Sonic Adventure 64 DX")) then --Sonic Adventure 64 DX support (Port of Team Cornersoft's SA64 C3 Demo, with a few extra functionalities and enhancements)
                modsupporthelperfunctions.kirby.add_eatable_enemy("bomb",bhvUkikaboom,"evil Ukiki's Ukikaboom")--adding the Sonic Adventure 64 DX's Ukiki bomb to the bomb enemy table  
                modsupporthelperfunctions.kirby.add_eatable_enemy("bomb",bhvEvilUkiki,"evil Ukiki(immobile)")--adding the Sonic Adventure 64 DX's evil Ukiki enemy (immobile variant)to the bomb enemy table  
                modsupporthelperfunctions.kirby.add_eatable_enemy("bomb",bhvEvilUkikiMoving,"evil Ukiki(mobile)")--adding the Sonic Adventure 64 DX's Ukiki bomb to the bomb enemy table  
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvEvilUkiki,"generic_attack") --making the Sonic Adventure 64 DX's evil Ukiki enemy (immobile variant) killable by kirby projectiles
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvEvilUkikiMoving,"generic_attack") --making the Sonic Adventure 64 DX's evil Ukiki enemy (mobile variant) killable by kirby projectiles
            elseif ((value.name == "ULTRA IRIOS")) then --ULTRA IRIOS romhack support 
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvULTRAIRIOSCustom002,bhvULTRAIRIOSprojectile) --making the ULTRA IRIOS killable by kirby projectiles
            elseif ((value.name == "\\#FFC600\\Star \\#00BEFF\\Revenge \\#FF0034\\7\\#E7E7E7\\-Park of Time")) then --star revenge 7 romhack support 
                maxkirbyjumps = 1
                if romhackchange == nil then
                    modsupporthelperfunctions.kirby.addromhackchange(starrevenge7romhackchange)
                    modsupporthelperfunctions.hasromhackbadge = _G.romhackbadges.hasbadge --local reference for _G.romhackbadges.hasbadge
                    modsupporthelperfunctions.hasromhackbadgetable = {} --table of collected badges
                end
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvFFC600Star00BEFFRevengeFF00347E7E7E7ParkOfTimeCustom007,kirbybhv_superblock_revenge7,function(enemyobj,obj)
                    return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                end) --making the Super block in star revenge 7 destroyable by kirby projectiles
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvFFC600Star00BEFFRevengeFF00347E7E7E7ParkOfTimeCustom008,kirbybhv_ultrablock_revenge7,function(enemyobj,obj)
                    return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                end) --making the Ultra block in star revenge 7 destroyable by kirby projectiles
            elseif ((value.name == "\\#D10000\\Star \\#FFB128\\Revenge \\#7238BD\\7.5: Kedowser's Return") or ((value.name == "\\#2969B0\\Star Revenge 7.5: \\#475577\\Kedowser's \\#28324E\\Return"))) then --star revenge 7.5 romhack support 
                maxkirbyjumps = 1
                if romhackchange == nil then
                    modsupporthelperfunctions.kirby.addromhackchange(starrevenge7romhackchange)
                    modsupporthelperfunctions.hasromhackbadge = _G.romhackbadges.hasbadge --local reference for _G.romhackbadges.hasbadge
                    modsupporthelperfunctions.hasromhackbadgetable = {} --table of collected badges
                end
                if (value.name == "\\#D10000\\Star \\#FFB128\\Revenge \\#7238BD\\7.5: Kedowser's Return") then
                    modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvD10000StarFFB128Revenge7238BD75KedowserSReturnCustom007,kirbybhv_superblock_revenge7,function(enemyobj,obj)
                        return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                    end) --making the Super block in star revenge 7 destroyable by kirby projectiles
                    modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvD10000StarFFB128Revenge7238BD75KedowserSReturnCustom008,kirbybhv_ultrablock_revenge7,function(enemyobj,obj)
                        return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                    end) --making the Ultra block in star revenge 7 destroyable by kirby projectiles
                else
                    modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhv2969B0StarRevenge75475577KedowserS28324EReturnCustom007,kirbybhv_superblock_revenge7,function(enemyobj,obj)
                        return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                    end) --making the Super block in star revenge 7 destroyable by kirby projectiles
                    modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhv2969B0StarRevenge75475577KedowserS28324EReturnCustom008,kirbybhv_ultrablock_revenge7,function(enemyobj,obj)
                        return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                    end) --making the Ultra block in star revenge 7 destroyable by kirby projectiles
                end 
            elseif (value.name == "\\#0129FD\\Star \\#EC0000\\Revenge \\#E7E7E7\\8-Scepter of Hope") then
                if romhackchange == nil then
                    modsupporthelperfunctions.kirby.addromhackchange(function ()
                        if (modsupporthelperfunctions.hasromhackbadgetable['SB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('SB') == "1") then --if kirby has the super stomp badge
                            modsupporthelperfunctions.hasromhackbadgetable['SB'] = 1
                        end
                        if (modsupporthelperfunctions.hasromhackbadgetable['UB'] == nil) and (modsupporthelperfunctions.hasromhackbadge('UB') == "1") then --if kirby has the ultra stomp badge
                            modsupporthelperfunctions.hasromhackbadgetable['UB'] = 1
                        end
                    end)
                    modsupporthelperfunctions.hasromhackbadge = _G.romhackbadges.hasbadge --local reference for _G.romhackbadges.hasbadge
                    modsupporthelperfunctions.hasromhackbadgetable = {} --table of collected badges
                end
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhv0129FDStarEC0000RevengeE7E7E78ScepterOfHopeCustom005,kirbybhv_superblock_revenge7,function(enemyobj,obj)
                    return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                end) --making the Super block in star revenge 8 destroyable by kirby projectiles
                modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhv0129FDStarEC0000RevengeE7E7E78ScepterOfHopeCustom006,kirbybhv_ultrablock_revenge7,function(enemyobj,obj)
                    return obj_check_overlap_with_hitbox_params(enemyobj,obj.oPosX + obj.oVelX ,obj.oPosY + obj.oVelY,obj.oPosZ + obj.oVelZ,360,360,360)
                end) --making the Ultra block in star revenge 8 destroyable by kirby projectiles
            end
        elseif (value.incompatible ~= nil) and string.match((value.incompatible), "gamemode") then
            if value.name == nil then

            elseif ((value.name == "Arena"))then
                -- _G.kirby.add_eatable_enemy("bomb",bhvArenaCustom007,"arena bobomb")--adding arena's bobomb projectile to the bomb enemy table  
                -- _G.kirby.add_eatable_enemy("none",bhvArenaCustom008,"arena cannonball")--adding arena's cannonball projectile to the none enemy table  
                modsupporthelperfunctions.kirby.add_eatable_enemy("fire",bhvArenaCustom009,"arena flame")--adding arena's flame projectile to the fire enemy table  
                if (allycheck == nil) and (_G.Arena.get_player_team ~= nil) then --if another mod didn't already pass an allycheck function
                    modsupporthelperfunctions.Arena = _G.Arena
                    modsupporthelperfunctions.kirby.addallycheck(kirbyarenaallycheck)
                end
            end
        elseif (value.incompatible ~= nil) and string.match((value.incompatible), "gore") then
            if ((value.name == "GORE / Hard-Mode!")) then
                goremodehardmodesetup(enemytable)
            end

        elseif value.name == nil then

        elseif (string.match(value.name,"OMM Rebirth")) then
            --_G.kirby.add_eatable_enemy("ghost",bhvOmmCappy,"omm rebirth cappy",true,kirbycappy,"nointeract")--adding the omm rebirth cappy enemy to the ghost enemy table  currently need to make custom function for this otherwise it gives infinite ability stars
        elseif (string.match(value.name,"Door Bust")) then
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(id_bhvDoor,destroy_Door_by_projectile) --making the door bust mod's door destroyable by kirby projectiles
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(id_bhvStarDoor,destroy_Door_by_projectile) --making the door bust mod's door destroyable by kirby projectiles
            modsupporthelperfunctions.kirby.add_directattackabletableenemy(id_bhvDoor,destroy_Door) --making the door bust mod's door destroyable by kirby attacks
            modsupporthelperfunctions.kirby.add_directattackabletableenemy(id_bhvStarDoor,destroy_Door) --making the door bust mod's door destroyable by kirby attacks  
        elseif (string.match(value.name,"Brutal Bosses")) then
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvBossCustomMadPiano,function(enemyobj,obj)
                if enemyobj.oAction ~= 4 then
                    local m = nearest_possible_mario_state_to_object(enemyobj)
                    enemyobj.oForwardVel = -20
                    enemyobj.oVelY = 40
                    enemyobj.oMoveAngleYaw = obj_angle_to_object(enemyobj, m.marioObj)
                    enemyobj.oAction = 4
                    return true
                end
            end) --making the Brutal Bosses mod's piano hittable by projectiles
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvBossCustomTuxiesMother,function(enemyobj,obj)
                local projectileimmuneactions = {[0] = true,[5] = true,[6] = true,[7] = true}
                if (projectileimmuneactions[enemyobj.oAction] ~= true) and (enemyobj.oInteractType ~= INTERACT_TEXT) then
                    if enemyobj.oInteractType == INTERACT_BOUNCE_TOP2 then
                        play_sound(SOUND_GENERAL2_RIGHT_ANSWER, enemyobj.header.gfx.cameraToObject)
                        if enemyobj.oHealth > 1 then
                            enemyobj.oHealth = enemyobj.oHealth - 1
                            enemyobj.oSubAction = 1
                            enemyobj.oAction = 6
                        else
                            enemyobj.header.gfx.node.flags = enemyobj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE --make mother boss's model invisible
                            seq_player_lower_volume(SEQ_PLAYER_LEVEL, 15, 60)
                            smlua_text_utils_dialog_replace(gBehaviorValues.dialogs.TuxieMotherBabyWrongDialog, 1, 4, 30, 200,
                            "Oh... I shouldn't\n"
                            .. "have underestimated\n"
                            .. "you.\n"
                            .. "Owwww...\n"
                            .. "What do you want?\n"
                            .. "A reward?\n"
                            .. "People like you\n"
                            .. "deserve nothing!\n"
                            .. "...Fine! Take this\n"
                            .. "Dark Star!\n"
                            .. "Just leave me alone.\n"
                            .. "Please.")
                            enemyobj.oAction = 7
                        end
                    end
                    return true
                elseif (enemyobj.oInteractType == INTERACT_TEXT) then
                    return false
                end
            end) --making the Brutal Bosses mod's tuxie's mother boss hittable by projectiles
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvYoshi,function(enemyobj,obj)
                local YOSHI_ACT_DAMAGED = YOSHI_ACT_CREDITS + 4
                if (enemyobj.oAction > YOSHI_ACT_CREDITS) and (enemyobj.oInteractType ~= INTERACT_TEXT) and (enemyobj.oAction ~= YOSHI_ACT_DAMAGED) then
                    enemyobj.oInteractStatus = INT_STATUS_INTERACTED | INT_STATUS_TOUCHED_BOB_OMB
                    return true
                elseif (enemyobj.oInteractType == INTERACT_TEXT) then
                    return false
                end
            end) --making the Brutal Bosses mod's yoshi boss hittable by projectiles
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(bhvBossCustomToadMessage,function(enemyobj,obj)
                local projectileimmuneactions = {[2] = true,[4] = true}
                if (projectileimmuneactions[enemyobj.oAction] ~= true) and (enemyobj.oInteractType ~= INTERACT_TEXT) then
                    enemyobj.oInteractStatus = INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
                    return true
                elseif (enemyobj.oInteractType == INTERACT_TEXT) then
                    return false
                end
            end) --making the Brutal Bosses mod's Toad boss hittable by projectiles
            modsupporthelperfunctions.kirby.add_projectilehurtableenemy(id_bhvWigglerHead,function(enemyobj,obj)
                local WIGGLER_ACT_CUSTOM_SHRINK = WIGGLER_ACT_FALL_THROUGH_FLOOR + 1
                local WIGGLER_ACT_CUSTOM_GROW = WIGGLER_ACT_FALL_THROUGH_FLOOR + 2
                if (enemyobj.oAction == WIGGLER_ACT_WALK) and (enemyobj.oWigglerTextStatus >= WIGGLER_TEXT_STATUS_COMPLETED_DIALOG) and (enemyobj.oTimer >= 60) then
                    if (obj_has_behavior_id(obj,id_bhvkirbyairbullet) == 0 ) then
                        if (enemyobj.header.gfx.scale.x == 1) then -- grow back when hit in small form
                            enemyobj.oAction = WIGGLER_ACT_KNOCKBACK
                        else
                            cur_obj_play_sound_2(SOUND_OBJ_WIGGLER_ATTACKED)
                            enemyobj.oAction = WIGGLER_ACT_JUMPED_ON
                        end                        
                    end
                end
            end) --making the Brutal Bosses mod's wiggler boss hittable by projectiles
        end
    end
    if modsupporthelperfunctions.kirby.kirbyaltsetmodelfunction == nil then
        hook_event(HOOK_OBJECT_SET_MODEL,object_set_model) -- Called when a behavior changes models. Also runs when a behavior spawns.
    end
    if servermodsync then
        if hook_mod_menu_text ~= nil then
            hook_mod_menu_text(string.format("mod version %s",version))
        end
        hook_mod_menu_button("print kirby server config",function(index)
            kirbyconfig_command('printserver')
        end)
        hook_mod_menu_button("print kirby server config",function(index)
            kirbyconfig_command('printlocal')
        end)

        hook_mod_menu_button("save current kirby config",function(index)
            kirbyconfig_command('save')
        end)
        hook_mod_menu_button("load kirby config",function(index)
            kirbyconfig_command('load')
        end)
        hook_mod_menu_button("toggle kirby losing ability on hit",function(index)
            local s
            if gGlobalSyncTable.loseability then
                s = 'off'
            else
                s = 'on'
            end
            kirbyloseability_command(s)
        end)
        hook_mod_menu_button("toggle kirby ability to pick an ability on star select",function(index)
            local s
            if gGlobalSyncTable.abilitychoose then
                s = 'off'
            else
                s = 'on'
            end
            kirbyabilitychoose_command(s)
        end)
        hook_mod_menu_button("toggle kirby projectiles player interaction",function(index)
            local s
            if gGlobalSyncTable.projectilehurtallies then
                s = 'off'
            else
                s = 'on'
            end
            kirbysolidprojectiles_command(s)
        end)
        
        hook_mod_menu_checkbox("move kirby ui with dpad",false,function(index,value)
            movingui = value
        end)
        hook_mod_menu_checkbox("toggle kirby ui",false,function(index,value)
            toggleui = value
        end)
        hook_mod_menu_checkbox("change kirby swallow button",false,function(index,value)
            
            if value then
                if (settingswallowbutton == false) and (set2ndswallowbutton == false) then
                    settingswallowbutton = value
                    if gPlayerSyncTable[0].kirby == false then
                        djui_chat_message_create('turn on kirby moveset to change the swallow button')
                    end
                end
            end
        end)
        hook_mod_menu_button("help",function(index)
            kirby_command('help')
        end)
        hook_mod_menu_button("kirby abilitylist",function(index)
            kirby_command('abilitylist')
        end)
        

        if _G.cheatsApi ~= nil then
            hook_mod_menu_checkbox("kirby ability chooser",false,function(index,value)
                kirbyfreechoose = value
            end)
        end
        if kirbyaltmovesetcheck == nil then
            hook_mod_menu_checkbox("kirby moveset",false,function(index,value)
                if forcetoggle > 0 then
                    if (forcetoggle == 1) and gPlayerSyncTable[0].kirby ~= false then
                        gPlayerSyncTable[0].kirby = false
                        possessed = false
                        gPlayerSyncTable[0].kirbypossess = 0
                        if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                            gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                        end
                        gPlayerSyncTable[0].kirbypower = kirbyability_none
                        if kirbyissuper and kirbyhaswing == false then
                            gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
                        end
                    elseif (forcetoggle == 2) and gPlayerSyncTable[0].kirby ~= true then
                        gPlayerSyncTable[0].kirby = true
                        gPlayerSyncTable[0].kirbypower = kirbyability_none
                        gPlayerSyncTable[0].kirbypossess = 0
                        gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                    end
                elseif (value ~= gPlayerSyncTable[0].kirby) then
                    if value then
                        gPlayerSyncTable[0].kirbypower = kirbyability_none
                        gPlayerSyncTable[0].kirbypossess = 0
                        gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
                    else
                        possessed = false
                        gPlayerSyncTable[0].kirbypossess = 0
                        if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                            gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
                        end
                        gPlayerSyncTable[0].kirbypower = kirbyability_none
                        if kirbyissuper and kirbyhaswing == false then
                            gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
                        end
                    end
                    gPlayerSyncTable[0].kirby = value
                end
            end)
        else
            hook_mod_menu_button("kirby moveset",function(index)
                local s
                if gPlayerSyncTable[0].kirby then
                    s = 'off'
                else
                    s = 'on'
                end
                kirby_command(s)
            end)
        end
    end
end

--- @param m MarioState
--Called when a player connects
local function on_player_connected(m)
    -- only run on server
    if not network_is_server() then
        return
	end
    if servermodsync == false then
        if usingcoopdx == 3 then
            servermodsync = true
        end
        modsupport()
        
        if usingcoopdx == 0 then
            servermodsync = true
			log_to_console('You are using a version of excoop before the merging of coopdx and excoop some features are unavailable')
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases')
            log_to_console('or if using the outdated excoop android port then instead use the coopdx port at https://github.com/ManIsCat2/sm64coopdx/releases')
		elseif usingcoopdx <= 2 then
            servermodsync = true
			log_to_console('You are using a version of coopdx before the merging of coopdx and excoop some features are unavailable',2)
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases',2)
		end
    end
	for i=0,(MAX_PLAYERS-1) do
		if (gPlayerSyncTable[i].gaincoin == nil or gPlayerSyncTable[i].kirby == nil or gPlayerSyncTable[i].canexhale == nil or gPlayerSyncTable[i].losingability == nil or gPlayerSyncTable[i].kirbyjumps == nil or gPlayerSyncTable[i].kirbypower == nil or gPlayerSyncTable[i].kirbypossess == nil or gPlayerSyncTable[i].breathingfire == nil or  gPlayerSyncTable[i].inhaling == nil) then
			gPlayerSyncTable[i].gaincoin = 0
            gPlayerSyncTable[i].kirby = false
            gPlayerSyncTable[i].canexhale = false
            gPlayerSyncTable[i].canfloat = false
            gPlayerSyncTable[i].losingability = false
            gPlayerSyncTable[i].kirbyjumps = 0
            gPlayerSyncTable[i].kirbypower = kirbyability_none
            gPlayerSyncTable[i].kirbypossess = 0
            gPlayerSyncTable[i].breathingfire = false
            gPlayerSyncTable[i].inhaledplayer = inhaledtable.held_none
            gPlayerSyncTable[i].livingprojectile = false
            gPlayerSyncTable[i].inhaleescape = 0
            gPlayerSyncTable[i].grabbedby = gNetworkPlayers[i].globalIndex
            gPlayerSyncTable[i].inhaling = false
            gPlayerSyncTable[i].modelId = nil
            gPlayerSyncTable[i].possessedmodelId = nil
		end
    end
end

local function print_table(table)
    local t = ''

    for key,value in pairs(table)do
        t = t .. ' ' .. table[key]
        if next(table,key) ~= nil then
            t = t .. ','
        end
    end
    return t
end

---@param m MarioState
---@param o Object
---@param interactType InteractionType
---@param interactValue boolean
--this function is for kirby interacting with objects.
local function on_interact(m,o,interactType,interactValue)
    local interactkicked = {[INT_KICK] = true,[INT_TRIP] = true} --table of interact values for an object being kicked
    if m.playerIndex ~= 0 then
        return
    elseif gPlayerSyncTable[0].kirby == false then
        if (obj_has_behavior_id(o,id_bhvkirbyflame) ~= 0) then
            o.oInteractStatus = 0
            network_send_object(o, true)
        elseif (obj_has_behavior_id(o,id_bhvkirbybomb) ~= 0) and (interactkicked[determine_interaction(m,o)] == true)  then
                o.oKirbyProjectileOwner = gNetworkPlayers[m.playerIndex].globalIndex
                network_send_object(o, true)
        elseif(obj_has_behavior_id(o,id_bhvkirbylivingprojectile) ~= 0) then
            gPlayerSyncTable[network_local_index_from_global(o.oKirbyProjectileOwner)].livingprojectile = false
        elseif (obj_has_behavior_id(o,id_bhvkirbyinhalehitbox) ~= 0) and (m.action ~= ACT_KIRBY_LIVING_PROJECTILE and (m.action ~= ACT_GRABBED)) then
            o.oInteractStatus = INT_STATUS_GRABBED_MARIO | INT_STATUS_INTERACTED
            o.usingObj = m.marioObj
            m.usedObj = o
            m.interactObj = o
            m.heldByObj = o
            m.pos.x = m.usedObj.oPosX
            m.pos.y = m.usedObj.oPosY
            m.pos.z = m.usedObj.oPosZ
            set_mario_action(m,ACT_GRABBED,0)
            gPlayerSyncTable[network_local_index_from_global(o.oKirbyProjectileOwner)].inhaledplayer = inhaledtable.held_held
        end
        return
    end
    local childobj
    local objectupdated = false
    if (obj_has_behavior_id(o,id_bhvVanishCap) ~= 0)then
        kirbyhasvanish = true
    elseif (obj_has_behavior_id(o,id_bhvWingCap) ~= 0)then
        kirbyhaswing = true
    elseif (obj_has_behavior_id(o,id_bhvkirbyflame) ~= 0) or (obj_has_behavior_id(o,id_bhvkirbylivingprojectile) ~= 0) then
        o.oInteractStatus = 0
        network_send_object(o, true)
    elseif (obj_has_behavior_id(o,id_bhvkirbybomb) ~= 0) and (interactkicked[determine_interaction(m,o)] == true)  then
        o.oKirbyProjectileOwner = gNetworkPlayers[m.playerIndex].globalIndex
        network_send_object(o, true)
    elseif (((obj_has_behavior_id(o,id_bhvKlepto) ~= 0) and (m.cap == SAVE_FLAG_CAP_ON_KLEPTO))) and (gGlobalSyncTable.loseability == true  and gPlayerSyncTable[0].kirbypower ~= kirbyability_none) then --make kirby able to have ability stolen by klepto
        m.cap = MARIO_CAP_ON_HEAD
        m.flags = m.flags | MARIO_NORMAL_CAP | MARIO_CAP_ON_HEAD
        o.oAnimState = KLEPTO_ANIM_STATE_HOLDING_NOTHING
        o.oAction = KLEPTO_ACT_WAIT_FOR_MARIO
        objectupdated = true
        kirbypowerrelease(m)
    elseif ( ((obj_has_behavior_id(o,id_bhvUkiki) ~= 0) and (o.oBehParams2ndByte == UKIKI_CAP) and (m.cap == SAVE_FLAG_CAP_ON_UKIKI) and o.oUkikiTextState == UKIKI_TEXT_STOLE_CAP)) and (gGlobalSyncTable.loseability == true and gPlayerSyncTable[0].kirbypower ~= kirbyability_none) then --make kirby able to have ability stolen by ukiki
        m.cap = MARIO_CAP_ON_HEAD
        m.flags = m.flags | MARIO_NORMAL_CAP | MARIO_CAP_ON_HEAD
        o.oUkikiHasCap = o.oUkikiHasCap & ~UKIKI_CAP_ON
        o.oUkikiTextState = UKIKI_TEXT_DEFAULT
        o.oAction = UKIKI_ACT_IDLE
        kirbypowerrelease(m)
        objectupdated = true
    elseif (obj_has_behavior_id(o,id_bhvkirbyinhalehitbox) ~= 0) and (m.action ~= ACT_KIRBY_LIVING_PROJECTILE and (m.action ~= ACT_GRABBED)) then
        o.oInteractStatus = INT_STATUS_GRABBED_MARIO | INT_STATUS_INTERACTED
        o.usingObj = m.marioObj
        m.usedObj = o
        m.interactObj = o
        m.heldByObj = o
        m.pos.x = m.usedObj.oPosX
        m.pos.y = m.usedObj.oPosY
        m.pos.z = m.usedObj.oPosZ
        set_mario_action(m,ACT_GRABBED,0)
        gPlayerSyncTable[network_local_index_from_global(o.oKirbyProjectileOwner)].inhaledplayer = inhaledtable.held_held
    end
    local key = get_id_from_behavior(o.behavior)
    if kirbyabilitymovelist[m.action] == 1 or (directattackableenemy[key] == "custom") then

        if (directattackableenemy[key] == "custom") and (directattackfunctions[key] ~= nil) then --call an external function to determine interaction
            local customfunc = directattackfunctions[key]
            if customfunc ~= nil then
                customfunc(o)--custom object being hit by a kirby move
            end
        elseif ((obj_has_behavior_id(o,id_bhvKingBobomb) ~= 0) or (directattackableenemy[key] == "id_bhvKingBobomb") ) and (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 7 and o.oAction ~= 8) then
            o.oPosY = o.oPosY + 20
            o.oVelY = 50
            o.oForwardVel = 20
            o.oAction = 4
            objectupdated = true
        elseif ((obj_has_behavior_id(o,id_bhvBowser) ~= 0) or (directattackableenemy[key] == "id_bhvBowser")) and(o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 12 and o.oAction ~= 20 ) then
            childobj = obj_get_nearest_object_with_behavior_id(obj,id_bhvBowserTailAnchor)
            if  childobj ~= nil and obj_check_hitbox_overlap(m.marioObj, childobj) or childobj == nil then
                o.oHealth = o.oHealth - 1
                if o.oHealth  <= 0 then
                    o.oMoveAngleYaw = o.oBowserAngleToCentre + 0x8000
                    o.oAction = 4
                    spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,o.oPosX,o.oPosY,o.oPosZ,function(newobj)
                        newobj.parentObj = o
                    end)
                else
                    o.oAction = 12
                end
                objectupdated = true
            end
        elseif ((obj_has_behavior_id(o,id_bhvMips) ~= 0) or (directattackableenemy[key] == "id_bhvMips")) and (o.oMipsStarStatus == MIPS_STAR_STATUS_HAVENT_SPAWNED_STAR or o.oMipsStarStatus == MIPS_STAR_STATUS_SHOULD_SPAWN_STAR) then
            bhv_spawn_star_no_level_exit(o, o.oBehParams2ndByte + 3, bool_to_num[true])
            obj_init_animation(o,0)
            o.oAction = MIPS_ACT_IDLE
            o.oMipsStarStatus = MIPS_STAR_STATUS_ALREADY_SPAWNED_STAR
            objectupdated = true
        elseif ((obj_has_behavior_id(o,id_bhvChuckya) ~= 0) or (directattackableenemy[key] == "id_bhvChuckya")) and ( o.oAction ~= 2) then
            o.oInteractStatus = o.oInteractStatus & ~INT_STATUS_GRABBED_MARIO
            o.usingObj = nil
            o.oPosY = o.oPosY + 20
            o.oVelY = 50
            o.oForwardVel = 20
            o.oAction = 2
            objectupdated = true
        elseif (obj_has_behavior_id(o,id_bhvBreakableBox) ~= 0) or (obj_has_behavior_id(o,id_bhvExclamationBox) ~= 0) or (directattackableenemy[key] == "id_bhvBreakableBox") then
            o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        end
    elseif ((interactType & INTERACT_BOUNCE_TOP ~= 0) or (interactType & INTERACT_BOUNCE_TOP2 ~= 0)) and (m.pos.y > m.floorHeight) and (o.oInteractStatus & INT_STATUS_WAS_ATTACKED ~= 0) and (m.pos.y > (o.oPosY + o.hitboxHeight / 2 - o.hitboxDownOffset) ) then -- refresh kirby's midair jumps when bouncing on an enemy
        gPlayerSyncTable[0].kirbyjumps = maxkirbyjumps
        kirbyfloattime = kirbymaxfloattime
        gPlayerSyncTable[0].canexhale = false
    end

    if (m.action == ACT_KIRBY_GHOST_DASH) and (gPlayerSyncTable[0].kirbypossess == 0) and (possessableenemytable[key] ~= nil) and (not possessed) then
        if (possessableenemytable[key] == "custom") and (possessfunctions[key] ~= nil) then --call an external function to determine interaction
            local customfunc = possessfunctions[key]
            if customfunc ~= nil then
                possessed,gPlayerSyncTable[0].possessedmodelId = customfunc(m,o,interactType,interactValue)--obj being hit by kirby ghost dash return true to possess the enemy
            end
        elseif (possessableenemytable[key] == "goomba") and o.oHealth == 0 then
            gPlayerSyncTable[0].possessedmodelId = E_MODEL_GOOMBA
            possessed = true
        elseif (possessableenemytable[key] == "Swoop") and o.oHealth == 0 then
            gPlayerSyncTable[0].possessedmodelId = E_MODEL_SWOOP
            possessed = true
        elseif (possessableenemytable[key] == "bobomb") then
            gPlayerSyncTable[0].possessedmodelId = E_MODEL_BLACK_BOBOMB
            possessed = true
        elseif (possessableenemytable[key] == "bulletbill") then
            gPlayerSyncTable[0].possessedmodelId = E_MODEL_BULLET_BILL
            possessed = true
        end

        if possessed then
            gPlayerSyncTable[0].modelId = E_MODEL_NONE
            gPlayerSyncTable[0].kirbypossess = key
        end
    end

    if objectupdated == true then
        network_send_object(o, true)
    end
end

--sets up a clientside kirby ability display
local function kirbyDisplay()
    local hidetextactions = {[ACT_READING_AUTOMATIC_DIALOG] = true,[ACT_READING_NPC_DIALOG] = true,[ACT_READING_SIGN] = true, [ACT_INTRO_CUTSCENE] = true,[ACT_IN_CANNON] = true,[ACT_CREDITS_CUTSCENE] = true,[ACT_END_PEACH_CUTSCENE] = true,[ACT_END_WAVING_CUTSCENE] = true,[ACT_STAR_DANCE_NO_EXIT] = true}
    local m = gMarioStates[0]
    if (gPlayerSyncTable[0].kirby == false) or (hidetextactions[m.action] == true) or ( (m.action == ACT_IDLE) and (hidetextactions[m.prevAction] == true)) or ((toggleui == false) and (settingswallowbutton ~= true) and (movingui ~= true) and not((instarselect == true) and (gGlobalSyncTable.abilitychoose == true)) and (kirbyfreechoose ~= true)) or (modmenuopen)  then
        return
    end

    local possessname

    djui_hud_set_font(FONT_HUD)
    djui_hud_set_resolution(RESOLUTION_N64)

    local scale = 1

    local swallowbutton1name

    local swallowbutton2name

    local kirbyui_x_scaled = (kirbyui_x/320)*djui_hud_get_screen_width()
	local kirbyui_y_scaled = (kirbyui_y/240)*djui_hud_get_screen_height()

    local kirbytext
	djui_hud_set_color(255, 255, 255, 255)
    if (instarselect == false) and (gPlayerSyncTable[0].kirbypossess ~= 0) then
        if possessablenametable[gPlayerSyncTable[0].kirbypossess] ~= nil then
            possessname = possessablenametable[gPlayerSyncTable[0].kirbypossess]
        else
            possessname = "?"
        end
        kirbytext = string.format("possessing %s", possessname)
    elseif settingswallowbutton == true then
        if buttons[swallowbutton1] ~= nil then
            swallowbutton1name = buttons[swallowbutton1].name
        else
            swallowbutton1name = "nil"
        end

        if buttons[swallowbutton2] ~= nil then
            swallowbutton2name = buttons[swallowbutton2].name
        else
            swallowbutton2name = "nil"
        end
        kirbytext = string.format("swallowbutton combo %s +%s",swallowbutton1name, swallowbutton2name)

    else
        kirbytext = string.format("ability %s", kirbyabilitylist[gPlayerSyncTable[0].kirbypower])

    end

    if (djui_hud_measure_text(kirbytext) + kirbyui_x_scaled) > djui_hud_get_screen_width() then
        djui_hud_print_text(kirbytext, djui_hud_get_screen_width() - djui_hud_measure_text(kirbytext), -kirbyui_y_scaled, scale)
    else
        djui_hud_print_text(kirbytext, kirbyui_x_scaled, -kirbyui_y_scaled, scale)
    end

    if (instarselect == true) and (gGlobalSyncTable.abilitychoose == true) or kirbyfreechoose then
        if kirbyui_y > -120 then
            djui_hud_print_text("pick an ability using dpad", 0, 220, scale)
        else
            djui_hud_print_text("pick an ability using dpad", 0, 0, scale)
        end
    elseif  movingui == true  then
        if kirbyui_y > -120 then
            djui_hud_print_text("move ui using dpad, a to save, b to cancel", 0, 220, 0.8)
        else
            djui_hud_print_text("move ui using dpad, a to save,b to cancel", 0, 0, 0.8)
        end
    elseif  settingswallowbutton == true  then

        if kirbyui_y > -120 then
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 220, 0.8)
        else
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 0, 0.8)
        end
    end
end

local function kirbyhookupdate()
    if kirbyaltmovesetcheck ~= nil then
        kirbyaltmovesetcheck()
    end
    if gPlayerSyncTable[0].kirby ~= true then
       return
    end
    if (instarselect == true) and (gPlayerSyncTable[0].inhaledplayer > 0) then
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_none
    end

    if (instarselect == true and (gGlobalSyncTable.abilitychoose == true)) or kirbyfreechoose then
        if (gMarioStates[0].controller.buttonPressed == R_JPAD) and (gPlayerSyncTable[0].kirbypower < (kirbyability_max -1)) then
            gPlayerSyncTable[0].kirbypower = gPlayerSyncTable[0].kirbypower + 1
            gPlayerSyncTable[0].kirbypossess = 0
            gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
            gPlayerSyncTable[0].possessedmodelId = nil
        elseif (gMarioStates[0].controller.buttonPressed == L_JPAD) and (gPlayerSyncTable[0].kirbypower > (kirbyability_none)) then
            gPlayerSyncTable[0].kirbypower = gPlayerSyncTable[0].kirbypower - 1
            gPlayerSyncTable[0].kirbypossess = 0
            gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
            gPlayerSyncTable[0].possessedmodelId = nil
        end
    elseif movingui == true then
        if (gMarioStates[0].controller.buttonPressed == A_BUTTON) then
            movingui = false
            djui_chat_message_create(string.format("kirbyability ui's x coordinate is now %d", kirbyui_x))
            djui_chat_message_create(string.format("kirbyability ui's y coordinate is now %d", kirbyui_y))
            mod_storage_save("kirbyability_ui_x", tostring(kirbyui_x))
            mod_storage_save("kirbyability_ui_y", tostring(kirbyui_y))
            djui_chat_message_create('kirby ui config saved to mod storage')
        elseif (gMarioStates[0].controller.buttonPressed == B_BUTTON) then
            movingui = false
            kirbyui_x = tonumber(mod_storage_load("kirbyability_ui_x"))
            kirbyui_y = tonumber(mod_storage_load("kirbyability_ui_y"))
            djui_chat_message_create('kirby ui config loaded')
            djui_chat_message_create(string.format("kirbyability ui's x coordinate is %d", kirbyui_x))
            djui_chat_message_create(string.format("kirbyability ui's y coordinate is %d", kirbyui_y))
        else    
            if (gMarioStates[0].controller.buttonDown == R_JPAD) and (kirbyui_x < 320) then
                kirbyui_x= kirbyui_x + 1
            elseif (gMarioStates[0].controller.buttonDown == L_JPAD) and (kirbyui_x > 0) then
                kirbyui_x= kirbyui_x - 1
            end

            if (gMarioStates[0].controller.buttonDown == U_JPAD) and (kirbyui_y < 0) then
                kirbyui_y= kirbyui_y + 1
            elseif (gMarioStates[0].controller.buttonDown == D_JPAD) and (kirbyui_y > -240) then
                kirbyui_y= kirbyui_y - 1
            end

        end
    elseif settingswallowbutton == true then
        if (gMarioStates[0].controller.buttonPressed == A_BUTTON) then
            if set2ndswallowbutton == false then
                set2ndswallowbutton = true
                gMarioStates[0].controller.buttonPressed = gMarioStates[0].controller.buttonPressed & ~A_BUTTON
            else
                settingswallowbutton = false
                set2ndswallowbutton = false
                djui_chat_message_create(string.format("kirby swallowbutton1 is %s", buttons[swallowbutton1].name))
                djui_chat_message_create(string.format("kirby swallowbutton2 is %s", buttons[swallowbutton2].name))
                mod_storage_save("swallowbutton1", tostring(swallowbutton1))
                mod_storage_save("swallowbutton2", tostring(swallowbutton2))
                djui_chat_message_create('kirby swallow button combo  saved to mod storage')
            end
        elseif (gMarioStates[0].controller.buttonPressed == B_BUTTON) then
            settingswallowbutton = false
            swallowbutton1 = tonumber(mod_storage_load("swallowbutton1"))
            swallowbutton2 = tonumber(mod_storage_load("swallowbutton2"))
            djui_chat_message_create('kirby swallow button config loaded')
            djui_chat_message_create(string.format("kirby swallowbutton1 is %s", buttons[swallowbutton1].name))
            djui_chat_message_create(string.format("kirby swallowbutton2 is %s", buttons[swallowbutton2].name))
        else
            if (gMarioStates[0].controller.buttonPressed == R_JPAD) and buttons[swallowbutton1].next ~= nil and set2ndswallowbutton == false then
                swallowbutton1 = buttons[swallowbutton1].next
            elseif (gMarioStates[0].controller.buttonPressed == L_JPAD) and buttons[swallowbutton1].prev ~= nil and set2ndswallowbutton == false then
                swallowbutton1 = buttons[swallowbutton1].prev
            elseif (gMarioStates[0].controller.buttonPressed == R_JPAD) and buttons[swallowbutton2].next ~= nil and set2ndswallowbutton == true then
                    swallowbutton2 = buttons[swallowbutton2].next
            elseif (gMarioStates[0].controller.buttonPressed == L_JPAD) and buttons[swallowbutton2].prev ~= nil and set2ndswallowbutton == true then
                    swallowbutton2 = buttons[swallowbutton2].prev
            end

        end
    end
end

--Called when the local player finishes the join process (if the player isn't the host)
local function on_join()
    if servermodsync == false then
        if usingcoopdx == 3 then
            servermodsync = true
        end
        modsupport()
        if usingcoopdx == 0 then
            servermodsync = true
			log_to_console('You are using a version of excoop before the merging of coopdx and excoop some features are unavailable')
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases')
            log_to_console('or if using the outdated excoop android port then instead use the coopdx port at https://github.com/ManIsCat2/sm64coopdx/releases')
		elseif usingcoopdx <= 2 then
            servermodsync = true
			log_to_console('You are using a version of coopdx before the merging of coopdx and excoop some features are unavailable',2)
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases',2)
		end
    end
    gPlayerSyncTable[0].gaincoin = 0
    gPlayerSyncTable[0].kirby = false
    gPlayerSyncTable[0].canexhale = false
    gPlayerSyncTable[0].losingability = false
    gPlayerSyncTable[0].kirbyjumps = 0
    gPlayerSyncTable[0].kirbypower = kirbyability_none
    gPlayerSyncTable[0].kirbypossess = 0
    gPlayerSyncTable[0].breathingfire = false
    gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_none
    gPlayerSyncTable[0].livingprojectile = false
    gPlayerSyncTable[0].inhaleescape = 0
    gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
    gPlayerSyncTable[0].inhaling = false
    gPlayerSyncTable[0].modelId = nil
end

---@param m MarioState
---@param stepType number
--Called once per player per frame before physics code is run, return an integer to cancel it with your own step result
local function before_phys_step(m,stepType)
    if m.playerIndex ~= 0 or gPlayerSyncTable[0].kirby == false then
        if gPlayerSyncTable[m.playerIndex].kirby and (gPlayerSyncTable[m.playerIndex].kirbypower ~= kirbyability_wrestler) and m.action == ACT_FREEFALL and m.prevAction == ACT_KIRBY_JUMP and m.vel.y < 0 and (gPlayerSyncTable[m.playerIndex].kirbypossess == 0) then
            if m.vel.y < -10 and (gPlayerSyncTable[m.playerIndex].canfloat == true) then
                m.vel.y = -10
            end
        end
        return
    end
    local obj
    if directattackablenointeracttable ~= nil then
        for key,value in pairs(directattackablenointeracttable)do
            obj = obj_get_nearest_object_with_behavior_id(m.marioObj,key)
            if obj ~= nil and ((nearest_mario_state_to_object(obj)).playerIndex == 0) and obj_check_hitbox_overlap(m.marioObj,obj) then

                if (directattackablenointeracttable[key] ~= nil) then --call an external function to determine interaction
                    local customfunc = directattackablenointeracttable[key]
                    if customfunc ~= nil then
                        customfunc(obj)--custom object being hit by a kirby move
                    end
                end
            end
        end
    end 
    if m.action == ACT_FREEFALL and m.vel.y > 0 and m.ceil ~= nil and m.ceil.type == SURFACE_HANGABLE and (m.ceilHeight < (m.pos.y + m.vel.y + 160)) and (m.controller.buttonDown & A_BUTTON ~= 0)  then
        return AIR_STEP_GRABBED_CEILING
    elseif m.action == ACT_FREEFALL and m.vel.y > 0 and m.ceil ~= nil and ((gPlayerSyncTable[0].kirbypossess == id_bhvSwoop) or (possessablemoveset[gPlayerSyncTable[0].kirbypossess] == "Swoop")) and (m.ceilHeight < (m.pos.y + m.vel.y + 160)) and (m.controller.buttonDown & A_BUTTON ~= 0)  then
            return AIR_STEP_GRABBED_CEILING 
    elseif  m.action == ACT_FREEFALL and m.prevAction == ACT_KIRBY_JUMP and m.vel.y < 0 and (gPlayerSyncTable[0].kirbypossess == 0) and (gPlayerSyncTable[0].kirbypower ~= kirbyability_wrestler) then
        if m.vel.y < -10 and (kirbyfloattime > 0) then
            m.vel.y = -10
            kirbyfloattime = kirbyfloattime - 1
            if (kirbyfloattime <= 0) then
                gPlayerSyncTable[0].canfloat = false
            elseif (gPlayerSyncTable[0].canfloat == false) then
                    gPlayerSyncTable[0].canfloat = true
            end
        end
        m.peakHeight = m.pos.y
    elseif ((gPlayerSyncTable[0].kirbypossess ~= 0) ) then
        m.peakHeight = m.pos.y
    end

end

-- Called when the level is initialized
local function on_level_init()
    if (gMarioStates[0].flags &  MARIO_VANISH_CAP) ~= 0 then
        kirbyhasvanish = true
    end
    if (gMarioStates[0].flags &  MARIO_WING_CAP) ~= 0 then
        kirbyhaswing = true
    end
    for i = 0,MAX_PLAYERS - 1,1 do
        inhalingtable[i] = false
    end
end

--- @param o Object
--Called when a behavior changes models. Also runs when a behavior spawns.
object_set_model = function(o)
    if obj_has_behavior_id(o, id_bhvMario) ~= 0 then
        local i = network_local_index_from_global(o.globalPlayerIndex)
        if (gPlayerSyncTable[i].modelId ~= nil) and (gPlayerSyncTable[i].kirby == true) and (obj_has_model_extended(o, gPlayerSyncTable[i].modelId) == 0) then
            return obj_set_model_extended(o, gPlayerSyncTable[i].modelId)
        end
    end
end


--Called when the current area is synchronized
local function on_sync_valid()
    local m = gMarioStates[0]
    local np = gNetworkPlayers[m.playerIndex]
    local grabbed = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    local o

    if (gPlayerSyncTable[0].breathingfire == true) then   
        spawn_sync_object(id_bhvkirbyflame, kirbymodeltable.kirbyflame, m.pos.x, m.pos.y, m.pos.z,function(obj)
            obj.oKirbyProjectileOwner = np.globalIndex
        end)
    elseif (grabbed == 0) and gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held and m.hurtCounter <= 0 then
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_owner_left
    elseif (grabbed > 0) and gPlayerSyncTable[grabbed].inhaledplayer == inhaledtable.warp_to_owner then
        if ( (gNetworkPlayers[0].currActNum == gNetworkPlayers[grabbed].currActNum) or (gNetworkPlayers[0].currAreaIndex == gNetworkPlayers[grabbed].currAreaIndex) or (gNetworkPlayers[0].currLevelNum == gNetworkPlayers[grabbed].currLevelNum) ) then
            gPlayerSyncTable[grabbed].inhaledplayer = inhaledtable.finish_warp
        end
    end
    for i = 0,MAX_PLAYERS - 1,1 do
        if possessingtable[i] == true then
            possessingtable[i] = false
        end
    end
end

---@param levelnum integer 
--Called when the level changes, return true to show act selection screen and false otherwise
local function use_act_select(levelnum)
    local owner = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    if (owner > 0) and ((gPlayerSyncTable[owner].inhaledplayer == inhaledtable.held_owner_left) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.warp_to_owner) or (gPlayerSyncTable[owner].inhaledplayer == inhaledtable.finish_warp)) then
        return false
    end
end

---@param bool boolean usedExitToCastle
--Called when the local player exits through the pause screen, return false to prevent the exit
local function on_pause_exit(bool)
    local m = gMarioStates[0]
    local grabbed = network_local_index_from_global(gPlayerSyncTable[0].grabbedby)
    if gPlayerSyncTable[0].inhaledplayer > 0 then
        gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
    end
    if m.action == ACT_KIRBY_LIVING_PROJECTILE then
        gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
    end
    if (grabbed > 0) and (gPlayerSyncTable[0].inhaledplayer ~= inhaledtable.warp_to_owner) and (gPlayerSyncTable[0].inhaledplayer ~= inhaledtable.finish_warp) and (gPlayerSyncTable[0].inhaledplayer ~= inhaledtable.held_owner_left) then --prevent exiting through the pause menu while held by kirby
        if m.heldByObj ~= nil then
            return false
        else
            gPlayerSyncTable[grabbed].inhaledplayer = inhaledtable.held_none
            gPlayerSyncTable[0].grabbedby = gNetworkPlayers[0].globalIndex
        end
    end
end

---@param dialogId integer
--Called when a dialog appears. Return false to prevent it from appearing. Return a second parameter as any string to override the text in the textbox
local function on_dialog(dialogId)
    local bossdeathid = {[gBehaviorValues.dialogs.KingBobombDefeatDialog] = id_bhvKingBobomb,[gBehaviorValues.dialogs.EyerokDefeatedDialog] = id_bhvEyerokBoss ,[gBehaviorValues.dialogs.KingWhompDefeatDialog] = id_bhvWhompKingBoss,[gBehaviorValues.dialogs.WigglerAttack1Dialog] =id_bhvWigglerHead,[gBehaviorValues.dialogs.Bowser1DefeatedDialog] =id_bhvBowser,[gBehaviorValues.dialogs.Bowser2DefeatedDialog] =id_bhvBowser,[gBehaviorValues.dialogs.Bowser3DefeatedDialog] =id_bhvBowser,[gBehaviorValues.dialogs.Bowser3Defeated120StarsDialog] =id_bhvBowser }
    local parentobj
    if dialogId == gBehaviorValues.dialogs.KingWhompDialog and (obj_get_nearest_object_with_behavior_id(gMarioStates[0].marioObj,id_bhvWhompKingBoss) ~= nil) then
        parentobj = obj_get_nearest_object_with_behavior_id(gMarioStates[0].marioObj,id_bhvWhompKingBoss)
        spawn_sync_object(id_bhvkingwhompabilitystarspawner,E_MODEL_NONE, parentobj.oPosX, parentobj.oPosY, parentobj.oPosZ,function(newobj)
            newobj.parentObj = parentobj
        end)
    end
    
    if bossdeathid[dialogId] ~= nil then
        local bossobj = obj_get_nearest_object_with_behavior_id(gMarioStates[0].marioObj,bossdeathid[dialogId])
        if bossobj ~= nil then
            boss_death(bossobj)
        end
    end

end

---@param m MarioState
---@param sound CharacterSound
--Called when mario retrieves a character sound to play, return a character sound or 0 to override it
local function on_character_sound(m,sound)
    if (gPlayerSyncTable[m.playerIndex].kirby ~= false) then
        return kirbyvoicesound(m,sound)
    end

end

hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step) --Called once per player per frame before physics code is run, return an integer to cancel it with your own step result
hook_event(HOOK_MARIO_UPDATE, mario_update) --Called once per player per frame at the end of a mario update
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action) --hook which is called every time a player's current action is changed
hook_event(HOOK_ON_PVP_ATTACK, on_pvp_attack) --hook for pvp attacks
hook_event(HOOK_ON_DEATH, on_death) --hook for the player dying
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining
hook_event(HOOK_ON_INTERACT, on_interact) --Called before mario interacts with an object, return true to allow the interaction
hook_event(HOOK_ON_HUD_RENDER, kirbyDisplay) -- hook for displaying ability
hook_event(HOOK_UPDATE, kirbyhookupdate) -- hook for displaying ability
hook_event(HOOK_JOINED_GAME, on_join) -- Called when the local player finishes the join process (if the player isn't the host)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init) -- Called when the level is initialized	
hook_event(HOOK_ON_SYNC_VALID,on_sync_valid) --Called when the current area is synchronized
hook_event(HOOK_USE_ACT_SELECT,use_act_select)--Called when the level changes, return true to show act selection screen and false otherwise
hook_event(HOOK_ON_PAUSE_EXIT,on_pause_exit)--Called when the local player exits through the pause screen, return false to prevent the exit
hook_event(HOOK_ON_DIALOG,on_dialog)--Called when a dialog appears. Return false to prevent it from appearing. Return a second parameter as any string to override the text in the textbox
hook_event(HOOK_CHARACTER_SOUND,on_character_sound) --Called when mario retrieves a character sound to play, return a character sound or 0 to override it

--chat commands

--- @param msg string
--this is the function for enabling or disabling kirby moveset, getting moveset info, and getting the list of available kirby abilities
kirby_command = function(msg)
    local m = string.lower(msg)
    if m == 'on' then
        if forcetoggle == 1 or forcetoggle == 3 then
            djui_chat_message_create('the ability to turn on the moveset was disabled by another mod')
            return true
        end
        if kirbyaltmovesettoggle ~= nil then
            return kirbyaltmovesettoggle(true)
        end
        djui_chat_message_create('kirby moveset is \\#00C7FF\\on\\#ffffff\\!')
        gPlayerSyncTable[0].kirby = true
        gPlayerSyncTable[0].kirbypower = kirbyability_none
        gPlayerSyncTable[0].kirbypossess = 0
        gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
        return true
	elseif m == 'off' then
        if kirbyabilitymovelist[gMarioStates[0].action] or gMarioStates[0].action == ACT_KIRBY_INHALE or gMarioStates[0].action == ACT_KIRBY_INHALE_FALL or gMarioStates[0].action == ACT_KIRBY_JUMP then
            djui_chat_message_create('cancel the current kirby action before doing this command')
        elseif forcetoggle == 2 or forcetoggle == 3 then
            djui_chat_message_create('the ability to turn off the moveset was disabled by another mod')
            return true
        else
            if kirbyaltmovesettoggle ~= nil then
                return kirbyaltmovesettoggle(false)
            end
            djui_chat_message_create('kirby moveset is \\#A02200\\off\\#ffffff\\!') 
            gPlayerSyncTable[0].kirby = false
            possessed = false
            gPlayerSyncTable[0].kirbypossess = 0
            if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
            end
            gPlayerSyncTable[0].kirbypower = kirbyability_none
            if kirbyissuper and kirbyhaswing == false then
                gMarioStates[0].flags = gMarioStates[0].flags & ~MARIO_WING_CAP
            end
        end

        return true
    elseif m == 'help' then
        djui_chat_message_create(string.format("In the current version of this kirby mod (%s) you can do the following in your current form",version))
        kirbymovesethelp()
        return true
    elseif m == 'abilitylist' then
        djui_chat_message_create("the following kirbyabilities can be obtained ")
        djui_chat_message_create(string.format("%s \n",print_table(kirbyabilitylist)))
        return true
    end
    return false
end

--this function returns kirby moveset info
function kirbymovesethelp()
    djui_chat_message_create(string.format("Kirby can do %d midair jumps by pressing a in the air(b instead if long jumping. If kirby has the wingcap he can do infinite midair jumps instead of normal wingcap flight.)", maxkirbyjumps))
    djui_chat_message_create(string.format("kirby current power is %s \n",kirbyabilitylist[gPlayerSyncTable[0].kirbypower]))
    if  gPlayerSyncTable[0].kirbypower == kirbyability_none then
        djui_chat_message_create(string.format("In this form kirby can inhale enemies by pressing b when not holding anything this move lasts as long as the b button is held. Kirby can swallow held swallowable enemies/objects by pressing %s + %s.", buttons[swallowbutton1].name,buttons[swallowbutton2].name))
        djui_chat_message_create('pressing b after doing a midair jump lets kirby do a midair exhale attack instead of an inhale')
        djui_chat_message_create('this form has no ground pound equivalent')

    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_fire then
        djui_chat_message_create('In this form kirby can spit fire by pressing b this attack continues as long as the b button is held. If kirby attempts a dive he will turn into a fireball instead of shooting fire.')
        djui_chat_message_create('By pressing z kirby can perform a fire ball spin which has ground pound properties.If the move lands on level ground it will transition into a fire ball roll')

    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_needle then
        djui_chat_message_create('In this form kirby can eject needle from his body by pressing b while doing this move kirby can stick to walls he collides with.The move can be canceled by pressing b again.')
        djui_chat_message_create('By pressing the z button kirby can use the falling spine attack which has ground pound properties. Holding the z button can allow kirby to stick to slopes after landing for as long as the z button is held.')

    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_stone then
        djui_chat_message_create('In this form kirby can turn into an invincible stone by pressing the b or z button which deals damage while sliding or falling  when falling the move has ground pound properties. The move can be canceled by pressing the b button')

    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_bomb then
        djui_chat_message_create('In this form kirby can spawn bombs by pressing b. When holding a bomb he can press z to bomb jump.')
        djui_chat_message_create('this form has no ground pound equivalent')

    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_wheel then
        djui_chat_message_create('In this form kirby can turn into a wheel which allows him to run on water,and sand (with the metal cap he can also roll on lava)')
        djui_chat_message_create('while kirby is a wheel he can jump by pressing the A button and when falling in wheel form he can press the z button to downshift stopping forward momentum but gaining ground pound properties')
    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_wrestler then
        djui_chat_message_create('This form can wall kick')
        djui_chat_message_create('this form has mario moveset without double and triple jumps')
    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_ghost then
        djui_chat_message_create('In this form kirby can do a dash with vanish properties.Some enemies can be possessed use (kirbyfoodinfo possession)command for a list')
        djui_chat_message_create('this form has no ground pound equivalent')
    elseif  gPlayerSyncTable[0].kirbypower == kirbyability_wing then
        djui_chat_message_create('In this form fire feathers with b(instead of punching or kicking) or do a condor head(instead of diving)')
        djui_chat_message_create('you can perform a condor bomb from a condor head or the air by pressing z which has ground pound properties')
        djui_chat_message_create('you can perform a condor dive from a condor head or the air by pressing z while holding a which has ground pound properties')

    end
    if  gPlayerSyncTable[0].kirbypower ~= kirbyability_wrestler then
        djui_chat_message_create('This form cannot wall kick')
    end
    if  gPlayerSyncTable[0].kirbypower ~= kirbyability_none then
        djui_chat_message_create(string.format("You can press the  %s +%s buttons to discard your current ability",buttons[swallowbutton1].name, buttons[swallowbutton2].name))
    end
end

--- @param msg string
--this function returns kirby the eatable kirby enemies
local function kirbyfoodinfo_command(msg)
    local m = string.lower(msg)
    if m == kirbyabilitylist[kirbyability_none] then
        djui_chat_message_create("the following enemies don't give an ability")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_none])))
        return true
    elseif m == kirbyabilitylist[kirbyability_fire] then
        djui_chat_message_create("the following enemies give fire ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_fire])))
        return true
    elseif m == kirbyabilitylist[kirbyability_needle] then
        djui_chat_message_create("the following enemies give needle ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_needle])))
        return true
    elseif m == kirbyabilitylist[kirbyability_stone] then
        djui_chat_message_create("the following enemies give stone ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_stone])))
        return true
    elseif m == kirbyabilitylist[kirbyability_bomb] then
        djui_chat_message_create("the following enemies give bomb ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_bomb])))
        return true
    elseif m == kirbyabilitylist[kirbyability_wrestler] then
        djui_chat_message_create("the following enemies give wrestler ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_wrestler])))
        return true
    elseif m == kirbyabilitylist[kirbyability_wheel] then
        djui_chat_message_create("the following enemies give wheel ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_wheel])))
        return true
    elseif m == kirbyabilitylist[kirbyability_ghost] then
        djui_chat_message_create("the following enemies give ghost ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_ghost])))
        return true
    elseif m == kirbyabilitylist[kirbyability_wing] then
        djui_chat_message_create("the following enemies give wing ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_wing])))
        return true 
    elseif m == kirbyabilitylist[kirbyability_sleep] then
        djui_chat_message_create("the following enemies give sleep ability ")
        djui_chat_message_create(string.format("%s \n",print_table(enemytable[kirbyability_sleep])))
        return true
    elseif m == "possession" then
        djui_chat_message_create("the following enemies can be possessed by ghost kirby ")
        djui_chat_message_create(string.format("%s \n",print_table(possessablenametable)))
        return true        
    end
    return false
end

--- @param msg string
--this is the function for enabling or disabling kirby losing his ability on hit
kirbyloseability_command = function (msg)
    if not network_is_server() and not network_is_moderator then
        djui_chat_message_create('Only the host or a mod can change this setting!')
        return true
    end
    local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\kirby will now lose his ability on hit\\#ffffff\\!')
		gGlobalSyncTable.loseability = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\kirby will no longer lose his ability on hit\\#ffffff\\!')
		gGlobalSyncTable.loseability = false 
		return true
    end
    return false
end


--- @param msg string
--this is the function for moving the kirby ui
local function kirbyui_x_command(msg)

    if tonumber(msg) and (tonumber(msg) >= 0) then
		mod_storage_save("kirbyability_ui_x", msg)
		kirbyui_x = tonumber(mod_storage_load("kirbyability_ui_x"))
        djui_chat_message_create(string.format("kirbyability ui's x coordinate is now %d", kirbyui_x))
        return true
    elseif msg == 'dpad' then
        movingui = true
        return true
    elseif msg == 'toggleui' then
        toggleui = not toggleui
		djui_chat_message_create(string.format("the ui has been turned  %s",bool_to_str[toggleui]))
        return true
	else
		djui_chat_message_create('Invalid input. Must be a number like kirbyability_ui_x 5 and the number needs to be 0 or greater.')
		return true
    end
    return false
end

--- @param msg string
--this is the function for moving the kirby ui
local function kirbyui_y_command(msg)

    if tonumber(msg) and (tonumber(msg) <= 0) then
		mod_storage_save("kirbyability_ui_y", msg)
		kirbyui_y = tonumber(mod_storage_load("kirbyability_ui_y"))
        djui_chat_message_create(string.format("kirbyability ui's y coordinate is now %d", kirbyui_y))
        return true
    elseif msg == 'dpad' then
        movingui = true
        return true
    elseif msg == 'toggleui' then
        toggleui = not toggleui
		djui_chat_message_create(string.format("the ui has been turned  %s",bool_to_str[toggleui]))
        return true
	else
		djui_chat_message_create('Invalid input. Must be a number like kirbyability_ui_y -5 and the number needs to be 0 or less.')
		return true
    end
    return false
end

--- @param msg string
--this is the function for enabling or disabling kirby losing his ability on hit
kirbyabilitychoose_command = function (msg)
    if not network_is_server() and not network_is_moderator then
        djui_chat_message_create('Only the host or a mod can change this setting!')
        return true
    end
    local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\kirby can now pick an ability on star select\\#ffffff\\!')
		gGlobalSyncTable.abilitychoose = true
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\kirby can no longer now pick an ability on star select\\#ffffff\\!')
		gGlobalSyncTable.abilitychoose = false
		return true
    end
    return false
end

--- @param msg string
--this is the function for save server settings or loading them
kirbyconfig_command = function(msg)

    local m = string.lower(msg)
    if m == 'save' then
        mod_storage_save("kirbyloseability", tostring(gGlobalSyncTable.loseability))
	    mod_storage_save("kirbyabilitychoose", tostring(gGlobalSyncTable.abilitychoose))
        mod_storage_save("projectilehurtallies", tostring(gGlobalSyncTable.projectilehurtallies))
        djui_chat_message_create('current kirby server config saved')
        return true
	elseif m == 'load' then
		if not network_is_server() and not network_is_moderator then
            djui_chat_message_create('Only the host or a mod can change this setting!')
            return true
        else
            gGlobalSyncTable.loseability = toboolean( mod_storage_load("kirbyloseability"))
            gGlobalSyncTable.abilitychoose = toboolean(mod_storage_load("kirbyabilitychoose"))
            gGlobalSyncTable.projectilehurtallies = toboolean(mod_storage_load("projectilehurtallies"))
            djui_chat_message_create('kirby config loaded')
            return true
        end
    elseif m == 'printserver' then
        djui_chat_message_create(string.format("This server is running version %s of the kirby mod  with the following settings",version))
		djui_chat_message_create(string.format("kirby lose ability on hit is %s",bool_to_str[gGlobalSyncTable.loseability]))
		djui_chat_message_create(string.format("kirby choose ability on act select is %s",bool_to_str[gGlobalSyncTable.abilitychoose]))
        djui_chat_message_create(string.format("kirby projectile's ability to hurt players when interaction is solid (and another mod isn't overwritting the setting) is %s",bool_to_str[gGlobalSyncTable.projectilehurtallies]))
        return true
	elseif m == 'printlocal'then
        djui_chat_message_create(string.format("kirby moveset is %s",bool_to_str[gPlayerSyncTable[0].kirby]))
		djui_chat_message_create(string.format("kirby ui x pos is %d",kirbyui_x))
		djui_chat_message_create(string.format("kirby ui y pos is %d",kirbyui_y))
        djui_chat_message_create(string.format("kirby swallowbutton1 is %s", buttons[swallowbutton1].name))
        djui_chat_message_create(string.format("kirby swallowbutton2 is %s", buttons[swallowbutton2].name))
		return true
    end
    return false
end

--- @param msg string
--this is the function for changing the swallow/releaseability button
local function kirbyswallowbutton_command(msg)
    local m = string.lower(msg)
    if m == 'reset' then
        djui_chat_message_create('kirby swallow button was set to default')
        swallowbutton1 = X_BUTTON
        swallowbutton2 = X_BUTTON
        djui_chat_message_create(string.format("kirby swallowbutton1 is %s", buttons[swallowbutton1].name))
        djui_chat_message_create(string.format("kirby swallowbutton2 is %s", buttons[swallowbutton2].name))
        return true
    elseif m == 'change' then
        settingswallowbutton = true
        set2ndswallowbutton = false 
        return true
    end
    return false
end

--- @param msg string
--this is the function for controlling  how kirby projectiles affect other players when player interaction is solid
kirbysolidprojectiles_command = function (msg)
    if not network_is_server() and not network_is_moderator then
        djui_chat_message_create('Only the host or a mod can change this setting!')
        return true
    end
    local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\kirby projectiles now hurt players when interaction is set to solid\\#ffffff\\!')
		gGlobalSyncTable.projectilehurtallies = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\kirby projectiles no longer hurt players when interaction is set to solid\\#ffffff\\!')
		gGlobalSyncTable.projectilehurtallies = false 
		return true
    end
    return false
end

hook_chat_command('kirbyfoodinfo', "enter an ability name to get a list of enemies that give that power , or possession for enemies kirby can possess", kirbyfoodinfo_command)
hook_chat_command('kirbyability_ui_x', "kirbyability_ui_x [number|dpad|toggleui] this sets the x position of the kirby ui should be a value  between 0 and 320 or kirbyability_ui_x \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad or toggleui to toggle the ui", kirbyui_x_command)
hook_chat_command('kirbyability_ui_y', "kirbyability_ui_y [number|dpad|toggleui] this sets the y position of the kirby ui should be a value between 0 and  -240 or kirbyability_ui_y \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad or toggleui to toggle the ui", kirbyui_y_command)
hook_chat_command('kirbysolidprojectiles', "[on|off] whether kirby projectiles hurt other players when the interaction is solid(can be overwritten by external mods)", kirbysolidprojectiles_command)
hook_chat_command('kirbyabilitychoose', "[on|off] whether kirby can pick an ability on star select", kirbyabilitychoose_command)
hook_chat_command('kirbyloseability', "[on|off] whether kirby should lose his ability on hit", kirbyloseability_command)
hook_chat_command('kirbyconfig', "[save|load|printserver|printlocal] to save the current kirby settings to a file or load them (loading only works if used by a moderator or the server)", kirbyconfig_command)
hook_chat_command('kirbyswallowbutton', "[reset|change] set the button/buttons to swallow/ability release, reset sets it back to default(default x) and change allows you to change it. command works when kirby moveset is on ", kirbyswallowbutton_command)
hook_chat_command('kirby', "[on|off|help|abilitylist] turn kirbymoveset \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\. You can also enter \\#A02200\\help \\#ffffff\\ for moveset info for current form or enter \\#A02200\\ abilitylist \\#ffffff\\ to get formlist", kirby_command)

id_bhvabilitystar = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_abilitystar_init, bhv_abilitystar_loop) --behavior id of the kirby ability star
id_bhvcopyessence = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_copyessence_init, bhv_copyessence_loop) --behavior id of the kirby copy essence
id_bhvkirbybomb = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_kirbybomb_init, bhv_kirbybomb_loop) --behavior id of bomb kirby's bombs 
id_bhvkirbywingfeather = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_wingfeather_init, bhv_wingfeather_loop) --behavior id of the wing kirby's feather projectiles
id_bhvkirbyflame = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_kirbyflame_init, bhv_kirbyflame_loop) --behavior id of the fire kirby's fire breath
id_bhvkirbyexplosion = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_kirbyexplosion_init, bhv_kirbyexplosion_loop) --behavior id of the kirby explosions that don't hurt their owner
id_bhvkirbyairbullet = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_airbullet_init, bhv_airbullet_loop) --behavior id of the kirby's exhale projectile
id_bhvkirbyinhalehitbox = hook_behavior(nil, OBJ_LIST_POLELIKE, true, bhv_kirbyinhalehitbox_init, bhv_kirbyinhalehitbox_loop) --behavior id of the kirby inhale hitbox that can grab players
id_bhvkirbylivingprojectile = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, true, bhv_kirbylivingprojectile_init, bhv_kirbylivingprojectile_loop) --behavior id of the hitbox used when kirby throws other players
id_bhvkirbypossessmodel = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_kirbypossessmodel_init, bhv_kirbypossessmodel_loop) --the function for the object that kirby uses when possessing something
id_bhvbowserbossdeathconfirm = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_kirbybowserdeathconfirm_init, bhv_kirbybowserdeathconfirm_loop) --the function for the object that is used for making sure bowser dies when he is set to 0 or less health by a kirby move or projectile
id_bhvkingwhompabilitystarspawner = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_kirbykingwhompabilitystar_init, bhv_kirbykingwhompabilitystar_loop) --the function for the an ability star spawner for king whomp



hook_mario_action(ACT_KIRBY_BOMB_JUMP, act_kirbybombjump)
hook_mario_action(ACT_KIRBY_WHEEL_ROLL, act_kirbywheelroll)
hook_mario_action(ACT_KIRBY_WHEEL_FALL, act_kirbywheelrollfall)
hook_mario_action(ACT_KIRBY_WHEEL_DOWNSHIFT, act_kirbywheeldownshift,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_WHEEL_JUMP, act_kirbywheelrolljump)
hook_mario_action(ACT_KIRBY_ROCK_SLIDING, act_kirbyrocksliding,INT_KICK)
hook_mario_action(ACT_KIRBY_ROCK_FALL, act_kirbyrockfall,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_ROCK_IDLE, act_kirbyrockidle)
hook_mario_action(ACT_KIRBY_ROCK_WATER_SLIDING, act_kirbyrockwatersliding,INT_KICK)
hook_mario_action(ACT_KIRBY_ROCK_WATER_SINK, act_kirbyrockwatersink,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_ROCK_WATER_IDLE, act_kirbyrockwateridle)
hook_mario_action(ACT_KIRBY_NEEDLE_FALL, act_kirbyneedlefall,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_NEEDLE_SLIDING, act_kirbyneedlesliding,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_NEEDLE_IDLE, act_kirbyneedleidle,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_NEEDLE_FALLING_SPINE, act_kirbyneedlefallingspine,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND, act_kirbyneedlefallingspineland)
hook_mario_action(ACT_KIRBY_JUMP, act_kirbyjump)
hook_mario_action(ACT_KIRBY_EXHALE, act_kirbyexhale)
hook_mario_action(ACT_KIRBY_INHALE, act_kirbyinhale)
hook_mario_action(ACT_KIRBY_INHALE_FALL, act_kirbyinhalefall)
hook_mario_action(ACT_KIRBY_FIRE_BREATH, act_kirbyfirebreath)
hook_mario_action(ACT_KIRBY_FIRE_BREATH_FALL, act_kirbyfirebreathfall)
hook_mario_action(ACT_KIRBY_FIRE_BALL, act_kirbyfireball,INT_KICK)
hook_mario_action(ACT_KIRBY_FIRE_BALL_SPIN, act_kirbyfireballspin,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_FIRE_BALL_ROLL, act_kirbyfireballroll,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_FIRE_BALL_ROLL_JUMP, act_kirbyfireballrolljump,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, act_kirbyfireballclimb,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_SPECIAL_FALL, act_kirbyspecialfall)
hook_mario_action(ACT_KIRBY_GHOST_DASH, act_kirbyghostdash,INT_KICK)
hook_mario_action(ACT_KIRBY_WING_FLAP, act_kirbywingflap,INT_SLIDE_KICK)
hook_mario_action(ACT_KIRBY_WING_FEATHER_GUN, act_kirbywingfeathergun)
hook_mario_action(ACT_KIRBY_WING_FEATHER_GUN_FALL, act_kirbywingfeathergunfall)
hook_mario_action(ACT_KIRBY_WING_CONDOR_HEAD, act_kirbywingcondorhead,INT_KICK)
hook_mario_action(ACT_KIRBY_WING_CONDOR_BOMB, act_kirbywingcondorbomb,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_WING_CONDOR_DIVE, act_kirbywingcondordive,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_SLEEP, act_kirbysleep)
hook_mario_action(ACT_KIRBY_LAND, act_kirbyland,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_LAND_INVULNERABLE, act_kirbylandinvulnerable,INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_KIRBY_POSSESS_BOBOMB_FUSELIT, act_kirbypossessbobombfuselit)
hook_mario_action(ACT_KIRBY_POSSESS_BULLET_BILL, act_kirbypossessbulletbill)
hook_mario_action(ACT_KIRBY_LIVING_PROJECTILE, act_kirbylivingprojectile)
hook_mario_action(ACT_KIRBY_STAR_SPIT_AIR, act_kirbystarspitair)



---@param id BehaviorId
--this function is used to remove an enemy from an ability table before adding it to another
local function kirbyremovebhv(id)
    for key,value in pairs(enemytable) do
        if value[id] ~= nil then
            value[id] = nil
            break
        end

    end
    return
end

local invalidbhvid = {[id_bhvMario] = true,[id_bhvcopyessence] = true,[id_bhvabilitystar] = true,[id_bhvkirbybomb] = true,[id_bhvkirbyflame]= true,[id_bhvkirbywingfeather] = true,[id_bhvkirbyexplosion] = true,[id_bhvkirbyairbullet] = true,[id_bhvkirbyinhalehitbox] = true,[id_bhvkirbylivingprojectile] = true,[id_bhvkirbypossessmodel] = true,[id_bhvbowserbossdeathconfirm] = true,[id_bhvkingwhompabilitystarspawner] = true} --table of bhvids that external mods can't add to projectilehurtableenemy or directattackableenemy
modsupporthelperfunctions.charSelecteatablechar = {[0] = kirbyability_none} --indecies of characters that give a specific power



--kirby mod api functions
_G.kirby ={

    --this function allows other mods to add an eatable enemy for kirby
    add_eatable_enemy = function(...) --function for allowing another mod to add a custom eatable enemy
        local arg  = table.pack(...)
        local abilityname --- string the power kirby gets from eating the enemy
        local bhvid ---BehaviorId 
        local name    ---String name of object to print when showing the object in a list
        local nosync = false    ---boolean does the object despawn itself on hitting mario like monty mole's rocks if so set this to true to avoid syncing a nil object
        local customdeath    ---String name of behavior to use for death or nil if object needs no special treatment which cause it to be removed by obj_mark_for_deletion and gain coins based on its unmodified oNumLootCoins at death from kirby eating it
        local customfunction    --- a custom function to use for when kirby eats an enemy return true to have the object marked for deletion expects the function to have the following parameters function(o,interactType) o the eatable object,interactType the current interaction with the object
        local nameintable = false --if abilityname is in kirbyabilitylist
        if arg.n < 3 then
            if usingcoopdx > 0 then
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_eatable_enemy current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_eatable_enemy current kirby moveset version is %s",version))
            end
            return
        else
            abilityname = string.lower(arg[1])
            bhvid = arg[2]
            if (bhvid == nil) then
                if usingcoopdx > 0 then
                    log_to_console(string.format("bhvid value of nil was passed to _G.kirby.add_eatable_enemy current kirby moveset version is %s",version), 1)
                else
                    log_to_console(string.format("bhvid value of nil was passed to _G.kirby.add_eatable_enemy current kirby moveset version is %s",version))
                end
                return
            end
            name = arg[3]
            if arg.n == 4 then
                nonsync = arg[4] 

            elseif arg.n >= 5 and (type(arg[5]) == "string") then
                nonsync = arg[4]
                if arg[5] == "custom" then
                    customdeath = "other"
                else
                    customdeath = arg[5]
                end
            elseif arg.n >= 5 and (type(arg[5]) == "function") then
                nonsync = arg[4]
                customdeath = "custom"
                customfunction = arg[5]
            end
            if arg.n >= 6 and (type(arg[6]) == "string") and arg[6] == "nointeract" then
                eatabletype0[bhvid] = true
            end
        end
        kirbyremovebhv(bhvid) --make sure the enemy isn't already in an ability table if it is remove it.
        if abilityname == "removeitem" then
            if eatabletype0[bhvid] ~= nil then
                eatabletype0[bhvid] = nil
            end
            return
        end
        for key,value in pairs(kirbyabilitylist)do
            if value == abilityname then
                enemytable[key][bhvid] = name
                nameintable = true
                break
            end
        end
        if nameintable == false then
            if (usingcoopdx > 0) and (abilityname ~= "none") then
                log_to_console(string.format("another mod tried to add an enemy with an invalid ability value which might mean that a newer version of this kirby mod exists.The enemy has been added to the none enemy list current kirby moveset version is %s",version), 1)
            elseif (usingcoopdx == 0) and (abilityname ~= "none") then
                log_to_console(string.format("another mod tried to add an enemy with an invalid ability value which might mean that a newer version of this kirby mod exists.The enemy has been added to the none enemy list current kirby moveset version is %s",version))
            end
            enemytable[kirbyability_none][bhvid] = name
        end
        if nosync then--used for not trying to sync an object that despawns on hit like monty mole's rocks if equal to true
            kirbynosync[bhvid] = true 
        end
        if customdeath then --used for custom objects that won't die properly with obj_mark_for_deletion
            if (customdeath == "custom") and (customfunction ~= nil) then
                kirbycustomfoodfunctions[bhvid] = customfunction

            end
            kirbycustomfoodbehavior[bhvid] = customdeath
        end
    end,

    add_projectilehurtableenemy = function(...) --function for allowing kirby's projectiles to hurt a custom enemy
        local arg  = table.pack(...)
        local bhvid ---BehaviorId
        local hurttype ---  string "generic_attack" for the damage to be a generic attack , "ground_pound" for ground pound,a specfic string for a unique interaction used in function kirbyprojectileattack()
        local hurtfunction --- function a custom function to use when the kirby projectile's hitbox overlaps with the object expects function parameters like the following function(enemyobj,obj) enemyobj being hit by kirby projectile and obj the kirby projectile
        local collisionfunction --a custom hitbox check function for the object with bhvid interacting with kirby projectiles.  expects function parameters like the following function(enemyobj,obj) enemyobj being hit by kirby projectile and obj the kirby projectile
        if arg.n < 2 then
            if usingcoopdx > 0 then
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_projectilehurtableenemy current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_projectilehurtableenemy current kirby moveset version is %s",version))
            end
            return
        else
            bhvid = arg[1]
            if invalidbhvid[bhvid] == true then
                if usingcoopdx > 0 then
                    log_to_console(string.format("invalid bhvid was passed (bhvid %s) to _G.kirby.add_projectilehurtableenemy current kirby moveset version is %s",tostring(bhvid),version), 1)
                else
                    log_to_console(string.format("invalid bhvid was passed (bhvid %s) to _G.kirby.add_projectilehurtableenemy current kirby moveset version is %s",tostring(bhvid),version))
                end
                return
            elseif (type(arg[2]) == "string") then
                if arg[2] == "custom" then
                    hurttype = "other"
                else
                    hurttype = arg[2]
                end

            elseif (type(arg[2]) == "function") then
                hurttype = "custom"
                hurtfunction = arg[2]
            else
                if usingcoopdx > 0 then
					log_to_console(string.format("arg[2] that was passed to _G.kirby.add_projectilehurtableenemy was an invalid input this occured on kirby moveset version %s",version), 1)
				else
					log_to_console(string.format("arg[2] that was passed to _G.kirby.add_projectilehurtableenemy was an invalid input this occured on kirby moveset version %s",version))
				end
                return
            end
        if (type(arg[3]) == "function") or (type(arg[3]) == "nil") then
            collisionfunction = arg[3]
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("arg[3] that was passed to _G.kirby.add_projectilehurtableenemy was an invalid input this occured on kirby moveset version %s",version), 1)
            else
                log_to_console(string.format("arg[3] that was passed to _G.kirby.add_projectilehurtableenemy was an invalid input this occured on kirby moveset version %s",version))
            end
            return
        end

        end
        if hurttype == "custom" and hurtfunction ~= nil then
            projectilefunctions[bhvid] = hurtfunction --hurtfunction arg[1] is object being hit by kirby projectile and hurtfunction arg[2] the kirby projectile
        end
        projectilehurtableenemy[bhvid] = hurttype
        projectilehurtableenemycustomcollision[bhvid] = collisionfunction
    end,
    ---@param name string 
    get_kirbybehaviorid = function(name) -- function that returns the behavior id of a kirby object
        local kirbyidtable = {['copy essence'] = id_bhvcopyessence,['ability star'] = id_bhvabilitystar,['kirby bomb'] =id_bhvkirbybomb,['id_bhvkirbyflame'] = id_bhvkirbyflame,['id_bhvkirbywingfeather'] = id_bhvkirbywingfeather,['id_bhvkirbyexplosion']= id_bhvkirbyexplosion,["id_bhvkirbyairbullet"] = id_bhvkirbyairbullet,["id_bhvkirbyinhalehitbox"] = id_bhvkirbyinhalehitbox,["id_bhvkirbylivingprojectile"] = id_bhvkirbylivingprojectile,["id_bhvkirbypossessmodel"] = id_bhvkirbypossessmodel}
        if name == "table" then --return a table containing all kirby objects' behavior ids
            return kirbyidtable
        elseif name == "projectiletable" then --return a table containing the behaviorids for only kirby projectiles and the abilitystar
            kirbyidtable['copy essence'] = nil
            kirbyidtable['id_bhvkirbypossessmodel'] = nil
            return kirbyidtable
        elseif kirbyidtable[name] ~= nil then
            return kirbyidtable[name]
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("kirby object not found either kirby mod may be out of date or another mod may be out of date current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("kirby object not found either kirby mod may be out of date or another mod may be out of date current kirby moveset version is %s",version))
            end
            return
        end
    end,

    --- @param abilitytype number the ability the copy essence should have
    ---@param posx number the x postion of the object
    ---@param posy number the y postion of the object
    ---@param posz number the z postion of the object
    spawn_copyessence = function(abilitytype,posx,posy,posz) --spawns and sets up a copy essence
        local x
        if (abilitytype > 0) and (abilitytype < kirbyability_max) then
            x = abilitytype
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("another mod tried to spawn a copy essence with an invalid ability value which might mean that a newer version of this kirby mod exists. current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("another mod tried to spawn a copy essence with an invalid ability value which might mean that a newer version of this kirby mod exists. current kirby moveset version is %s",version))
            end
            x = kirbyability_none
        end
       obj = spawn_sync_object(id_bhvcopyessence,E_MODEL_TRANSPARENT_STAR, posx, posy, posz,function(newobj)
            newobj.oKirbyAbilitytype = x
        end)
        return obj
    end,

    --- @param abilitytype number the ability the ability star should have
    ---@param posx number the x postion of the object
    ---@param posy number the y postion of the object
    ---@param posz number the z postion of the object
    spawn_abilitystar = function(abilitytype,posx,posy,posz) --spawns and sets up an abilitystar
        local x
        if (abilitytype > 0) and (abilitytype < kirbyability_max) then
            x = abilitytype
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("another mod tried to spawn an abilitystar with an invalid ability value which might mean that a newer version of this kirby mod exists.current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("another mod tried to spawn an abilitystar with an invalid ability value which might mean that a newer version of this kirby mod exists.current kirby moveset version is %s",version))
            end
            x = kirbyability_none
        end
        obj = spawn_sync_object(id_bhvabilitystar,kirbymodeltable.abilitystar,posx, posy, posz,function(newobj)
            newobj.oKirbyAbilitytype = x
        end)
        return obj
    end,
    is_kirby = function(...) --function that returns true if the player is kirby false otherwise
        local arg  = table.pack(...)
	    local playerindex
		if arg.n == 0 then --if no arguments are passed default to the local player
			playerindex = 0
			return gPlayerSyncTable[playerindex].kirby
		elseif (type(arg[1]) == "number") and (arg[1] >= 0) and (arg[1] < MAX_PLAYERS) then
			playerindex = arg[1]
			return gPlayerSyncTable[playerindex].kirby
		else
			if usingcoopdx > 0 then
				log_to_console(string.format("arg[1] that was passed to _G.kirby.is_kirby was an invalid input this occured on sonic health version %s",version), 1)
			else
				log_to_console(string.format("arg[1] that was passed to _G.kirby.is_kirby was an invalid input this occured on sonic health version %s",version))
			end
			return
	    end

    end,
    ---@param  toggle number
    forcemoveset = function(toggle) -- lets another mod toggle the kirby mod 
        forcetoggle = toggle
        if toggle == 1 then --force the kirby moveset off
            djui_chat_message_create('kirby moveset is \\#A02200\\off\\#ffffff\\ due to other mod!')
            gPlayerSyncTable[0].kirby = false
            if gPlayerSyncTable[0].inhaledplayer == inhaledtable.held_held then
                gPlayerSyncTable[0].inhaledplayer = inhaledtable.held_drop
            end
            gPlayerSyncTable[0].kirbypower = kirbyability_none
            gPlayerSyncTable[0].kirbypossess = 0
            gPlayerSyncTable[0].modelId = nil
            gPlayerSyncTable[0].breathingfire = false
            gPlayerSyncTable[0].inhaling = false
            possessed = false
        elseif toggle == 2 then --force kirby moveset on
            djui_chat_message_create('kirby moveset is \\#A02200\\on\\#ffffff\\ due to other mod!')
            gPlayerSyncTable[0].kirby = true
            gPlayerSyncTable[0].kirbypower = kirbyability_none
            gPlayerSyncTable[0].kirbypossess = 0
            gPlayerSyncTable[0].modelId = E_MODEL_KIRBY
            possessed = false
        elseif toggle == 3 then --disable the ability to turn the moveset on or off through commands
            djui_chat_message_create('kirby moveset toggle commands locked due to other mod!')
        else
            djui_chat_message_create('kirby moveset toggle restrictions by other mod lifted!')
        end
    end,
    add_directattackabletableenemy = function(...) --function for allowing kirby moves to have a unique interaction with custom behaviors
        local arg  = table.pack(...)
        local bhvid ---BehaviorId
        local hurttype ---string such as "id_bhvKingBobomb" to determine interaction gets set to custom if a function is passed in
        local hurtfunction --- function a custom function to use when a kirby move connects expects function with the following parameters function(o) o custom object being hit by a kirby move
        if arg.n < 2 then
            if usingcoopdx > 0 then
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_directattackabletableenemy current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_directattackabletableenemy current kirby moveset version is %s",version))
            end
            return
        else
            bhvid = arg[1]
            if invalidbhvid[bhvid] == true then
                if usingcoopdx > 0 then
                    log_to_console(string.format("invalid bhvid was passed (bhvid %s) to _G.kirby.add_directattackabletableenemy current kirby moveset version is %s",tostring(bhvid),version), 1)
                else
                    log_to_console(string.format("invalid bhvid was passed (bhvid %s) to _G.kirby.add_directattackabletableenemy current kirby moveset version is %s",tostring(bhvid),version))
                end
                return
            elseif (type(arg[2]) == "string") then
                if (arg[2] == "custom") or (arg[2] == "nointeract" and (type(arg[3]) ~= "function")) then
                    hurttype = "other"
                elseif arg[2] == "nointeract" and (type(arg[3]) == "function") then
                    hurttype = "nointeract"
                    hurtfunction = arg[3]
                else
                    hurttype = arg[2]
                end

            elseif (type(arg[2]) == "function") then
                hurttype = "custom"
                hurtfunction = arg[2]
            end

        end
        if hurttype == "custom" and hurtfunction ~= nil then
            directattackfunctions[bhvid] = hurtfunction --hurtfunction arg[1] is object being hit by kirby attack
        end
        if arg[3] == nil then
           directattackableenemy[bhvid] = hurttype 
        elseif hurttype == "nointeract"  then
            directattackablenointeracttable[bhvid] = hurtfunction --hurtfunction arg[1] is object being hit by kirby attack
        end

    end,
    getkirbymoves = function(string)
        local kirbymoves = {["ACT_KIRBY_BOMB_JUMP"] = ACT_KIRBY_BOMB_JUMP,["ACT_KIRBY_WHEEL_ROLL"] = ACT_KIRBY_WHEEL_ROLL,["ACT_KIRBY_WHEEL_FALL"] = ACT_KIRBY_WHEEL_FALL,["ACT_KIRBY_WHEEL_DOWNSHIFT"] = ACT_KIRBY_WHEEL_DOWNSHIFT,["ACT_KIRBY_WHEEL_JUMP"] = ACT_KIRBY_WHEEL_JUMP,["ACT_KIRBY_ROCK_FALL"] = ACT_KIRBY_ROCK_FALL,["ACT_KIRBY_ROCK_SLIDING"] = ACT_KIRBY_ROCK_SLIDING,["ACT_KIRBY_ROCK_IDLE"] = ACT_KIRBY_ROCK_IDLE,["ACT_KIRBY_ROCK_WATER_SINK"] = ACT_KIRBY_ROCK_WATER_SINK,["ACT_KIRBY_ROCK_WATER_SLIDING"] = ACT_KIRBY_ROCK_WATER_SLIDING,["ACT_KIRBY_ROCK_WATER_IDLE"] = ACT_KIRBY_ROCK_WATER_IDLE,["ACT_KIRBY_JUMP"] = ACT_KIRBY_JUMP,["ACT_KIRBY_EXHALE"] = ACT_KIRBY_EXHALE,["ACT_KIRBY_INHALE"] = ACT_KIRBY_INHALE,["ACT_KIRBY_INHALE_FALL"] = ACT_KIRBY_INHALE_FALL,["ACT_KIRBY_NEEDLE_IDLE"] = ACT_KIRBY_NEEDLE_IDLE,["ACT_KIRBY_NEEDLE_SLIDING"] = ACT_KIRBY_NEEDLE_SLIDING ,["ACT_KIRBY_NEEDLE_FALL"] = ACT_KIRBY_NEEDLE_FALL,["ACT_KIRBY_NEEDLE_FALLING_SPINE"] = ACT_KIRBY_NEEDLE_FALLING_SPINE,["ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND"] = ACT_KIRBY_NEEDLE_FALLING_SPINE_LAND,["ACT_KIRBY_FIRE_BREATH"] =  ACT_KIRBY_FIRE_BREATH,["ACT_KIRBY_FIRE_BREATH_FALL"] = ACT_KIRBY_FIRE_BREATH_FALL,["ACT_KIRBY_FIRE_BALL"] = ACT_KIRBY_FIRE_BALL,["ACT_KIRBY_FIRE_BALL_SPIN"] = ACT_KIRBY_FIRE_BALL_SPIN,["ACT_KIRBY_FIRE_BALL_ROLL"]= ACT_KIRBY_FIRE_BALL_ROLL,["ACT_KIRBY_FIRE_BALL_ROLL_JUMP"]= ACT_KIRBY_FIRE_BALL_ROLL_JUMP,["ACT_KIRBY_FIRE_BALL_ROLL_CLIMB"] = ACT_KIRBY_FIRE_BALL_ROLL_CLIMB, ["ACT_KIRBY_SPECIAL_FALL"]= ACT_KIRBY_SPECIAL_FALL ,["ACT_KIRBY_GHOST_DASH"] = ACT_KIRBY_GHOST_DASH,["ACT_KIRBY_WING_FLAP"] = ACT_KIRBY_WING_FLAP,["ACT_KIRBY_WING_FEATHER_GUN"] = ACT_KIRBY_WING_FEATHER_GUN,["ACT_KIRBY_WING_FEATHER_GUN_FALL"] = ACT_KIRBY_WING_FEATHER_GUN_FALL, ["ACT_KIRBY_WING_CONDOR_HEAD"] = ACT_KIRBY_WING_CONDOR_HEAD, ["ACT_KIRBY_WING_CONDOR_BOMB"] = ACT_KIRBY_WING_CONDOR_BOMB,["ACT_KIRBY_WING_CONDOR_DIVE"] = ACT_KIRBY_WING_CONDOR_DIVE,["ACT_KIRBY_SLEEP"]= ACT_KIRBY_SLEEP,["ACT_KIRBY_LAND"] = ACT_KIRBY_LAND,["ACT_KIRBY_LAND_INVULNERABLE"] = ACT_KIRBY_LAND_INVULNERABLE,["ACT_KIRBY_POSSESS_BOBOMB_FUSELIT"]= ACT_KIRBY_POSSESS_BOBOMB_FUSELIT,["ACT_KIRBY_POSSESS_BULLET_BILL"] = ACT_KIRBY_POSSESS_BULLET_BILL,["ACT_KIRBY_LIVING_PROJECTILE"] = ACT_KIRBY_LIVING_PROJECTILE,["ACT_KIRBY_STAR_SPIT_AIR"] = ACT_KIRBY_STAR_SPIT_AIR}
        if string == "table" then
            return kirbymoves
        elseif kirbymoves[string] ~= nil then
            return kirbymoves[string]
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("kirby move not found either kirby mod may be out of date or another mod may be out of date current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("kirby move not found either kirby mod may be out of date or another mod may be out of date current kirby moveset version is %s",version))
            end
            return
        end
    end,
    add_possesableableenemy = function(...) --function for allowing kirby to possess something with ghost dask
        local arg  = table.pack(...)
        local bhvid ---BehaviorId
        local hurttype  --used for checking if kirby successfully possessed something
        local hurtfunction -- function a custom function to use when kirby hits an enemy with ghost dash function(m,o,interactType,interactValue)--obj being hit by kirby ghost dash first return value is whether the possession was successful and the second return value is the model to use for possession
        local name --the name of the enemy which is shown in a list
        local movesetfunction --expects function with the following parameters function(m) m mariostate function for specific possession's moveset
        local movesettype --The possession moveset type which is a string
        local possessedanimationfunction --animationfunction for when kirby is possessing an object expects function with the following parameters function(o,playerindex) o object which will be animated instead of kirby (whose model will be invisible when possessing something) when possessing something playerindex of the player possessing the object
        if arg.n < 2 then
            if usingcoopdx > 0 then
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_possesableableenemy current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("too few arguments where passed to _G.kirby.add_possesableableenemy current kirby moveset version is %s",version))
            end
            return
        else
            bhvid = arg[1]
            if (type(arg[2]) == "string") then
                if arg[2] == "custom" then
                    hurttype = "other"
                else
                    hurttype = arg[2]
                end

            elseif (type(arg[2]) == "function") then
                hurttype = "custom"
                hurtfunction = arg[2]
            end

            if(type(arg[3]) == "string") then
                name = arg[3]
            end

            if (type(arg[4]) == "string") then
                if arg[4] == "custom" then
                    movesettype = "other"
                else
                    movesettype = arg[4]
                end

            elseif (type(arg[4]) == "function") then
                movesettype = "custom"
                movesetfunction = arg[4]
            end
            if (type(arg[5]) == "function") then
                possessedanimationfunction = arg[5]
            end
        end
        if hurttype == "custom" and hurtfunction ~= nil then
            possessfunctions[bhvid] = hurtfunction --hurtfunction arg[1] is object being hit by kirby projectile and hurtfunction arg[2] the kirby projectile
        end
        if movesettype == "custom" and movesetfunction ~= nil then
            possessablemovesetfunction[bhvid].movesetfunction = movesetfunction
            possessablemovesetfunction[bhvid].animfunction = possessedanimationfunction
        end
        if hurttype ~= "removeitem" then
            possessableenemytable[bhvid] = hurttype
            possessablemoveset[bhvid] = movesettype
            if name ~= nil then
                possessablenametable[bhvid] = name
            end
        else
            if possessableenemytable[bhvid] ~= nil then
                possessableenemytable[bhvid] = nil
            end
            if possessfunctions[bhvid] ~= nil then
                possessfunctions[bhvid] = nil
            end
            if possessablenametable[bhvid] ~= nil then
                possessablenametable[bhvid] = nil
            end
        end

    end,
    --- @param obj Object kirby projectile to find the owner of
    ---@param str string used to determine if the end user want owner's local index or global index 
    getkirbyprojectileowner = function(obj,str)
        if str == "local" then --get the local index of the player who threw obj
            return network_local_index_from_global(obj.oKirbyProjectileOwner)
        elseif str == "launchedbylocal" and (obj_has_behavior_id(obj,id_bhvkirbylivingprojectile) ~= 0) then --get the local index of the player who threw obj.oKirbyProjectileOwner with obj
            return network_local_index_from_global(obj.oKirbyLivingProjectileLaunchedby)
        elseif str == "launchedby" and (obj_has_behavior_id(obj,id_bhvkirbylivingprojectile) ~= 0) then --get the global index of the player who threw obj.oKirbyProjectileOwner
            return obj.oKirbyLivingProjectileLaunchedby
        elseif str == "launchedbylocal" then --get the local index of the player who threw obj
            return network_local_index_from_global(obj.oKirbyProjectileOwner)
        else
            return obj.oKirbyProjectileOwner
        end
    end,
    ---@param str string string in the kirbyabilitylist table
    --can be used by moveset to have a kirby power assigned to it which will be given when swallowed by kirby
    givemovesetkirbyability = function(str)
        if gPlayerSyncTable[0].kirby == true then
            return
        end
        local ability
        for key,value in pairs(kirbyabilitylist)do
            if value == str then
                ability = key
                break
            end
        end
        if ability == nil then
            if usingcoopdx > 0 then
                log_to_console(string.format("kirby ability name passed to givemovesetkirbyability by external mod was an invalid kirby ability name which might mean that a newer version of this kirby mod exists current kirby moveset version is %s",version), 1)
            else
                log_to_console(string.format("kirby ability name passed to givemovesetkirbyability by external mod was an invalid kirby ability name which might mean that a newer version of this kirby mod exists current kirby moveset version is %s",version))
            end
            ability = kirbyability_none
        end
        gPlayerSyncTable[0].kirbypower = ability
    end,
    --- @param func function function to check if the local player is on the same team as the kirby projectile's owner
    --function for other mods to add a team check for gamemodes 
    addallycheck = function(func)
        allycheck = func --expects the function to have parameters customfunc(kirbyprojectileowner,playerhitbyprojectile) param kirbyprojectileowner local index of the projectile's owner and param playerhitbyprojectile local index of player hit by projectile and the function should return true when the hit player is an ally and false otherwise
    end,
    --- @param func function function to check if the local player is on the same team as the kirby projectile's owner
    --function for romhacks to change the kirby moveset
    addromhackchange = function(func)
        romhackchange = func --expects the function to have parameters customfunc(m,incomingaction) ---@param m MarioStateparam incomingAction integer this function is called before every time a player's current action is changed return 1 to cancel the incomingaction or an action to change it
    end,
    --this function allows other mods to change kirby's max amount of midair jumps
    setmaxkirbyjumps = function(newmaxjumps)
        maxkirbyjumps = newmaxjumps
    end,
    --this function returns the current kirby moveset version
    getversion = function()
        return version
    end,
    --- @param characterindex number a character's position in the character select table
    ---@param abilityname string the kirby ability name as a string
    ---this allows a character in the character select mod to give a specific ability when kirby eats them
    addeatablecharacterselect = function(characterindex,abilityname)
        local nameintable = false
        for key,value in pairs(kirbyabilitylist)do
            if value == abilityname then
                modsupporthelperfunctions.charSelecteatablechar[characterindex] = key
                nameintable = true
                return
            end
        end
        if nameintable == false then
            if (usingcoopdx > 0) and (abilityname ~= "none") then
                log_to_console(string.format("another mod tried to give a character select character an invalid ability value which might mean that a newer version of this kirby mod exists.The character has been given the none enemy ability current kirby moveset version is %s",version), 1)
            elseif (usingcoopdx == 0) and (abilityname ~= "none") then
                log_to_console(string.format("another mod tried to give a character select character an invalid ability value which might mean that a newer version of this kirby mod exists.The character has been given the none enemy ability current kirby moveset version is %s",version))
            end
            modsupporthelperfunctions.charSelecteatablechar[characterindex] = kirbyability_none
        end
    end
}

modsupporthelperfunctions.kirby = _G.kirby --local reference to _G.kirby

modsupporthelperfunctions.kirby.add_eatable_enemy("bomb",id_bhvkirbybomb,"kirbybomb")--adding the kirby bomb to the bomb enemy table
modsupporthelperfunctions.kirby.add_eatable_enemy("wing",id_bhvkirbywingfeather,"kirbywing projectile")--adding the kirby feather to the wing enemy table


--[[ example of using _G.kirby.add_eatable enemy in another file

    function ringcheck(o)
        djui_chat_message_create('kirby ate a ring')
        return 1
    end
    id_bhvCoinring = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_coinring_init, bhv_coinring_loop)

    function on_player_connected(m)
        if _G.kirby ~= nil then
		    _G.kirby.add_eatable_enemy("none",id_bhvCoinring,"ring",false,ringcheck)--adding the sonic ring to the none enemy table
	    end
    end
    hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining

]]



