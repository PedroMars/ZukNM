local API = require("api")
local TIMER = require("zukME-main/timer")
local PrayerFlicker = require("zukME-main.prayer_flicker")
local Setup = require("zukME-main.setup")
local zukPreparation = require("zukME-main.ZukPreparation")
local Slib = require("zukME-main.slib")


local main = {}


---------------------------------------------------------------------
--# CHANGE THESE VALUES IN `setup.lua`
---------------------------------------------------------------------
HAS_ZUK_CAPE = Setup.HAS_ZUK_CAPE
USE_BOOK = Setup.USE_BOOK
USE_POISON = Setup.USE_POISON
USE_EXCAL = Setup.USE_EXCAL
USE_ELVEN_SHARD = Setup.USE_ELVEN_SHARD
OVERLOAD_NAME = type(Setup.OVERLOAD_NAME) == "string" and Setup.OVERLOAD_NAME or ""
OVERLOAD_NAME2 = type(Setup.OVERLOAD_NAME2) == "string" and Setup.OVERLOAD_NAME2 or ""
OVERLOAD_BUFF_ID = Setup.OVERLOAD_BUFF_ID
NECRO_PRAYER_NAME = type(Setup.NECRO_PRAYER_NAME) == "string" and Setup.NECRO_PRAYER_NAME or ""
NECRO_PRAYER_BUFF_ID = Setup.NECRO_PRAYER_BUFF_ID
BOOK_NAME = type(Setup.BOOK_NAME) == "string" and Setup.BOOK_NAME or ""
BOOK_BUFF_ID = Setup.BOOK_BUFF_ID
RESTORE_NAME = type(Setup.RESTORE_NAME) == "string" and Setup.RESTORE_NAME or ""
FOOD_NAME = type(Setup.FOOD_NAMEHard) == "string" and Setup.FOOD_NAME or ""
FOOD_POT_NAME = type(Setup.FOOD_POT_NAMEHard) == "string" and Setup.FOOD_POT_NAME or ""
ADREN_POT_NAME = type(Setup.ADREN_POT_NAME) == "string" and Setup.ADREN_POT_NAME or ""
RING_SWITCH = type(Setup.RING_SWITCH) == "string" and Setup.RING_SWITCH or ""
tentativas = 0
HardMode = true
HpmaxInicial = 8500
venenostick = true
pocaostick = true
---------------------------------------------------------------------
--# END
---------------------------------------------------------------------

local TIMERS = {
  GCD = { -- global cooldown tracker
    name = "GCD",
    duration = 1600,
  },
  Vuln = { -- prevent vuln bomb spam
    name = "Vuln Bomb",
    duration = 1800,
  },
  Excal = { -- keep track of 5min cooldown instead of checking each time
    name = "Excal",
    duration = (1000 * 60 * 5) + 1,
  },
  Elven = { -- keep track of 5min cooldown instead of checking each time
    name = "Elven",
    duration = (1000 * 60 * 5) + 1,
  },
  Buffs = { -- check buffs every second
    name = "Buffs",
    duration = 1000,
  }
}
-----------------------------------------------------------
--# SECTION: Constants used throughout the script
---------------------------------------------------------------------
--- @type WPOINT | nil
SAFESPOT_JAD = nil
SAFESPOT2 = nil
SAFESPOT3 = nil
--- @type WPOINT | nil
SAFESPOT_NORMAL = nil
ARENA_MIN_X = math.mininteger
ARENA_MAX_X = math.maxinteger
ARENA_MIN_Y = math.mininteger
ARENA_MAX_Y = math.maxinteger
LAST_CAST = os.clock()
zukX = 0
zukY = 0


REGULAR_WAVES = {
  [1] = true,
  [2] = true,
  [3] = true,
  [7] = true,
  [8] = true,
  [12] = true,
  [13] = true,
}
JAD_WAVES = {
  [6] = true,
  [11] = true,
  [16] = true,
}
CHALLENGE_WAVES = {
  [5] = true,
  [10] = true,
  [15] = true,
}
IGNEOUS_WAVES = {
  [4] = true,
  [9] = true,
  [14] = true,
}

POSSIBLE_TARGETS = {
  Hur = 28535,          -- basic meleer
  Igneous_Hur = 28537,  -- igneous hur
  Volatile_Hur = 28546, -- volatile hur (challenge wave)
  Mej = 28542,          -- basic mager
  Zek = 28543,          -- tier 2 mager
  Igneous_Mej = 28544,  -- igneous mej
  Mejkot = 28536,       -- tier 2 meleer
  Xil = 28538,          -- basic ranger
  Tok_Xil = 28539,      -- tier 2 ranger
  Igneous_Xil = 28540,  -- igneous xil
  Kih = 28545,          -- prayer drainer
  Jad = 28534,          -- jad
  Unbreakable = 28547,  -- unbreakable ket (challenge wave)
  Fatal_1 = 28548,      -- fatal 1 (challenge wave)
  Fatal_2 = 28549,      -- fatal 2 (challenge wave)
  Fatal_3 = 28550,      -- fatal 3 (challenge wave)
  Har_Aken = 28529,     -- har aken
}

ZUK_IDS = {
  Init = 28525,
  DPS = 28526,   -- dps check zuk
  START = 28525, -- start instance
  FIGHT = 28527, -- main fight
  END = 28528,   -- kneeling zuk after successful kill
}

WAVE_TARGETS = {
  [1] = {
    [POSSIBLE_TARGETS.Kih] = { priority = 1 },
    [POSSIBLE_TARGETS.Hur] = { priority = 3 }
  },
  [2] = {
    [POSSIBLE_TARGETS.Kih] = { priority = 4 },
    [POSSIBLE_TARGETS.Xil] = { priority = 8 },
    [POSSIBLE_TARGETS.Hur] = { priority = 1 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 2 }
  },
  [3] = {
    [POSSIBLE_TARGETS.Kih] = { priority = 4 },
    [POSSIBLE_TARGETS.Xil] = { priority = 8 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 8 },
    [POSSIBLE_TARGETS.Hur] = { priority = 1 }
  },
  [4] = { -- igneous wave
    [POSSIBLE_TARGETS.Igneous_Hur] = { priority = 30 },
    [POSSIBLE_TARGETS.Igneous_Xil] = { priority = 20 },
    [POSSIBLE_TARGETS.Igneous_Mej] = { priority = 10 }
  },
  [5] = { -- challenge wave
    [POSSIBLE_TARGETS.Volatile_Hur] = { priority = 100 }
  },
  [6] = {
    [POSSIBLE_TARGETS.Jad] = { priority = 20 },
    [POSSIBLE_TARGETS.Kih] = { priority = 6 },
    [POSSIBLE_TARGETS.Xil] = { priority = 12 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 4 }
  },
  [7] = {
    [POSSIBLE_TARGETS.Kih] = { priority = 10 },
    [POSSIBLE_TARGETS.Xil] = { priority = 15 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 10 },
    [POSSIBLE_TARGETS.Mej] = { priority = 10 },
    [POSSIBLE_TARGETS.Tok_Xil] = { priority = 25 }
  },
  [8] = {
    [POSSIBLE_TARGETS.Xil] = { priority = 15 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 8 },
    [POSSIBLE_TARGETS.Mej] = { priority = 5 },
    [POSSIBLE_TARGETS.Tok_Xil] = { priority = 25 }
  },
  [9] = { -- igneous wave
    [POSSIBLE_TARGETS.Igneous_Hur] = { priority = 30 },
    [POSSIBLE_TARGETS.Igneous_Xil] = { priority = 20 },
    [POSSIBLE_TARGETS.Igneous_Mej] = { priority = 10 }
  },
  [10] = { -- challenge wave
    [POSSIBLE_TARGETS.Unbreakable] = { priority = 100 }
  },
  [11] = {
    [POSSIBLE_TARGETS.Jad] = { priority = 20 },
    [POSSIBLE_TARGETS.Kih] = { priority = 3 },
    [POSSIBLE_TARGETS.Mej] = { priority = 10 },
    [POSSIBLE_TARGETS.Mejkot] = { priority = 5 }
  },
  [12] = {
    [POSSIBLE_TARGETS.Kih] = { priority = 15 },
    [POSSIBLE_TARGETS.Mej] = { priority = 5 },
    [POSSIBLE_TARGETS.Tok_Xil] = { priority = 25 },
    [POSSIBLE_TARGETS.Zek] = { priority = 30 }
  },
  [13] = {
    [POSSIBLE_TARGETS.Mej] = { priority = 10 },
    [POSSIBLE_TARGETS.Tok_Xil] = { priority = 20 },
    [POSSIBLE_TARGETS.Zek] = { priority = 30 }
  },
  [14] = { -- igneous wave
    [POSSIBLE_TARGETS.Igneous_Hur] = { priority = 30 },
    [POSSIBLE_TARGETS.Igneous_Xil] = { priority = 20 },
    [POSSIBLE_TARGETS.Igneous_Mej] = { priority = 10 }
  },
  [15] = { -- challenge wave
    [POSSIBLE_TARGETS.Fatal_1] = { priority = 1 },
    [POSSIBLE_TARGETS.Fatal_2] = { priority = 1 },
    [POSSIBLE_TARGETS.Fatal_3] = { priority = 1 }
  },
  [16] = {
    [POSSIBLE_TARGETS.Jad] = { priority = 10 }
  },
  [17] = {
    [POSSIBLE_TARGETS.Har_Aken] = { priority = 1000 }
  },
  [18] = {
    [POSSIBLE_TARGETS.Igneous_Hur] = { priority = 10 },
    [POSSIBLE_TARGETS.Igneous_Xil] = { priority = 20 },
    [POSSIBLE_TARGETS.Igneous_Mej] = { priority = 30 }
  }
}



