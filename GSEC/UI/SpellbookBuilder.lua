local GSE = GSE
local Config = GSE.ControlPanel
if not Config then return end

local Builder = {
  spells = {},
  rows = {},
  filter = "all",
  generatedNames = {},
  scanned = false,
}
Config.SpellbookBuilder = Builder

local BOOK_SPELL = BOOKTYPE_SPELL or "spell"
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local CATEGORY_ORDER = { "rotation", "area", "cooldown", "defense", "healing", "utility" }
local CATEGORY_INDEX = {}
local CATEGORY = {
  rotation = { label = "MAIN", suffix = "MAIN", bind = "Mouse wheel down; repeat manually around 100 ms." },
  area = { label = "AOE", suffix = "AOE", bind = "Shift + mouse wheel down or a dedicated multi-target key." },
  cooldown = { label = "BURST", suffix = "BURST", bind = "Mouse wheel up or a dedicated manual key." },
  defense = { label = "DEFENSE", suffix = "DEF", bind = "Mouse button 4; press when protection is needed." },
  healing = { label = "HEAL", suffix = "HEAL", bind = "Mouse button 5; use mouseover or friendly targets." },
  utility = { label = "UTILITY", suffix = "UTIL", bind = "A dedicated manual key; utility is situational." },
}
for index, key in ipairs(CATEGORY_ORDER) do CATEGORY_INDEX[key] = index end

local EXCLUDED_TABS = {
  ["ascension vanity items"] = true,
  ["companions"] = true,
  ["mounts"] = true,
  ["professions"] = true,
}

local MAINTENANCE_WORDS = {
  "hearthstone", "teleport", "portal", "riding skill", "summons a mount", "mount speed", "profession", "smelting",
  "cooking", "fishing", "first aid", "archaeology", "create food", "create water",
  "conjure", "resurrect", "resurrection", "revive", "ritual", "language", "weapon skill",
  "armor proficiency", "opening", "lockpicking", "disenchant", "milling", "prospecting",
}
local HEALING_WORDS = {
  "heals ", "heal the", "healing", "restores health", "restore health", "health over",
  "regenerates health", "regenerate health", "friendly target", "wounded ally",
}
local DEFENSE_WORDS = {
  "damage taken", "reduces all damage", "reduce damage", "absorbs damage", "absorb damage",
  "damage absorption", "become immune", "immunity", "increases armor", "increase armor",
  "increases dodge", "increases parry", "chance to dodge", "chance to parry", "protects you",
  "protects the caster", "defensive", "cannot be harmed",
}
local UTILITY_WORDS = {
  "interrupt", "silence", "stun", "incapacitate", "disorient", "fear", "root", "snare",
  "movement speed", "run speed", "dispels", "dispel", "purges", "purge", "remove a poison",
  "remove a curse", "remove a disease", "remove a magic", "taunt", "threat", "crowd control",
  "stealth", "invisible", "invisibility", "detect invisibility", "control of", "charms ",
}
local BURST_WORDS = {
  "increases all damage", "increases your damage", "increase your damage", "increases attack power",
  "increases spell power", "increases haste", "increases your haste", "critical strike chance",
  "all attacks deal", "damage dealt is increased", "damage done is increased",
}
local OFFENSE_WORDS = {
  " damage", "weapon damage", "deals ", "attack the", "attacks the", "strike the", "strikes the",
  "blast the", "burns the", "bleed", "poison", "disease", "damage over time", "enemy target",
  "hostile target", "combo point", "generates rage", "generates energy", "generates runic",
}
local AREA_WORDS = {
  "all enemies", "all targets", "nearby enemies", "nearby targets", "enemies within", "targets within",
  "surrounding enemies", "multiple enemies", "each enemy", "area of effect", "in a cone", "cone in front",
  "around the caster", "around you", "target area", "target location", "selected area",
}
local CHANNEL_WORDS = { "channeled", "channeling", "channels ", "while channeling" }
local GENERATOR_WORDS = {
  "generates rage", "generates energy", "generates runic", "generates mana", "generates a combo point",
  "generates 1 combo point", "awards 1 combo point", "adds a combo point", "gain rage", "gain energy",
  "gain runic power", "restores mana", "restore mana",
}
local FINISHER_WORDS = {
  "finishing move", "per combo point", "consumes all combo", "consumes combo", "requires combo point",
  "consumes all charges", "consume all charges", "consumes up to", "consume up to",
}
local PERIODIC_WORDS = {
  "damage over time", "healing over time", "every 1 sec", "every 2 sec", "every 3 sec", "periodic damage",
  "periodically", "bleed", "disease", "poison",
}
local EXECUTE_WORDS = {
  "below 20% health", "below 25% health", "below 35% health", "less than 20% health",
  "less than 25% health", "low health", "execute an enemy",
}
local MANUAL_TARGET_WORDS = { "target location", "target area", "selected area", "click on the ground" }
local SETUP_WORDS = {
  "shapeshift into", "assume a ", "enter a stance", "switch to ", "activates an aura", "summons a pet",
  "summons your", "dismisses your", "only usable out of combat", "cannot be used in combat",
}
local FRIENDLY_WORDS = {
  "friendly target", "friendly targets", "party member", "raid member", "an ally", "allies", "friendly unit",
}
local SELF_WORDS = { "on yourself", "protects you", "protects the caster", "the caster gains", "surrounds the caster" }
local REQUIREMENT_WORDS = {
  "requires stealth", "requires cat form", "requires bear form", "requires defensive stance",
  "requires battle stance", "requires berserker stance", "requires a melee weapon", "requires a shield",
  "requires a ranged weapon", "must be behind", "must be in front", "only usable while",
}

local POWER_TYPE_NAMES = {
  [0] = "mana", [1] = "rage", [2] = "focus", [3] = "energy", [4] = "happiness",
  [5] = "runes", [6] = "runic power",
}

local function trim(value)
  return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function compactLine(value, maxCharacters)
  local text = tostring(value or ""):gsub("[%c]", " "):gsub("%s+", " ")
  text = trim(text)
  maxCharacters = tonumber(maxCharacters) or 64
  if string.len(text) <= maxCharacters then return text end
  return string.sub(text, 1, math.max(1, maxCharacters - 3)) .. "..."
end

local function spellOverrideKey(spell)
  return string.lower(trim(spell and spell.name))
end

local function getCharacterKey()
  local characterKey
  if type(GSE.GetCharacterName) == "function" then
    local ok, value = pcall(GSE.GetCharacterName)
    if ok then characterKey = trim(value) end
  end
  if not characterKey or characterKey == "" then
    local name = type(UnitName) == "function" and UnitName("player") or "Unknown"
    local realm = type(GetRealmName) == "function" and GetRealmName() or "Unknown"
    characterKey = tostring(name or "Unknown") .. "@" .. tostring(realm or "Unknown")
  end
  return characterKey
end

local function getBuilderStore()
  if type(GSEOptions) ~= "table" then return nil end
  if type(GSEOptions.SpellbookBuilderOverrides) ~= "table" then
    GSEOptions.SpellbookBuilderOverrides = { version = 2, characters = {}, generatedSets = {} }
  end
  local root = GSEOptions.SpellbookBuilderOverrides
  root.version = 2
  if type(root.characters) ~= "table" then root.characters = {} end
  if type(root.generatedSets) ~= "table" then root.generatedSets = {} end
  return root
end

local function getCharacterOverrideStore()
  local root = getBuilderStore()
  if not root then return nil end
  local characterKey = getCharacterKey()
  if type(root.characters[characterKey]) ~= "table" then root.characters[characterKey] = {} end
  return root.characters[characterKey]
end

local function getGeneratedSet(create)
  local root = getBuilderStore()
  if not root then return nil end
  local characterKey = getCharacterKey()
  if create and type(root.generatedSets[characterKey]) ~= "table" then root.generatedSets[characterKey] = {} end
  return root.generatedSets[characterKey]
end

local function hasGeneratedRoles(generated)
  return type(generated) == "table" and type(generated.roles) == "table" and next(generated.roles) ~= nil
end

local function autoSyncEnabled()
  return type(GSEOptions) == "table" and GSEOptions.spellbookAutoSync == true
end

local function getSpellOverride(spell, create)
  local store = getCharacterOverrideStore()
  local key = spellOverrideKey(spell)
  if not store or key == "" then return nil end
  if create and type(store[key]) ~= "table" then store[key] = {} end
  return store[key], store, key
end

local function pruneSpellOverride(spell)
  local override, store, key = getSpellOverride(spell, false)
  if override and next(override) == nil then store[key] = nil end
