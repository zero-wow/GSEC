local GSE = GSE
local Statics = GSE.Static
local L = GSE.L
GSELibrary = {}

Statics.CastCmds = { use = true, cast = true, spell = true, cancelaura = true, cancelform = true, stopmacro = true, petautocastoff = true, petautocaston = true, petattack = true }

Statics.CleanStrings = {
  [1] = "/console Sound_EnableSFX 0%;",
  [2] = "/console Sound_EnableSFX 1%;",
  [3] = "/script UIErrorsFrame:Hide%(%)%;",
  [4] = "/run UIErrorsFrame:Clear%(%)%;",
  [5] = "/script UIErrorsFrame:Clear%(%)%;",
  [6] = "/run UIErrorsFrame:Hide%(%)%;",
  [7] = "/console Sound_EnableErrorSpeech 1",
  [8] = "/console Sound_EnableErrorSpeech 0",

  [11] = "/console Sound_EnableSFX 0",
  [12] = "/console Sound_EnableSFX 1",
  [13] = "/script UIErrorsFrame:Hide%(%)",
  [14] = "/run UIErrorsFrame:Clear%(%)",
  [15] = "/script UIErrorsFrame:Clear%(%)",
  [16] = "/run UIErrorsFrame:Hide%(%)",
  [17] = "/console Sound_EnableErrorSpeech 1%;",
  [18] = "/console Sound_EnableErrorSpeech 0%;",
  [19] = [[""]],
  [20] = "/stopmacro [@playertarget, noexists]",

  [30] = "/use 2",
  [31] = "/use [combat] 11",
  [32] = "/use [combat] 12",
  [33] = "/use [combat] 13",
  [34] = "/use [combat] 14",
  [35] = "/use 11",
  [36] = "/use 12",
  [37] = "/use 13",
  [38] = "/use 14",
  [39] = "/Use [combat] 11",
  [40] = "/Use [combat] 12",
  [41] = "/Use [combat] 13",
  [42] = "/Use [combat] 14",
  [43] = "/use [combat]11",
  [44] = "/use [combat]12",
  [45] = "/use [combat]13",
  [46] = "/use [combat]14",
  [47] = "/use [combat]2",
  [48] = "/use [combat] 2",
  [49] = "/use [combat]5",
  [50] = "/use [combat] 5",
  [51] = "/use [combat]1",
  [52] = "/use [combat] 1",
  [53] = "/use 1",
  [54] = "/use 5",
  [101] = "\n\n",
}

Statics.StringReset =  "|r"
Statics.CoreLoadedMessage = "GS-CoreLoaded"

Statics.SpecIDList = {
  [0] = "Global",
  [1] = "Warrior",
  [2] = "Paladin",
  [3] = "Hunter",
  [4] = "Rogue",
  [5] = "Priest",
  [6] = "DeathKnight",
  [7] = "Shaman",
  [8] = "Mage",
  [9] = "Warlock",
 --- [10] = "Monk",
  [11] = "Druid",
 --- [12] = "Demon Hunter",
  [62] = "Arcane",
  [63] = "Fire",
  [64] = "Frost - Mage",
  [65] = "Holy - Paladin",
  [66] = "Protection - Paladin",
  [70] = "Retribution",
  [71] = "Arms",
  [72] = "Fury",
  [73] = "Protection - Warrior",
  [102] = "Balance",
  [103] = "Feral",
 --- [104] = "Guardian",
  [105] = "Restoration - Druid",
  [250] = "Blood",
  [251] = "Frost - DK",
  [252] = "Unholy",
  [253] = "Beast Mastery",
  [254] = "Marksmanship",
  [255] = "Survival",
  [256] = "Discipline",
  [257] = "Holy - Priest",
  [258] = "Shadow",
  [259] = "Assassination",
 --- [260] = "Outlaw",
  [261] = "Subtlety",
  [262] = "Elemental",
  [263] = "Enhancement",
  [264] = "Restoration - Shaman",
  [265] = "Affliction",
  [266] = "Demonology",
  [267] = "Destruction",
 --- [268] = "Brewmaster",
 --- [269] = "Windwalker",
 --- [270] = "Mistweaver",
 --- [577] = "Havoc",
 --- [581] = "Vengeance",
}

local function LocalizedClassName(token, fallback)
  if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] then
    return LOCALIZED_CLASS_NAMES_MALE[token]
  end
  return fallback
end