local tmp_ids = {}
for _, id in pairs(POSSIBLE_TARGETS) do
  table.insert(tmp_ids, id)
end

ALL_POSSIBLE_TARGET_IDS = tmp_ids


FIGHT_STATE = {
  --- @type AllObject | nil
  target = nil,              -- active target
  --- @type Target_data | nil
  targetInfo = nil,          -- active target info
  wave = 0,                  -- current wave
  isNormalWave = false,      -- normal wave
  isIgneousWave = false,     -- igneous wave
  isJadWave = false,         -- jad wave
  isChallengeWave = false,   -- challenge wave
  isPizzaPhase = false,      -- zuk fight pizza phase
  zukDpsCheckActive = false, -- if we are currently in a 50k dps check for zuk
  --- @type AllObject | nil
  lastClickedTarget = nil,   -- used for moving to igneous Mej domes or pizza phase targets
  movingToTarget = false,    -- used for moving to igneous Mej domes or pizza phase targets
}
---------------------------------------------------------------------
--# END SECTION: Constants used throughout the script
---------------------------------------------------------------------
math.randomseed(os.time())
---------------------------------------------------------------------
--# SECTION: Targeting related functions
---------------------------------------------------------------------
---
function vidaZUk()
  local hpatual = API.GetHPMax_()
  if hpatual < HpmaxInicial then
    if API.DoAction_Inventory3(RESTORE_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
    end
  end
end

local function IsPlayerAtWPoint(target_wpoint, tolerance)
  -- Obtém a coordenada atual do jogador
  local player_coord = API.PlayerCoord()

  -- Verifica se as coordenadas do jogador foram obtidas com sucesso
  if not player_coord then
    API.Log("Não foi possível obter as coordenadas do jogador. Ele pode não estar logado ou em um estado inválido.", "warn")
    return false
  end

  -- Verifica se o nível do andar (Z) corresponde
  if player_coord.z ~= target_wpoint.z then
    return false
  end

  -- Calcula a distância entre o jogador e o WPOINT alvo
  -- A API.Math_DistanceW calcula a distância entre dois WPOINTs.
  local distance = API.Math_DistanceW(player_coord, target_wpoint)

  -- Retorna true se a distância for menor ou igual à tolerância
  if distance <= tolerance then
    API.Log(string.format("Jogador está em %d,%d,%d (distância %.2f do alvo %d,%d,%d).",
            player_coord.x, player_coord.y, player_coord.z, distance,
            target_wpoint.x, target_wpoint.y, target_wpoint.z), "debug")
    return true
  else
    API.Log(string.format("Jogador está em %d,%d,%d (distância %.2f do alvo %d,%d,%d). Fora da tolerância de %d.",
            player_coord.x, player_coord.y, player_coord.z, distance,
            target_wpoint.x, target_wpoint.y, target_wpoint.z, tolerance), "debug")
    return false
  end
end

local function areTargetsAlive(targets)
  local npcs = API.GetAllObjArray1(targets, 40, { 1 })
  if #npcs == 0 then
    return false
  end

  for _, npc in ipairs(npcs) do
    if npc.Life > 0 then
      return true
    end
  end

  return false
end

local function areTargetsAlivePerto(targets)
  local npcs = API.GetAllObjArray1(targets, 12, { 1 })
  if #npcs == 0 then
    return false
  end

  for _, npc in ipairs(npcs) do
    if npc.Life > 0 then
      return true
    end
  end

  return false
end


local function extraActionButtonVisible()
  return API.VB_FindPSettinOrder(10254).state == 3
end

local function doExtraActionButton()
  API.logWarn("Clicking extra action button")
  return API.DoAction_Interface(0x2e, 0xffffffff, 1, 743, 1, -1, API.OFF_ACT_GeneralInterface_route)
end

local function needsTarget()
  local target = API.ReadLpInteracting()
  local targetInfo = API.ReadTargetInfo(false)
  return (target == nil or
          target.Id == 0)
          and
          (targetInfo == nil or
                  (targetInfo.Hitpoints <= 0 and (
                          targetInfo.Target_Name:match("^%s*$") or
                                  targetInfo.Target_Name:gsub("^%s*(.-)%s*$", "%1") == "" or
                                  targetInfo.Target_Name == "Tap to find target")))
end

local function getHighestPriorityTarget()
  local wave = FIGHT_STATE.wave
  if wave < 1 or wave > 18 then return nil end
  local waveTargets = WAVE_TARGETS[wave]
  local ids = {}
  --- @type AllObject | nil
  local bestTarget = nil
  local bestScore = math.huge -- lowest score is best

  for id, _ in pairs(waveTargets) do
    table.insert(ids, id)
  end

  --- @type AllObject[]
  local npcs = API.GetAllObjArray1(ids, 30, { 1 })

  for _, npc in ipairs(npcs) do
    if npc.Life > 0 then
      local animFactor = npc.Anim > 0 and 2 or 1
      -- score targets based on priority, distance from player, and animation
      local score = npc.Distance / (waveTargets[npc.Id].priority * animFactor)
      if score < bestScore then
        bestScore = score
        bestTarget = npc
      end
    end
  end

  return bestTarget
end

local function currentlyTargeting(targetId, targetName)
  local currentTarget = API.ReadLpInteracting().Id or nil
  local currentTargetName = API.ReadTargetInfo(false).Target_Name or nil
  return currentTarget == targetId or currentTargetName == targetName
end

local function findNextBestTarget()
  -- Target Zuk if the extra action button is showing
  if extraActionButtonVisible() then
    if FIGHT_STATE.wave == 18 then
      return API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 40, { 1 })
    else
      return API.GetAllObjArrayFirst({ ZUK_IDS.DPS }, 40, { 1 })
    end
  end

  if FIGHT_STATE.wave == 18 then
    local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 40, { 1 })
    -- Switch pizza phase targets as they spawn
    if zuk.Anim == 34505 and areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Hur, POSSIBLE_TARGETS.Igneous_Mej, POSSIBLE_TARGETS.Igneous_Xil }) and needsTarget() then
      return getHighestPriorityTarget()
    end
    if areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Mej }) and not currentlyTargeting(POSSIBLE_TARGETS.Igneous_Mej, "Igneous TzekHaar-Mej") then
      return API.GetAllObjArrayFirst({ POSSIBLE_TARGETS.Igneous_Mej }, 40, { 1 })
    elseif areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Xil }) and
            not currentlyTargeting(POSSIBLE_TARGETS.Igneous_Xil, "Igneous TzekHaar-Xil") and
            not areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Mej }) then
      return API.GetAllObjArrayFirst({ POSSIBLE_TARGETS.Igneous_Xil }, 40, { 1 })
    elseif areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Hur }) and
            not currentlyTargeting(POSSIBLE_TARGETS.Igneous_Hur, "Igneous TzekHaar-Hur") and
            not areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Mej, POSSIBLE_TARGETS.Igneous_Xil }) then
      return API.GetAllObjArrayFirst({ POSSIBLE_TARGETS.Igneous_Hur }, 40, { 1 })
    else
      return nil
    end
    return zuk
  end

  -- Target Har Aken if surfaced, otherwise build adren off zuk
  if FIGHT_STATE.wave == 17 then
    if areTargetsAlive({ POSSIBLE_TARGETS.Har_Aken }) then
      return API.GetAllObjArrayFirst({ POSSIBLE_TARGETS.Har_Aken }, 40, { 1 })
    elseif areTargetsAlive({ 28530, 28531 }) and not areTargetsAlive({ POSSIBLE_TARGETS.Har_Aken }) then
      return API.GetAllObjArrayFirst({ ZUK_IDS.DPS }, 40, { 1 })
    end
  end

  -- Target the highest priority target for most waves
  return getHighestPriorityTarget()
