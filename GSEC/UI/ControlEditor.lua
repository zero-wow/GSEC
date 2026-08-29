local GSE = GSE
local Config = GSE.ControlPanel
if not Config then return end

local Editor = {
  activeTab = "details",
  activeSection = "core",
  classID = GSE.GetCurrentClassID(),
  listRows = {},
  listEntries = {},
  versionButtons = {},
  dirty = false,
}
Config.SequenceEditor = Editor

local function makeText(parent, font, size, color)
  return Config.MakeText(parent, font, size, color)
end

local function trim(value)
  return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function normalizeName(value)
  return trim(value):gsub(" ", "_"):gsub(",", "_")
end

local function sequenceNameExists(name)
  if type(GSELibrary) ~= "table" then return false end
  for _, library in pairs(GSELibrary) do
    if type(library) == "table" and library[name] ~= nil then return true end
  end
  return false
end

local function uniqueSequenceName(stem)
  stem = normalizeName(stem)
  if stem == "" then stem = "SEQUENCE" end
  stem = string.sub(stem, 1, 16)
  if not sequenceNameExists(stem) then return stem end
  for index = 2, 9999 do
    local suffix = "_" .. index
    local candidate = string.sub(stem, 1, math.max(1, 16 - string.len(suffix))) .. suffix
    if not sequenceNameExists(candidate) then return candidate end
  end
  return "NEW_SEQUENCE"
end

local function nextSequenceName()
  local _, specName = GSE.GetCurrentSpecID()
  local stem = string.upper(tostring(specName or "SEQUENCE")):gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
  if stem == "" then stem = "SEQUENCE" end
  return uniqueSequenceName("NEW_" .. stem)
end

local function listText(value)
  if type(value) ~= "table" then return "" end
  return table.concat(value, "\n")
end

local function currentBuilderCharacterKey()
  if type(GSE.GetCharacterName) == "function" then
    local ok, value = pcall(GSE.GetCharacterName)
    if ok and value and value ~= "" then return tostring(value) end
  end
  local name = type(UnitName) == "function" and UnitName("player") or "Unknown"
  local realm = type(GetRealmName) == "function" and GetRealmName() or "Unknown"
  return tostring(name or "Unknown") .. "@" .. tostring(realm or "Unknown")
end

local function generatedTemplateKeys()
  local root = type(GSEOptions.SpellbookBuilderOverrides) == "table" and GSEOptions.SpellbookBuilderOverrides or nil
  local sets = root and root.generatedSets
  local all, current = {}, {}
  if type(sets) ~= "table" then return all, current end
  local characterKey = currentBuilderCharacterKey()
  for owner, generated in pairs(sets) do
    if type(generated) == "table" and type(generated.roles) == "table" then
      local classID = tonumber(generated.classID) or (owner == characterKey and GSE.GetCurrentClassID())
      if classID then
        for _, record in pairs(generated.roles) do
          if type(record) == "table" and type(record.name) == "string" and record.name ~= "" then
            local key = tostring(classID) .. "," .. record.name
            all[key] = true
            if owner == characterKey then current[key] = true end
          end
        end
      end
    end
  end
  return all, current
end

local delayedHelp = { delay = 2 }

local function clearDelayedHelp(owner)
  if owner and delayedHelp.pendingOwner ~= owner and delayedHelp.shownOwner ~= owner then return end
  delayedHelp.target = nil
  delayedHelp.pendingOwner = nil
  delayedHelp.elapsed = 0
  if delayedHelp.timer then delayedHelp.timer:Hide() end
  if delayedHelp.shownOwner then
    delayedHelp.shownOwner = nil
    GameTooltip:Hide()
  end
end

local function getDelayedHelpTimer()
  if delayedHelp.timer then return delayedHelp.timer end
  local timer = CreateFrame("Frame", nil, UIParent)
  timer:Hide()
  timer:SetScript("OnUpdate", function(self, elapsed)
    local target = delayedHelp.target
    if not target or (target.IsVisible and not target:IsVisible()) then
      clearDelayedHelp()
      return
    end
    delayedHelp.elapsed = delayedHelp.elapsed + (tonumber(elapsed) or 0)
    if delayedHelp.elapsed < delayedHelp.delay then return end
    self:Hide()
    delayedHelp.target = nil
    delayedHelp.shownOwner = delayedHelp.pendingOwner
    delayedHelp.pendingOwner = nil
    Config:ShowHelp(delayedHelp.shownOwner, delayedHelp.title, delayedHelp.detail)
  end)
  delayedHelp.timer = timer
  return timer
end

local function appendScript(frame, scriptName, callback)
  if not frame or not frame.SetScript then return end
  if frame.HookScript then
    frame:HookScript(scriptName, callback)
    return
  end
  local previous = frame.GetScript and frame:GetScript(scriptName)
  frame:SetScript(scriptName, function(self, ...)
    if previous then previous(self, ...) end
    callback(self, ...)
  end)
end

local function attachDelayedHelp(frame, owner, title, detail)
  if not frame then return end
  if frame.EnableMouse then frame:EnableMouse(true) end
  owner = owner or frame
  appendScript(frame, "OnEnter", function(self)
    clearDelayedHelp()
    delayedHelp.target = self
    delayedHelp.pendingOwner = owner
    delayedHelp.title = title
    delayedHelp.detail = detail
    delayedHelp.elapsed = 0
    getDelayedHelpTimer():Show()
  end)
  appendScript(frame, "OnLeave", function()
    clearDelayedHelp(owner)
  end)
end

local function attachInputDelayedHelp(input, title, detail)
  if not input then return end
  attachDelayedHelp(input, input, title, detail)
  attachDelayedHelp(input.scroll, input, title, detail)
  attachDelayedHelp(input.editbox, input, title, detail)
end

