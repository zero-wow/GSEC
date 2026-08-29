local GSE = GSE
local L = GSE.L

local TITLE_R, TITLE_G, TITLE_B = 1, 0.82, 0
local TEXT_R, TEXT_G, TEXT_B = 1, 1, 1
local VALUE_R, VALUE_G, VALUE_B = 0.45, 0.85, 1
local MUTED_R, MUTED_G, MUTED_B = 0.65, 0.65, 0.65

local function addLine(tooltip, text, r, g, b)
  if text ~= nil and text ~= "" then
    tooltip:AddLine(tostring(text), r or TEXT_R, g or TEXT_G, b or TEXT_B)
  end
end

local function addDoubleLine(tooltip, left, right, leftR, leftG, leftB, rightR, rightG, rightB)
  tooltip:AddDoubleLine(
    tostring(left or ""),
    tostring(right or ""),
    leftR or TEXT_R,
    leftG or TEXT_G,
    leftB or TEXT_B,
    rightR or VALUE_R,
    rightG or VALUE_G,
    rightB or VALUE_B
  )
end

local function addPartyUsers(tooltip)
  if not GSEOptions or not GSEOptions.showGSEUsers then
    return
  end

  local partyUsers = GSE.UnsavedOptions and GSE.UnsavedOptions["PartyUsers"]
  if type(partyUsers) ~= "table" or next(partyUsers) == nil then
    return
  end

  local users = {}
  for name, version in pairs(partyUsers) do
    users[#users + 1] = {
      name = tostring(name),
      version = tostring(version or "")
    }
  end
  table.sort(users, function(left, right)
    return left.name < right.name
  end)

  addLine(tooltip, "GSEC Users", TITLE_R, TITLE_G, TITLE_B)
  for _, user in ipairs(users) do
    addDoubleLine(tooltip, user.name, user.version)
  end
end

local function getQueueTarget(event)
  if type(event) ~= "table" then
    return ""
  end
  return event.name or event.sequencename or ""
end

local function addOOCQueue(tooltip)
  if not GSEOptions or not GSEOptions.showGSEoocqueue then
    return
  end

  local status = GSE.CheckOOCQueueStatus and GSE.CheckOOCQueueStatus() or ""
  addLine(tooltip, string.format(L["The GSE Out of Combat queue is %s"], status), TITLE_R, TITLE_G, TITLE_B)

  local queue = type(GSE.OOCQueue) == "table" and GSE.OOCQueue or {}
  local queueSize = #queue
  if queueSize == 0 then
    addLine(tooltip, L["There are no events in out of combat queue"], MUTED_R, MUTED_G, MUTED_B)
    return
  end

  addLine(
    tooltip,
    string.format(L["There are %i events in out of combat queue"], queueSize),
    MUTED_R,
    MUTED_G,
    MUTED_B
  )
  for _, event in ipairs(queue) do
    local action = type(event) == "table" and event.action or nil
    addDoubleLine(tooltip, action and L[action] or "", getQueueTarget(event))
  end
end

local function showTooltip(tooltip)
  if not tooltip then
    return
  end

  tooltip:ClearLines()
  addDoubleLine(
    tooltip,
    "GSEC",
    GSE.formatModVersion(GSE.VersionString),
    TITLE_R,
    TITLE_G,
    TITLE_B,
    MUTED_R,
    MUTED_G,
    MUTED_B
  )
  addLine(tooltip, "GSEC: Left Click to open the Control Center")
  addLine(tooltip, "GSEC: Middle Click to open the Transmission Interface")
  addLine(tooltip, "GSEC: Right Click to open the Sequence Debugger")
  addPartyUsers(tooltip)
  addOOCQueue(tooltip)
end

local function handleClick(_, button)
  GameTooltip:Hide()
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
  OnTooltipShow = showTooltip,
  OnClick = handleClick
})