Statics.ClassTokenByID = {
  [1] = "WARRIOR",
  [2] = "PALADIN",
  [3] = "HUNTER",
  [4] = "ROGUE",
  [5] = "PRIEST",
  [6] = "DEATHKNIGHT",
  [7] = "SHAMAN",
  [8] = "MAGE",
  [9] = "WARLOCK",
  [11] = "DRUID",
  [12] = "BARBARIAN",
  [13] = "WITCHDOCTOR",
  [14] = "DEMONHUNTER",
  [15] = "WITCHHUNTER",
  [16] = "STORMBRINGER",
  [17] = "FLESHWARDEN",
  [18] = "GUARDIAN",
  [19] = "MONK",
  [20] = "SONOFARUGAL",
  [21] = "RANGER",
  [22] = "CHRONOMANCER",
  [23] = "NECROMANCER",
  [24] = "PYROMANCER",
  [25] = "CULTIST",
  [26] = "STARCALLER",
  [27] = "SUNCLERIC",
  [28] = "TINKER",
  [29] = "PROPHET",
  [30] = "REAPER",
  [31] = "WILDWALKER",
  [32] = "SPIRITMAGE",
}

Statics.ClassAliasMap = {
  ["BARBARIAN"] = "BARBARIAN",
  ["BLOODMAGE"] = "SONOFARUGAL",
  ["CHRONOMANCER"] = "CHRONOMANCER",
  ["CULTIST"] = "CULTIST",
  ["DEATHKNIGHT"] = "DEATHKNIGHT",
  ["DEMONHUNTER"] = "DEMONHUNTER",
  ["DRUID"] = "DRUID",
  ["FELSWORN"] = "DEMONHUNTER",
  ["FLESHWARDEN"] = "FLESHWARDEN",
  ["GUARDIAN"] = "GUARDIAN",
  ["HUNTER"] = "HUNTER",
  ["KNIGHTOFXOROTH"] = "FLESHWARDEN",
  ["MAGE"] = "MAGE",
  ["MONK"] = "MONK",
  ["NECROMANCER"] = "NECROMANCER",
  ["PALADIN"] = "PALADIN",
  ["PRIEST"] = "PRIEST",
  ["PRIMALIST"] = "WILDWALKER",
  ["PROPHET"] = "PROPHET",
  ["PYROMANCER"] = "PYROMANCER",
  ["RANGER"] = "RANGER",
  ["REAPER"] = "REAPER",
  ["ROGUE"] = "ROGUE",
  ["RUNEMASTER"] = "SPIRITMAGE",
  ["SHAMAN"] = "SHAMAN",
  ["SONOFARUGAL"] = "SONOFARUGAL",
  ["SPIRITMAGE"] = "SPIRITMAGE",
  ["STARCALLER"] = "STARCALLER",
  ["STORMBRINGER"] = "STORMBRINGER",
  ["SUNCLERIC"] = "SUNCLERIC",
  ["TEMPLAR"] = "MONK",
  ["TINKER"] = "TINKER",
  ["VENOMANCER"] = "PROPHET",
  ["WARLOCK"] = "WARLOCK",
  ["WARRIOR"] = "WARRIOR",
  ["WILDWALKER"] = "WILDWALKER",
  ["WITCHDOCTOR"] = "WITCHDOCTOR",
  ["WITCHHUNTER"] = "WITCHHUNTER",
}

Statics.ClassIDByToken = {}
for classid, token in pairs(Statics.ClassTokenByID) do
  Statics.ClassIDByToken[token] = classid
end

Statics.ClassIconByID = {
  [1] = "Interface\\Icons\\INV_Sword_27",
  [2] = "Interface\\Icons\\Ability_ThunderBolt",
  [3] = "Interface\\Icons\\INV_Weapon_Bow_07",
  [4] = "Interface\\Icons\\INV_ThrowingKnife_04",
  [5] = "Interface\\Icons\\INV_Staff_30",
  [6] = "Interface\\Icons\\Spell_Deathknight_ClassIcon",
  [7] = "Interface\\Icons\\Spell_Nature_BloodLust",
  [8] = "Interface\\Icons\\INV_Staff_13",
  [9] = "Interface\\Icons\\Spell_Nature_FaerieFire",
  [11] = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
  [12] = "Interface\\Icons\\Ability_Warrior_BattleShout",
  [13] = "Interface\\Icons\\Spell_Nature_BloodLust",
  [14] = "Interface\\Icons\\Ability_DualWield",
  [15] = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
  [16] = "Interface\\Icons\\Spell_Nature_Lightning",
  [17] = "Interface\\Icons\\Spell_Shadow_RainOfFire",
  [18] = "Interface\\Icons\\INV_Shield_06",
  [19] = "Interface\\Icons\\INV_Staff_37",
  [20] = "Interface\\Icons\\Spell_Shadow_LifeDrain02",
  [21] = "Interface\\Icons\\INV_Weapon_Bow_07",
  [22] = "Interface\\Icons\\Spell_Arcane_Blast",
  [23] = "Interface\\Icons\\Spell_Shadow_DeathCoil",
  [24] = "Interface\\Icons\\Spell_Fire_FlameBolt",
  [25] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
  [26] = "Interface\\Icons\\Spell_Arcane_StarFire",
  [27] = "Interface\\Icons\\Spell_Holy_HolyBolt",
  [28] = "Interface\\Icons\\INV_Gizmo_02",
  [29] = "Interface\\Icons\\Ability_Creature_Poison_05",
  [30] = "Interface\\Icons\\Ability_CriticalStrike",
  [31] = "Interface\\Icons\\Spell_Nature_Earthquake",
  [32] = "Interface\\Icons\\Spell_Arcane_PortalDarnassus",
}