local function makeInput(parent, multiline)
  local frame = CreateFrame("Frame", nil, parent)
  Config:RegisterFrame(frame, "inset", "muted")
  frame:SetHeight(multiline and 76 or 20)

  local edit
  local scroll
  if multiline then
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -3)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 3)
    edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(100)
    edit:SetHeight(70)
    scroll:SetScrollChild(edit)
    local function updateEditHeight()
      local width = math.max(40, scroll:GetWidth())
      local charactersPerLine = math.max(10, math.floor(width / 7))
      local lineCount = 0
      local value = edit:GetText() or ""
      for line in string.gmatch(value .. "\n", "([^\n]*)\n") do
        lineCount = lineCount + math.max(1, math.ceil(string.len(line) / charactersPerLine))
      end
      edit:SetHeight(math.max(scroll:GetHeight(), (lineCount * 14) + 8))
    end
    frame.UpdateEditHeight = updateEditHeight
    local function scrollText(_, delta)
      local shiftDown = type(IsShiftKeyDown) == "function" and IsShiftKeyDown()
      if frame.useBodyScroll and not shiftDown and Editor.bodyScroll then
        Editor:ScrollBody(delta)
        return
      end
      local maximum = math.max(0, edit:GetHeight() - scroll:GetHeight())
      scroll:SetVerticalScroll(math.max(0, math.min(maximum, scroll:GetVerticalScroll() - (delta * 24))))
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", scrollText)
    edit:EnableMouseWheel(true)
    edit:SetScript("OnMouseWheel", scrollText)
    scroll:SetScript("OnMouseUp", function()
      edit:SetFocus()
      edit:SetCursorPosition(edit:GetNumLetters())
    end)
    scroll:SetScript("OnSizeChanged", function(_, width, height)
      edit:SetWidth(math.max(20, width))
      updateEditHeight()
    end)
  else
    edit = CreateFrame("EditBox", nil, frame)
    edit:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -2)
    edit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 2)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:EnableMouseWheel(true)
    edit:SetScript("OnMouseWheel", function(_, delta)
      if frame.useBodyScroll and Editor.bodyScroll then Editor:ScrollBody(delta) end
    end)
  end

  frame.editbox = edit
  frame.scroll = scroll
  frame.suppress = false
  if edit.SetNumeric then edit:SetNumeric(false) end
  edit:SetTextColor(0.91, 0.91, 0.86, 1)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  if not multiline then
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  end
  edit:SetScript("OnEditFocusGained", function()
    frame.focused = true
    frame:Refresh()
  end)
  edit:SetScript("OnEditFocusLost", function()
    frame.focused = false
    frame:Refresh()
  end)
  edit:SetScript("OnTextChanged", function(self, userInput)
    if multiline and frame.UpdateEditHeight then frame.UpdateEditHeight() end
    if userInput and not frame.suppress and frame.OnValueChanged then
      frame:OnValueChanged(self:GetText())
    end
  end)
  function frame:SetText(value)
    self.suppress = true
    self.editbox:SetText(tostring(value or ""))
    self.editbox:SetCursorPosition(0)
    self.suppress = false
    if self.scroll then self.scroll:SetVerticalScroll(0) end
  end
  function frame:GetText()
    return self.editbox:GetText()
  end
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

local function addField(parent, labelText, x, y, width, callback)
  local label = makeText(parent, "GameFontNormalSmall", 10, "dim")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y - 4)
  label:SetWidth(58)
  label:SetJustifyH("RIGHT")
  label:SetText(labelText)
  local input = makeInput(parent, false)
  input:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 63, -y)
  input:SetWidth(width - 63)
  input.useBodyScroll = true
  input.OnValueChanged = function(_, value)
    callback(value)
    Editor:MarkDirty()
  end
  return input
end

local function makeTriState(parent, labelText, x, y, width, getter, setter)
  local button
  button = Config:MakeButton(parent, labelText, function(_, mouseButton)
    local versionIndex = tonumber(Editor.activeTab)
    if not Editor.sequence or not versionIndex or not Editor.sequence.MacroVersions or not Editor.sequence.MacroVersions[versionIndex] then return end
    local value = getter()
    if mouseButton == "RightButton" then
      value = nil
    elseif value == nil then
      value = true
    elseif value == true then
      value = false
    else
      value = nil
    end
    setter(value)
    Editor:MarkDirty()
    button:RefreshState()
  end)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetSize(width, 22)
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  function button:RefreshState()
    local versionIndex = tonumber(Editor.activeTab)
    if not Editor.sequence or not versionIndex or not Editor.sequence.MacroVersions or not Editor.sequence.MacroVersions[versionIndex] then
      self.label:SetText(labelText .. "  DEFAULT")
      self.selected = false
      self.kind = "normal"
      self:RefreshTheme()
      return
    end
    local value = getter()
    local suffix = value == nil and "DEFAULT" or (value and "ON" or "OFF")
    self.label:SetText(labelText .. "  " .. suffix)
    self.selected = value == true
    self.kind = value == false and "danger" or "normal"
    self:RefreshTheme()
  end
  button:RefreshState()
  return button
end

function Editor:SetStatusText(message)
  Config:SetStatus(message, "dim")
end

function Editor:MarkDirty()
  self.dirty = true
  Config:SetStatus("Unsaved sequence changes", "warning")
end

function Editor:CreateEmptySequence()
  return {
    Author = GSE.GetCharacterName(),
    Talents = GSE.GetCurrentTalents(),
    Default = 1,
    SpecID = GSE.GetCurrentSpecID(),
    MacroVersions = {
      [1] = {
        PreMacro = {}, PostMacro = {}, KeyPress = {}, KeyRelease = {},
        StepFunction = "Sequential", [1] = "/say Hello",
      },
    },
  }
end

function Editor:PrepareSequence(sequence)
  sequence.MacroVersions = sequence.MacroVersions or {}
  if not sequence.MacroVersions[1] then sequence.MacroVersions[1] = self:CreateEmptySequence().MacroVersions[1] end
  for index, version in ipairs(sequence.MacroVersions) do
    sequence.MacroVersions[index] = GSE.TranslateSequence(version, "From Editor")
    version = sequence.MacroVersions[index]
    version.KeyPress = version.KeyPress or {}
    version.KeyRelease = version.KeyRelease or {}
    version.PreMacro = version.PreMacro or {}
    version.PostMacro = version.PostMacro or {}
    version.StepFunction = version.StepFunction or "Sequential"
  end
  sequence.Default = tonumber(sequence.Default) or 1
  return sequence
end

