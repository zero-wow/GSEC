local GSE = GSE

local TITLE_R, TITLE_G, TITLE_B = 0.88, 0.61, 0.24
local TEXT_R, TEXT_G, TEXT_B = 0.91, 0.91, 0.86
local MUTED_R, MUTED_G, MUTED_B = 0.56, 0.63, 0.71

local function isQTip(tooltip)
  return tooltip and type(tooltip.Clear) == "function" and type(tooltip.SetCellMarginH) == "function"
end

local function resetTooltip(tooltip)
  if isQTip(tooltip) then
    tooltip:Clear()
    tooltip:SetColumnLayout(1, "LEFT")
    tooltip:SetCellMarginH(4)
    tooltip:SetCellMarginV(1)
  else
    tooltip:ClearLines()
  end
end

local function addLine(tooltip, text, r, g, b, header)
  if not text or text == "" then return end
  if isQTip(tooltip) then
    if header then tooltip:AddHeader(tostring(text)) else tooltip:AddLine(tostring(text)) end
  else
    tooltip:AddLine(tostring(text), r or TEXT_R, g or TEXT_G, b or TEXT_B)
  end
end

local function collectPartyUsers()
  if not GSEOptions or not GSEOptions.showGSEUsers then return nil end
  local partyUsers = GSE.UnsavedOptions and GSE.UnsavedOptions.PartyUsers
  if type(partyUsers) ~= "table" then return nil end
  local users = {}
  for name in pairs(partyUsers) do table.insert(users, tostring(name)) end
  table.sort(users)
  if #users == 0 then return nil end
  local shown = {}
  for index = 1, math.min(3, #users) do table.insert(shown, users[index]) end
  local suffix = #users > 3 and " +" .. tostring(#users - 3) or ""
  return "Users: " .. table.concat(shown, ", ") .. suffix
end

local function queueSummary()
  if not GSEOptions or not GSEOptions.showGSEoocqueue then return nil end
  local queue = type(GSE.OOCQueue) == "table" and GSE.OOCQueue or {}
  local count = #queue
  if count == 0 then return nil end
  local first = queue[1]
  local action = type(first) == "table" and tostring(first.action or "work") or "work"
  local target = type(first) == "table" and tostring(first.name or first.sequencename or "") or ""
  local detail = target ~= "" and (" - " .. action .. ": " .. target) or (" - " .. action)
  return "Queue: " .. tostring(count) .. " pending" .. detail
end

local function showTooltip(tooltip)
  if not tooltip then return end
  resetTooltip(tooltip)
  addLine(tooltip, "GSEC " .. tostring(GSE.formatModVersion(GSE.VersionString)), TITLE_R, TITLE_G, TITLE_B, true)
  addLine(tooltip, "Left Click: Control Center")
  addLine(tooltip, "Middle Click: Transmission")
  addLine(tooltip, "Right Click: Sequence Debugger")
  addLine(tooltip, queueSummary(), MUTED_R, MUTED_G, MUTED_B)
  addLine(tooltip, collectPartyUsers(), MUTED_R, MUTED_G, MUTED_B)
end

local function handleClick(_, button)
  if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
  if button == "LeftButton" then
    if GSE.OpenControlPanel then GSE.OpenControlPanel() else GSE.GUIShowViewer() end
  elseif button == "MiddleButton" then
    GSE.GUIShowTransmissionGui()
  elseif button == "RightButton" then
    GSE.GUIShowDebugWindow()
  end
end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
ldb:NewDataObject("GSEC", {
  type = "data source",
  text = "GSEC",
  icon = "Interface\\Icons\\Ability_CriticalStrike",
  OnTooltipShow = showTooltip,
  OnClick = handleClick,
})