Statics.wotlkClassIDList = {
  [0] = "Global",
  [1] = LocalizedClassName("WARRIOR", "Warrior"),
  [2] = LocalizedClassName("PALADIN", "Paladin"),
  [3] = LocalizedClassName("HUNTER", "Hunter"),
  [4] = LocalizedClassName("ROGUE", "Rogue"),
  [5] = LocalizedClassName("PRIEST", "Priest"),
  [6] = LocalizedClassName("DEATHKNIGHT", "Death Knight"),
  [7] = LocalizedClassName("SHAMAN", "Shaman"),
  [8] = LocalizedClassName("MAGE", "Mage"),
  [9] = LocalizedClassName("WARLOCK", "Warlock"),
  [11] = LocalizedClassName("DRUID", "Druid"),
  [12] = LocalizedClassName("BARBARIAN", "Barbarian"),
  [13] = LocalizedClassName("WITCHDOCTOR", "Witch Doctor"),
  [14] = LocalizedClassName("DEMONHUNTER", "Felsworn"),
  [15] = LocalizedClassName("WITCHHUNTER", "Witch Hunter"),
  [16] = LocalizedClassName("STORMBRINGER", "Stormbringer"),
  [17] = LocalizedClassName("FLESHWARDEN", "Knight of Xoroth"),
  [18] = LocalizedClassName("GUARDIAN", "Guardian"),
  [19] = LocalizedClassName("MONK", "Templar"),
  [20] = LocalizedClassName("SONOFARUGAL", "Bloodmage"),
  [21] = LocalizedClassName("RANGER", "Ranger"),
  [22] = LocalizedClassName("CHRONOMANCER", "Chronomancer"),
  [23] = LocalizedClassName("NECROMANCER", "Necromancer"),
  [24] = LocalizedClassName("PYROMANCER", "Pyromancer"),
  [25] = LocalizedClassName("CULTIST", "Cultist"),
  [26] = LocalizedClassName("STARCALLER", "Starcaller"),
  [27] = LocalizedClassName("SUNCLERIC", "Sun Cleric"),
  [28] = LocalizedClassName("TINKER", "Tinker"),
  [29] = LocalizedClassName("PROPHET", "Venomancer"),
  [30] = LocalizedClassName("REAPER", "Reaper"),
  [31] = LocalizedClassName("WILDWALKER", "Primalist"),
  [32] = LocalizedClassName("SPIRITMAGE", "Runemaster"),
}
Statics.wotlkSpecIDList = {
  [0] = "Global",
  [1] = LocalizedClassName("WARRIOR", "Warrior"),
  [2] = LocalizedClassName("PALADIN", "Paladin"),
  [3] = LocalizedClassName("HUNTER", "Hunter"),
  [4] = LocalizedClassName("ROGUE", "Rogue"),
  [5] = LocalizedClassName("PRIEST", "Priest"),
  [6] = LocalizedClassName("DEATHKNIGHT", "Death Knight"),
  [7] = LocalizedClassName("SHAMAN", "Shaman"),
  [8] = LocalizedClassName("MAGE", "Mage"),
  [9] = LocalizedClassName("WARLOCK", "Warlock"),
  [11] = LocalizedClassName("DRUID", "Druid"),
  [12] = LocalizedClassName("BARBARIAN", "Barbarian"),
  [13] = LocalizedClassName("WITCHDOCTOR", "Witch Doctor"),
  [14] = LocalizedClassName("DEMONHUNTER", "Felsworn"),
  [15] = LocalizedClassName("WITCHHUNTER", "Witch Hunter"),
  [16] = LocalizedClassName("STORMBRINGER", "Stormbringer"),
  [17] = LocalizedClassName("FLESHWARDEN", "Knight of Xoroth"),
  [18] = LocalizedClassName("GUARDIAN", "Guardian"),
  [19] = LocalizedClassName("MONK", "Templar"),
  [20] = LocalizedClassName("SONOFARUGAL", "Bloodmage"),
  [21] = LocalizedClassName("RANGER", "Ranger"),
  [22] = LocalizedClassName("CHRONOMANCER", "Chronomancer"),
  [23] = LocalizedClassName("NECROMANCER", "Necromancer"),
  [24] = LocalizedClassName("PYROMANCER", "Pyromancer"),
  [25] = LocalizedClassName("CULTIST", "Cultist"),
  [26] = LocalizedClassName("STARCALLER", "Starcaller"),
  [27] = LocalizedClassName("SUNCLERIC", "Sun Cleric"),
  [28] = LocalizedClassName("TINKER", "Tinker"),
  [29] = LocalizedClassName("PROPHET", "Venomancer"),
  [30] = LocalizedClassName("REAPER", "Reaper"),
  [31] = LocalizedClassName("WILDWALKER", "Primalist"),
  [32] = LocalizedClassName("SPIRITMAGE", "Runemaster"),
  [62] = "Arcane - Mage",
  [63] = "Fire - Mage",
  [64] = "Frost - Mage",
  [65] = "Holy - Paladin",
  [66] = "Protection - Paladin",
  [70] = "Retribution - Paladin",
  [71] = "Arms - Warrior",
  [72] = "Fury - Warrior",
  [73] = "Protection - Warrior",
  [102] = "Balance - Druid",
  [103] = "Feral - Druid",
---  [104] = "Guardian - Druid",
  [105] = "Restoration - Druid",
  [250] = "Blood - DeathKnight",
  [251] = "Frost - DeathKnight",
  [252] = "Unholy - DeathKnight",
  [253] = "Beast Mastery - Hunter",
  [254] = "Marksmanship - Hunter",
  [255] = "Survival - Hunter",
  [256] = "Discipline - Priest",
  [257] = "Holy - Priest",
  [258] = "Shadow - Priest",
  [259] = "Assassination - Rogue",
  [260] = "Combat - Rogue",
  [261] = "Subtlety - Rogue",
  [262] = "Elemental - Shaman",
  [263] = "Enhancement - Shaman",
  [264] = "Restoration - Shaman",
  [265] = "Affliction - Warlock",
  [266] = "Demonology - Warlock",
  [267] = "Destruction - Warlock",
 --- [268] = "Brewmaster",
---  [269] = "Windwalker",
  ---[270] = "Mistweaver",
---[577] = "Havoc",
---  [581] = "Vengeance",
}