function Editor:LoadKey(key)
  local elements = GSE.split(key, ",")
  local classID = tonumber(elements[1])
  local name = elements[2]
  if not classID or not name or not GSELibrary[classID] or not GSELibrary[classID][name] then return end
  local ok, sequence = pcall(function()
    local clone = GSE.CloneSequence(GSELibrary[classID][name], true)
    if type(clone) ~= "table" then error("could not clone " .. tostring(name)) end
    return self:PrepareSequence(clone)
  end)
  if not ok then
    Config:SetStatus("Could not load " .. tostring(name) .. ". See chat for the exact error.", "danger")
    GSE.Print("/gsec load error for " .. tostring(name) .. ": " .. tostring(sequence), "GSE")
    return false
  end
  self.classID = classID
  self.originalClassID = classID
  self.originalName = name
  self.name = name
  self.selectedKey = key
  self.sequence = sequence
  self.activeTab = "details"
  self.activeSection = "core"
  self.dirty = false
  self:RefreshEditor()
  self:RefreshList()
  Config:SetStatus("Editing " .. name, "dim")
  return true
end

function Editor:RequestLoad(key)
  if self.dirty and self.selectedKey ~= key then
    self.pendingAction = function() self:LoadKey(key) end
    StaticPopup_Show("GSE_CONTROL_DISCARD")
    return
  end
  self:LoadKey(key)
end

function Editor:NewSequence(duplicate)
  local function create()
    local ok, sequence = pcall(function()
      local value = duplicate and self.sequence and GSE.CloneSequence(self.sequence, true) or self:CreateEmptySequence()
      if type(value) ~= "table" then error("could not create an empty sequence") end
      return self:PrepareSequence(value)
    end)
    if not ok then
      Config:SetStatus("Could not create a new sequence. See chat for the exact error.", "danger")
      GSE.Print("/gsec new-sequence error: " .. tostring(sequence), "GSE")
      return
    end
    local baseName = duplicate and uniqueSequenceName((self.name or "SEQUENCE") .. "_COPY") or nextSequenceName()
    self.classID = GSE.GetCurrentClassID()
    self.originalClassID = self.classID
    self.originalName = ""
    self.name = normalizeName(baseName)
    self.selectedKey = nil
    self.sequence = sequence
    self.activeTab = 1
    self.activeSection = "core"
    self.dirty = true
    self:RefreshEditor()
    Config:SetStatus(duplicate and "Unsaved duplicate" or "New unsaved sequence", "warning")
    if self.nameInput then
      self.nameInput.editbox:SetFocus()
      self.nameInput.editbox:HighlightText()
    end
  end
  if self.dirty then
    self.pendingAction = create
    StaticPopup_Show("GSE_CONTROL_DISCARD")
  else
    create()
  end
end

function Editor:Save()
  if not self.sequence then return end
  local name = normalizeName(self.nameInput:GetText())
  if name == "" then
    Config:SetStatus("Sequence name is required.", "danger")
    return
  end
  self.name = name
  self.nameInput:SetText(name)
  local ok = GSE.GUIUpdateSequenceDefinition(self.classID, name, self.sequence, self.originalName, self)
  if not ok then return end
  self.classID = GSE.ResolveSequenceClassID(self.classID, self.sequence)
  self.originalClassID = self.classID
  self.originalName = name
  self.selectedKey = tostring(self.classID) .. "," .. name
  self.dirty = false
  self.savePending = true
  Config:SetStatus("Saved " .. name .. ". Applying out of combat.", "success")
  GSE:ScheduleTimer(function()
    Editor.savePending = false
    Editor:RefreshList()
  end, 1.1)
end

function Editor:Delete()
  if not self.sequence or self.originalName == "" then return end
  if self.savePending then
    Config:SetStatus("Wait for the pending save to finish before deleting.", "warning")
    return
  end
  if InCombatLockdown() then
    Config:SetStatus("Leave combat before deleting a sequence.", "warning")
    return
  end
  self.pendingDeleteClassID = self.originalClassID or self.classID
  self.pendingDeleteName = self.originalName
  StaticPopupDialogs["GSE_CONTROL_DELETE"].text = "Delete " .. self.pendingDeleteName .. " and its GSE macro stub?"
  StaticPopup_Show("GSE_CONTROL_DELETE")
end

function Editor:ConfirmDelete()
  local classID, name = self.pendingDeleteClassID, self.pendingDeleteName
  self.pendingDeleteClassID, self.pendingDeleteName = nil, nil
  if not classID or not name or name == "" then return end
  GSE.DeleteSequence(classID, name)
  local deletedCurrent = self.originalName == name
  if deletedCurrent then
    self.sequence, self.selectedKey, self.originalName = nil, nil, ""
    self.dirty = false
  end
  self:RefreshList()
  if deletedCurrent then
    local first = self.listEntries[1]
    if first then self:LoadKey(first.key) else self:NewSequence(false) end
  end
end

function Editor:AddVersion()
  if not self.sequence then return end
  local source = self.sequence.MacroVersions[tonumber(self.sequence.Default) or 1] or self.sequence.MacroVersions[1]
  table.insert(self.sequence.MacroVersions, GSE.CloneMacroVersion(source, true))
  self.activeTab = table.getn(self.sequence.MacroVersions)
  self.activeSection = "core"
  self:MarkDirty()
  self:RefreshEditor()
end

function Editor:DeleteVersion()
  local version = tonumber(self.activeTab)
  if not version or table.getn(self.sequence.MacroVersions) <= 1 then
    Config:SetStatus("A sequence must keep at least one version.", "warning")
    return
  end
  if tonumber(self.sequence.Default) == version then
    Config:SetStatus("Choose another default version before deleting this one.", "warning")
    return
  end
  table.remove(self.sequence.MacroVersions, version)
  for _, key in ipairs({ "Default", "Raid", "Mythic", "PVP", "Dungeon", "Heroic", "Party" }) do
    local value = tonumber(self.sequence[key])
    if value and value > version then self.sequence[key] = value - 1 end
  end
  self.activeTab = math.min(version, table.getn(self.sequence.MacroVersions))
  self:MarkDirty()
  self:RefreshEditor()
end