end

local function defaultSpellOrder(spell)
  local categoryIndex = CATEGORY_INDEX[spell.category] or (#CATEGORY_ORDER + 1)
  local priority = tonumber(spell.analysisPriority) or 50
  local stableIndex = tonumber(spell.arrayIndex) or 0
  return (categoryIndex * 100000) + (priority * 100) + stableIndex
end

local function applySpellOverride(spell)
  local override = getSpellOverride(spell, false)
  if not override then
    spell.order = defaultSpellOrder(spell)
    return
  end
  local scannerCategory = spell.category
  if CATEGORY[override.category] then
    spell.category = override.category
    spell.manualCategory = true
    spell.reason = "Manual role: " .. CATEGORY[spell.category].label .. " (suggested " .. CATEGORY[scannerCategory].label .. ")."
  end
  spell.order = tonumber(override.order) or defaultSpellOrder(spell)
  spell.banned = override.banned and true or false
  if spell.banned then
    spell.selected = false
  elseif override.selected ~= nil then
    spell.selected = override.selected and true or false
  end
end

local function normalizeName(value)
  local name = string.upper(trim(value)):gsub("[^%w_]+", "_"):gsub("_+", "_")
  name = name:gsub("^_+", ""):gsub("_+$", "")
  if name == "" then name = "AUTO_BUILD" end
  return string.sub(name, 1, 16)
end

local function cleanTooltipText(value)
  value = tostring(value or "")
  value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  value = value:gsub("|T.-|t", ""):gsub("|H.-|h", ""):gsub("|h", "")
  value = value:gsub("[%c]", " "):gsub("%s+", " ")
  return trim(value)
end

local function tooltipMarksPassive(text)
  text = string.lower(cleanTooltipText(text))
  return string.find(text, "%f[%a]passive%f[%A]") ~= nil
    or string.find(text, "cannot be cast", 1, true) ~= nil
    or string.find(text, "always active", 1, true) ~= nil
end

local function containsAny(text, words)
  for _, word in ipairs(words) do
    if string.find(text, word, 1, true) then return true end
  end
  return false
end

local function makeText(parent, font, size, color)
  return Config.MakeText(parent, font, size, color)
end

local function makeInput(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetHeight(20)
  Config:RegisterFrame(frame, "inset", "muted")
  local edit = CreateFrame("EditBox", nil, frame)
  edit:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -2)
  edit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 2)
  edit:SetAutoFocus(false)
  edit:SetFontObject(ChatFontNormal)
  edit:SetMaxLetters(16)
  if edit.SetNumeric then edit:SetNumeric(false) end
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEditFocusGained", function() frame.focused = true frame:Refresh() end)
  edit:SetScript("OnEditFocusLost", function() frame.focused = false frame:Refresh() end)
  edit:SetScript("OnTextChanged", function(self, userInput)
    if userInput and frame.OnValueChanged then frame:OnValueChanged(self:GetText()) end
  end)
  edit:EnableMouseWheel(true)
  edit:SetScript("OnMouseWheel", function(_, delta) Builder:ScrollList(delta) end)
  frame.editbox = edit
  function frame:SetText(value)
    self.editbox:SetText(tostring(value or ""))
    self.editbox:SetCursorPosition(0)
  end
  function frame:GetText() return self.editbox:GetText() end
  function frame:Refresh()
    local colors = Config:GetPalette()
    self:SetBackdropColor(unpack(colors.inset))
    self:SetBackdropBorderColor(unpack(colors[self.focused and "focusBorder" or "muted"] or colors.muted))
    self.editbox:SetTextColor(unpack(colors.text))
  end
  table.insert(Config.controls, frame)
  frame:Refresh()
  return frame
end

local function getScanTooltip()
  if Builder.scanTooltip then return Builder.scanTooltip end
  if _G.GSESpellbookBuilderTooltip then
    Builder.scanTooltip = _G.GSESpellbookBuilderTooltip
    return Builder.scanTooltip
  end
  local ok, tooltip = pcall(CreateFrame, "GameTooltip", "GSESpellbookBuilderTooltip", UIParent, "GameTooltipTemplate")
  if ok then Builder.scanTooltip = tooltip end
  return Builder.scanTooltip
end

local function getTooltipDescription(slot, spellID)
  local tooltip = getScanTooltip()
  if not tooltip then return "" end
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:ClearLines()
  local loaded = false
  if slot and tooltip.SetSpellBookItem then
    loaded = pcall(tooltip.SetSpellBookItem, tooltip, slot, BOOK_SPELL)
  end
  if (not loaded or tooltip:NumLines() < 2) and spellID and tooltip.SetHyperlink then
    tooltip:ClearLines()
    loaded = pcall(tooltip.SetHyperlink, tooltip, "spell:" .. tostring(spellID))
  end
  if not loaded then tooltip:Hide() return "" end
  local lines = {}
  local tooltipName = tooltip:GetName()
  for index = 2, tooltip:NumLines() do
    for _, side in ipairs({ "TextLeft", "TextRight" }) do
      local line = tooltipName and _G[tooltipName .. side .. index]
      local text = cleanTooltipText(line and line:GetText())
      if text ~= "" then table.insert(lines, text) end
    end
  end
  tooltip:Hide()
  return table.concat(lines, " ")
end

local function parseTooltipCooldown(text)
  local amount, unit = text:match("(%d+%.?%d*)%s*(sec)%a* cooldown")
  if not amount then amount, unit = text:match("(%d+%.?%d*)%s*(min)%a* cooldown") end
  local seconds = tonumber(amount)
  if seconds and unit == "min" then seconds = seconds * 60 end
  return seconds
end

local function readBaseCooldown(spellID, spellName, description)
  local cooldownMs, gcdMs
  if type(GetSpellBaseCooldown) == "function" then
    local query = spellID or spellName
    local ok, base, gcd = pcall(GetSpellBaseCooldown, query)
    if ok then cooldownMs, gcdMs = tonumber(base), tonumber(gcd) end
    if (not cooldownMs or cooldownMs <= 0) and spellID and spellName then
      ok, base, gcd = pcall(GetSpellBaseCooldown, spellName)
      if ok then cooldownMs, gcdMs = tonumber(base), tonumber(gcd) end
    end
  end
  local cooldownSeconds = cooldownMs and cooldownMs > 0 and (cooldownMs / 1000) or nil
  if not cooldownSeconds then cooldownSeconds = parseTooltipCooldown(string.lower(description or "")) end
  return cooldownSeconds, gcdMs and gcdMs > 0 and (gcdMs / 1000) or nil
end

local function formatSeconds(value)
  if not value then return nil end
  if value == math.floor(value) then return tostring(math.floor(value)) end
  return string.format("%.1f", value)
end

local function describeMetadata(spell)
  local details = {}
  if spell.castTimeMs ~= nil then
    if spell.castTimeMs <= 0 then
      table.insert(details, "instant")
    else
      table.insert(details, formatSeconds(spell.castTimeMs / 1000) .. "s cast")
    end
  end
  if spell.cooldownSeconds and spell.cooldownSeconds > 0 then
    table.insert(details, formatSeconds(spell.cooldownSeconds) .. "s cooldown")
  end
  if spell.maxRange and spell.maxRange > 0 then
    table.insert(details, tostring(spell.minRange or 0) .. "-" .. tostring(spell.maxRange) .. " yd")
  elseif spell.maxRange == 0 then
    table.insert(details, "self/melee range")
  end
  if spell.powerCost and spell.powerCost > 0 then
    table.insert(details, tostring(spell.powerCost) .. " " .. (POWER_TYPE_NAMES[spell.powerType] or ("power " .. tostring(spell.powerType or "?"))))
  end
  return table.concat(details, ", ")
end