Statics.SpecIDHashList = {}
for k,v in pairs(Statics.wotlkSpecIDList) do
  Statics.SpecIDHashList[v] = k
end

Statics.SequenceDebug = "SEQUENCEDEBUG"

Statics.Priority = "Priority"
Statics.Sequential = "Sequential"

--- <code>GSStaticPriority</code> is a static step function that goes 1121231234123451234561234567
--    use this like StepFunction = GSStaticPriority, in a macro
--    This overides the sequential behaviour that is standard in GS
Statics.PriorityImplementation = [[
  limit = limit or 1
  if step == limit then
    limit = limit % #macros + 1
    step = 1
  else
    step = step % #macros + 1
  end
]]

--- <code>GSStaticLoopPriority</code> is a static step function that goes 1121231234123451234561234567
--    but it does this within an internal loop.  So more like 123343456
--    If the macro has loopstart or loopstop defined then it will use this instead of GSStaticPriority
Statics.LoopPriorityImplementation = [[
  if step < loopstart then
    step = step + 1

  elseif step > loopstop and loopstop == #macros then
    if step >= #macros then
      loopiter = 1
      step = loopstart
      if looplimit > 0 then
        step = 1
        limit = loopstart
      end
    else
      step = step + 1
    end
  elseif step == loopstop then
    if looplimit > 0 then
      if loopiter >= looplimit then
        if loopstop >= #macros then
          step = 1
          limit = loopstart
        else
          step = step + 1
          loopiter = 1
        end
      else
        step = loopstart
        loopiter = loopiter + 1
      end
    else
      step = loopstart
    end
  elseif step >= #macros then
    loopiter = 1
    step = loopstart
    if looplimit > 0 then
      step = 1
      limit = loopstart
    end
  else
    limit = limit or loopstart
    if step == limit then
      limit = limit % loopstop + 1
      step = loopstart
      if limit == loopiter then
        loopiter = loopiter + 1
      end
    else
      step = step + 1
    end
  end
]]

