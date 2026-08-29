local GSE = GSE
local L = GSE.L

local Statics = GSE.Static
local GetSpecialization=GetSpecialization or GSE.GetCurrentSpecID
if not GetSpecialization then
	GetSpecialization=GSE.GetCurrentSpecID
end

local function normaliseLookupValue(value)
  if value == nil then
    return ""
  end
  value = string.upper(tostring(value))
  value = string.gsub(value, "[%s%p_]+", "")
  return value
end

local function resolveClassToken(value)
  local normalised = normaliseLookupValue(value)
  if GSE.isEmpty(normalised) then
    return nil
  end
  if Statics.ClassAliasMap and Statics.ClassAliasMap[normalised] then
    return Statics.ClassAliasMap[normalised]
  end
  return normalised
end

function GSE.GetClassDisplayName(classid)
  classid = tonumber(classid)
  if classid and Statics.wotlkClassIDList[classid] then
    return Statics.wotlkClassIDList[classid]
  end
  return Statics.wotlkClassIDList[0]
end

function GSE.ResolveClassID(classidOrName)
  local classid = tonumber(classidOrName)
  if classid and Statics.wotlkClassIDList[classid] then
    return classid
  end

  local token = resolveClassToken(classidOrName)
  if GSE.isEmpty(token) then
    return nil
  end

  if Statics.ClassIDByToken and Statics.ClassIDByToken[token] then
    return Statics.ClassIDByToken[token]
  end

  for id, displayName in pairs(Statics.wotlkClassIDList) do
    if resolveClassToken(displayName) == token then
      return id
    end
  end

  return nil
end

function GSE.ResolveSequenceClassID(classid, sequence)
  local resolved = GSE.ResolveClassID(classid)
  if resolved and resolved ~= 0 then
    return resolved
  end

  if type(sequence) == "table" then
    resolved = GSE.ResolveClassID(sequence.ClassID or sequence.classid or sequence.ClassName or sequence.classname)
    if resolved and resolved ~= 0 then
      return resolved
    end

    if not GSE.isEmpty(sequence.SpecID) then
      resolved = tonumber(GSE.GetClassIDforSpec(sequence.SpecID))
      if resolved and resolved ~= 0 then
        return resolved
      end
    end
  end

  local classDisplayName, classToken = UnitClass("player")
  resolved = GSE.ResolveClassID(classToken) or GSE.ResolveClassID(classDisplayName)
  return resolved or 0
end
--- Return the characters current spec id
function GSE.GetSpecialization()
return GSE.GetCurrentSpecID()
end
function GSE.GetCurrentSpecID()
--local  name, iconTexture, pointsSpent, background, previewPointsSpent = GetTalentTabInfo(tabIndex[, inspect[, isPet]][, talentGroup])
-- if event == "INSPECT_READY" then
  -- local spec = ""
  -- _, name = GetTalentTabInfo(GetPrimaryTalentTree(GetActiveTalentGroup()))
  -- spec = name
  -- return spec
-- else
  -- NotifyInspect(unit)
-- end
 -- local currentSpec = GetSpecialization() --local index = GetActiveTalentGroup(isInspect, isPet);
  --return currentSpec and select(1, GetSpecializationInfo(currentSpec)) or 0 ---specid Statics.wotlkSpecIDList 

--local name, icon, pointsSpent, background, previewPointsSpent = GetTalentTabInfo(tab,isInspect,isPet,activeSpec);


  local activeSpec = GetActiveTalentGroup()
local maxpointspents=0
local  primarytree=0
----print(GetTalentTabInfo(activeTalentGroup))
for tab = 1, GetNumTalentTabs() do
   local tabname, tabicon, nopointsSpent, tabbackground, tabpreviewPointsSpent = GetTalentTabInfo(tab,false,false,activeSpec)
   if (nopointsSpent>maxpointspents) then
      maxpointspents=nopointsSpent
      primarytree=tab
   end
   if (primarytree==0) then
      primarytree=1
   end
end

	local name1,icon=GetTalentTabInfo(primarytree,false,false,activeSpec);
  local currentClassID = GSE.GetCurrentClassID()
  local talentName = name1 or ""
  local normalisedTalentName = normaliseLookupValue(talentName)
  local specid

  for k,v in pairs(Statics.wotlkSpecIDList) do
    if k > 32 then
      local searchStr = normaliseLookupValue(v)
      local specClassID = tonumber(GSE.GetClassIDforSpec(k))
      if specClassID == currentClassID and not GSE.isEmpty(normalisedTalentName) and string.find(searchStr, normalisedTalentName, 1, true) then
        specid = k
        break
      end
    end
  end

  if GSE.isEmpty(specid) then
    specid = currentClassID
  end

  if GSE.isEmpty(talentName) or specid == currentClassID then
    talentName = GSE.GetClassDisplayName(currentClassID)
  end

  return specid, talentName, icon
end

--- Return the characters class id
function GSE.GetCurrentClassID()
  local classDisplayName, classToken = UnitClass("player")
  return GSE.ResolveClassID(classToken) or GSE.ResolveClassID(classDisplayName) or 0
end

--- Return the characters class id
function GSE.GetCurrentClassNormalisedName()
  local classDisplayName, classToken = UnitClass("player")
  return resolveClassToken(classToken) or resolveClassToken(classDisplayName) or ""
end

function GSE.GetClassIDforSpec(specid)
  local classid = GSE.ResolveClassID(specid)
  if classid then
    return classid
  end

  specid = tonumber(specid)
  if GSE.isEmpty(specid) then
    return nil
  end

  local value = Statics.wotlkSpecIDList[specid]
  if not value then
    return nil
  end

  local idx = string.find(value, " %- ")
  if idx ~= nil then
    local className = string.sub(value, idx + 3)
    return GSE.ResolveClassID(className)
  end

  return GSE.ResolveClassID(value)
end

function GSE.GetClassIcon(classid)
  classid = tonumber(classid)
  return (classid and Statics.ClassIconByID[classid]) or Statics.QuestionMark
end

--- Check if the specID provided matches the plauers current class.
function GSE.isSpecIDForCurrentClass(specID)
  local currentClassID = GSE.GetCurrentClassID()
  local specClassID = tonumber(GSE.GetClassIDforSpec(specID))
  return (specClassID and specClassID == currentClassID) or tonumber(specID) == currentClassID or false
end


function GSE.GetSpecNames()
  local keyset={}
  for k,v in pairs(Statics.wotlkSpecIDList) do
    keyset[v] = v
  end
  return keyset
end

--- Returns the Character Name in the form Player@server
function GSE.GetCharacterName()
  return  GetUnitName("player", true) .. '@' .. GetRealmName()
end

--- Returns the current Talent Selections as a string
function GSE.GetCurrentTalents()
  local talents = ""
    for talentTier = 1, 7 do
  --for talentTier = 1, MAX_TALENT_TIERS do
    --local available, selected = GetTalentTierInfo(talentTier, 1)
   -- talents = talents .. (available and selected or "?" .. ",")
   talents = talents .. ("?" .. ",")
  end
  return talents
end


--- Experimental attempt to load a WeakAuras string.
function GSE.LoadWeakauras(str)
  local WeakAuras = WeakAuras

  if WeakAuras then
    WeakAuras.ImportString(str)
  end
end