local function classifySpell(spell)
  local combined = string.lower((spell.name or "") .. " " .. (spell.description or ""))
  local tabName = string.lower(spell.tabName or "")
  local signals = {
    maintenance = containsAny(combined, MAINTENANCE_WORDS),
    healing = containsAny(combined, HEALING_WORDS),
    defense = containsAny(combined, DEFENSE_WORDS),
    utility = containsAny(combined, UTILITY_WORDS),
    burst = containsAny(combined, BURST_WORDS),
    offense = containsAny(combined, OFFENSE_WORDS),
    area = containsAny(combined, AREA_WORDS),
    channel = containsAny(combined, CHANNEL_WORDS),
    generator = containsAny(combined, GENERATOR_WORDS),
    finisher = containsAny(combined, FINISHER_WORDS),
    periodic = containsAny(combined, PERIODIC_WORDS),
    execute = containsAny(combined, EXECUTE_WORDS),
    manualTarget = containsAny(combined, MANUAL_TARGET_WORDS),
    setup = containsAny(combined, SETUP_WORDS),
    friendly = containsAny(combined, FRIENDLY_WORDS),
    selfOnly = containsAny(combined, SELF_WORDS),
    requirement = containsAny(combined, REQUIREMENT_WORDS),
  }
  signals.cooldownSeconds = spell.cooldownSeconds
  signals.castSeconds = spell.castTimeMs and (spell.castTimeMs / 1000) or nil
  signals.resourceCost = spell.powerCost
  spell.signals = signals

  local category, recommended, reason, confidence
  if spell.name == "Attack" or spell.name == "Auto Attack" or spell.name == "Auto Shot" or spell.name == "Shoot" then
    category, recommended, confidence = "utility", false, "high"
    reason = "Excluded: GSE uses /startattack."
  elseif signals.maintenance then
    category, recommended, confidence = "utility", false, "high"
    reason = "Excluded: non-combat or maintenance spell."
  elseif signals.setup then
    category, recommended, confidence = "utility", false, "high"
    reason = "Excluded: manual setup spell."
  elseif signals.manualTarget then
    category, recommended, confidence = signals.area and "area" or "utility", false, "high"
    reason = "Excluded: requires ground targeting."
  elseif signals.healing then
    category, recommended, confidence = "healing", true, "high"
    reason = "Healing spell."
  elseif signals.defense then
    category, recommended, confidence = "defense", true, "high"
    reason = "Defensive spell."
  elseif signals.utility then
    category, recommended, confidence = "utility", true, "high"
    reason = "Utility or control spell."
  elseif signals.burst or (spell.cooldownSeconds and spell.cooldownSeconds >= 20) then
    category, recommended, confidence = "cooldown", true, signals.burst and "high" or "medium"
    reason = "Burst or long-cooldown spell."
  elseif signals.area and signals.offense then
    category, recommended, confidence = "area", true, "high"
    reason = "Multi-target damage."
  elseif signals.offense then
    category, recommended, confidence = "rotation", true, "high"
    reason = "Core damage spell."
  elseif tabName == "general" then
    category, recommended, confidence = "utility", false, "medium"
    reason = "Excluded: no clear combat role."
  else
    category, recommended, confidence = "rotation", true, "low"
    reason = "MAIN fallback; role uncertain."
  end

  local priority = 50
  if signals.periodic then priority = priority - 15 end
  if signals.generator then priority = priority - 12 end
  if signals.finisher then priority = priority + 20 end
  if signals.execute then priority = priority + 25 end
  if signals.channel then priority = priority + 8 end
  if signals.requirement then priority = priority + 10 end
  spell.analysisPriority = priority
  spell.confidence = confidence
  spell.metadataSummary = describeMetadata(spell)
  return category, recommended, reason
end

local function readSpell(slot, spellID, tabName)
  local spellType
  if slot and type(GetSpellBookItemInfo) == "function" then
    local ok, itemType, itemID = pcall(GetSpellBookItemInfo, slot, BOOK_SPELL)
    if ok then spellType, spellID = itemType, itemID or spellID end
  end
  if type(spellType) == "string" and string.lower(spellType) ~= "spell" then return nil end

  local name, subName, icon, powerCost, isFunnel, powerType, castTimeMs, minRange, maxRange
  if slot and type(GetSpellBookItemName) == "function" then
    local ok, itemName, itemSubName = pcall(GetSpellBookItemName, slot, BOOK_SPELL)
    if ok then name, subName = itemName, itemSubName end
  end
  if not name and slot and type(GetSpellName) == "function" then
    local ok, itemName, itemSubName = pcall(GetSpellName, slot, BOOK_SPELL)
    if ok then name, subName = itemName, itemSubName end
  end
  if spellID and type(GetSpellInfo) == "function" then
    local ok, infoName, infoSubName, infoIcon, infoPowerCost, infoIsFunnel, infoPowerType, infoCastTime, infoMinRange, infoMaxRange = pcall(GetSpellInfo, spellID)
    if ok then
      name = name or infoName
      subName = subName or infoSubName
      icon = infoIcon
      powerCost, isFunnel, powerType = tonumber(infoPowerCost), infoIsFunnel and true or false, tonumber(infoPowerType)
      castTimeMs, minRange, maxRange = tonumber(infoCastTime), tonumber(infoMinRange), tonumber(infoMaxRange)
    end
  end
  if not icon and slot and type(GetSpellTexture) == "function" then
    local ok, texture = pcall(GetSpellTexture, slot, BOOK_SPELL)
    if ok then icon = texture end
  end
  if not name or trim(name) == "" then return nil end

  local description = getTooltipDescription(slot, spellID)
  local passive = type(subName) == "string" and string.find(string.lower(subName), "passive", 1, true)
  if not passive and type(IsPassiveSpell) == "function" then
    local ok, result
    if slot then ok, result = pcall(IsPassiveSpell, slot, BOOK_SPELL) end
    passive = ok and result and true or false
    if not passive and spellID then
      ok, result = pcall(IsPassiveSpell, spellID)
      passive = ok and result and true or false
    end
  end
  if not passive and tooltipMarksPassive(description) then passive = true end
  if passive then return nil end

  local cooldownSeconds, gcdSeconds = readBaseCooldown(spellID, name, description)
  local spell = {
    name = trim(name), subName = trim(subName), id = tonumber(spellID) or spellID,
    icon = icon or QUESTION_MARK, slot = slot, tabName = tabName or "Ascension",
    description = description, source = slot and "spellbook" or "ascension",
    powerCost = powerCost, powerType = powerType, isFunnel = isFunnel,
    castTimeMs = castTimeMs, minRange = minRange, maxRange = maxRange,
    cooldownSeconds = cooldownSeconds, gcdSeconds = gcdSeconds,
  }
  spell.category, spell.recommended, spell.reason = classifySpell(spell)
  spell.selected = spell.recommended
  spell.banned = false
  return spell
end

local function addKnownAscensionSpells(addSpell)
  if not C_CharacterAdvancement or type(C_CharacterAdvancement.GetKnownSpells) ~= "function" then return end
  local ok, known = pcall(C_CharacterAdvancement.GetKnownSpells)
  if not ok or type(known) ~= "table" then return end
  local ids = {}
  for _, value in ipairs(known) do
    if type(value) == "number" then
      table.insert(ids, value)
    elseif type(value) == "table" then
      local spellID = tonumber(value.spellID or value.SpellID or value.id or value.ID or value[1])
      if spellID then table.insert(ids, spellID) end
    end
  end
  if #ids == 0 then
    for key, value in pairs(known) do
      if type(key) == "number" then
        table.insert(ids, key)
      elseif type(value) == "number" then
        table.insert(ids, value)
      elseif type(value) == "table" then
        local spellID = tonumber(value.spellID or value.SpellID or value.id or value.ID or value[1])
        if spellID then table.insert(ids, spellID) end
      end
    end
  end
  local seen = {}
  for _, spellID in ipairs(ids) do
    if spellID and not seen[spellID] then
      seen[spellID] = true
      addSpell(readSpell(nil, spellID, "Ascension"), false)
    end
  end
end

local function findWholePhrase(text, phrase)
  local startAt = 1
  while true do
    local first, last = string.find(text, phrase, startAt, true)
    if not first then return nil end
    local before = first == 1 and "" or string.sub(text, first - 1, first - 1)
    local after = last == string.len(text) and "" or string.sub(text, last + 1, last + 1)
    if (before == "" or not string.find(before, "[%w_]")) and (after == "" or not string.find(after, "[%w_]")) then
      return first, last
    end
    startAt = last + 1
  end
end

local function inferKnownSpellRelationships(spells)
  for _, spell in ipairs(spells) do
    local description = string.lower(spell.description or "")
    local links, dependencies = {}, {}
    for _, other in ipairs(spells) do
      if other ~= spell then
        local otherName = string.lower(other.name or "")
        if string.len(otherName) >= 4 then
          local first = findWholePhrase(description, otherName)
          if first then
            table.insert(links, other.name)
            local prefix = string.sub(description, math.max(1, first - 28), first - 1)
            if string.find(prefix, "requires%s*$") or string.find(prefix, "while%s*$")
              or string.find(prefix, "after%s*$") or string.find(prefix, "when%s*$") then
              table.insert(dependencies, other.name)
            end
          end
        end
      end
    end
    spell.links = links
    spell.dependencies = dependencies
    if #dependencies > 0 then spell.analysisPriority = (spell.analysisPriority or 50) + 6 end
  end