function Editor:PickupSequenceMacro(entryKey)
  if InCombatLockdown and InCombatLockdown() then
    Config:SetStatus("Leave combat before dragging a sequence to an action bar.", "warning")
    return false
  end

  local elements = GSE.split(tostring(entryKey or ""), ",")
  local classID = tonumber(elements[1]) or 0
  local sequenceName = elements[2]
  local library = GSELibrary and GSELibrary[classID]
  local sequence = library and library[sequenceName]
  if not sequence or GSE.isEmpty(sequenceName) then
    Config:SetStatus("That sequence is no longer available.", "danger")
    return false
  end

  local macroIndex = GetMacroIndexByName(sequenceName)
  if not macroIndex or macroIndex <= 0 then
    GSE.CreateMacroIcon(sequenceName, sequence.Icon, classID == 0)
    macroIndex = GetMacroIndexByName(sequenceName)
  end

  if macroIndex and macroIndex > 0 then
    PickupMacro(macroIndex)
    Config:SetStatus("Drag " .. sequenceName .. " onto an action bar slot.", "success")
    return true
  else
    Config:SetStatus("Could not create a macro icon for " .. sequenceName .. ".", "danger")
    return false
  end
end

function Editor:RefreshList()
  if not self.listScroll or not self.listChild then return end
  local filter = string.lower(trim(self.search or ""))
  local entries = {}
  local ok, names = pcall(GSE.GetSequenceNames)
  if not ok or type(names) ~= "table" then
    local message = ok and "invalid sequence list" or names
    names = {}
    Config:SetStatus("The GSE sequence library could not be read.", "danger")
    GSE.Print("/gsec sequence-list error: " .. tostring(message), "GSE")
  end
  local templateMode = GSEOptions.autoBuiltTemplateFilter
  if templateMode ~= "ALL" and templateMode ~= "HIDE" then templateMode = "CURRENT" end
  local talentSpecMode = GSEOptions.talentSpecMacroVisibility
  if talentSpecMode ~= "NONE" and talentSpecMode ~= "CURRENT" and talentSpecMode ~= "CLASS" and talentSpecMode ~= "ALL" then
    talentSpecMode = nil
  end
  local allTemplates, currentTemplates = generatedTemplateKeys()
  local seen = {}
  local currentClassID = GSE.GetCurrentClassID()
  local currentSpecID = GSE.GetCurrentSpecID()
  local function addEntry(key, name, searchOverride)
    key, name = tostring(key), tostring(name)
    if seen[key] then return end
    local elements = GSE.split(key, ",")
    local classID = tonumber(elements[1]) or 0
    local sequence = GSELibrary[classID] and GSELibrary[classID][name]
    if not sequence then return end
    if filter ~= "" and not string.find(string.lower(name), filter, 1, true) then return end
    local hidden = {}
    if talentSpecMode == "NONE" and classID ~= 0 then
      if not searchOverride then return end
      table.insert(hidden, "TALENT SPECS")
    elseif searchOverride and classID ~= 0 then
      if talentSpecMode == "CURRENT" and classID ~= currentClassID then
        table.insert(hidden, "OTHER CLASS")
      elseif talentSpecMode == "CURRENT" and tonumber(sequence.SpecID) ~= tonumber(currentSpecID) and tonumber(sequence.SpecID) ~= classID then
        table.insert(hidden, "OTHER TALENT SPEC")
      elseif talentSpecMode == "CLASS" and classID ~= currentClassID then
        table.insert(hidden, "OTHER CLASS")
      end
    elseif searchOverride and classID == 0 and not (GSEOptions.filterList or {})["Global"] then
      table.insert(hidden, "GLOBAL")
    end
    if templateMode == "HIDE" and allTemplates[key] then
      if not searchOverride then return end
      table.insert(hidden, "AUTO-BUILT")
    elseif templateMode == "CURRENT" and allTemplates[key] and not currentTemplates[key] then
      if not searchOverride then return end
      table.insert(hidden, "OTHER CHARACTER")
    end
    local source = "GLOBAL"
    if classID ~= 0 then
      local specID = tonumber(sequence.SpecID)
      source = (GSE.Static.wotlkSpecIDList and GSE.Static.wotlkSpecIDList[specID]) or ("CLASS " .. tostring(classID))
    end
    local label = name
    if filter ~= "" then
      label = label .. " [" .. source .. "]"
      if #hidden > 0 then label = label .. " [HIDDEN: " .. table.concat(hidden, ", ") .. "]" end
    end
    seen[key] = true
    table.insert(entries, { key = key, name = name, label = label, classID = classID })
  end
  for key, name in pairs(names) do
    addEntry(key, name)
  end
  local additionalTemplates = templateMode == "ALL" and allTemplates or currentTemplates
  if templateMode ~= "HIDE" then
    for key in pairs(additionalTemplates) do
      local elements = GSE.split(key, ",")
      local classID = tonumber(elements[1]) or 0
      local sequenceName = elements[2]
      if sequenceName and GSELibrary[classID] and GSELibrary[classID][sequenceName] then
        addEntry(key, sequenceName)
      end
    end
  end
  if filter ~= "" then
    for classID, library in pairs(GSELibrary or {}) do
      if type(library) == "table" then
        for sequenceName in pairs(library) do
          addEntry(tostring(classID) .. "," .. tostring(sequenceName), sequenceName, true)
        end
      end
    end
  end
  table.sort(entries, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
  self.listEntries = entries
  for index, entry in ipairs(entries) do
    local row = self.listRows[index]
    if not row then
      local rowIndex = index
      row = Config:MakeButton(self.listChild, "", function()
        local targetRow = Editor.listRows[rowIndex]
        if targetRow and targetRow.entryKey then Editor:RequestLoad(targetRow.entryKey) end
      end)
      row:SetHeight(20)
      row.label:ClearAllPoints()
      row.label:SetPoint("LEFT", row, "LEFT", 6, 0)
      row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
      row.label:SetJustifyH("LEFT")
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta) Editor:ScrollList(delta) end)
      row:RegisterForDrag("LeftButton")
      row:SetScript("OnDragStart", function()
        local targetRow = Editor.listRows[rowIndex]
        if targetRow and targetRow.entryKey then Editor:PickupSequenceMacro(targetRow.entryKey) end
      end)
      self.listRows[index] = row
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.listChild, "TOPLEFT", 0, -((index - 1) * 21))
    row:SetPoint("TOPRIGHT", self.listChild, "TOPRIGHT", 0, -((index - 1) * 21))
    row.entryKey = entry.key
    row.label:SetText((entry.classID == 0 and "* " or "") .. (entry.label or entry.name))
    row.selected = entry.key == self.selectedKey
    row:RefreshTheme()
    row:Show()
  end
  for index = #entries + 1, #self.listRows do
    self.listRows[index].entryKey = nil
    self.listRows[index]:Hide()
  end

  local visibleHeight = math.max(1, self.listScroll:GetHeight())
  local contentHeight = math.max(visibleHeight, #entries * 21)
  self.listChild:SetHeight(contentHeight)
  local maximum = math.max(0, contentHeight - visibleHeight)
  self.listSlider:SetMinMaxValues(0, maximum)
  self.listSlider:SetValueStep(1)
  self:SetListScrollbarVisible(maximum > 0)
  if maximum > 0 then
    self.listSlider:Show()
  else
    self.listSlider:Hide()
    self.listSlider:SetValue(0)
  end
  if self.listScroll:GetVerticalScroll() > maximum then self.listSlider:SetValue(maximum) end
  if self.listCount then self.listCount:SetText(tostring(#entries) .. " SEQUENCES") end
end

function Editor:ScrollList(delta)
  if not self.listSlider then return end
  local minimum, maximum = self.listSlider:GetMinMaxValues()
  local value = math.max(minimum, math.min(maximum, (tonumber(self.listSlider:GetValue()) or 0) - (delta * 63)))
  self.listSlider:SetValue(value)
end

function Editor:SetListScrollbarVisible(visible)
  visible = visible and true or false
  if self.listScrollbarVisible == visible or not self.listScroll or not self.listPanel then return end
  self.listScrollbarVisible = visible
  self.listScroll:ClearAllPoints()
  self.listScroll:SetPoint("TOPLEFT", self.listPanel, "TOPLEFT", 4, -28)
  self.listScroll:SetPoint("BOTTOMRIGHT", self.listPanel, "BOTTOMRIGHT", visible and -14 or -4, 27)
end

function Editor:GetBodyContentHeight()
  if self.activeTab == "details" then return 300 end
  if self.activeSection == "items" then return 220 end
  return 340
end

function Editor:UpdateBodyScroll()
  if not self.bodyScroll or not self.body or not self.bodySlider then return end
  local context = tostring(self.activeTab) .. ":" .. tostring(self.activeSection)
  local reset = self.bodyScrollContext ~= context
  self.bodyScrollContext = context
  local visibleHeight = math.max(1, self.bodyScroll:GetHeight())
  local contentHeight = math.max(visibleHeight, self:GetBodyContentHeight())
  self.body:SetHeight(contentHeight)
  local maximum = math.max(0, contentHeight - visibleHeight)
  self.bodySlider:SetMinMaxValues(0, maximum)
  self.bodySlider:SetValueStep(1)
  self:SetBodyScrollbarVisible(maximum > 0)
  if maximum > 0 then
    self.bodySlider:Show()
  else
    self.bodySlider:Hide()
  end
  local value = reset and 0 or (tonumber(self.bodySlider:GetValue()) or 0)
  self.bodySlider:SetValue(math.max(0, math.min(maximum, value)))
end

function Editor:SetBodyScrollbarVisible(visible)
  visible = visible and true or false
  if self.bodyScrollbarVisible == visible or not self.bodyScroll or not self.editorPanel then return end
  self.bodyScrollbarVisible = visible
  self.bodyScroll:ClearAllPoints()
  self.bodyScroll:SetPoint("TOPLEFT", self.editorPanel, "TOPLEFT", 1, -52)
  self.bodyScroll:SetPoint("BOTTOMRIGHT", self.editorPanel, "BOTTOMRIGHT", visible and -14 or -1, 4)
end

function Editor:ScrollBody(delta)
  if not self.bodySlider then return end
  local minimum, maximum = self.bodySlider:GetMinMaxValues()
  local value = math.max(minimum, math.min(maximum, (tonumber(self.bodySlider:GetValue()) or 0) - (delta * 48)))
  self.bodySlider:SetValue(value)
end

function Editor:AttachBodyWheel(frame)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta) Editor:ScrollBody(delta) end)
end

function Editor:RefreshEditor()
  if not self.page or not self.sequence then return end
  self.detailsPane:Hide()
  self.versionPane:Hide()
  self.corePane:Hide()
  self.itemsPane:Hide()
  self.nameInput:SetText(self.name or "")
  if self.activeTab == "details" then
    self.detailsPane:Show()
    self.versionPane:Hide()
  else
    self.detailsPane:Hide()
    self.versionPane:Show()
  end
  self.detailsButton.selected = self.activeTab == "details"
  self.detailsButton:RefreshTheme()

  local versionCount = table.getn(self.sequence.MacroVersions)
  for index, button in ipairs(self.versionButtons) do
    if index <= versionCount then
      button.version = index
      button.label:SetText("V" .. index)
      button.selected = tonumber(self.activeTab) == index
      button:RefreshTheme()
      button:Show()
    else
      button.version = nil
      button:Hide()
    end
  end

  if self.activeTab == "details" then
    self:RefreshDetails()
    self:UpdateBodyScroll()
  else
    self:RefreshVersion()
  end
end

function Editor:RefreshDetails()
  local sequence = self.sequence
  self.authorInput:SetText(sequence.Author or "")
  self.talentsInput:SetText(sequence.Talents or "")
  self.helpLinkInput:SetText(sequence.Helplink or "")
  self.specInput:SetText(sequence.SpecID or "")
  self.iconInput:SetText(sequence.Icon or "")
  self.helpInput:SetText(sequence.Help or "")
  for _, button in ipairs(self.defaultButtons) do button:RefreshState() end
end

function Editor:RefreshVersion()
  local version = self.sequence.MacroVersions[tonumber(self.activeTab)]
  if not version then return end
  self.corePane:Hide()
  self.itemsPane:Hide()
  if self.activeSection == "core" then self.corePane:Show() else self.corePane:Hide() end
  if self.activeSection == "items" then self.itemsPane:Show() else self.itemsPane:Hide() end
  for key, button in pairs(self.sectionButtons) do
    button.selected = key == self.activeSection
    button:RefreshTheme()
  end
  self.stepButton.label:SetText("STEP  " .. string.upper(version.StepFunction or "Sequential"))
  self.loopInput:SetText(version.LoopLimit or "")
  self.sequenceInput:SetText(listText(version))
  self.keyPressInput:SetText(listText(version.KeyPress))
  self.preMacroInput:SetText(listText(version.PreMacro))
  self.postMacroInput:SetText(listText(version.PostMacro))
  self.keyReleaseInput:SetText(listText(version.KeyRelease))
  for _, button in ipairs(self.itemButtons) do button:RefreshState() end
  self:UpdateBodyScroll()
end

function Editor:BuildList(page)
  local panel = CreateFrame("Frame", nil, page)
  panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
  panel:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
  panel:SetWidth(146)
  Config:RegisterFrame(panel, "surface", "muted")
  self.listPanel = panel

  local search = makeInput(panel, false)
  search:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
  search:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
  search.OnValueChanged = function(_, value)
    Editor.search = value
    if Editor.listSlider then Editor.listSlider:SetValue(0) end
    Editor:RefreshList()
  end
  self.searchInput = search

  local scroll = CreateFrame("ScrollFrame", nil, panel)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -28)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 27)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(_, delta) Editor:ScrollList(delta) end)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(124)
  child:SetHeight(1)
  scroll:SetScrollChild(child)
  self.listScroll, self.listChild = scroll, child
  self.listScrollbarVisible = false
  self.listRows = {}

  local slider = CreateFrame("Slider", nil, panel)
  slider:SetOrientation("VERTICAL")
  slider:SetWidth(8)
  slider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -31)
  slider:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 31)
  Config:RegisterFrame(slider, "inset", "muted")
  slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
  local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
  if thumb then thumb:SetSize(8, 18) Config:RegisterTexture(thumb, "gold") end
  slider:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
  slider:SetMinMaxValues(0, 0)
  slider:SetValue(0)
  self.listSlider = slider
  scroll:SetScript("OnSizeChanged", function(_, width)
    child:SetWidth(math.max(40, width))
    Editor:RefreshList()
  end)

  local count = makeText(panel, "GameFontNormalSmall", 9, "dim")
  count:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 5, 6)
  self.listCount = count
  local newButton = Config:MakeButton(panel, "NEW", function() Editor:NewSequence(false) end)
  newButton:SetWidth(42)
  newButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 3)