Statics.PrintKeyModifiers = [[
print("Right alt key " .. tostring(IsRightAltKeyDown()))
print("Left alt key " .. tostring(IsLeftAltKeyDown()))
print("Any alt key " .. tostring(IsAltKeyDown()))
print("Right ctrl key " .. tostring(IsRightControlKeyDown()))
print("Left ctrl key " .. tostring(IsLeftControlKeyDown()))
print("Any ctrl key " .. tostring(IsControlKeyDown()))
print("Right shft key " .. tostring(IsRightShiftKeyDown()))
print("Left shft key " .. tostring(IsLeftShiftKeyDown()))
print("Any shft key " .. tostring(IsShiftKeyDown()))
print("Any mod key " .. tostring(IsModifierKeyDown()))
print("GetMouseButtonClicked() " .. GetMouseButtonClicked() )
]]

Statics.OnClick = [=[
local step = self:GetAttribute('step')
local loopstart = self:GetAttribute('loopstart') or 1
local loopstop = self:GetAttribute('loopstop') or #macros
local loopiter = self:GetAttribute('loopiter') or 1
local looplimit = self:GetAttribute('looplimit') or 0
loopstart = tonumber(loopstart)
loopstop = tonumber(loopstop)
loopiter = tonumber(loopiter)
looplimit = tonumber(looplimit)
step = tonumber(step)
self:SetAttribute('macrotext', self:GetAttribute('KeyPress') .. "\n" .. macros[step] .. "\n" .. self:GetAttribute('KeyRelease'))
%s
if not step or not macros[step] then -- User attempted to write a step method that doesn't work, reset to 1
  print('|cffff0000Invalid step assigned by custom step sequence', self:GetName(), step or 'nil', '|r')
  step = 1
end
self:SetAttribute('step', step)
self:SetAttribute('loopiter', loopiter)
--self:CallMethod('UpdateIcon')
]=]

--- <code>GSStaticLoopPriority</code> is a static step function that
--    operates in a sequential mode but with an internal loop.
--    eg 12342345
Statics.LoopSequentialImplementation = [[
if step < loopstart then
  -- I am before the loop increment to next step.
  step = step + 1
elseif step > loopstop then
  if step >= #macros then
    loopiter = 1
    step = loopstart
    if looplimit > 0 then
      step = 1
    end
  else
    step = step + 1
  end
elseif step == loopstop then
  if looplimit > 0 then
    if loopiter >= looplimit then
      if loopstop >= #macros then
        step = 1
      else
        step = step + 1
      end
      loopiter = 1
    else
      step = loopstart
      loopiter = loopiter + 1
    end
  else
    step = loopstart
  end
elseif step >= #macros then
  loopiter = 1
  step = loopstart
  if looplimit > 0 then
    step = 1
  end
else
  step = step + 1
end
]]

Statics.StringFormatEscapes = {
    ["|c%x%x%x%x%x%x%x%x"] = "", -- color start
    ["|r"] = "", -- color end
    ["|H.-|h(.-)|h"] = "%1", -- links
    ["|T.-|t"] = "", -- textures
    ["{.-}"] = "", -- raid target icons
}

Statics.MacroResetSkeleton = [[
if %s then
  self:SetAttribute('step', 1)
  self:SetAttribute('loopiter', 1)
end
]]

Statics.SourceLocal = "Local"
Statics.SourceTransmission = "Transmission"
Statics.DebugModules = {}
Statics.DebugModules["Translator"] = "Translator"
Statics.DebugModules["Storage"] = "Storage"
Statics.DebugModules["Editor"] ="Editor"
Statics.DebugModules["Viewer"] = "Viewer"
Statics.DebugModules["Versions"] = "Versions"
Statics.DebugModules[Statics.SourceTransmission] = Statics.SourceTransmission
Statics.DebugModules["API"] = "API"
Statics.DebugModules["GUI"] = "GUI"


Statics.TranslationKey = "KEY"
Statics.TranslationHash = "HASH"
Statics.TranslationShadow = "SHADOW"

Statics.Spec = "Spec"
Statics.Class = "Class"
Statics.All = "All"
Statics.Global = "Global"

Statics.SampleMacros = {}
Statics.QuestionMark = "INV_MISC_QUESTIONMARK"

Statics.ReloadMessage = "Reload"
Statics.CommPrefix = "GSE"