end

local function hashText(source)
  local hash = 5381
  for index = 1, string.len(source) do hash = ((hash * 33) + string.byte(source, index)) % 2147483647 end
  return string.format("%08x", hash)
end

local function buildLoadoutFingerprint(spells)
  local parts = {}
  for _, spell in ipairs(spells) do
    table.insert(parts, tostring(spell.id or 0) .. ":" .. string.lower(spell.name or ""))
  end
  table.sort(parts)
  return hashText(table.concat(parts, "|"))
end

local function appendSignatureArray(parts, label, values)
  table.insert(parts, label)
  if type(values) ~= "table" then return end
  for index, value in ipairs(values) do table.insert(parts, tostring(index) .. "=" .. tostring(value or "")) end
end

local function sequenceSignature(sequence)
  if type(sequence) ~= "table" then return nil end
  local parts = {
    "Author=" .. tostring(sequence.Author or ""), "Talents=" .. tostring(sequence.Talents or ""),
    "Default=" .. tostring(sequence.Default or ""), "SpecID=" .. tostring(sequence.SpecID or ""),
    "Icon=" .. tostring(sequence.Icon or ""), "Help=" .. tostring(sequence.Help or ""),
  }
  for versionIndex, version in ipairs(sequence.MacroVersions or {}) do
    table.insert(parts, "Version=" .. tostring(versionIndex))
    table.insert(parts, "StepFunction=" .. tostring(version.StepFunction or ""))
    appendSignatureArray(parts, "KeyPress", version.KeyPress)
    appendSignatureArray(parts, "PreMacro", version.PreMacro)
    appendSignatureArray(parts, "Body", version)
    appendSignatureArray(parts, "PostMacro", version.PostMacro)
    appendSignatureArray(parts, "KeyRelease", version.KeyRelease)
  end
  return hashText(table.concat(parts, "\031"))
end

local function finalizeLoadout(spells)
  inferKnownSpellRelationships(spells)
  for _, spell in ipairs(spells) do
    spell.scanReason = spell.reason
    applySpellOverride(spell)
  end
  return buildLoadoutFingerprint(spells)
end

function Builder:DefaultBaseName()
  local _, specName = GSE.GetCurrentSpecID()
  local className = GSE.GetCurrentClassNormalisedName and GSE.GetCurrentClassNormalisedName() or "BUILD"
  local stem = trim(specName) ~= "" and specName or className
  return normalizeName("AUTO_" .. tostring(stem or "BUILD"))
end