end

function Editor:BuildDetails(parent)
  local pane = CreateFrame("Frame", nil, parent)
  pane:SetAllPoints()
  pane:Hide()
  self.detailsPane = pane
  self.authorInput = addField(pane, "Author", 4, 4, 198, function(v) self.sequence.Author = v end)
  self.talentsInput = addField(pane, "Talents", 206, 4, 198, function(v) self.sequence.Talents = v end)
  self.helpLinkInput = addField(pane, "Help link", 4, 29, 400, function(v) self.sequence.Helplink = v end)
  self.specInput = addField(pane, "Spec ID", 4, 54, 198, function(v) self.sequence.SpecID = tonumber(v) or v end)
  self.iconInput = addField(pane, "Icon", 206, 54, 198, function(v) self.sequence.Icon = v end)

  local helpLabel = makeText(pane, "GameFontNormalSmall", 10, "dim")
  helpLabel:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, -84)
  helpLabel:SetText("Help / notes")
  local help = makeInput(pane, true)
  help:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, -98)
  help:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -4, -98)
  help:SetHeight(92)
  help.useBodyScroll = true
  help.OnValueChanged = function(_, value) self.sequence.Help = value self:MarkDirty() end
  self.helpInput = help

  local heading = makeText(pane, "GameFontNormalSmall", 10, "gold")
  heading:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, -198)
  heading:SetText("ACTIVE VERSION BY CONTENT")
  self.defaultButtons = {}
  local contexts = { "Default", "Raid", "Mythic", "PVP", "Dungeon", "Heroic", "Party" }
  for index, key in ipairs(contexts) do
    local contextKey = key
    local x = ((index - 1) % 3) * 130 + 4
    local y = 215 + (math.floor((index - 1) / 3) * 25)
    local button
    button = Config:MakeButton(pane, key, function(_, mouseButton)
      local count = table.getn(self.sequence.MacroVersions)
      if contextKey ~= "Default" and mouseButton == "RightButton" then
        self.sequence[contextKey] = nil
      else
        local current = tonumber(self.sequence[contextKey]) or tonumber(self.sequence.Default) or 1
        self.sequence[contextKey] = (current % count) + 1
      end
      self:MarkDirty()
      button:RefreshState()
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetSize(124, 22)
    button:SetPoint("TOPLEFT", pane, "TOPLEFT", x, -y)
    self:AttachBodyWheel(button)
    function button:RefreshState()
      local explicit = tonumber(Editor.sequence[contextKey])
      local value = explicit or tonumber(Editor.sequence.Default) or 1
      self.label:SetText(string.upper(contextKey) .. "  V" .. value .. ((contextKey ~= "Default" and not explicit) and "  DEFAULT" or ""))
    end
    table.insert(self.defaultButtons, button)
  end
end

function Editor:BuildVersion(parent)
  local pane = CreateFrame("Frame", nil, parent)
  pane:SetAllPoints()
  pane:Hide()
  self.versionPane = pane
  self.sectionButtons = {}
  local sectionX = 4
  for _, entry in ipairs({ { "core", "SEQUENCE", 78 }, { "items", "USE / RESET", 88 } }) do
    local sectionKey = entry[1]
    local button = Config:MakeButton(pane, entry[2], function()
      self.activeSection = sectionKey
      self:RefreshVersion()
    end)
    button:SetSize(entry[3], 20)
    button:SetPoint("TOPLEFT", pane, "TOPLEFT", sectionX, -2)
    self:AttachBodyWheel(button)
    sectionX = sectionX + entry[3] + 4
    self.sectionButtons[sectionKey] = button
  end
  local deleteVersion = Config:MakeButton(pane, "DELETE V", function() self:DeleteVersion() end, "danger")
  deleteVersion:SetSize(66, 20)
  deleteVersion:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -4, -2)
  self:AttachBodyWheel(deleteVersion)

  local core = CreateFrame("Frame", nil, pane)
  core:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, -26)
  core:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", 0, 0)
  self.corePane = core
  core:Hide()
  local step = Config:MakeButton(core, "STEP", function()
    local version = self.sequence.MacroVersions[tonumber(self.activeTab)]
    version.StepFunction = version.StepFunction == "Priority" and "Sequential" or "Priority"
    self:MarkDirty()
    self:RefreshVersion()
  end)
  step:SetSize(150, 20)
  step:SetPoint("TOPLEFT", core, "TOPLEFT", 4, -2)
  self:AttachBodyWheel(step)
  self.stepButton = step
  attachDelayedHelp(step, step, "STEP FUNCTION", "Click to switch the step pattern. Sequential runs 1, 2, 3, 4 and repeats. Priority runs 1; 1, 2; 1, 2, 3; and so on, so earlier lines are attempted more often. GSE cannot detect whether a spell successfully cast.")
  local loopLabel = makeText(core, "GameFontNormalSmall", 10, "dim")
  loopLabel:SetPoint("TOPLEFT", core, "TOPLEFT", 166, -7)
  loopLabel:SetText("LOOP LIMIT")
  local loopLabelHit = CreateFrame("Frame", nil, core)
  loopLabelHit:SetPoint("TOPLEFT", core, "TOPLEFT", 162, -2)
  loopLabelHit:SetSize(66, 20)
  loopLabelHit:EnableMouse(true)
  self:AttachBodyWheel(loopLabelHit)
  local loop = makeInput(core, false)
  loop:SetSize(58, 20)
  loop:SetPoint("TOPLEFT", core, "TOPLEFT", 232, -2)
  loop.useBodyScroll = true
  loop.editbox:SetNumeric(true)
  loop.OnValueChanged = function(_, value)
    local version = self.sequence.MacroVersions[tonumber(self.activeTab)]
    version.LoopLimit = value ~= "" and tonumber(value) or nil
    self:MarkDirty()
  end
  self.loopInput = loop
  local loopHelp = "Sets how many times the main Sequence block repeats before PostMacro is reached in loop mode. Leave it blank for no fixed repeat limit."
  attachDelayedHelp(loopLabelHit, loop, "LOOP LIMIT", loopHelp)
  attachInputDelayedHelp(loop, "LOOP LIMIT", loopHelp)
  local sequenceLabel = makeText(core, "GameFontNormalSmall", 10, "gold")
  sequenceLabel:SetPoint("TOPLEFT", core, "TOPLEFT", 4, -103)
  sequenceLabel:SetText("SEQUENCE")
  local sequenceInput = makeInput(core, true)
  sequenceInput:SetPoint("TOPLEFT", core, "TOPLEFT", 4, -117)
  sequenceInput:SetPoint("TOPRIGHT", core, "TOPRIGHT", -4, -117)
  sequenceInput:SetHeight(102)
  sequenceInput.useBodyScroll = true
  sequenceInput.OnValueChanged = function(_, value)
    local version = self.sequence.MacroVersions[tonumber(self.activeTab)]
    for index in ipairs(version) do version[index] = nil end
    for index, line in ipairs(GSE.SplitMeIntolines(value)) do version[index] = line end
    self:MarkDirty()
  end
  self.sequenceInput = sequenceInput

  local hookDefinitions = {
    { label = "KEYPRESS", key = "KeyPress", side = "left", y = 28, height = 70, help = "Prepended before the current Sequence line on every GSE activation. Use it for commands that must appear before each step." },
    { label = "PREMACRO", key = "PreMacro", side = "right", y = 28, height = 70, help = "Inserted as opening sequence steps before the main Sequence block. These lines are stepped through at the start of the loop; they do not all run before every click." },
    { label = "POSTMACRO", key = "PostMacro", side = "left", y = 232, height = 76, help = "Inserted after the main Sequence block. Set a positive Loop Limit when you want the repeating main block to finish and reach these closing steps." },
    { label = "KEYRELEASE", key = "KeyRelease", side = "right", y = 232, height = 76, help = "Appended after the current Sequence line on every activation. In this client it describes macro order; it is not a guaranteed physical key-up event." },
  }
  self.hookGroups = {}
  for _, definition in ipairs(hookDefinitions) do
    local hookKey = definition.key
    local group = CreateFrame("Frame", nil, core)
    if definition.side == "left" then
      group:SetPoint("TOPLEFT", core, "TOPLEFT", 4, -definition.y)
      group:SetPoint("TOPRIGHT", core, "TOP", -2, -definition.y)
    else
      group:SetPoint("TOPLEFT", core, "TOP", 2, -definition.y)
      group:SetPoint("TOPRIGHT", core, "TOPRIGHT", -4, -definition.y)
    end
    group:SetHeight(definition.height)
    self:AttachBodyWheel(group)
    self.hookGroups[hookKey] = group

    local label = makeText(group, "GameFontNormalSmall", 10, "gold")
    label:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -1)
    label:SetText(definition.label)
    local input = makeInput(group, true)
    input:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -14)
    input:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
    input.useBodyScroll = true
    input.OnValueChanged = function(_, value)
      self.sequence.MacroVersions[tonumber(self.activeTab)][hookKey] = GSE.SplitMeIntolines(value)
      self:MarkDirty()
    end
    attachDelayedHelp(group, input, definition.label, definition.help)
    attachInputDelayedHelp(input, definition.label, definition.help)
    if hookKey == "KeyPress" then self.keyPressInput = input end
    if hookKey == "PreMacro" then self.preMacroInput = input end
    if hookKey == "PostMacro" then self.postMacroInput = input end
    if hookKey == "KeyRelease" then self.keyReleaseInput = input end
  end

  local items = CreateFrame("Frame", nil, pane)
  items:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, -26)
  items:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", 0, 0)
  self.itemsPane = items
  items:Hide()
  local note = makeText(items, "GameFontNormalSmall", 10, "dim")
  note:SetPoint("TOPLEFT", items, "TOPLEFT", 4, -5)
  note:SetText("Left-click cycles Default / On / Off. Right-click restores Default.")
  self.itemButtons = {}
  local itemDefinitions = { { "Combat reset", "Combat" }, { "Head", "Head" }, { "Neck", "Neck" }, { "Belt", "Belt" }, { "Ring 1", "Ring1" }, { "Ring 2", "Ring2" }, { "Trinket 1", "Trinket1" }, { "Trinket 2", "Trinket2" } }
  for index, definition in ipairs(itemDefinitions) do
    local labelText, itemKey = definition[1], definition[2]
    local x = ((index - 1) % 2) * 202 + 4
    local y = 25 + (math.floor((index - 1) / 2) * 27)
    local button = makeTriState(items, labelText, x, y, 194,
      function() return self.sequence.MacroVersions[tonumber(self.activeTab)][itemKey] end,
      function(value) self.sequence.MacroVersions[tonumber(self.activeTab)][itemKey] = value end)
    self:AttachBodyWheel(button)
    table.insert(self.itemButtons, button)
  end