end

--- @param target AllObject | nil
local function attackTarget(target)
  if target ~= nil then
    if API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, target) then
    end
    API.RandomSleep2(600, 300, 300)
    return true
  end
  return false
end

--- @param safespot WPOINT
local function goToSafespot(safespot)
  local playerPos = API.PlayerCoord()

  if playerPos.x == safespot.x and playerPos.y == safespot.y then
    return
  end
  if API.DoAction_Tile(safespot) then
    API.RandomSleep2(300, 200, 200)
    if API.Dist_FLPW(safespot) > 9 then
      if API.DoAction_Dive_Tile(safespot) then
        API.RandomSleep2(300, 200, 200)
      else if API.DoAction_Ability_check("Surge", 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
        API.RandomSleep2(600, 200, 200)
        API.DoAction_Tile(safespot)
      end
      end
    end
    API.WaitUntilMovingEnds(2, 4)
  end
end


local function shouldStopTargetingZuk()
  if (FIGHT_STATE.target ~= nil and FIGHT_STATE.target.Id == ZUK_IDS.DPS) or
          (FIGHT_STATE.targetInfo ~= nil and FIGHT_STATE.targetInfo.Target_Name == "TzKal-Zuk") then
    return (FIGHT_STATE.isChallengeWave and areTargetsAlive(ALL_POSSIBLE_TARGET_IDS)) or
            (FIGHT_STATE.wave == 17 and areTargetsAlive({ POSSIBLE_TARGETS.Har_Aken })) or
            areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Hur, POSSIBLE_TARGETS.Igneous_Mej, POSSIBLE_TARGETS.Igneous_Xil })
  end
end

local function shouldStopTargetingAken()
  if (FIGHT_STATE.target ~= nil and FIGHT_STATE.target.Id == POSSIBLE_TARGETS.Har_Aken) or
          (FIGHT_STATE.targetInfo ~= nil and FIGHT_STATE.targetInfo.Target_Name == "TzekHaar-Aken") then
    return areTargetsAlive({ 28530, 28531 }) and not areTargetsAlive({ POSSIBLE_TARGETS.Har_Aken })
  end
end

local function needsNewTarget()
  return needsTarget() or shouldStopTargetingZuk() or shouldStopTargetingAken()
end

--- @param target AllObject | nil
local function needToBeNextToTarget(target)
  if target == nil then return false end
  return target.Id == POSSIBLE_TARGETS.Igneous_Mej or
          (FIGHT_STATE.isPizzaPhase and
                  (target.Id == POSSIBLE_TARGETS.Igneous_Hur or
                          target.Id == POSSIBLE_TARGETS.Igneous_Xil))
end

--- @param target AllObject | nil
local function moveWithinAreaOfTarget(target)
  if target == nil then return end
  if FIGHT_STATE.lastClickedTarget ~= nil and
          FIGHT_STATE.lastClickedTarget.Unique_Id == target.Unique_Id then
    return
  end
  --- @type WPOINT
  local targetTile = WPOINT.new(math.floor(target.Tile_XYZ.x), math.floor(target.Tile_XYZ.y), 0)
  local tile = WPOINT.new(targetTile.x + math.random(-1, 1), targetTile.y + math.random(-1, 1), 0)
  if target.Distance > 7 then
    if API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, target) then
      API.RandomSleep2(1000, 200, 200)
      if API.DoAction_Ability_check("Surge", 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
        API.RandomSleep2(300, 200, 200)
        API.DoAction_Tile(tile)
      else
        API.RandomSleep2(300, 200, 200)
        API.DoAction_Tile(tile)
      end
    end
  else
    if API.DoAction_Tile(tile) then
      API.RandomSleep2(600, 200, 200)
    end
  end
  FIGHT_STATE.lastClickedTarget = target
  FIGHT_STATE.movingToTarget = true
end

local function withinAttackRange()
  local target = FIGHT_STATE.target
  if target ~= nil then
    local distance = API.Dist_FLP(target.Tile_XYZ)
    if distance <= 8 then
      return true
    end
  end
  return false
end

--- Potentially good target to activate death skulls or threads on
--- @param minTargets number
--- @param maxDist? number
--- @return boolean
local function worthSkullingOrThreading(minTargets, maxDist)
  maxDist = maxDist or 6
  local currTarget = FIGHT_STATE.target
  if currTarget == nil or currTarget.Id <= 0 then
    return false
  end
  local numTargets = 0
  --- @type AllObject[]
  local targets = API.GetAllObjArray1(ALL_POSSIBLE_TARGET_IDS, 40, { 1 })

  for _, target in ipairs(targets) do
    if target.Life > 0 and (API.Math_DistanceA(currTarget, target) / 512) <= maxDist then
      numTargets = numTargets + 1
    end
  end

  return numTargets >= minTargets
end

--- @param target AllObject | nil
--- @param range? number
local function surgeAttackTarget(target, range)
  range = range or 16
  if target ~= nil then
    if target.Distance > range then
      if attackTarget(target) then
        API.RandomSleep2(1000, 200, 200)
        if API.DoAction_Ability_check("Surge", 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
          API.RandomSleep2(300, 200, 200)
          return attackTarget(target)
        end
      end
    else
      return attackTarget(target)
    end
  end
end
---------------------------------------------------------------------
--# END SECTION: Targeting related functions
---------------------------------------------------------------------

---------------------------------------------------------------------
--# SECTION: Buff helper functions
---------------------------------------------------------------------

--- Source: https://github.com/sonsonmagro/Sonsons-Rasial/blob/main/core/player_manager.lua#L437
--- Checks if the player has a specific buff
--- @param buffId number
--- @return {found: boolean, remaining: number}
local function getBuff(buffId)
  local buff = API.Buffbar_GetIDstatus(buffId, false)
  return { found = buff.found, remaining = (buff.found and API.Bbar_ConvToSeconds(buff)) or 0 }
end

--- Source: https://github.com/sonsonmagro/Sonsons-Rasial/blob/main/core/player_manager.lua#L445
--- Checks if the player has a specific debuff
--- @param debuffId number
--- @return {found: boolean, remaining: number}
local function getDebuff(debuffId)
  local debuff = API.DeBuffbar_GetIDstatus(debuffId, false)
  return { found = debuff.found or false, remaining = (debuff.found and API.Bbar_ConvToSeconds(debuff)) or 0 }
end

local function targetBloated()
  return API.VB_FindPSettinOrder(11303).state >> 5 & 0x1 == 1
end

local function targetVulned()
  return API.VB_FindPSettinOrder(896).state >> 29 & 0x1 == 1
end

local function targetDeathMarked()
  return API.VB_FindPSettinOrder(11303).state >> 7 & 0x1 == 1
end

local function invokeDeathActive()
  return getBuff(30100).found
end


local function inThreadsRotation()
  return API.Buffbar_GetIDstatus(30129, false).found
end

local function specAttackOnCooldown()
  return API.DeBuffbar_GetIDstatus(55480, false).found
end

local function specAttackOnCooldown2()
  return API.DeBuffbar_GetIDstatus(55524, false).found
end


local function necrosisStacks()
  return getBuff(30101).remaining or 0
end

local function soulStacks()
  return getBuff(30123).remaining or 0
end

local function onCooldown(abilityName)
  return API.GetABs_name(abilityName, true).cooldown_timer > 0
end

local function targetStunnedOrBound()
  return (API.VB_FindPSett(896).state >> 0 & 0x1 == 1) or
          (API.VB_FindPSett(896).state >> 1 & 0x1 == 1)
end

local function deathSkullsActive()
  return #API.GetAllObjArray1({ 7882 }, 12, { 5 }) > 0
end

local function zukStartFightAnimation()
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 30, { 1 })
  return zuk ~= nil and ((zuk.Anim == 34518 or zuk.Anim == 34494) or zuk.Tile_XYZ.y > ARENA_MAX_Y)
end

local function getZukDpsCheckActive()
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.DPS }, 30, { 1 })
  return zuk ~= nil and zuk.Anim == 34516
end