function Builder:Scan(sourceEvent)
  local trackedSet = getGeneratedSet(false)
  local hadTrackedDrafts = hasGeneratedRoles(trackedSet)
  local previousFingerprint = self.fingerprint or (trackedSet and trackedSet.fingerprint)
  local spells, byName = {}, {}
  local function addSpell(spell, replace)
    if not spell then return end
    local key = string.lower(spell.name)
    local existing = byName[key]
    if existing then
      if replace and spell.slot then
        spell.order = existing.order
        spell.arrayIndex = existing.arrayIndex
        spells[existing.arrayIndex] = spell
        byName[key] = spell
      end
      return
    end
    spell.arrayIndex = #spells + 1
    spell.order = spell.arrayIndex
    spells[spell.arrayIndex] = spell
    byName[key] = spell
  end

  if type(GetNumSpellTabs) == "function" and type(GetSpellTabInfo) == "function" then
    local okTabs, tabCount = pcall(GetNumSpellTabs)
    if okTabs then
      for tab = 1, tonumber(tabCount) or 0 do
        local okTab, tabName, _, offset, count = pcall(GetSpellTabInfo, tab)
        local excluded = EXCLUDED_TABS[string.lower(tabName or "")]
        if okTab and not excluded and tonumber(offset) and tonumber(count) then
          for slot = offset + 1, offset + count do
            addSpell(readSpell(slot, nil, tabName), true)
          end
        end
      end
    end
  end
  addKnownAscensionSpells(addSpell)

  self.fingerprint = finalizeLoadout(spells)
  self.spells = spells
  self.scanned = true
  self.dirty = false
  self.dirtyEvent = nil
  self.filter = self.filter or "all"
  if self.nameInput and trim(self.nameInput:GetText()) == "" then self.nameInput:SetText(self:DefaultBaseName()) end
  self:RefreshFilterButtons()
  self:RefreshRows()
  local changed = previousFingerprint ~= nil and previousFingerprint ~= self.fingerprint
  if #spells == 0 then
    self.emptyScanRetries = (self.emptyScanRetries or 0) + 1
    if sourceEvent and self.emptyScanRetries <= 4 and self.eventFrame then
      self.dirty = true
      self.dirtyEvent = "SPELL_API_RETRY"
      self.scanDelay = 1.5
    end
    Config:SetStatus("Spell data is not ready yet. GSE will retry automatically; no window needs to be opened.", "warning")
  else
    self.emptyScanRetries = 0
    local prefix = sourceEvent and (changed and "Loadout changed; rescanned " or "Loadout event checked ") or "Scanned "
    Config:SetStatus(prefix .. tostring(#spells) .. " exact known active spells. Fingerprint " .. self.fingerprint .. ".", "success")
  end
  local shouldCreate = #spells > 0 and not hadTrackedDrafts
  local shouldSync = #spells > 0 and sourceEvent and changed and hadTrackedDrafts
  if autoSyncEnabled() and sourceEvent and (shouldCreate or shouldSync) then
    local ok, message
    if shouldCreate and self.CreateSet then
      ok, message = pcall(self.CreateSet, self, { automatic = true, baseName = self:DefaultBaseName() })
    elseif self.SyncGeneratedSet then
      ok, message = pcall(self.SyncGeneratedSet, self, false)
    else
      ok = true
    end
    self.manualSyncPending = nil
    self.manualSyncDelay = nil
    if not ok then Config:SetStatus("Automatic spellbook draft update failed safely: " .. tostring(message), "danger") end
  end
end

local LOADOUT_CHANGE_EVENTS = {
  "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
  "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED",
  "ASCENSION_KNOWN_ENTRIES_UPDATED", "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED",
  "CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT", "CHARACTER_ADVANCEMENT_LEARN_RESULT",
  "CHARACTER_ADVANCEMENT_UNLEARN_RESULT", "MYSTIC_ENCHANT_SPECIALIZATION_LINK_UPDATED",
  "MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT", "MYSTIC_ENCHANT_SLOT_UPDATE", "ACTIVE_MANASTORM_UPDATED",
}

function Builder:ScheduleLoadoutScan(event)
  self.dirty = true
  self.dirtyEvent = event or self.dirtyEvent or "SPELLS_CHANGED"
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
  if not self.eventFrame then return end
  self.scanDelay = 0.75
end

function Builder:RequestDraftSync()
  if not autoSyncEnabled() then return end
  local generated = getGeneratedSet(false)
  if type(generated) ~= "table" or type(generated.roles) ~= "table" or not next(generated.roles) then return end
  self.manualSyncPending = true
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
  self.manualSyncDelay = 0.45
end

function Builder:EnsureEventFrame()
  if self.eventFrame then return end
  local frame = CreateFrame("Frame")
  self.eventFrame = frame
  for _, event in ipairs(LOADOUT_CHANGE_EVENTS) do pcall(frame.RegisterEvent, frame, event) end
  pcall(frame.RegisterEvent, frame, "PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
      if Builder.dirty then Builder:ScheduleLoadoutScan(Builder.dirtyEvent) end
      if Builder.manualSyncPending then Builder.manualSyncDelay = 0.45 end
    else
      Builder:ScheduleLoadoutScan(event)
    end
  end)
  frame:SetScript("OnUpdate", function(_, elapsed)
    local delta = tonumber(elapsed) or 0
    if Builder.scanDelay then
      Builder.scanDelay = Builder.scanDelay - delta
      if Builder.scanDelay <= 0 then
        Builder.scanDelay = nil
        if Builder.dirty and (type(InCombatLockdown) ~= "function" or not InCombatLockdown()) then
          Builder:Scan(Builder.dirtyEvent)
        end
      end
    end
    if Builder.manualSyncDelay then
      Builder.manualSyncDelay = Builder.manualSyncDelay - delta
      if Builder.manualSyncDelay <= 0 then
        Builder.manualSyncDelay = nil
        if Builder.manualSyncPending and (type(InCombatLockdown) ~= "function" or not InCombatLockdown()) then
          Builder.manualSyncPending = nil
          if Builder.SyncGeneratedSet then
            local ok, message = pcall(Builder.SyncGeneratedSet, Builder, true)
            if not ok then Config:SetStatus("Manual draft sync failed safely: " .. tostring(message), "danger") end
          end
        end
      end
    end
  end)
end

function Builder:VisibleSpells()
  local visible = {}
  for _, spell in ipairs(self.spells) do
    if self.filter == "all"
      or (self.filter == "banned" and spell.banned)
      or (self.filter ~= "banned" and not spell.banned and spell.category == self.filter) then
      table.insert(visible, spell)
    end
  end
  table.sort(visible, function(a, b)
    if a.order == b.order then return string.lower(a.name) < string.lower(b.name) end
    return a.order < b.order
  end)
  return visible
end

function Builder:ScrollList(delta)
  if not self.listScroll or not self.listChild then return end
  local maximum = math.max(0, self.listChild:GetHeight() - self.listScroll:GetHeight())
  local value = math.max(0, math.min(maximum, self.listScroll:GetVerticalScroll() - (delta * 58)))
  self.listScroll:SetVerticalScroll(value)
  if self.listSlider then self.listSlider:SetValue(value) end
end

function Builder:CycleCategory(spell)
  local index = CATEGORY_INDEX[spell.category] or 1
  spell.category = CATEGORY_ORDER[(index % #CATEGORY_ORDER) + 1]
  if not spell.banned then spell.selected = true end
  spell.order = defaultSpellOrder(spell)
  spell.reason = "Manual role: " .. CATEGORY[spell.category].label .. "."
  local override = getSpellOverride(spell, true)
  override.category = spell.category
  override.order = nil
  if not spell.banned then override.selected = true end
  self:RefreshRows()
  self:RequestDraftSync()
end

function Builder:ToggleSelection(spell)
  if spell.banned then
    Config:SetStatus(spell.name .. " is banned. Press UNBAN before including it.", "warning")
    return
  end
  spell.selected = not spell.selected
  local override = getSpellOverride(spell, true)
  override.selected = spell.selected and true or false
  pruneSpellOverride(spell)
  self:RefreshRows()
  self:RequestDraftSync()
end

function Builder:ToggleBan(spell)
  local override = getSpellOverride(spell, true)
  if spell.banned then
    spell.banned = false
    override.banned = nil
    if override.selected ~= nil then
      spell.selected = override.selected and true or false
    else
      spell.selected = spell.recommended and true or false
    end
    Config:SetStatus(spell.name .. " is allowed again and may be used by generated drafts.", "success")
  else
    if override.selected == nil then override.selected = spell.selected and true or false end
    override.banned = true
    spell.banned = true
    spell.selected = false
    Config:SetStatus(spell.name .. " is banned for this character. Rescans and auto-pick will keep it out.", "warning")
  end
  pruneSpellOverride(spell)
  self:RefreshRows()
  self:RequestDraftSync()
end

function Builder:MoveSpell(spell, direction)
  local peers = {}
  for _, candidate in ipairs(self.spells) do
    if candidate.category == spell.category then table.insert(peers, candidate) end
  end
  table.sort(peers, function(a, b) return a.order < b.order end)
  for index, candidate in ipairs(peers) do
    if candidate == spell then
      local other = peers[index + direction]
      if other then
        spell.order, other.order = other.order, spell.order
        local spellOverride = getSpellOverride(spell, true)
        local otherOverride = getSpellOverride(other, true)
        spellOverride.order = spell.order
        otherOverride.order = other.order
      end
      break
    end
  end
  self:RefreshRows()
  self:RequestDraftSync()
end

local function attachListWheel(frame)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta) Builder:ScrollList(delta) end)
end

local function getCursorPosition()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  return x / scale, y / scale
end

local function pointInside(frame, x, y)
  if not frame or not frame:IsShown() then return false end
  local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
  return left and right and top and bottom and x >= left and x <= right and y >= bottom and y <= top
end

function Builder:ReorderSpell(spell, target, placeAfter)
  if not spell or not target or spell == target or spell.category ~= target.category then return false end
  local peers = {}
  for _, candidate in ipairs(self.spells) do
    if candidate.category == spell.category then table.insert(peers, candidate) end
  end
  table.sort(peers, function(a, b) return a.order < b.order end)
  for index = #peers, 1, -1 do
    if peers[index] == spell then table.remove(peers, index) break end
  end
  local targetIndex
  for index, candidate in ipairs(peers) do
    if candidate == target then targetIndex = index break end
  end
  if not targetIndex then return false end
  table.insert(peers, targetIndex + (placeAfter and 1 or 0), spell)
  for index, candidate in ipairs(peers) do
    candidate.order = index * 10
    getSpellOverride(candidate, true).order = candidate.order
  end
  self:RefreshRows()
  self:RequestDraftSync()
  return true
end

function Builder:EndSpellDrag()
  local state = self.spellDrag
  if self.dragTracker then self.dragTracker:Hide() end
  self.spellDrag = nil
  if state and state.row then state.row.dragReleaseAt = GetTime() end
  if state and state.moved then Config:SetStatus("Spell order saved for " .. CATEGORY[state.spell.category].label .. ".", "success") end
end

function Builder:BeginSpellDrag(spell, row)
  if not spell then return end
  self.spellDrag = { spell = spell, row = row, moved = false }
  GameTooltip:Hide()
  if not self.dragTracker then
    self.dragTracker = CreateFrame("Frame", nil, UIParent)
    self.dragTracker:SetScript("OnUpdate", function()
      local state = Builder.spellDrag
      if not state then Builder.dragTracker:Hide() return end
      if type(IsMouseButtonDown) == "function" and not IsMouseButtonDown("LeftButton") then
        Builder:EndSpellDrag()
        return
      end
      local x, y = getCursorPosition()
      if not pointInside(Builder.listScroll, x, y) then return end
      for _, row in ipairs(Builder.rows) do
        local target = row.spell
        if target and row:IsShown() and target ~= state.spell and target.category == state.spell.category and pointInside(row, x, y) then
          local midpoint = (row:GetTop() + row:GetBottom()) / 2
          local placeAfter = y < midpoint
          local placement = spellOverrideKey(target) .. (placeAfter and ":after" or ":before")
          if placement ~= state.lastPlacement then
            state.lastPlacement = placement
            if Builder:ReorderSpell(state.spell, target, placeAfter) then state.moved = true end
          end
          return
        end
      end
    end)
  end
  self.dragTracker:Show()
end

function Builder:CreateRow(index)
  local row = CreateFrame("Button", nil, self.listChild)
  row:SetHeight(29)
  Config:RegisterFrame(row, "inset", "muted")
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row:SetScript("OnClick", function(self, mouseButton)
    if not self.spell then return end
    if self.dragged then
      local justReleased = not self.dragReleaseAt or (GetTime() - self.dragReleaseAt) < 0.25
      self.dragged, self.dragReleaseAt = nil, nil
      if justReleased then return end
    end
    if mouseButton == "RightButton" then Builder:CycleCategory(self.spell) else Builder:ToggleSelection(self.spell) end
  end)
  row:SetScript("OnEnter", function(self)
    self.hovered = true
    self:RefreshTheme()
    if self.spell then
      local state = self.spell.banned and "BANNED FOR THIS CHARACTER. " or ""
      Config:ShowHelp(self, self.spell.name .. " - " .. CATEGORY[self.spell.category].label, state .. self.spell.reason .. ((self.spell.description ~= "") and ("\n\n" .. self.spell.description) or ""))
    end
  end)
  row:SetScript("OnLeave", function(self) self.hovered = false self:RefreshTheme() GameTooltip:Hide() end)
  attachListWheel(row)
  row:RegisterForDrag("LeftButton")
  row:SetScript("OnDragStart", function(self)
    if self.spell then
      self.dragged = true
      Builder:BeginSpellDrag(self.spell, self)
    end
  end)
  row:SetScript("OnDragStop", function() Builder:EndSpellDrag() end)

  row.mark = makeText(row, "GameFontNormalSmall", 12, "success")
  row.mark:SetPoint("LEFT", row, "LEFT", 6, 0)
  row.mark:SetWidth(12)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(20, 20)
  row.icon:SetPoint("LEFT", row, "LEFT", 22, 0)
  row.nameText = makeText(row, "GameFontNormalSmall", 10, "text")
  row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 6, 4)
  row.nameText:SetWidth(132)
  row.nameText:SetJustifyH("LEFT")
  row.reasonText = makeText(row, "GameFontNormalSmall", 8, "dim")
  row.reasonText:SetPoint("LEFT", row.icon, "RIGHT", 6, -7)
  row.reasonText:SetHeight(10)
  row.reasonText:SetJustifyH("LEFT")
  if row.reasonText.SetWordWrap then row.reasonText:SetWordWrap(false) end
  if row.reasonText.SetNonSpaceWrap then row.reasonText:SetNonSpaceWrap(false) end

  row.down = Config:MakeButton(row, "v", function() if row.spell then Builder:MoveSpell(row.spell, 1) end end)
  row.down:SetSize(19, 20)
  row.down:SetPoint("RIGHT", row, "RIGHT", -3, 0)
  attachListWheel(row.down)
  row.up = Config:MakeButton(row, "^", function() if row.spell then Builder:MoveSpell(row.spell, -1) end end)
  row.up:SetSize(19, 20)
  row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)
  attachListWheel(row.up)
  row.categoryButton = Config:MakeButton(row, "MAIN", function() if row.spell then Builder:CycleCategory(row.spell) end end)
  row.categoryButton:SetSize(54, 20)
  row.categoryButton:SetPoint("RIGHT", row.up, "LEFT", -3, 0)
  attachListWheel(row.categoryButton)
  row.banButton = Config:MakeButton(row, "BAN", function() if row.spell then Builder:ToggleBan(row.spell) end end, "danger")
  row.banButton:SetSize(43, 20)
  row.banButton:SetPoint("RIGHT", row.categoryButton, "LEFT", -3, 0)
  attachListWheel(row.banButton)
  row.reasonText:SetPoint("RIGHT", row.banButton, "LEFT", -6, -7)

  function row:RefreshTheme()
    local colors = Config:GetPalette()
    local fillName = self.hovered and "hover" or (self.spell and self.spell.selected and "raised" or "inset")
    local borderName = self.spell and self.spell.banned and "dangerBorder" or (self.spell and self.spell.selected and "activeBorder" or "muted")
    self:SetBackdropColor(unpack(colors[fillName] or colors.inset))
    self:SetBackdropBorderColor(unpack(colors[borderName] or colors.muted))
    self.mark:SetTextColor(unpack(colors[self.spell and self.spell.banned and "danger" or (self.spell and self.spell.selected and "success" or "dim")]))
    self.nameText:SetTextColor(unpack(colors[self.spell and self.spell.banned and "danger" or "text"]))
  end
  Config.buttons[row] = true
  self.rows[index] = row
  return row