end

function Editor:BuildWorkspace(page)
  local panel = CreateFrame("Frame", nil, page)
  panel:SetPoint("TOPLEFT", page, "TOPLEFT", 147, 0)
  panel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
  Config:RegisterFrame(panel, "background", "muted")
  self.editorPanel = panel

  local name = makeInput(panel, false)
  name:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
  name:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -250, -4)
  name.OnValueChanged = function(_, value) self.name = value self:MarkDirty() end
  self.nameInput = name
  local duplicate = Config:MakeButton(panel, "DUP", function() self:NewSequence(true) end)
  duplicate:SetSize(38, 20)
  duplicate:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -206, -4)
  local save = Config:MakeButton(panel, "SAVE", function() self:Save() end)
  save:SetSize(54, 20)
  save:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -148, -4)
  local export = Config:MakeButton(panel, "EXP", function()
    if self.name and self.name ~= "" and GSE.GUIExportSequence then
      GSE.GUIExportSequence(self.classID, self.name)
    end
  end)
  export:SetSize(38, 20)
  export:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -106, -4)
  local import = Config:MakeButton(panel, "IMP", function()
    if GSE.GUIImportFrame then
      GSE.GUIImportFrame.ReturnToControl = true
      GSE.GUIImportFrame:Show()
    end
  end)
  import:SetSize(38, 20)
  import:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -64, -4)
  local delete = Config:MakeButton(panel, "DEL", function() self:Delete() end, "danger")
  delete:SetSize(54, 20)
  delete:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
  local details = Config:MakeButton(panel, "DETAILS", function() self.activeTab = "details" self:RefreshEditor() end)
  details:SetSize(58, 20)
  details:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -28)
  self.detailsButton = details
  for index = 1, 10 do
    local versionIndex = index
    local button
    button = Config:MakeButton(panel, "V" .. index, function()
      local targetButton = self.versionButtons[versionIndex]
      if targetButton and targetButton.version then self.activeTab = targetButton.version self:RefreshEditor() end
    end)
    button:SetSize(30, 20)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", 66 + ((index - 1) * 32), -28)
    self.versionButtons[index] = button
  end
  local addVersion = Config:MakeButton(panel, "+", function() self:AddVersion() end)
  addVersion:SetSize(26, 20)
  addVersion:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -28)

  local bodyScroll = CreateFrame("ScrollFrame", nil, panel)
  bodyScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -52)
  bodyScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 4)
  bodyScroll:EnableMouseWheel(true)
  bodyScroll:SetScript("OnMouseWheel", function(_, delta) Editor:ScrollBody(delta) end)
  local body = CreateFrame("Frame", nil, bodyScroll)
  body:SetWidth(400)
  body:SetHeight(1)
  bodyScroll:SetScrollChild(body)
  self.bodyScroll, self.body = bodyScroll, body
  self.bodyScrollbarVisible = false

  local bodySlider = CreateFrame("Slider", nil, panel)
  bodySlider:SetOrientation("VERTICAL")
  bodySlider:SetWidth(9)
  bodySlider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -56)
  bodySlider:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 4)
  Config:RegisterFrame(bodySlider, "inset", "muted")
  bodySlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
  local thumb = bodySlider.GetThumbTexture and bodySlider:GetThumbTexture()
  if thumb then thumb:SetSize(9, 18) Config:RegisterTexture(thumb, "gold") end
  bodySlider:SetScript("OnValueChanged", function(_, value) bodyScroll:SetVerticalScroll(value) end)
  bodySlider:SetMinMaxValues(0, 0)
  bodySlider:SetValue(0)
  self.bodySlider = bodySlider
  bodyScroll:SetScript("OnSizeChanged", function(_, width)
    body:SetWidth(math.max(100, width))
    Editor:UpdateBodyScroll()
  end)

  self:BuildDetails(body)
  self:BuildVersion(body)
end

function Editor:BuildPage(page)
  self.page = page
  page:SetHeight(398)
  self:BuildList(page)
  self:BuildWorkspace(page)
  page.OnSelected = function()
    Editor:RefreshList()
    if not Editor.sequence then
      local first = Editor.listEntries[1]
      if first then Editor:LoadKey(first.key) else Editor:NewSequence(false) end
    else
      Editor:RefreshEditor()
    end
  end
  return 398
end

StaticPopupDialogs["GSE_CONTROL_DISCARD"] = {
  text = "Discard the unsaved sequence changes?",
  button1 = YES,
  button2 = NO,
  OnAccept = function()
    Editor.dirty = false
    local action = Editor.pendingAction
    Editor.pendingAction = nil
    if action then action() end
  end,
  OnCancel = function() Editor.pendingAction = nil end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

StaticPopupDialogs["GSE_CONTROL_DELETE"] = {
  text = "Delete this sequence?",
  button1 = DELETE,
  button2 = CANCEL,
  OnAccept = function() Editor:ConfirmDelete() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

Config.PageBuilders.sequences = function(_, page) return Editor:BuildPage(page) end
table.insert(Config.Navigation, 1, { "sequences", "Sequences" })