local function isPizzaPhaseActive()
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 40, { 1 })
  return zuk.Anim == 34495 or zuk.Anim == 34501 or
          zuk.Anim == 34502 or zuk.Anim == 34505
end
---------------------------------------------------------------------
--# END SECTION: Buff helper functions
---------------------------------------------------------------------

---------------------------------------------------------------------
--# SECTION: Using abilities and applying buffs
---------------------------------------------------------------------
--- @param abilityName string
--- @return boolean
---
local habilitcast = 0
function main:useAbility(abilityName)
  if not API.Read_LoopyLoop() then return false end
  if needsNewTarget() then return false end
  local ability = API.GetABs_name(abilityName, true)
  if not ability or
          ability.enabled == false or
          ability.slot <= 0 or
          ability.cooldown_timer > 1 then
    return false
  end
  local stateTmp = API.VB_FindPSettinOrder(4501).state
  if API.DoAction_Ability(abilityName, 1, API.OFF_ACT_GeneralInterface_route, true) then
    local start = os.clock()
    local successful = true
    while LAST_GCD_STATE == stateTmp do
      local elapsed = os.clock() - start
      if elapsed >= 0.6 then
        successful = false
        break
      end
      LAST_GCD_STATE = API.VB_FindPSettinOrder(4501).state
      if LAST_GCD_STATE ~= stateTmp then
        successful = true
        break
      end
      API.RandomSleep2(100, 80, 50)
    end
    if not successful and habilitcast <= 2 then
      API.logDebug("Failed to cast ability " .. abilityName .. ", recasting")
      habilitcast = habilitcast + 1
      API.RandomSleep2(500,400,200)
      return main:useAbility(abilityName)
    end
    if habilitcast >= 2 then
      return true
    end
    local now = os.clock()
    local tickCasted = API.Get_tick()
    API.logDebug(string.format(
            "[CASTING] Successfully cast ability (%s) | DeltaT: %.5f s | Tick: %s",
            abilityName,
            now - LAST_CAST, tickCasted))
    LAST_CAST = now
    LAST_GCD_STATE = API.VB_FindPSettinOrder(4501).state
    TIMER:createSleep(TIMERS.GCD.name, TIMERS.GCD.duration)
    habilitcast = 0
    return true
  end
  API.logWarn(string.format("[CASTING] Failed to use ability (%s)", abilityName))
  return false
end

----------