end

function Builder:UpdateSummary()
  local selected, banned, groups = 0, 0, {}
  for _, key in ipairs(CATEGORY_ORDER) do groups[key] = 0 end
  for _, spell in ipairs(self.spells) do
    if spell.banned then
      banned = banned + 1
    elseif spell.selected then
      selected = selected + 1
      groups[spell.category] = groups[spell.category] + 1
    end
  end
  local groupCount = 0
  for _, key in ipairs(CATEGORY_ORDER) do if groups[key] > 0 then groupCount = groupCount + 1 end end
  if self.summaryText then
    self.summaryText:SetText(string.format("SEL %d/%d  BAN %d | MAIN %d  AOE %d  BURST %d  DEF %d  HEAL %d  UTIL %d", selected, #self.spells, banned, groups.rotation, groups.area, groups.cooldown, groups.defense, groups.healing, groups.utility))
  end
  if self.createButton then self.createButton.label:SetText("BUILD " .. tostring(groupCount) .. (groupCount == 1 and " DRAFT" or " DRAFTS")) end
end

function Builder:RefreshRows()
  if not self.listChild then return end
  local visible = self:VisibleSpells()
  self.visible = visible
  for index, spell in ipairs(visible) do
    local row = self.rows[index] or self:CreateRow(index)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.listChild, "TOPLEFT", 0, -((index - 1) * 30))
    row:SetPoint("TOPRIGHT", self.listChild, "TOPRIGHT", 0, -((index - 1) * 30))
    row.spell = spell
    row.mark:SetText(spell.banned and "x" or (spell.selected and "+" or "-"))
    row.icon:SetTexture(spell.icon or QUESTION_MARK)
    row.nameText:SetText(spell.name)
    row.reasonText:SetText(compactLine((spell.banned and "BANNED | " or "") .. spell.reason, 64))
    row.categoryButton.label:SetText(CATEGORY[spell.category].label)
    row.banButton.label:SetText(spell.banned and "UNBAN" or "BAN")
    row.banButton.selected = spell.banned and true or false
    row.banButton:RefreshTheme()
    row:RefreshTheme()
    row:Show()
  end
  for index = #visible + 1, #self.rows do self.rows[index]:Hide() end
  local visibleHeight = math.max(1, self.listScroll:GetHeight())
  local contentHeight = math.max(visibleHeight, #visible * 30)
  self.listChild:SetHeight(contentHeight)
  local maximum = math.max(0, contentHeight - visibleHeight)
  self.listSlider:SetMinMaxValues(0, maximum)
  self.listSlider:SetValueStep(1)
  if maximum > 0 then self.listSlider:Show() else self.listSlider:Hide() self.listScroll:SetVerticalScroll(0) end
  if self.listScroll:GetVerticalScroll() > maximum then self.listSlider:SetValue(maximum) end
  self:UpdateSummary()
end

function Builder:RefreshFilterButtons()
  if not self.filterButtons then return end
  for key, button in pairs(self.filterButtons) do
    button.selected = key == self.filter
    button:RefreshTheme()
  end
end

function Builder:SetFilter(filter)
  self.filter = filter
  self.listScroll:SetVerticalScroll(0)
  self.listSlider:SetValue(0)
  self:RefreshFilterButtons()
  self:RefreshRows()
end

function Builder:AutoSelect()
  for _, spell in ipairs(self.spells) do
    local override = getSpellOverride(spell, false)
    if override then override.selected = nil end
    spell.selected = not spell.banned and spell.recommended and true or false
    pruneSpellOverride(spell)
  end
  self:RefreshRows()
  Config:SetStatus("Restored the scanner's recommended combat selection without changing spell bans.", "success")
  self:RequestDraftSync()
end

function Builder:ClearSelection()
  for _, spell in ipairs(self.spells) do
    if not spell.banned then
      spell.selected = false
      local override = getSpellOverride(spell, true)
      override.selected = false
    end
  end
  self:RefreshRows()
  Config:SetStatus("Selection cleared. Existing spell bans were preserved.", "dim")
  self:RequestDraftSync()
end

local function nameIsTaken(name, reserved)
  local wanted = string.lower(name)
  if reserved[wanted] then return true end
  if type(GSELibrary) == "table" then
    for _, library in pairs(GSELibrary) do
      if type(library) == "table" then
        for existingName in pairs(library) do
          if string.lower(tostring(existingName)) == wanted then return true end
        end
      end
    end
  end
  for _, queued in ipairs(GSE.OOCQueue or {}) do
    if queued.sequencename and string.lower(tostring(queued.sequencename)) == wanted then return true end
  end
  if type(GetMacroIndexByName) == "function" then
    local ok, index = pcall(GetMacroIndexByName, name)
    if ok and tonumber(index) and tonumber(index) > 0 then return true end
  end
  return false
end

local function uniqueGeneratedName(base, suffix, reserved)
  base = normalizeName(base)
  for attempt = 1, 999 do
    local attemptSuffix = "_" .. suffix .. (attempt == 1 and "" or tostring(attempt))
    local candidate = string.sub(base, 1, math.max(1, 16 - string.len(attemptSuffix))) .. attemptSuffix
    if not nameIsTaken(candidate, reserved) then
      reserved[string.lower(candidate)] = true
      return candidate
    end
  end
  return nil
end

function Builder:BuildSequence(category, spells)
  local specID = GSE.GetCurrentSpecID()
  local version = { StepFunction = "Sequential", KeyPress = {}, KeyRelease = {}, PreMacro = {}, PostMacro = {} }
  local eligibleCount = 0
  for _, spell in ipairs(spells) do if not spell.banned then eligibleCount = eligibleCount + 1 end end
  if eligibleCount > 0 and (category == "rotation" or category == "area") then table.insert(version.KeyPress, "/startattack") end
  local containsChannel = false
  for _, spell in ipairs(spells) do
    if not spell.banned and spell.signals and spell.signals.channel then containsChannel = true break end
  end
  if containsChannel then table.insert(version.KeyPress, "/stopmacro [channeling]") end
  for _, spell in ipairs(spells) do
    if not spell.banned then
      local command
      if category == "healing" or (spell.signals and spell.signals.friendly) then
        command = "/cast [@mouseover,help,nodead][help,nodead][@player] " .. spell.name
      elseif spell.signals and spell.signals.selfOnly then
        command = "/cast [@player] " .. spell.name
      else
        command = "/cast " .. spell.name
      end
      table.insert(version, command)
    end
  end
  local help = {
    "Generated from the live spellbook by GSE Spellbook Builder.",
    "Exact loadout fingerprint: " .. tostring(self.fingerprint or "unknown") .. ".",
    "Draft role: " .. CATEGORY[category].label .. ". Review and test before relying on it in combat.",
    "Suggested input: " .. CATEGORY[category].bind,
    "The addon does not automate input or guarantee an optimal rotation.",
    "KeyRelease is intentionally left empty; add a release action only after testing that spell manually.",
    "",
    "Included because:",
  }
  for _, spell in ipairs(spells) do
    if not spell.banned then
      local detail = "- " .. spell.name .. " [" .. string.upper(spell.confidence or "unknown") .. "]: " .. spell.reason
      if spell.metadataSummary and spell.metadataSummary ~= "" then detail = detail .. " " .. spell.metadataSummary .. "." end
      if spell.dependencies and #spell.dependencies > 0 then detail = detail .. " Dependency hints: " .. table.concat(spell.dependencies, ", ") .. "." end
      table.insert(help, detail)
    end
  end
  if eligibleCount == 0 then
    table.insert(version, "/stopmacro")
    table.insert(help, "- No selected non-banned spells currently belong to this role. This draft is parked to preserve its name and binding.")
  end
  local sequence = {
    Author = GSE.GetCharacterName(), Talents = GSE.GetCurrentTalents(), Default = 1,
    SpecID = specID or GSE.GetCurrentClassID(), Help = table.concat(help, "\n"),
    SuppressAutoMacroStub = true,
    MacroVersions = { [1] = version },
  }
  for _, spell in ipairs(spells) do
    if not spell.banned and spell.icon then sequence.Icon = spell.icon break end
  end
  return sequence
end

function Builder:BuildSelectedGroups()
  local groups = {}
  for _, key in ipairs(CATEGORY_ORDER) do groups[key] = {} end
  for _, spell in ipairs(self.spells) do
    if spell.selected and not spell.banned then table.insert(groups[spell.category], spell) end
  end
  local totalGroups = 0
  for _, key in ipairs(CATEGORY_ORDER) do
    table.sort(groups[key], function(a, b) return a.order < b.order end)
    if #groups[key] > 0 then totalGroups = totalGroups + 1 end
  end
  return groups, totalGroups
end

local function saveGeneratedSequence(classID, name, definition, existingName)
  if type(GSE.GUIUpdateSequenceDefinition) ~= "function" then return false end
  local proxy = { OriginalSequenceName = existingName or "" }
  function proxy:SetStatusText() end
  local ok, result = pcall(GSE.GUIUpdateSequenceDefinition, classID, name, definition, existingName or "", proxy)
  return ok and result and true or false
end

function Builder:SyncGeneratedSet(manualRequest)
  local generated = getGeneratedSet(false)
  if type(generated) ~= "table" or type(generated.roles) ~= "table" or not next(generated.roles) then return false end
  if type(InCombatLockdown) == "function" and InCombatLockdown() then
    Config:SetStatus("Generated drafts will sync after combat.", "warning")
    return false
  end

  local groups = self:BuildSelectedGroups()
  local classID = GSE.GetCurrentClassID()
  local reserved = {}
  for _, record in pairs(generated.roles) do
    if type(record) == "table" and record.name then reserved[string.lower(record.name)] = true end
  end

  local updated, created, protected, missing, stale = 0, 0, 0, 0, 0
  for _, key in ipairs(CATEGORY_ORDER) do
    local spells = groups[key]
    local record = generated.roles[key]
    if #spells > 0 then
      local definition = self:BuildSequence(key, spells)
      if type(record) == "table" and record.name then
        local current = GSELibrary[classID] and GSELibrary[classID][record.name]
        local untouched = current and not current.ManualIntervention and record.signature
          and sequenceSignature(current) == record.signature
        if untouched then
          if saveGeneratedSequence(classID, record.name, definition, record.name) then
            record.signature = sequenceSignature(definition)
            record.fingerprint = self.fingerprint
            record.stale = nil
            record.protected = nil
            record.missing = nil
            updated = updated + 1
          else
            protected = protected + 1
          end
        elseif current then
          record.protected = true
          protected = protected + 1
        else
          record.missing = true
          missing = missing + 1
        end
      else
        local name = uniqueGeneratedName(generated.baseName or self:DefaultBaseName(), CATEGORY[key].suffix, reserved)
        if name and saveGeneratedSequence(classID, name, definition, "") then
          generated.roles[key] = { name = name, signature = sequenceSignature(definition), fingerprint = self.fingerprint }
          created = created + 1
        else
          protected = protected + 1
        end
      end
    elseif type(record) == "table" and record.name then
      local current = GSELibrary[classID] and GSELibrary[classID][record.name]
      local untouched = current and not current.ManualIntervention and record.signature
        and sequenceSignature(current) == record.signature
      if untouched then
        local definition = self:BuildSequence(key, {})
        definition.Icon = current.Icon
        if saveGeneratedSequence(classID, record.name, definition, record.name) then
          record.signature = sequenceSignature(definition)
          record.fingerprint = self.fingerprint
          record.stale = true
          record.protected = nil
          record.missing = nil
          updated = updated + 1
          stale = stale + 1
        else
          protected = protected + 1
        end
      elseif current then
        record.protected = true
        protected = protected + 1
      else
        record.missing = true
        missing = missing + 1
      end
    end
  end

  generated.classID = classID
  generated.fingerprint = self.fingerprint
  self.generatedNames = {}
  for _, key in ipairs(CATEGORY_ORDER) do
    local record = generated.roles[key]
    if type(record) == "table" and record.name then table.insert(self.generatedNames, record.name) end
  end
  if (updated > 0 or created > 0) and GSE.ProcessOOCQueue then pcall(function() GSE:ProcessOOCQueue() end) end
  if Config.SequenceEditor and Config.SequenceEditor.RefreshList then pcall(Config.SequenceEditor.RefreshList, Config.SequenceEditor) end

  local action = manualRequest and "Draft sync" or "Loadout auto-sync"
  local message = action .. ": " .. tostring(updated) .. " updated, " .. tostring(created) .. " added"
  if protected > 0 then message = message .. ", " .. tostring(protected) .. " preserved because edited" end
  if missing > 0 then message = message .. ", " .. tostring(missing) .. " missing/deleted" end
  if stale > 0 then message = message .. ", " .. tostring(stale) .. " empty role parked without deletion" end
  local warning = protected > 0 or missing > 0
  Config:SetStatus(message .. ".", warning and "warning" or "success")
  GSE.Print(message .. ".", "GSE")
  return true
end

function Builder:OpenCreated()
  local firstName = self.generatedNames[1]
  if not firstName then Config:SetStatus("Create a sequence set first.", "warning") return end
  local classID = GSE.GetCurrentClassID()
  if not GSELibrary[classID] or not GSELibrary[classID][firstName] then
    Config:SetStatus("The generated set is queued and will appear after combat or the save timer finishes.", "warning")
    return
  end
  local editor = Config.SequenceEditor
  if not editor then return end
  Config:ShowPage("sequences")
  editor:RefreshList()
  editor:LoadKey(tostring(classID) .. "," .. firstName)
end

function Builder:CreateSet(options)
  options = type(options) == "table" and options or {}
  local automatic = options.automatic and true or false
  if #self.spells == 0 then
    Config:SetStatus("No active spells are available yet. GSE will retry automatically.", "warning")
    return false
  end
  local groups, totalGroups = self:BuildSelectedGroups()
  if totalGroups == 0 then
    Config:SetStatus("No selected non-banned spells are available for generated sequences.", "warning")
    return false
  end

  local requestedBase = options.baseName
  if trim(requestedBase) == "" and self.nameInput then requestedBase = self.nameInput:GetText() end
  local base = normalizeName(trim(requestedBase) ~= "" and requestedBase or self:DefaultBaseName())
  if self.nameInput then self.nameInput:SetText(base) end
  local existingSet = getGeneratedSet(true)
  if type(existingSet) ~= "table" then
    Config:SetStatus("Generated sequence tracking is not ready yet. GSE will retry automatically.", "warning")
    return false
  end
  if type(existingSet) == "table" and existingSet.baseName == base and type(existingSet.roles) == "table" and next(existingSet.roles) then
    return self:SyncGeneratedSet(not automatic)
  end

  local classID, reserved, created, failed = GSE.GetCurrentClassID(), {}, {}, 0
  local generatedRoles = {}
  for _, key in ipairs(CATEGORY_ORDER) do
    if #groups[key] > 0 then
      local name = uniqueGeneratedName(base, CATEGORY[key].suffix, reserved)
      if name then
        local definition = self:BuildSequence(key, groups[key])
        local ok = saveGeneratedSequence(classID, name, definition, "")
        if ok then
          table.insert(created, name)
          generatedRoles[key] = { name = name, signature = sequenceSignature(definition), fingerprint = self.fingerprint }
        else
          failed = failed + 1
        end
      else
        failed = failed + 1
      end
    end
  end
  self.generatedNames = created
  if #created == 0 then
    Config:SetStatus("No sequences could be created. See chat for save errors.", "danger")
    return false
  end

  local generated = existingSet
  generated.version = 1
  generated.baseName = base
  generated.classID = classID
  generated.fingerprint = self.fingerprint
  generated.roles = generatedRoles
  generated.automatic = automatic or nil

  if not InCombatLockdown() and GSE.ProcessOOCQueue then pcall(function() GSE:ProcessOOCQueue() end) end
  if Config.SequenceEditor then Config.SequenceEditor:RefreshList() end
  local message = "Created " .. tostring(#created) .. " spellbook sequence" .. (#created == 1 and "" or "s") .. ": " .. table.concat(created, ", ")
  if failed > 0 then message = message .. ". " .. tostring(failed) .. " group(s) could not be saved." end
  Config:SetStatus(message, failed > 0 and "warning" or "success")
  GSE.Print(message, "GSE")
  if not automatic and not InCombatLockdown() then self:OpenCreated() end
  return true
end

function Builder:BuildPage(page)
  self.page = page
  self:EnsureEventFrame()
  local heading = makeText(page, "GameFontNormal", 13, "gold")
  heading:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -6)
  heading:SetText("AUTO BUILDER")
  local hint = makeText(page, "GameFontNormalSmall", 9, "dim")
  hint:SetPoint("LEFT", heading, "RIGHT", 8, 0)
  hint:SetText("SCAN -> REVIEW -> CREATE; AUTO BUILD IS OPTIONAL")

  local nameLabel = makeText(page, "GameFontNormalSmall", 9, "dim")
  nameLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -31)
  nameLabel:SetText("BASE NAME")
  local nameInput = makeInput(page)
  nameInput:SetPoint("TOPLEFT", page, "TOPLEFT", 68, -26)
  nameInput:SetWidth(164)
  nameInput:SetText(self:DefaultBaseName())
  nameInput.OnValueChanged = function(_, value) Builder.baseName = value end
  self.nameInput = nameInput

  local scan = Config:MakeButton(page, "SCAN", function() Builder:Scan() end)
  scan:SetSize(50, 20)
  scan:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -26)
  local auto = Config:MakeButton(page, "AUTO PICK", function() Builder:AutoSelect() end)
  auto:SetSize(67, 20)
  auto:SetPoint("RIGHT", scan, "LEFT", -4, 0)
  local clear = Config:MakeButton(page, "CLEAR", function() Builder:ClearSelection() end)
  clear:SetSize(50, 20)
  clear:SetPoint("RIGHT", auto, "LEFT", -4, 0)
  local sync
  sync = Config:MakeButton(page, "AUTO ON", function()
    GSEOptions.spellbookAutoSync = not autoSyncEnabled()
    sync.selected = autoSyncEnabled()
    sync.label:SetText(sync.selected and "AUTO ON" or "AUTO OFF")
    sync:RefreshTheme()
    Config:SetStatus(sync.selected and "Auto build is enabled for future out-of-combat loadout changes. Review and CREATE now to make the first templates." or "Auto build is disabled. Scans and manual CREATE remain available.", sync.selected and "success" or "warning")
  end)
  sync:SetSize(66, 20)
  sync:SetPoint("RIGHT", clear, "LEFT", -4, 0)
  sync.selected = autoSyncEnabled()
  sync.label:SetText(sync.selected and "AUTO ON" or "AUTO OFF")
  self.syncButton = sync

  self.filterButtons = {}
  local x = 5
  local filters = {
    { "all", "ALL", 36 }, { "rotation", "MAIN", 44 }, { "area", "AOE", 38 }, { "cooldown", "BURST", 50 },
    { "defense", "DEFENSE", 60 }, { "healing", "HEAL", 42 }, { "utility", "UTILITY", 56 },
    { "banned", "BANNED", 54 },
  }
  for _, entry in ipairs(filters) do
    local key = entry[1]
    local button = Config:MakeButton(page, entry[2], function() Builder:SetFilter(key) end)
    button:SetSize(entry[3], 20)
    button:SetPoint("TOPLEFT", page, "TOPLEFT", x, -51)
    x = x + entry[3] + 3
    self.filterButtons[key] = button
  end
  local panel = CreateFrame("Frame", nil, page)
  panel:SetPoint("TOPLEFT", page, "TOPLEFT", 5, -76)
  panel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -76)
  panel:SetHeight(244)
  Config:RegisterFrame(panel, "surface", "muted")
  local column = makeText(panel, "GameFontNormalSmall", 8, "dim")
  column:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -5)
  column:SetText("STATE   SPELL / WHY IT WAS CLASSIFIED                    BAN   ROLE   ORDER")

  local scroll = CreateFrame("ScrollFrame", nil, panel)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -20)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 3)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(_, delta) Builder:ScrollList(delta) end)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(530)
  child:SetHeight(1)
  scroll:SetScrollChild(child)
  scroll:SetScript("OnSizeChanged", function(_, width)
    child:SetWidth(math.max(100, width))
    Builder:RefreshRows()
  end)
  self.listScroll, self.listChild = scroll, child

  local slider = CreateFrame("Slider", nil, panel)
  slider:SetOrientation("VERTICAL")
  slider:SetWidth(9)
  slider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -23)
  slider:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 4)
  Config:RegisterFrame(slider, "inset", "muted")
  slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
  local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
  if thumb then thumb:SetSize(9, 18) Config:RegisterTexture(thumb, "gold") end
  slider:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
  self.listSlider = slider

  local summary = makeText(page, "GameFontNormalSmall", 9, "text")
  summary:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 2, -7)
  summary:SetPoint("RIGHT", page, "RIGHT", -5, 0)
  summary:SetJustifyH("LEFT")
  self.summaryText = summary

  local recommendation = CreateFrame("Frame", nil, page)
  recommendation:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -22)
  recommendation:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, -22)
  recommendation:SetHeight(34)
  Config:RegisterFrame(recommendation, "inset", "muted")
  local recommendationText = makeText(recommendation, "GameFontNormalSmall", 8, "dim")
  recommendationText:SetPoint("TOPLEFT", recommendation, "TOPLEFT", 7, -5)
  recommendationText:SetPoint("BOTTOMRIGHT", recommendation, "BOTTOMRIGHT", -7, 4)
  recommendationText:SetJustifyH("LEFT")
  recommendationText:SetJustifyV("TOP")
  recommendationText:SetText("BIND PLAN  MAIN: wheel down @ ~100 ms | AOE: Shift+wheel | BURST: wheel up | DEF: Mouse4 | HEAL: Mouse5. CREATE writes templates; AUTO only updates untouched drafts after loadout changes.")

  local create = Config:MakeButton(page, "CREATE 0 SEQUENCES", function() Builder:CreateSet() end)
  create:SetSize(138, 22)
  create:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -5, 4)
  self.createButton = create
  local open = Config:MakeButton(page, "OPEN CREATED", function() Builder:OpenCreated() end)
  open:SetSize(94, 22)
  open:SetPoint("RIGHT", create, "LEFT", -4, 0)

  page.OnSelected = function()
    sync.selected = autoSyncEnabled()
    sync.label:SetText(sync.selected and "AUTO ON" or "AUTO OFF")
    sync:RefreshTheme()
    local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown()
    if not Builder.scanned then
      Builder:Scan()
    elseif Builder.dirty and not inCombat then
      Builder:Scan(Builder.dirtyEvent)
    else
      Builder:RefreshRows()
      if Builder.dirty and inCombat then Config:SetStatus("Loadout changed in combat. Automatic rescan is queued for combat end.", "warning") end
    end
  end
  self:RefreshFilterButtons()
  self:RefreshRows()
  return 398
end

Config.PageBuilders.spellbook = function(_, page) return Builder:BuildPage(page) end
table.insert(Config.Navigation, 2, { "spellbook", "Auto Builder" })
Builder:EnsureEventFrame()