local function manageBuffs()
  if not TIMER:shouldRun(TIMERS.Buffs.name) then return end
  zukPreparation:CheckPlayerDeath()
  local prayer = API.GetPray_()
  local hp = API.GetHP_()
  local hppet = Familiars:GetHealth()
  local overload = getBuff(OVERLOAD_BUFF_ID)
  local overload2 = getBuff(33210)
  local necroPrayer = getBuff(NECRO_PRAYER_BUFF_ID)
  local necroPrayer2 = getBuff(30771)
  local book = USE_BOOK and getBuff(BOOK_BUFF_ID) or nil
  local poison = getBuff(30095)
  local darkness = getBuff(30122)
  local boneShield = API.GetABs_name("Greater Bone Shield", true)

  if venenostick == true or venenostick == "true" then
    if venenostick then
      if not Inventory:Contains(47709) then  --adicionar iddoincense
        Slib:Warn("No guam incense sticks found in inventory.")
        venenostick = false
      else
        Slib:CheckIncenseStick(47709)--adicionar iddoincense
      end
    end
  end

  if pocaostick == true or pocaostick == "true" then
    if pocaostick then
      if not Inventory:Contains(47713) then
        Slib:Warn("No lantadyme incense sticks found in inventory.")
        pocaostick = false
      else
        Slib:CheckIncenseStick(47713)
      end
    end
  end


  if hppet < math.random(10000, 13000) and hppet>1500 then
    if API.DoAction_Interface(0xffffffff,0xffffffff,1,662,117,-1,API.OFF_ACT_GeneralInterface_route) then
      API.DoAction_Interface(0xffffffff,0xffffffff,1,662,117,-1,API.OFF_ACT_GeneralInterface_route)
    end
  end



  if boneShield.action == "Activate" then
    if main:useAbility("Greater Bone Shield") then
      API.RandomSleep2(300, 200, 200)
    end
  end

  if USE_EXCAL and TIMER:shouldRun(TIMERS.Excal.name) then
    local excalOnCooldown = getDebuff(14632).found
    if not excalOnCooldown and API.GetHP_() < math.random(5500, 7500) then
      if API.DoAction_Inventory3("Excalibur", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        TIMER:createSleep(TIMERS.Excal.name, TIMERS.Excal.duration)
      end
    end
  end

  if USE_ELVEN_SHARD and TIMER:shouldRun(TIMERS.Elven.name) then
    local shardOnCooldown = getDebuff(43358).found
    if not shardOnCooldown and API.GetPray_() < math.random(500, 700) then
      if API.DoAction_Inventory3("elven ritual shard", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        TIMER:createSleep(TIMERS.Elven.name, TIMERS.Elven.duration)
      end
    end
  end

  if hp < math.random(4000, 6000) then
    if API.DoAction_Ability_check(FOOD_NAME, 1, API.OFF_ACT_GeneralInterface_route, true, true, false) then
      API.RandomSleep2(60, 10, 10)
      API.DoAction_Ability_check(FOOD_POT_NAME, 1, API.OFF_ACT_GeneralInterface_route, true, true, false)

    end

  end



  if not darkness.found or (darkness.found and darkness.remaining <= math.random(10, 120)) then
    if main:useAbility("Darkness") then
      API.RandomSleep2(300, 200, 200)
    end
  end

  if prayer < math.random(200, 400)  then
    if API.DoAction_Inventory3(RESTORE_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
    end
  end

  if not overload.found   or (overload.found and overload.remaining > 1 and overload.remaining < math.random(30)) then
    if API.DoAction_Inventory3(OVERLOAD_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
    end

  end

  if not (overload2.found)  or (overload2.found and overload2.remaining > 1 and overload2.remaining < math.random(30)) then
    if API.DoAction_Inventory3(OVERLOAD_NAME2, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
    end
  end

  if USE_POISON and not poison.found or (poison.found and poison.remaining > 1 and poison.remaining < math.random(30)) then
    if API.DoAction_Inventory3("Weapon poison", 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
    end
  end

  if not necroPrayer.found and not necroPrayer2.found and prayer > 50 then
    if API.DoAction_Ability(NECRO_PRAYER_NAME, 1, API.OFF_ACT_GeneralInterface_route, true) then
      API.RandomSleep2(300, 200, 200)
    end
  end


  if USE_BOOK and not book.found then
    if API.DoAction_Ability(BOOK_NAME, 1, API.OFF_ACT_GeneralInterface_route, true) then
      API.RandomSleep2(300, 200, 200)
    end
  end



  TIMER:createSleep(TIMERS.Buffs.name, TIMERS.Buffs.duration)
end
---------------------------------------------------------------------
--# END SECTION: Using abilities and applying buffs
---------------------------------------------------------------------

---------------------------------------------------------------------
--# SECTION: Combat rotations
---------------------------------------------------------------------
local function buildAdrenRotationBeforeZuk()
  if Inventory:Contains(RING_SWITCH) then
    if Inventory:Equip(RING_SWITCH) then
      API.RandomSleep2(400, 200, 50)
      return
    end
  end

  if not targetDeathMarked() and not invokeDeathActive() then
    if main:useAbility("Invoke Death") then return end
  end

  if main:useAbility("Conjure Undead Army") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function buildAdrenRotation()
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function isTargetNearDeath(targetHitpoints)
  return targetHitpoints <= 10000 -- Ajuste este valor conforme a sua preferência
end

local function challenge1Rotation()

  if Inventory:Contains(RING_SWITCH) then
    if Inventory:Equip(RING_SWITCH) then
      API.RandomSleep2(400, 200, 50)
      return
    end
  end

  if API.GetAdrenalineFromInterface() < 60 and not getDebuff(26094).found then
    if API.DoAction_Inventory3(ADREN_POT_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  if main:useAbility("Death Skulls") then return end

  if main:useAbility("Threads of Fate") then return end

  if soulStacks() >= 3 then
    if main:useAbility("Volley of Souls") then return end
  end

  if main:useAbility("Finger of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Basic Attack") then return end

end

local function waveClearRotation()
  -- Ativação de Invoke Death (se não estiver ativo e o alvo tiver HP suficiente)
  if main:useAbility("Conjure Undead Army") then return end

  if main:useAbility("Reflect") then return end

  if not targetDeathMarked() and not invokeDeathActive() and
          API.ReadTargetInfo(false).Hitpoints >= 20000 then
    if main:useAbility("Invoke Death") then return end
  end


  -- Threads of Fate e Death Skulls (priorização para multi-alvo e dano burst)
  -- Priorize Threads of Fate para maior flexibilidade se worthSkullingOrThreading for verdadeiro para ele
  if worthSkullingOrThreading(3, 4) and not deathSkullsActive() and soulStacks() >= 2 then
    if main:useAbility("Threads of Fate") then return end
  end

  -- Volley of Souls (dano AoE e de alma)
  if FIGHT_STATE.targetInfo.Hitpoints >= 10000 and soulStacks() >= 3 then
    if main:useAbility("Volley of Souls") then return end  end


  -- Death Skulls com Capa de Zuk (se Threads of Fate não for usado e for worth)
  if worthSkullingOrThreading(2) and HAS_ZUK_CAPE and not deathSkullsActive() then
    if main:useAbility("Death Skulls") then return end
  end

  if main:useAbility("Living Death") then return end

  -- Bloat (se o alvo tiver HP suficiente e não estiver bloated)
  if FIGHT_STATE.targetInfo.Hitpoints >= 20000 and not targetBloated() then
    if main:useAbility("Bloat") then return end
  end

  -- Conjure Undead Army (melhoria de dano geral e AoE)
  -- Colocado antes de outras conjurações para maximizar o tempo de atividade da armadura
  if main:useAbility("Conjure Undead Army") then return end

  -- Finger of Death (alto dano de necrose)
  if FIGHT_STATE.targetInfo.Hitpoints >= 10000 and necrosisStacks() >= 6 then
    if main:useAbility("Finger of Death") then return end
  end


  -- Ataque Especial (mais condicional)
  -- Usar quando tiver necrose e o alvo não estiver perto da morte
  if necrosisStacks() >= 1 and necrosisStacks() <= 5 and not specAttackOnCooldown() and
          not isTargetNearDeath(FIGHT_STATE.targetInfo.Hitpoints) then
    if main:useAbility("Weapon Special Attack") then return end
  end

  -- Conjurações restantes (priorização de acordo com o poder)
  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  -- Habilidades básicas
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Basic Attack") then return end

end


local function threadsRotation()


  if main:useAbility("Conjure Undead Army") then return end

  -- Death Skulls com Capa de Zuk (se Threads of Fate não for usado e for worth)
  if worthSkullingOrThreading(2) and HAS_ZUK_CAPE and not deathSkullsActive() then
    if main:useAbility("Death Skulls") then return end
  end


  if worthSkullingOrThreading(2, 4) and not deathSkullsActive() and soulStacks() >= 2 then
    if main:useAbility("Threads of Fate") then return end
  end

  if soulStacks() >= 2 then
    if main:useAbility("Volley of Souls") then return end
  end

  if necrosisStacks() >= 1 and
          necrosisStacks() <= 5 and not specAttackOnCooldown() then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if main:useAbility("Touch of Death") then return end

  if necrosisStacks() >= 6 then
    if main:useAbility("Finger of Death") then return end
  end

  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function stunRotation()
  if main:useAbility("Conjure Undead Army") then return end

  if not targetDeathMarked() and not invokeDeathActive() and
          API.ReadTargetInfo(false).Hitpoints >= 20000 then
    if main:useAbility("Invoke Death") then return end
  end

  if not targetStunnedOrBound() then
    if main:useAbility("Soul Strike") then return end
  end

  if not specAttackOnCooldown2() and not targetStunnedOrBound() then
    if main:useAbility("Essence of Finality") then return end
  end


  if main:useAbility("Touch of Death") then return end


  if not targetStunnedOrBound() then
    if main:useAbility("Soul Sap") then return end
  end

  if not targetBloated() then
    if main:useAbility("Bloat") then return end
  end

  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function attackZukIfPresent()
  -- Attempt to find Zuk (DPS phase) within a 40-unit radius
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 40, { 1 })

  -- If Zuk is found and is alive, attack it
  if zuk ~= nil and zuk.Life > 0  and not FIGHT_STATE.isPizzaPhase then
    if attackTarget(zuk) then
      return true
    end
  end
  return false
end


local function thresholdRotation()


  if main:useAbility("Conjure Undead Army") then return end

  if not targetDeathMarked() and not invokeDeathActive() and
          API.ReadTargetInfo(false).Hitpoints >= 20000 then
    if main:useAbility("Invoke Death") then return end
  end


  if necrosisStacks() >= 6 then
    if main:useAbility("Finger of Death") then return end
  end


  if not targetBloated() then
    if main:useAbility("Bloat") then return end
  end

  if necrosisStacks() >= 4 and not targetBloated() then
    if main:useAbility("Finger of Death") then return end
  end


  if main:useAbility("Touch of Death") then return end


  if FIGHT_STATE.targetInfo.Hitpoints > 20000 and
          not targetBloated() then
    if main:useAbility("Spectral Scythe") then return end
  end

  if FIGHT_STATE.targetInfo.Hitpoints > 5000 and
          necrosisStacks() >= 1 and necrosisStacks() <= 5 and
          not specAttackOnCooldown() then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if FIGHT_STATE.targetInfo.Hitpoints > 5000 and
          necrosisStacks() >= 1 and necrosisStacks() <= 5 and
          not specAttackOnCooldown2() then
    if main:useAbility("Essence of Finality") then return end
  end

  if soulStacks() >= 2 then
    if main:useAbility("Volley of Souls") then return end
  end

  if main:useAbility("Conjure Undead Army") then return end
  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function challenge2Rotation()
  if not targetVulned() and TIMER:shouldRun(TIMERS.Vuln.name) then
    if Inventory:Contains("Vulnerability bomb") then
      if API.DoAction_Inventory3("Vulnerability bomb", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        API.RandomSleep2(300, 200, 200)
        TIMER:createSleep(TIMERS.Vuln.name, TIMERS.Vuln.duration)
        return
      end
    end
  end

  if API.GetAdrenalineFromInterface() < 60 and not getDebuff(26094).found then
    if API.DoAction_Inventory3(ADREN_POT_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  if not targetDeathMarked() and not invokeDeathActive() then
    if main:useAbility("Invoke Death") then return end
  end

  if main:useAbility("Death Skulls") then return end

  if necrosisStacks() >= 6 then
    if main:useAbility("Finger of Death") then return end
  end

  if soulStacks() >= 3 then
    if main:useAbility("Volley of Souls") then return end
  end

  if not specAttackOnCooldown() then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if not specAttackOnCooldown2() then
    if main:useAbility("Essence of Finality") then return end
  end

  if main:useAbility("Finger of Death") then return end

  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function challenge3Rotation()
  if API.GetAdrenalineFromInterface() < 100 and not getDebuff(26094).found then
    if API.DoAction_Inventory3(ADREN_POT_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  -- Use barricade if devotion/resonance are not active
  if not getBuff(14222).found and onCooldown("Devotion") then
    if main:useAbility("Barricade") then return end
  end

  -- Use resonance if barricade/devotion not active
  if not getBuff(14228).found and not getBuff(21665).found then
    if main:useAbility("Resonance") then return end
  end

  -- Use devotion if barricade/resonance not active
  if not getBuff(14222).found and not getBuff(14228).found then
    if main:useAbility("Devotion") then return end
  end

  -- Use powerburst if devotion/resonance are not active and barricade didn't trigger
  if not getBuff(14222).found and onCooldown("Devotion") and
          not getBuff(14228).found and not getDebuff(48960).found then
    if API.DoAction_Inventory3("Powerburst of vitality", 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  -- Otherwise build adren off fatals
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function zukDpsCheckRotation()



  if main:useAbility("Conjure Undead Army") then return end

  if Inventory:Contains(RING_SWITCH) then
    if Inventory:Equip(RING_SWITCH) then
      API.RandomSleep2(500, 200, 50)
      return
    end
  end



  if not targetVulned() and TIMER:shouldRun(TIMERS.Vuln.name) then
    if Inventory:Contains("Vulnerability bomb") then
      if API.DoAction_Inventory3("Vulnerability bomb", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        API.RandomSleep2(300, 200, 200)
        TIMER:createSleep(TIMERS.Vuln.name, TIMERS.Vuln.duration)
        return
      end
    end
  end

  ---if main:useAbility("Death Skulls") then return end

  if main:useAbility("Death Skulls") then return end

  if soulStacks() >= 3 then
    if main:useAbility("Volley of Souls") then return end
  end

  if necrosisStacks() >= 6 and not deathSkullsActive() then
    if main:useAbility("Finger of Death") then return end
  end

  if not targetBloated() and not deathSkullsActive() then
    if main:useAbility("Bloat") then return end
  end

  if not specAttackOnCooldown() and not deathSkullsActive() then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if not specAttackOnCooldown2()and not deathSkullsActive() then
    if main:useAbility("Essence of Finality") then return end
  end

  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function zukFightRotation()
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 30, { 1 })

  if getDebuff(30096).found or getDebuff(26103).found then -- geothermal burn or stunn
    if main:useAbility("Freedom") then return end
  end

  if zuk.Anim == 34499 then
    if main:useAbility("Resonance") then return end
  end

  if zuk.Anim == 34493 then
    if main:useAbility("Anticipation") then return end
  end


  if not targetVulned() and TIMER:shouldRun(TIMERS.Vuln.name) then
    if Inventory:Contains("Vulnerability bomb") then
      if API.DoAction_Inventory3("Vulnerability bomb", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        TIMER:createSleep(TIMERS.Vuln.name, TIMERS.Vuln.duration)
        return
      end
    end
  end

  if API.GetAdrenalineFromInterface() < 60 and not getDebuff(26094).found then
    if API.DoAction_Inventory3(ADREN_POT_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  if main:useAbility("Conjure Undead Army") then return end

  if not targetDeathMarked() and not invokeDeathActive() then
    if main:useAbility("Invoke Death") then return end
  end

  if main:useAbility("Death Skulls") then return end

  if main:useAbility("Living Death") then return end

  if not targetBloated()  then
    if main:useAbility("Bloat") then return end
  end

  if necrosisStacks() >= 6  then
    if main:useAbility("Finger of Death") then return end
  end

  if soulStacks() >= 3  then
    if main:useAbility("Volley of Souls") then return end
  end

  if not specAttackOnCooldown()
          and necrosisStacks() >= 1 and necrosisStacks() <= 5 then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if not specAttackOnCooldown2()
          and necrosisStacks() >= 1 and necrosisStacks() <= 5 then
    if main:useAbility("Essence of Finality") then return end
  end

  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function harAkenRotation()
  if not targetVulned() and TIMER:shouldRun(TIMERS.Vuln.name) then
    if Inventory:Contains("Vulnerability bomb") then
      if API.DoAction_Inventory3("Vulnerability bomb", 0, 1, API.OFF_ACT_GeneralInterface_route) then
        TIMER:createSleep(TIMERS.Vuln.name, TIMERS.Vuln.duration)
        return
      end
    end
  end


  if main:useAbility("Conjure Undead Army") then return end

  if API.GetAdrenalineFromInterface() < 60 and not getDebuff(26094).found then
    if API.DoAction_Inventory3(ADREN_POT_NAME, 0, 1, API.OFF_ACT_GeneralInterface_route) then
      API.RandomSleep2(300, 200, 200)
      return
    end
  end

  if not targetDeathMarked() and not invokeDeathActive() then
    if main:useAbility("Invoke Death") then return end
  end

  if main:useAbility("Split Soul") then return end

  if FIGHT_STATE.targetInfo.Hitpoints > 60000 then
    if main:useAbility("Death Skulls") then return end
  end

  if not targetBloated() then
    if main:useAbility("Bloat") then return end
  end

  if necrosisStacks() >= 6 then
    if main:useAbility("Finger of Death") then return end
  end

  if soulStacks() >= 3 then
    if main:useAbility("Volley of Souls") then return end
  end

  if not specAttackOnCooldown() and necrosisStacks() >= 1 and necrosisStacks() <= 5 then
    if main:useAbility("Weapon Special Attack") then return end
  end

  if not specAttackOnCooldown2() and necrosisStacks() >= 1 and necrosisStacks() <= 5 then
    if main:useAbility("Essence of Finality") then return end
  end



  if main:useAbility("Conjure Undead Army") then return end
  if main:useAbility("Command Vengeful Ghost") then return end
  if main:useAbility("Command Skeleton Warrior") then return end
  if main:useAbility("Touch of Death") then return end
  if main:useAbility("Soul Sap") then return end
  if main:useAbility("Basic<nbsp>Attack") then return end
end

local function doRotation()
  if not TIMER:shouldRun(TIMERS.GCD.name) then return end
  local adren = API.GetAdrenalineFromInterface()
  API.RandomSleep2(300, 200, 200)
  if inThreadsRotation() then
    return threadsRotation()
  elseif FIGHT_STATE.wave == 18 then
    if FIGHT_STATE.isPizzaPhase then
      if areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Xil, POSSIBLE_TARGETS.Igneous_Mej }) then
        return thresholdRotation()
      elseif areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Hur }) then
        return stunRotation()
      elseif extraActionButtonVisible() then
        doExtraActionButton()
        API.RandomSleep2(600, 200, 200)
        return zukFightRotation()
      end
    elseif zukStartFightAnimation() then
      return buildAdrenRotationBeforeZuk()
    else
      return zukFightRotation()
    end
  elseif FIGHT_STATE.wave == 17 then
    if areTargetsAlive({ POSSIBLE_TARGETS.Har_Aken }) then
      return harAkenRotation()
    else
      return buildAdrenRotation()
    end
  elseif FIGHT_STATE.isIgneousWave then
    if areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Hur }) then
      return stunRotation()
    elseif areTargetsAlive({ POSSIBLE_TARGETS.Igneous_Xil, POSSIBLE_TARGETS.Igneous_Mej }) then
      return thresholdRotation()
    elseif extraActionButtonVisible()  and  adren < (HAS_ZUK_CAPE and 30 or 100) then
      return buildAdrenRotation()
    elseif extraActionButtonVisible() and  adren >= (HAS_ZUK_CAPE and 30 or 100) then
      if doExtraActionButton() then
        local zukdps = API.GetAllObjArrayFirst({ ZUK_IDS.DPS }, 50, { 1 })
        attackTarget(zukdps)
        API.RandomSleep2(500, 200, 100)
        main:useAbility("Split Soul")
      end
      return zukDpsCheckRotation()
    elseif FIGHT_STATE.zukDpsCheckActive then
      return zukDpsCheckRotation()
    elseif not FIGHT_STATE.zukDpsCheckActive and not areTargetsAlive(ALL_POSSIBLE_TARGET_IDS) then
      return buildAdrenRotation()
    end
  elseif areTargetsAlive({ POSSIBLE_TARGETS.Volatile_Hur }) then -- Challenge wave 1
    return challenge1Rotation()
  elseif areTargetsAlive({ POSSIBLE_TARGETS.Unbreakable }) then  -- Challenge wave 2
    return challenge2Rotation()
  elseif areTargetsAlive({ POSSIBLE_TARGETS.Fatal_1 }) then      -- Challenge wave 3
    return challenge3Rotation()
  elseif FIGHT_STATE.isNormalWave or FIGHT_STATE.isJadWave then
    return waveClearRotation()
  end
end
---------------------------------------------------------------------
--# END SECTION: Combat rotations
---------------------------------------------------------------------
---------------------------------------------------------------------
--# SECTION: What to pray and when
---------------------------------------------------------------------
--- @type PrayerConfig
local PRAYER_CONFIG = {
  defaultPrayer = PrayerFlicker.CURSES.SOUL_SPLIT,
  threats = {
    {
      name = "Meleers alive",
      type = "Conditional",
      prayer = PrayerFlicker.CURSES.DEFLECT_MELEE,
      condition = function()
        return areTargetsAlivePerto({ POSSIBLE_TARGETS.Hur, POSSIBLE_TARGETS.Igneous_Hur,
                                      POSSIBLE_TARGETS.Kih, POSSIBLE_TARGETS.Mejkot, POSSIBLE_TARGETS.Unbreakable })
      end,
      priority = 1,
      duration = 1,
      delay = 0
    },
    {
      name = "Basic Magers alive",
      type = "Conditional",
      prayer = PrayerFlicker.CURSES.DEFLECT_MAGIC,
      condition = function()
        return areTargetsAlivePerto({ POSSIBLE_TARGETS.Mej })
      end,
      priority = 3,
      duration = 1,
      delay = 0
    },
    {
      name = "Tier 2 Magers alive",
      type = "Conditional",
      prayer = PrayerFlicker.CURSES.DEFLECT_MAGIC,
      condition = function()
        return areTargetsAlivePerto({ POSSIBLE_TARGETS.Zek })
      end,
      priority = 6,
      duration = 1,
      delay = 0
    },
    {
      name = "Rangers alive",
      type = "Conditional",
      prayer = PrayerFlicker.CURSES.DEFLECT_RANGED,
      condition = function()
        return areTargetsAlivePerto({ POSSIBLE_TARGETS.Xil, POSSIBLE_TARGETS.Tok_Xil,
                                      POSSIBLE_TARGETS.Igneous_Xil })
      end,
      priority = 5,
      duration = 1,
      delay = 0
    },
    {
      name = "Jad ranged attack",
      type = "Animation",
      range = 40,
      prayer = PrayerFlicker.CURSES.DEFLECT_RANGED,
      npcId = POSSIBLE_TARGETS.Jad,
      id = 16202,
      priority = 11,
      delay = 0,
      duration = 2
    },
    {
      name = "Jad magic attack",
      type = "Animation",
      range = 40,
      prayer = PrayerFlicker.CURSES.DEFLECT_MAGIC,
      npcId = POSSIBLE_TARGETS.Jad,
      id = 16195,
      priority = 12,
      delay = 0,
      duration = 2
    },
    {
      name = "Jad melee attack",
      type = "Animation",
      range = 40,
      prayer = PrayerFlicker.CURSES.DEFLECT_MELEE,
      npcId = POSSIBLE_TARGETS.Jad,
      id = 16204,
      priority = 15,
      delay = 0,
      duration = 1
    },
    {
      name = "Zuk melee attack",
      type = "Animation",
      range = 40,
      prayer = PrayerFlicker.CURSES.DEFLECT_MELEE,
      npcId = ZUK_IDS.FIGHT,
      id = { 34496, 34497, 34498 },
      priority = 100,
      delay = 0,
      duration = 1
    },
    {
      name = "Zuk mage attack/damage",
      type = "Animation",
      range = 40,
      prayer = PrayerFlicker.CURSES.DEFLECT_MAGIC,
      npcId = ZUK_IDS.FIGHT,
      id = { 34501, 34499 },
      priority = 200,
      delay = 0,
      duration = 1
    },
    {
      name = "Fatal challenge range attack",
      type = "Projectile",
      range = 10,
      prayer = PrayerFlicker.CURSES.DEFLECT_RANGED,
      id = 7603,
      priority = 21,
      delay = 1,
      duration = 1
    },
    {
      name = "Fatal challenge magic attack",
      type = "Projectile",
      range = 10,
      prayer = PrayerFlicker.CURSES.DEFLECT_MAGIC,
      id = 7602,
      priority = 20,
      delay = 1,
      duration = 1
    }
  }
}
---------------------------------------------------------------------
--# END SECTION: What to pray and when
---------------------------------------------------------------------

---------------------------------------------------------------------
--# SECTION: General fight stuff
local naoPegou = false
---------------------------------------------------------------------
local function findArenaCoords()
  --- @type AllObject | nil
  local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.DPS }, 40, { 1 })
  if zuk ~= nil then
    local zukX = math.floor(zuk.Tile_XYZ.x)
    local zukY = math.floor(zuk.Tile_XYZ.y)
    print("Finding arena coords for " .. tostring(zukX) .. ", " .. tostring(zukY))
    SAFESPOT_JAD = WPOINT.new(zukX - 8, zukY - 14, 0)
    SAFESPOT_NORMAL = WPOINT.new(zukX + 9, zukY - 21, 0)
    SAFESPOT2 = WPOINT.new(zukX - 15, zukY - 31, 0 )
    SAFESPOT3 = WPOINT.new(zukX + 10, zukY -32, 0)
    ARENA_MIN_X = zukX - 15
    ARENA_MAX_X = zukX + 15
    ARENA_MAX_Y = zukY - 4
    ARENA_MIN_Y = zukY - 35

    valueX = (zukX -8)
    valueY = (zukY-14)

    if zukX == 0 or zukY == 0 then
      naoPegou = true
    else
      naoPegou = false
    end

    return true
  end
  return false
end


--- @param zuk AllObject
local function standingOnQuakeSpot(zuk)
  --- @type AllObject[]
  local quakeSpots = API.GetAllObjArray1({ 7450 }, 20, { 4 })
  local quakeCoords = {}
  if #quakeSpots == 0 then
    return nil
  end
  for _, spot in ipairs(quakeSpots) do
    table.insert(quakeCoords, spot.Tile_XYZ)
  end
  local safeTiles = API.Math_FreeTiles(quakeCoords, 2, 10, { zuk.Tile_XYZ }, true)
  if #safeTiles > 0 then
    return safeTiles[1]
  end
  return nil
end

local function standingOnLavaBlob()
  local blockedTileIds = { 121912, 121913, 121914, 121915, 121916, 121917, 121918 }
  --- @type AllObject[]
  local blockedTiles = API.GetAllObjArray1(blockedTileIds, 5, { 12 })
  --- @type AllObject[]
  local blobs = API.GetAllObjArray1({ 7585 }, 5, { 4 })
  if #blobs == 0 then
    return nil
  end
  local blobCoords = {}
  local blockedCoords = {}
  for _, spot in ipairs(blobs) do
    table.insert(blobCoords, spot.Tile_XYZ)
  end
  for _, spot in ipairs(blockedTiles) do
    table.insert(blockedCoords, spot.Tile_XYZ)
  end
  local safeTiles = API.Math_FreeTiles(blobCoords, 1, 8, blockedCoords, false)
  if #safeTiles == 0 then
    return nil
  else
    for _, tile in ipairs(safeTiles) do
      local tileX = math.floor(tile.x)
      local tileY = math.floor(tile.y)
      if tileX >= ARENA_MIN_X and tileX <= ARENA_MAX_X and tileY >= ARENA_MIN_Y and tileY <= ARENA_MAX_Y then
        return tile
      end
    end
  end
end

local function getCurrentWave()
  local wave = API.VB_FindPSettinOrder(10949).state + 1
  --- Weirdly, the wave is 0-indexed in the game, so we need to add 1 to it
  --- Also, it switches from 0 to -1 at start of instance, so we need to check for that too
  if wave > 0 then
    return wave
  else
    return 1
  end
end

local function checkCoord()
  if SAFESPOT_JAD == nil then
    findArenaCoords()
    while naoPegou and tentativas<6  do
      findArenaCoords()
      API.RandomSleep2(100, 100, 50)
      tentativas = tentativas + 1
    end
    tentativas = 0
  end
end

-- Place to execute logic when the wave changes
local function onWaveChange(newWave)
  if newWave ~= 18 then
    if Inventory:Contains(23643) then -- equip tokkul zo ring if not equipped
      Inventory:Equip(23643)
      API.RandomSleep2(300, 100, 50)
    end
  end
end


local prayerFlicker = PrayerFlicker.new(PRAYER_CONFIG)
--FIGHT_STATE.isNormalWave or
local function checkSafeSpot (safespot)
  if safespot ~= nil then
    local tentativas = 0
    goToSafespot(safespot)
    API.WaitUntilMovingEnds(2, 3)
    API.logWarn("[SEAR] Moving to safe point")
    API.logWarn("Valor atual da variável tentativas: " .. tentativas, "info")
    while not IsPlayerAtWPoint(safespot,0) and tentativas<6 and wave~=18  do
      goToSafespot(safespot)
      prayerFlicker:update()
      API.WaitUntilMovingEnds(1, 3)
      tentativas = tentativas + 1
      prayerFlicker:update()
      API.logWarn("[SEAR] Moving to safe point")
      API.logWarn("Valor atual da variável tentativas: " .. tentativas, "info")
      prayerFlicker:update()
      zukPreparation:CheckPlayerDeath()
    end
    API.logWarn("[SEAR] To seguro mamae")
    tentativas = 0
  end
end

local function updateFightState()
  local currWave = getCurrentWave()
  zukPreparation:CheckPlayerDeath()
  if FIGHT_STATE.wave ~= currWave then
    zukPreparation:CheckPlayerDeath()
    onWaveChange(currWave)
    API.logWarn("Estamos na wave " .. currWave)
    zukPreparation:CheckPlayerDeath()

  end

  FIGHT_STATE.wave = currWave

  FIGHT_STATE.target = API.ReadLpInteracting()

  FIGHT_STATE.targetInfo = API.ReadTargetInfo(false)

  FIGHT_STATE.isNormalWave = REGULAR_WAVES[currWave] or false

  FIGHT_STATE.isIgneousWave = IGNEOUS_WAVES[currWave] or false

  FIGHT_STATE.isJadWave = JAD_WAVES[currWave] or false

  FIGHT_STATE.isChallengeWave = CHALLENGE_WAVES[currWave] or false

  FIGHT_STATE.zukDpsCheckActive = getZukDpsCheckActive()

  FIGHT_STATE.isPizzaPhase = isPizzaPhaseActive()

end



---------------------------------------------------------------------
--# END SECTION: General fight stuff
---------------------------------------------------------------------
local zukDead = false
local killCount = 0     -- Contador de kills do Zuk
local playerDeaths = 0  -- Contador de mortes do jogador
local scriptStartTime = API.SystemTime() -- Use API.SystemTime() para o tempo de execução



--#region tracking table generation
-- A função tracking precisa receber o killCount e o tempo de execução como argumentos
local function tracking(currentKills, currentRuntimeString, currentDeaths)
  local metrics = {
    { "Zuk Kills: ",    currentKills },
    { "Player Deaths: ", currentDeaths }, -- Nova linha para as mortes do jogador na UI
    { "Runtime: ",      currentRuntimeString }
  }

  API.DrawTable(metrics)
end



local NPC_ALVO_ID = 28536 -- Exemplo de ID do NPC
local DISTANCIA_PERIGO = 2 -- Distância para considerar o NPC perigoso


-- CÓDIGO PARA COLOCAR NO INÍCIO DO SCRIPT (executa uma vez)

-- Define a duração em segundos (15 horas)
local shutdownDurationInSeconds = 15 * 60 * 60 -- 15 horas * 60 minutos * 60 segundos

-- Guarda o momento exato em que o script começou
local scriptStartTime = os.time()

---
-- @description Verifica se o tempo de execução excedeu o limite.
-- Esta é a forma recomendada e mais eficiente.
---
local function checkShutdownTimer_Efficient()
  -- Compara o tempo atual com o tempo inicial
  if (os.time() - scriptStartTime) >= shutdownDurationInSeconds then
    Logger:Warn("TEMPO LIMITE ATINGIDO. Desligando o script de forma eficiente.")
    API.Write_LoopyLoop(false)
  end
end



tracking(killCount, API.ScriptRuntimeString(), playerDeaths)
--#endregion

-- Main loop and initialization
API.Write_fake_mouse_do(false)
API.SetDrawLogs(true)

API.SetMaxIdleTime(9)

tracking(killCount, API.ScriptRuntimeString(), playerDeaths)
SAFESPOT_JAD = nil
zukPreparation:FullPreparationCycle() --- Para primeira kill comenta essa linha  / For first kill comment this line
updateFightState()
checkCoord()
goToSafespot(SAFESPOT_JAD)
checkSafeSpot(SAFESPOT_JAD)
-- Update buffs and overheads
prayerFlicker:update()
manageBuffs()


updateFightState()

while API.Read_LoopyLoop() do

  checkCoord()
  checkShutdownTimer_Efficient()


  tracking(killCount, API.ScriptRuntimeString(), playerDeaths)
  -- Stop script if either one of us is dead
  if areTargetsAlive({ ZUK_IDS.END }) or #API.GetAllObjArray1({ 27299 }, 25, { 1 }) > 0 then
    if not zukDead then -- Verifica se não estava morto antes para contar uma única vez por morte
      killCount = killCount + 1 -- Incrementa a contagem de kills
      zukDead = true -- Define como morto
      if zukDead == true and Equipment:Contains(55484) then
        SAFESPOT_JAD = nil
        zukPreparation:FullPreparationCycle()
        zukDead = false
        tracking(killCount, API.ScriptRuntimeString(), playerDeaths)
      end
    end
    goto continue
  end


  checkCoord()
  if not areTargetsAlive(ALL_POSSIBLE_TARGET_IDS) then
    if( FIGHT_STATE.isIgneousSafe or FIGHT_STATE.isNormalWave or FIGHT_STATE.isJadWave  )and SAFESPOT_JAD ~= nil then
      goToSafespot(SAFESPOT_JAD)
      API.WaitUntilMovingEnds(2, 3)
      API.logWarn("[SEAR] Moving to safe point")
      API.logWarn("Valor atual da variável tentativas: " .. tentativas, "info")
      checkSafeSpot(SAFESPOT_JAD)
      while not IsPlayerAtWPoint(SAFESPOT_JAD,0) and tentativas<6 and wave~=18  do
        goToSafespot(SAFESPOT_JAD)
        API.WaitUntilMovingEnds(1, 3)
        tentativas = tentativas + 1
        API.logWarn("[SEAR] Moving to safe point")
        API.logWarn("Valor atual da variável tentativas: " .. tentativas, "info")
        zukPreparation:CheckPlayerDeath()
      end
      if tentativas >= 6 and not IsPlayerAtWPoint(SAFESPOT_JAD,0) then
        SAFESPOT_JAD = nil
        checkCoord()
        goToSafespot(SAFESPOT_JAD)
      end
      API.logWarn("[SEAR] To seguro mamae")
      tentativas = 0
    end
  end

  -- Handle Har Aken wave mechanics
  if FIGHT_STATE.wave == 17 then
    local avoidBlobTile = standingOnLavaBlob()
    if avoidBlobTile ~= nil then
      if API.DoAction_TileF(avoidBlobTile) then
        API.logInfo("Avoiding lava blob")
        API.Sleep_tick(2)
      end
    end
  end
  -- Handle moving to igneous Mej domes or pizza phase targets
  if FIGHT_STATE.movingToTarget and FIGHT_STATE.lastClickedTarget ~= nil then
    if API.PInAreaF2(FIGHT_STATE.lastClickedTarget.Tile_XYZ, 3) then
      attackTarget(FIGHT_STATE.lastClickedTarget)
      FIGHT_STATE.movingToTarget = false
    else
      goto continue
    end
  end
  -- Handle targeting
  if needsNewTarget() or FIGHT_STATE.isPizzaPhase then
    local nextTarget = findNextBestTarget()
    if needToBeNextToTarget(nextTarget) then
      moveWithinAreaOfTarget(nextTarget)
      goto continue
    else
      surgeAttackTarget(nextTarget)
    end
  end
  if zukPreparation:CheckPlayerDeath() then
    SAFESPOT_JAD = nil
    updateFightState()
    manageBuffs()
    prayerFlicker:update()
    checkCoord()
    goToSafespot(SAFESPOT_JAD)
    playerDeaths = playerDeaths +1
  end
  -- Handle Zuk fight mechanics
  if FIGHT_STATE.wave == 18 then
    local zuk = API.GetAllObjArrayFirst({ ZUK_IDS.FIGHT }, 40, { 1 })
    local searDebuff = getDebuff(30721)
    if zuk == nil then return end
    local avoidQuakeTile = standingOnQuakeSpot(zuk)
    vidaZUk()
    -- Remove sear debuff
    if searDebuff.found then
      if searDebuff.remaining >= 15 then
        if API.DoAction_Ability_check("Surge", 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
          API.RandomSleep2(600, 200, 100)
        end
      elseif searDebuff.remaining < 15 and not API.ReadPlayerMovin2() then
        if API.DoAction_TileF(FFPOINT.new(zuk.Tile_XYZ.x, zuk.Tile_XYZ.y + (searDebuff.remaining / 2), 0)) then
          API.logWarn("[SEAR] Moving to remove sear debuff")
          zukPreparation:CheckPlayerDeath()
          API.Sleep_tick(1)
        end
      end
      -- Avoid quake tiles
    elseif avoidQuakeTile ~= nil then
      if API.DoAction_Ability_check("Surge", 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
        API.logWarn("[QUAKE] Surged away from quake spot " .. avoidQuakeTile.x .. ", " .. avoidQuakeTile.y)
        zukPreparation:CheckPlayerDeath()
      else
        if API.DoAction_TileF(avoidQuakeTile) then
          API.logWarn("[QUAKE] Moving away from quake tile")
          zukPreparation:CheckPlayerDeath()
        end
      end
      API.Sleep_tick(2)
    end
  end
  -- Do ability rotation
  if API.GetInCombBit() and withinAttackRange() then
    doRotation()
  end
  updateFightState()
  -- Update buffs and overheads
  manageBuffs()
  prayerFlicker:update()
  attackZukIfPresent()
  if not Inventory:Contains(42267) then
    SAFESPOT_JAD = nil
    zukPreparation:FullPreparationCycle()
    API.logWarn("To sem comida, vou economizar indo base")
  end


  ::continue::
  API.RandomSleep2(30, 50, 0)
end