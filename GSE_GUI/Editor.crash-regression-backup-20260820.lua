local GNOME,_ = ...
local Statics = GSE.Static
local GSE = GSE

local AceGUI = LibStub("AceGUI-3.0")
local L = GSE.L
local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libCE = libC:GetAddonEncodeTable()

local otherversionlistboxvalue = ""
local default = 1
local raid = 1
local pvp = 1
local mythic = 1
local classid = GSE.GetCurrentClassID()

local editframe = AceGUI:Create("Frame")
editframe:Hide()
GSE.GUIEditFrame = editframe
editframe.Sequence = {}
editframe.Sequence.MacroVersions = {}
editframe.SequenceName = ""
editframe.PendingSequenceName = ""
editframe.OriginalSequenceName = ""
editframe.SuppressNameChange = false
editframe.Default = 1
editframe.Raid = 1
editframe.PVP = 1
editframe.Mythic = 1
editframe.Dungeon = 1
editframe.Heroic = 1
editframe.Party = 1
editframe.ClassID = classid
editframe.save = false
editframe.SelectedTab = "config"

local fleft, fbottom, fwidth, fheight = editframe.frame:GetBoundsRect()
editframe.Left = fleft
editframe.Bottom = fbottom
editframe.Width = fwidth
editframe.Height = fheight

editframe:SetTitle(L["Sequence Editor"])
--editframe:SetStatusText(L["Gnome Sequencer: Sequence Editor."])
editframe:SetCallback("OnClose", function (self)
  editframe:Hide();
  if editframe.save then
    local event = {}
    event.action = "openviewer"
    table.insert(GSE.OOCQueue, event)
  else
    GSE.GUIShowViewer()
  end
  editframe.save = false
end)
editframe:SetLayout("List")
-- Set resize bounds based on screen size
local maxHeight = GetScreenHeight() - 40
local maxWidth = GetScreenWidth() - 40
editframe.frame:SetMaxResize(maxWidth, maxHeight)
-- Set minimum size to prevent content overflow
editframe.frame:SetMinResize(600, 500)

local EDITOR_ACTION_BAR_SIDE_INSET = 15
local EDITOR_ACTION_BAR_BOTTOM_OFFSET = 42
local EDITOR_ACTION_BAR_HEIGHT = 24
local EDITOR_ACTION_BAR_SPACING = 6
local EDITOR_ACTION_BAR_MIN_BUTTON_WIDTH = 85
local EDITOR_ACTION_BAR_MAX_BUTTON_WIDTH = 120
local EDITOR_CONTENT_BOTTOM_OFFSET = EDITOR_ACTION_BAR_BOTTOM_OFFSET + EDITOR_ACTION_BAR_HEIGHT + 8
local EDITOR_SECTION_BUTTON_HEIGHT = 24

local EDITOR_BACKDROP = {
  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 4, bottom = 3 },
}

local EDITOR_BUTTON_COLORS = {
  section = {
    normal = { 0.10, 0.10, 0.09, 0.95, 0.36, 0.30, 0.16, 0.95, 0.82, 0.78, 0.64 },
    selected = { 0.19, 0.15, 0.07, 0.98, 0.72, 0.58, 0.18, 1.0, 1.0, 0.88, 0.35 },
  },
  primary = {
    normal = { 0.16, 0.13, 0.05, 0.98, 0.72, 0.58, 0.18, 1.0, 1.0, 0.88, 0.35 },
    selected = { 0.20, 0.16, 0.06, 0.98, 0.80, 0.64, 0.20, 1.0, 1.0, 0.92, 0.45 },
  },
  secondary = {
    normal = { 0.08, 0.08, 0.08, 0.95, 0.42, 0.35, 0.18, 0.95, 0.90, 0.84, 0.72 },
    selected = { 0.12, 0.11, 0.09, 0.98, 0.56, 0.46, 0.20, 1.0, 1.0, 0.88, 0.35 },
  },
  danger = {
    normal = { 0.15, 0.08, 0.08, 0.96, 0.58, 0.24, 0.20, 0.95, 0.96, 0.82, 0.74 },
    selected = { 0.18, 0.09, 0.09, 0.98, 0.70, 0.28, 0.24, 1.0, 1.0, 0.86, 0.78 },
  },
}

local function setFontStringColor(fontString, red, green, blue)
  if not fontString then
    return
  end
  fontString:SetTextColor(red, green, blue)
  fontString:SetShadowColor(0, 0, 0, 1)
  fontString:SetShadowOffset(1, -1)
end

local function applyBackdropStyle(frame, red, green, blue, alpha, borderRed, borderGreen, borderBlue, borderAlpha)
  frame:SetBackdrop(EDITOR_BACKDROP)
  frame:SetBackdropColor(red, green, blue, alpha)
  frame:SetBackdropBorderColor(borderRed, borderGreen, borderBlue, borderAlpha)
end

local function applyEditorFrameSkin()
  applyBackdropStyle(editframe.frame, 0.05, 0.04, 0.03, 0.96, 0.56, 0.45, 0.16, 1.0)
  if not editframe.FrameBackground then
    editframe.FrameBackground = editframe.frame:CreateTexture(nil, "BACKGROUND")
    editframe.FrameBackground:SetAllPoints(editframe.frame)
    editframe.FrameBackground:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    editframe.FrameBackground:SetVertexColor(0.40, 0.30, 0.12, 0.22)
  end
end

local function getButtonColorSet(style, selected)
  local colorSet = EDITOR_BUTTON_COLORS[style or "section"] or EDITOR_BUTTON_COLORS.section
  return selected and colorSet.selected or colorSet.normal
end

local function applyNativeBoardButtonSkin(button, style, selected)
  local colors = getButtonColorSet(style, selected)
  button:SetNormalTexture("")
  button:SetHighlightTexture("")
  button:SetPushedTexture("")
  button:SetDisabledTexture("")
  applyBackdropStyle(button, colors[1], colors[2], colors[3], colors[4], colors[5], colors[6], colors[7], colors[8])
  setFontStringColor(button:GetFontString(), colors[9], colors[10], colors[11])
end

local function applyAceBoardButtonSkin(widget, style, selected)
  local frame = widget.frame
  frame:SetHeight(EDITOR_SECTION_BUTTON_HEIGHT)
  applyNativeBoardButtonSkin(frame, style, selected)
  if frame.SetButtonState then
    frame:SetButtonState(selected and "PUSHED" or "NORMAL", selected and true or false)
  end
end

local function updateSectionButtonStates(selectedGroup)
  if not editframe.SectionButtons then
    return
  end
  for value, widget in pairs(editframe.SectionButtons) do
    applyAceBoardButtonSkin(widget, widget.BoardButtonStyle or "section", tostring(value) == tostring(selectedGroup))
  end
end

local function getSelectedEditorTab()
  local selectedTab = editframe.SelectedTab
  if GSE.isEmpty(selectedTab) or selectedTab == "group" or selectedTab == "new" then
    return "config"
  end
  selectedTab = tostring(selectedTab)
  if selectedTab == "config" then
    return selectedTab
  end
  local numericTab = tonumber(selectedTab)
  if numericTab and editframe.Sequence and editframe.Sequence.MacroVersions and editframe.Sequence.MacroVersions[numericTab] then
    return tostring(numericTab)
  end
  return "config"
end

local function getEditorContentHeight()
  if editframe.content and editframe.content.GetHeight then
    return editframe.content:GetHeight() or 0
  end
  return 0
end

local function getEditorTabBodyHeight(container, minimumHeight)
  local contentHeight = 0
  if container and container.content and container.content.GetHeight then
    contentHeight = container.content:GetHeight() or 0
  end
  if contentHeight <= 0 and editframe.ContentContainer and editframe.ContentContainer.content and editframe.ContentContainer.content.GetHeight then
    contentHeight = editframe.ContentContainer.content:GetHeight() or 0
  end
  if contentHeight <= 0 then
    contentHeight = editframe.Height - 240
  end
  return math.max(minimumHeight or 100, contentHeight - 10)
end

local function getEditorContainerWidth(container, padding)
  local contentWidth = 0
  if container and container.content and container.content.GetWidth then
    contentWidth = container.content:GetWidth() or 0
  end
  if contentWidth <= 0 and editframe.ContentContainer and editframe.ContentContainer.content and editframe.ContentContainer.content.GetWidth then
    contentWidth = editframe.ContentContainer.content:GetWidth() or 0
  end
  if contentWidth <= 0 then
    contentWidth = editframe.Width - 60
  end
  return math.max(260, contentWidth - (padding or 0))
end

local function addEditorHeading(parent, text)
  local heading = AceGUI:Create("Heading")
  heading:SetText(text)
  if heading.label then
    heading.label:SetTextColor(1.0, 0.84, 0.28)
  end
  if heading.left then
    heading.left:SetVertexColor(0.70, 0.56, 0.18)
  end
  if heading.right then
    heading.right:SetVertexColor(0.70, 0.56, 0.18)
  end
  parent:AddChild(heading)
end

local function getEditorSectionList()
  local sections = {
    config = L["Configuration"],
  }
  if editframe.Sequence and editframe.Sequence.MacroVersions and type(editframe.Sequence.MacroVersions) == "table" then
    for index in ipairs(editframe.Sequence.MacroVersions) do
      sections[tostring(index)] = string.format("Version %d", index)
    end
  end
  return sections
end

local function getEditorSectionTitle(section)
  if tostring(section) == "config" then
    return L["Configuration"]
  end
  return string.format("Version %d", tonumber(section) or 0)
end

local function versionHasOptionalData(version)
  local versionData = editframe.Sequence and editframe.Sequence.MacroVersions and editframe.Sequence.MacroVersions[tonumber(version)]
  if not versionData then
    return false
  end
  local optionalKeys = {
    "Combat",
    "Head",
    "Neck",
    "Belt",
    "Ring1",
    "Ring2",
    "Trinket1",
    "Trinket2",
  }
  for _, key in ipairs(optionalKeys) do
    if versionData[key] ~= nil then
      return true
    end
  end
  return false
end

local function shouldShowVersionOptions(version)
  local numericVersion = tonumber(version)
  editframe.ShowVersionOptions = editframe.ShowVersionOptions or {}
  if editframe.ShowVersionOptions[numericVersion] ~= nil then
    return editframe.ShowVersionOptions[numericVersion]
  end
  return versionHasOptionalData(numericVersion)
end

local function setVersionOptionsVisible(version, isVisible)
  editframe.ShowVersionOptions = editframe.ShowVersionOptions or {}
  editframe.ShowVersionOptions[tonumber(version)] = isVisible
end

local function saveCurrentSequence()
  editframe.Sequence.ManualIntervention = true
  local sequenceName = editframe.PendingSequenceName
  if GSE.isEmpty(sequenceName) and editframe.nameeditbox then
    sequenceName = editframe.nameeditbox:GetText()
  end
  if GSE.isEmpty(sequenceName) and not GSE.isEmpty(editframe.OriginalSequenceName) then
    sequenceName = editframe.OriginalSequenceName
    if editframe.nameeditbox then
      editframe.SuppressNameChange = true
      editframe.nameeditbox:SetText(sequenceName)
      editframe.SuppressNameChange = false
    end
  end
  editframe.SequenceName = sequenceName
  editframe.PendingSequenceName = sequenceName
  if GSE.GUIUpdateSequenceDefinition(editframe.ClassID, editframe.SequenceName, editframe.Sequence) then
    editframe.PendingSequenceName = editframe.SequenceName
    editframe.OriginalSequenceName = editframe.SequenceName
    editframe.save = true
  end
end

local function addEditorMacroVersion()
  if GSE.isNewFirstTimeCreated then
    if GSE.GUIUpdateSequenceDefinition(editframe.ClassID, editframe.SequenceName, editframe.Sequence) then
      editframe.PendingSequenceName = editframe.SequenceName
      editframe.OriginalSequenceName = editframe.SequenceName
      editframe.save = true
    end
  end

  local sourceVersion = tonumber(editframe.Sequence.Default) or 1
  local sourceMacro = editframe.Sequence.MacroVersions[sourceVersion] or editframe.Sequence.MacroVersions[1]
  table.insert(editframe.Sequence.MacroVersions, GSE.CloneMacroVersion(sourceMacro))
  local newVersion = tostring(table.getn(editframe.Sequence.MacroVersions))
  editframe.SelectedTab = newVersion
  GSE.GUIEditorPerformLayout(editframe)
end

local function layoutEditorActionBar()
  if not editframe.ActionBar or not editframe.ActionButtonOrder then
    return
  end

  local barWidth = editframe.ActionBar:GetWidth()
  if not barWidth or barWidth <= 0 then
    barWidth = math.max(0, (editframe.Width or 0) - (EDITOR_ACTION_BAR_SIDE_INSET * 2))
  end

  local buttonCount = #editframe.ActionButtonOrder
  if buttonCount == 0 then
    return
  end

  local totalSpacing = EDITOR_ACTION_BAR_SPACING * (buttonCount - 1)
  local buttonWidth = math.floor((barWidth - totalSpacing) / buttonCount)
  buttonWidth = math.max(EDITOR_ACTION_BAR_MIN_BUTTON_WIDTH, math.min(EDITOR_ACTION_BAR_MAX_BUTTON_WIDTH, buttonWidth))

  local usedWidth = (buttonWidth * buttonCount) + totalSpacing
  local startOffset = math.max(0, math.floor((barWidth - usedWidth) / 2))
  local previousButton

  for index, button in ipairs(editframe.ActionButtonOrder) do
    button:ClearAllPoints()
    button:SetWidth(buttonWidth)
    button:SetHeight(EDITOR_ACTION_BAR_HEIGHT)
    if index == 1 then
      button:SetPoint("LEFT", editframe.ActionBar, "LEFT", startOffset, 0)
    else
      button:SetPoint("LEFT", previousButton, "RIGHT", EDITOR_ACTION_BAR_SPACING, 0)
    end
    previousButton = button
  end
end

local function ensureEditorActionBar()
  if editframe.ActionBar then
    layoutEditorActionBar()
    return
  end

  local function createEditorActionButton(text, onClick)
    local button = CreateFrame("Button", nil, editframe.ActionBar, "UIPanelButtonTemplate")
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
  end

  editframe.ActionBar = CreateFrame("Frame", nil, editframe.frame)
  editframe.ActionBar:SetHeight(EDITOR_ACTION_BAR_HEIGHT)
  editframe.ActionBar:SetPoint("BOTTOMLEFT", editframe.frame, "BOTTOMLEFT", EDITOR_ACTION_BAR_SIDE_INSET, EDITOR_ACTION_BAR_BOTTOM_OFFSET)
  editframe.ActionBar:SetPoint("BOTTOMRIGHT", editframe.frame, "BOTTOMRIGHT", -EDITOR_ACTION_BAR_SIDE_INSET, EDITOR_ACTION_BAR_BOTTOM_OFFSET)

  editframe.ActionButtonOrder = {
    createEditorActionButton(L["Save"], saveCurrentSequence),
    createEditorActionButton(L["Delete"], function() GSE.GUIDeleteSequence(editframe.ClassID, editframe.SequenceName) end),
    createEditorActionButton(L["Send"], function() GSE.GUIShowTransmissionGui(editframe.ClassID .. "," .. editframe.SequenceName) end),
    createEditorActionButton(L["Options"], function() GSE.OpenOptionsPanel() end),
    createEditorActionButton(L["Close"] or CLOSE, function() editframe:Hide() end),
  }

  applyNativeBoardButtonSkin(editframe.ActionButtonOrder[1], "primary", false)
  applyNativeBoardButtonSkin(editframe.ActionButtonOrder[2], "danger", false)
  applyNativeBoardButtonSkin(editframe.ActionButtonOrder[3], "secondary", false)
  applyNativeBoardButtonSkin(editframe.ActionButtonOrder[4], "secondary", false)
  applyNativeBoardButtonSkin(editframe.ActionButtonOrder[5], "section", false)

  layoutEditorActionBar()
end

local function refreshSelectedEditorTab()
  if editframe.ContentContainer then
    local selectedGroup = getSelectedEditorTab()
    updateSectionButtonStates(selectedGroup)
    if editframe.ContentContainer.SetTitle then
      editframe.ContentContainer:SetTitle(getEditorSectionTitle(selectedGroup))
      if editframe.ContentContainer.titletext then
        editframe.ContentContainer.titletext:SetTextColor(1.0, 0.86, 0.30)
      end
    end
  end
end

local function configureEditorFrameFooter()
  applyEditorFrameSkin()
  local children = { editframe.frame:GetChildren() }
  for _, child in ipairs(children) do
    if child and child.GetObjectType and child:GetObjectType() == "Button" then
      local text = child.GetText and child:GetText()
      if text == CLOSE then
        editframe.FooterCloseButton = child
      else
        editframe.FooterStatusBar = child
      end
    end
  end

  if editframe.FooterCloseButton then
    editframe.FooterCloseButton:Hide()
    editframe.FooterCloseButton:EnableMouse(false)
  end

  if editframe.FooterStatusBar then
    editframe.FooterStatusBar:ClearAllPoints()
    editframe.FooterStatusBar:SetPoint("BOTTOMLEFT", 15, 15)
    editframe.FooterStatusBar:SetPoint("BOTTOMRIGHT", -15, 15)
    applyBackdropStyle(editframe.FooterStatusBar, 0.08, 0.07, 0.05, 0.95, 0.42, 0.34, 0.12, 0.95)
  end

  ensureEditorActionBar()

  if editframe.content then
    editframe.content:ClearAllPoints()
    editframe.content:SetPoint("TOPLEFT", 17, -27)
    editframe.content:SetPoint("BOTTOMRIGHT", -17, EDITOR_CONTENT_BOTTOM_OFFSET)
    applyBackdropStyle(editframe.content, 0.03, 0.03, 0.03, 0.92, 0.24, 0.20, 0.10, 0.92)
  end

  layoutEditorActionBar()
end

editframe:SetCallback("OnShow", function()
  editframe.Left, editframe.Bottom, editframe.Width, editframe.Height = editframe.frame:GetBoundsRect()
  configureEditorFrameFooter()
  if editframe.updateTabGroupHeight then
    editframe.updateTabGroupHeight()
  end
  editframe:DoLayout()
  refreshSelectedEditorTab()
end)
editframe.frame:SetScript("OnSizeChanged", function ()
  if editframe.HandlingResize then
    return
  end
  editframe.HandlingResize = true
  editframe.Left, editframe.Bottom, editframe.Width, editframe.Height = editframe.frame:GetBoundsRect()
  local screenHeight = GetScreenHeight()
  local screenWidth = GetScreenWidth()
  local maxHeight = screenHeight - 40  -- Leave some space at top/bottom
  local maxWidth = screenWidth - 40    -- Leave some space at sides
  
  -- Get current position
  local top = editframe.frame:GetTop()
  local bottom = editframe.frame:GetBottom()
  local left = editframe.frame:GetLeft()
  local right = editframe.frame:GetRight()
  
  -- Check if we need to constrain the size or reposition
  local needsResize = false
  local needsMove = false
  local newHeight = editframe.Height
  local newWidth = editframe.Width
  
  if editframe.Height > maxHeight then
    newHeight = maxHeight
    needsResize = true
  end
  
  if editframe.Width > maxWidth then
    newWidth = maxWidth
    needsResize = true
  end
  
  -- Check if window is going off screen edges
  if top and top > screenHeight then
    needsMove = true
  end
  
  if bottom and bottom < 0 then
    needsMove = true
  end
  
  if left and left < 0 then
    needsMove = true
  end
  
  if right and right > screenWidth then
    needsMove = true
  end
  
  -- Apply constraints if needed
  if needsResize then
    editframe.frame:SetHeight(newHeight)
    editframe.frame:SetWidth(newWidth)
    editframe.Height = newHeight
    editframe.Width = newWidth
  end
  
  -- Reposition if off screen
  if needsMove then
    local newPoint = {}
    newPoint.x = math.min(math.max(left or 20, 20), screenWidth - newWidth - 20)
    newPoint.y = math.min(math.max(bottom or 20, 20), screenHeight - newHeight - 20)
    editframe.frame:ClearAllPoints()
    editframe.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", newPoint.x, newPoint.y)
  end

  configureEditorFrameFooter()

  -- Update TabGroup height and layout
  if editframe.updateTabGroupHeight then
    editframe.updateTabGroupHeight()
  end
  editframe:DoLayout()
  refreshSelectedEditorTab()
  editframe.HandlingResize = false
end)


local specdropdownvalue = editframe.SpecID


function GSE.GUICreateEditorTabs()
  local tabl = {
    {
      text=L["Configuration"],
      value="config"
    },
  }
  if editframe.Sequence.MacroVersions and type(editframe.Sequence.MacroVersions) == "table" then
    for k,v in ipairs(editframe.Sequence.MacroVersions) do
      local insline = {}
      insline.text = tostring(k)
      insline.value = tostring(k)
      table.insert(tabl, insline)
    end
  end
  table.insert(tabl,   {
      text=L["New"],
      value="new"
    }  )
  return tabl
end

function GSE.GUIEditorPerformLayout(frame)
  frame:ReleaseChildren()
  local displayedSequenceName = editframe.PendingSequenceName
  if GSE.isEmpty(displayedSequenceName) then
    displayedSequenceName = editframe.SequenceName
  end
  if GSE.isEmpty(displayedSequenceName) and not GSE.isEmpty(editframe.OriginalSequenceName) then
    displayedSequenceName = editframe.OriginalSequenceName
    editframe.SequenceName = displayedSequenceName
  end
  editframe.PendingSequenceName = displayedSequenceName
  local headerGroup = AceGUI:Create("SimpleGroup")
  headerGroup:SetFullWidth(true)
  headerGroup:SetLayout("Flow")

  local nameeditbox = AceGUI:Create("EditBox")
  nameeditbox:SetLabel(L["Sequence Name"])
  nameeditbox:SetWidth(320)
  nameeditbox:SetCallback("OnTextChanged", function(widget, _, value)
    if editframe.SuppressNameChange then
      return
    end
    editframe.PendingSequenceName = value
    editframe.SequenceName = value
  end)
  nameeditbox:DisableButton( true)
  editframe.SuppressNameChange = true
  nameeditbox:SetText(displayedSequenceName or "")
  editframe.SuppressNameChange = false
  editframe.nameeditbox = nameeditbox
  headerGroup:AddChild(nameeditbox)

  local iconpicker = AceGUI:Create("Icon")
  iconpicker:SetLabel(L["Macro Icon"])
  iconpicker.frame:RegisterForDrag("LeftButton")
  iconpicker.frame:SetScript("OnDragStart", function()
    if not GSE.isEmpty(editframe.SequenceName) then
      PickupMacro(editframe.SequenceName)
    end
  end)
  iconpicker:SetImage(GSEOptions.DefaultDisabledMacroIcon)
  headerGroup:AddChild(iconpicker)
  editframe.iconpicker = iconpicker

  local macroSummary = AceGUI:Create("Label")
  macroSummary:SetWidth(220)
  macroSummary:SetText(string.format("Versions: %d   Default: %d", table.getn(editframe.Sequence.MacroVersions or {}), tonumber(editframe.Sequence.Default) or 1))
  macroSummary:SetColor(1.0, 0.88, 0.35)
  macroSummary:SetFontObject(GameFontNormal)
  headerGroup:AddChild(macroSummary)

  frame:AddChild(headerGroup)

  local selectedSection = getSelectedEditorTab()
  local workspaceGroup = AceGUI:Create("SimpleGroup")
  workspaceGroup:SetFullWidth(true)
  workspaceGroup:SetLayout("Flow")
  editframe.SectionButtons = {}
  editframe.SectionDropdown = nil

  local function addSectionButton(text, value, width, style)
    local button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetWidth(width)
    button.BoardButtonStyle = style or "section"
    button:SetCallback("OnClick", function()
      if editframe.ContentContainer and editframe.ContentContainer.SelectTab then
        editframe.ContentContainer:SelectTab(value)
      end
    end)
    applyAceBoardButtonSkin(button, button.BoardButtonStyle, tostring(value) == tostring(selectedSection))
    editframe.SectionButtons[tostring(value)] = button
    workspaceGroup:AddChild(button)
  end

  addSectionButton(L["Configuration"], "config", 125, "section")
  if editframe.Sequence and editframe.Sequence.MacroVersions and type(editframe.Sequence.MacroVersions) == "table" then
    for versionIndex in ipairs(editframe.Sequence.MacroVersions) do
      addSectionButton(string.format("V%d", versionIndex), tostring(versionIndex), 60, "section")
    end
  end

  local newVersionButton = AceGUI:Create("Button")
  newVersionButton:SetText(L["New"])
  newVersionButton:SetWidth(80)
  newVersionButton.BoardButtonStyle = "primary"
  newVersionButton:SetCallback("OnClick", function()
    addEditorMacroVersion()
  end)
  applyAceBoardButtonSkin(newVersionButton, "primary", false)
  workspaceGroup:AddChild(newVersionButton)

  if tonumber(selectedSection) then
    local toggleRulesButton = AceGUI:Create("Button")
    toggleRulesButton:SetText(shouldShowVersionOptions(selectedSection) and "Hide Rules" or "Show Rules")
    toggleRulesButton:SetWidth(100)
    toggleRulesButton.BoardButtonStyle = "secondary"
    toggleRulesButton:SetCallback("OnClick", function()
      setVersionOptionsVisible(selectedSection, not shouldShowVersionOptions(selectedSection))
      editframe.SelectedTab = selectedSection
      GSE.GUIEditorPerformLayout(editframe)
    end)
    applyAceBoardButtonSkin(toggleRulesButton, "secondary", false)
    workspaceGroup:AddChild(toggleRulesButton)

    local deleteVersionButton = AceGUI:Create("Button")
    deleteVersionButton:SetText(L["Delete"])
    deleteVersionButton:SetWidth(80)
    deleteVersionButton.BoardButtonStyle = "danger"
    deleteVersionButton:SetCallback("OnClick", function()
      GSE.GUIDeleteVersion(tonumber(selectedSection))
    end)
    applyAceBoardButtonSkin(deleteVersionButton, "danger", false)
    workspaceGroup:AddChild(deleteVersionButton)
  end

  frame:AddChild(workspaceGroup)

  local contentHost = AceGUI:Create("InlineGroup")
  contentHost:SetTitle(getEditorSectionTitle(selectedSection))
  contentHost:SetFullWidth(true)
  contentHost:SetLayout("Fill")
  if contentHost.border then
    applyBackdropStyle(contentHost.border, 0.07, 0.07, 0.08, 0.92, 0.54, 0.43, 0.15, 0.98)
  end
  if contentHost.titletext then
    contentHost.titletext:SetTextColor(1.0, 0.86, 0.30)
  end
  contentHost.SelectTab = function(self, group)
    local requestedGroup = group and tostring(group) or "config"
    if editframe.RenderingTab then
      return
    end
    editframe.SelectedTab = requestedGroup
    GSE.GUISelectEditorTab(self, "SelectTab", group)
  end
  editframe.ContentContainer = contentHost

  local function updateTabGroupHeight()
    local availableHeight = getEditorContentHeight() - 120
    if availableHeight <= 0 then
      availableHeight = editframe.Height - 220
    end
    contentHost:SetHeight(math.max(320, availableHeight))
  end
  updateTabGroupHeight()
  editframe.updateTabGroupHeight = updateTabGroupHeight

  frame:AddChild(contentHost)
  contentHost:SelectTab(selectedSection)
end

function GSE.GetVersionList()
  local tabl = {}
  classid = tonumber(classid)
  if editframe and editframe.Sequence and editframe.Sequence.MacroVersions and type(editframe.Sequence.MacroVersions) == "table" then
    for k,v in ipairs(editframe.Sequence.MacroVersions) do
      tabl[tostring(k)] = tostring(k)
    end
  end
  return tabl
end

function GSE:GUIDrawMetadataEditor(container)
  editframe.iconpicker:SetImage(GSE.GetMacroIcon(editframe.ClassID, editframe.SequenceName))

  editframe.ConfigScrollStatus = editframe.ConfigScrollStatus or {}

  local contentcontainer = AceGUI:Create("ScrollFrame")
  contentcontainer:SetFullWidth(true)
  contentcontainer:SetLayout("Flow")
  contentcontainer:SetHeight(getEditorTabBodyHeight(container, 140))
  contentcontainer:SetStatusTable(editframe.ConfigScrollStatus)

  local contentWidth = getEditorContainerWidth(container, 30)
  local columnWidth = math.max(180, math.floor((contentWidth - 36) / 3))
  local assignmentWidth = math.max(180, math.floor((contentWidth - 24) / 3))

  addEditorHeading(contentcontainer, "Macro Details")

  local detailsGroup = AceGUI:Create("SimpleGroup")
  detailsGroup:SetLayout("Flow")
  detailsGroup:SetWidth(contentWidth)

  local speciddropdown = AceGUI:Create("Dropdown")
  speciddropdown:SetLabel(L["Specialisation / Class ID"])
  speciddropdown:SetWidth(columnWidth)
  speciddropdown:SetList(GSE.GetSpecNames())
  speciddropdown:SetCallback("OnValueChanged", function (obj,event,key)
    local sid = Statics.SpecIDHashList[key]
    specdropdownvalue = key
    editframe.SpecID = sid
    editframe.Sequence.SpecID = sid

    if tonumber(sid) > 12 then
      editframe.ClassID = GSE.GetClassIDforSpec(tonumber(sid))
    else
      editframe.ClassID = tonumber(sid)
    end
  end)
  speciddropdown:SetValue(Statics.wotlkSpecIDList[editframe.Sequence.SpecID])
  detailsGroup:AddChild(speciddropdown)

  local talentseditbox = AceGUI:Create("EditBox")
  talentseditbox:SetLabel(L["Talents"])
  talentseditbox:SetWidth(columnWidth)
  talentseditbox:DisableButton(true)
  talentseditbox:SetText(editframe.Sequence.Talents)
  talentseditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Talents = key
  end)
  detailsGroup:AddChild(talentseditbox)

  local authoreditbox = AceGUI:Create("EditBox")
  authoreditbox:SetLabel(L["Author"])
  authoreditbox:SetWidth(columnWidth)
  authoreditbox:DisableButton(true)
  if not GSE.isEmpty(editframe.Sequence.Author) then
    authoreditbox:SetText(editframe.Sequence.Author)
  end
  authoreditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Author = key
  end)
  detailsGroup:AddChild(authoreditbox)
  contentcontainer:AddChild(detailsGroup)

  addEditorHeading(contentcontainer, "Notes")

  local helpeditbox = AceGUI:Create("MultiLineEditBox")
  helpeditbox:SetLabel(L["Help Information"])
  helpeditbox:SetWidth(contentWidth)
  helpeditbox:DisableButton(true)
  helpeditbox:SetNumLines(3)
  helpeditbox:SetFullWidth(true)
  if not GSE.isEmpty(editframe.Sequence.Help) then
    helpeditbox:SetText(editframe.Sequence.Help)
  end
  helpeditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Help = key
  end)
  contentcontainer:AddChild(helpeditbox)

  local helplinkeditbox = AceGUI:Create("EditBox")
  helplinkeditbox:SetLabel(L["Help Link"])
  helplinkeditbox:SetWidth(contentWidth)
  helplinkeditbox:DisableButton(true)
  if not GSE.isEmpty(editframe.Sequence.Helplink) then
    helplinkeditbox:SetText(editframe.Sequence.Helplink)
  end
  helplinkeditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Helplink = key
  end)
  contentcontainer:AddChild(helplinkeditbox)

  addEditorHeading(contentcontainer, "Version Defaults")

  local assignmentRow1 = AceGUI:Create("SimpleGroup")
  assignmentRow1:SetLayout("Flow")
  assignmentRow1:SetWidth(contentWidth)

  local defaultdropdown = AceGUI:Create("Dropdown")
  defaultdropdown:SetLabel(L["Default Version"])
  defaultdropdown:SetWidth(assignmentWidth)
  defaultdropdown:SetList(GSE.GetVersionList())
  defaultdropdown:SetValue(tostring(editframe.Default))
  defaultdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    editframe.Sequence.Default = tonumber(key)
    editframe.Default = tonumber(key)
  end)
  assignmentRow1:AddChild(defaultdropdown)

  local raiddropdown = AceGUI:Create("Dropdown")
  raiddropdown:SetLabel(L["Raid"])
  raiddropdown:SetWidth(assignmentWidth)
  raiddropdown:SetList(GSE.GetVersionList())
  raiddropdown:SetValue(tostring(editframe.Raid))
  raiddropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Raid = nil
    else
      editframe.Sequence.Raid = tonumber(key)
      editframe.Raid = tonumber(key)
    end
  end)
  assignmentRow1:AddChild(raiddropdown)

  local mythicdropdown = AceGUI:Create("Dropdown")
  mythicdropdown:SetLabel(L["Mythic"])
  mythicdropdown:SetWidth(assignmentWidth)
  mythicdropdown:SetList(GSE.GetVersionList())
  mythicdropdown:SetValue(tostring(editframe.Mythic))
  mythicdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Mythic = nil
    else
      editframe.Sequence.Mythic = tonumber(key)
      editframe.Mythic = tonumber(key)
    end
  end)
  assignmentRow1:AddChild(mythicdropdown)
  contentcontainer:AddChild(assignmentRow1)

  local assignmentRow2 = AceGUI:Create("SimpleGroup")
  assignmentRow2:SetLayout("Flow")
  assignmentRow2:SetWidth(contentWidth)

  local pvpdropdown = AceGUI:Create("Dropdown")
  pvpdropdown:SetLabel(L["PVP"])
  pvpdropdown:SetWidth(assignmentWidth)
  pvpdropdown:SetList(GSE.GetVersionList())
  pvpdropdown:SetValue(tostring(editframe.PVP))
  pvpdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.PVP = nil
    else
      editframe.Sequence.PVP = tonumber(key)
      editframe.PVP = tonumber(key)
    end
  end)
  assignmentRow2:AddChild(pvpdropdown)

  local dungeondropdown = AceGUI:Create("Dropdown")
  dungeondropdown:SetLabel(L["Dungeon"])
  dungeondropdown:SetWidth(assignmentWidth)
  dungeondropdown:SetList(GSE.GetVersionList())
  dungeondropdown:SetValue(tostring(editframe.Dungeon))
  dungeondropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Dungeon = nil
    else
      editframe.Sequence.Dungeon = tonumber(key)
      editframe.Dungeon = tonumber(key)
    end
  end)
  assignmentRow2:AddChild(dungeondropdown)

  local heroicdropdown = AceGUI:Create("Dropdown")
  heroicdropdown:SetLabel(L["Heroic"])
  heroicdropdown:SetWidth(assignmentWidth)
  heroicdropdown:SetList(GSE.GetVersionList())
  heroicdropdown:SetValue(tostring(editframe.Heroic))
  heroicdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Heroic = nil
    else
      editframe.Sequence.Heroic = tonumber(key)
      editframe.Heroic = tonumber(key)
    end
  end)
  assignmentRow2:AddChild(heroicdropdown)
  contentcontainer:AddChild(assignmentRow2)

  local assignmentRow3 = AceGUI:Create("SimpleGroup")
  assignmentRow3:SetLayout("Flow")
  assignmentRow3:SetWidth(contentWidth)

  local partydropdown = AceGUI:Create("Dropdown")
  partydropdown:SetLabel(L["Party"])
  partydropdown:SetWidth(assignmentWidth)
  partydropdown:SetList(GSE.GetVersionList())
  partydropdown:SetValue(tostring(editframe.Party))
  partydropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Party = nil
    else
      editframe.Sequence.Party = tonumber(key)
      editframe.Party = tonumber(key)
    end
  end)
  assignmentRow3:AddChild(partydropdown)
  contentcontainer:AddChild(assignmentRow3)

  container:AddChild(contentcontainer)
end

function GSE:GUIDrawMacroEditor(container, version)
  version = tonumber(version)
  if GSE.isEmpty(editframe.Sequence.MacroVersions[version]) then
    editframe.Sequence.MacroVersions[version] = {}
    editframe.Sequence.MacroVersions[version].PreMacro = {}
    editframe.Sequence.MacroVersions[version].PostMacro = {}
    editframe.Sequence.MacroVersions[version].KeyPress = {}
    editframe.Sequence.MacroVersions[version].KeyRelease = {}
    editframe.Sequence.MacroVersions[version].StepFunction = "Sequential"
    editframe.Sequence.MacroVersions[version][1] = "/say Hello"
  end

  editframe.Sequence.MacroVersions[version] = GSE.TranslateSequence(editframe.Sequence.MacroVersions[version], "From Editor")

  local versionData = editframe.Sequence.MacroVersions[version]
  editframe.VersionScrollStatus = editframe.VersionScrollStatus or {}
  editframe.VersionScrollStatus[version] = editframe.VersionScrollStatus[version] or {}

  local contentcontainer = AceGUI:Create("ScrollFrame")
  contentcontainer:SetFullWidth(true)
  contentcontainer:SetLayout("Flow")
  contentcontainer:SetHeight(getEditorTabBodyHeight(container, 140))
  contentcontainer:SetStatusTable(editframe.VersionScrollStatus[version])

  local contentWidth = getEditorContainerWidth(container, 30)
  local pairWidth = math.max(220, math.floor((contentWidth - 14) / 2))
  local showVersionOptions = shouldShowVersionOptions(version)

  local function addVersionCheckbox(parent, label, field, width)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetType("checkbox")
    checkbox:SetWidth(width or 95)
    checkbox:SetTriState(true)
    checkbox:SetLabel(label)
    checkbox:SetValue(versionData[field])
    checkbox:SetCallback("OnValueChanged", function (sel, object, value)
      versionData[field] = value
    end)
    parent:AddChild(checkbox)
  end

  local controlsGroup = AceGUI:Create("SimpleGroup")
  controlsGroup:SetLayout("Flow")
  controlsGroup:SetWidth(contentWidth)

  local stepdropdown = AceGUI:Create("Dropdown")
  stepdropdown:SetLabel(L["Step Function"])
  stepdropdown:SetWidth(math.max(220, pairWidth))
  stepdropdown:SetList({
    ["Sequential"] = L["Sequential (1 2 3 4)"],
    ["Priority"] = L["Priority List (1 12 123 1234)"],
  })
  if GSE.isEmpty(versionData.StepFunction) then
    versionData.StepFunction = "Sequential"
  end
  stepdropdown:SetValue(versionData.StepFunction)
  stepdropdown:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.StepFunction = value
  end)
  controlsGroup:AddChild(stepdropdown)

  local looplimit = AceGUI:Create("EditBox")
  looplimit:SetLabel(L["Inner Loop Limit"])
  looplimit:DisableButton(true)
  looplimit:SetMaxLetters(4)
  looplimit:SetWidth(120)
  if not GSE.isEmpty(versionData.LoopLimit) then
    looplimit:SetText(tonumber(versionData.LoopLimit))
  end
  looplimit.editbox:SetNumeric()
  looplimit:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.LoopLimit = value
  end)
  controlsGroup:AddChild(looplimit)
  contentcontainer:AddChild(controlsGroup)

  addEditorHeading(contentcontainer, "Sequence")

  local spellbox = AceGUI:Create("MultiLineEditBox")
  spellbox:SetLabel(L["Sequence"])
  spellbox:SetNumLines(14)
  spellbox:DisableButton(true)
  spellbox:SetWidth(contentWidth)
  spellbox:SetFullWidth(true)
  spellbox.editBox:SetScript("OnLeave", function() GSE.GUIParseText(spellbox) end)
  if not GSE.isEmpty(versionData) then
    spellbox:SetText(table.concat(versionData, "\n"))
  end
  spellbox:SetCallback("OnTextChanged", function (sel, object, value)
    if versionData and type(versionData) == "table" then
      for index in ipairs(versionData) do
        versionData[index] = nil
      end
    end
    local newpairs = GSE.SplitMeIntolines(value)
    for index, line in ipairs(newpairs) do
      versionData[index] = line
    end
  end)
  contentcontainer:AddChild(spellbox)

  addEditorHeading(contentcontainer, "Execution Blocks")

  local linegroup1 = AceGUI:Create("SimpleGroup")
  linegroup1:SetLayout("Flow")
  linegroup1:SetWidth(contentWidth)

  local KeyPressbox = AceGUI:Create("MultiLineEditBox")
  KeyPressbox:SetLabel(L["KeyPress"])
  KeyPressbox:SetNumLines(3)
  KeyPressbox:DisableButton(true)
  KeyPressbox:SetWidth(pairWidth)
  KeyPressbox.editBox:SetScript("OnLeave", function() GSE.GUIParseText(KeyPressbox) end)
  if not GSE.isEmpty(versionData.KeyPress) then
    KeyPressbox:SetText(table.concat(versionData.KeyPress, "\n"))
  end
  KeyPressbox:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.KeyPress = GSE.SplitMeIntolines(value)
  end)
  linegroup1:AddChild(KeyPressbox)

  local PreMacro = AceGUI:Create("MultiLineEditBox")
  PreMacro:SetLabel(L["PreMacro"])
  PreMacro:SetNumLines(3)
  PreMacro:DisableButton(true)
  PreMacro:SetWidth(pairWidth)
  PreMacro.editBox:SetScript("OnLeave", function() GSE.GUIParseText(PreMacro) end)
  if not GSE.isEmpty(versionData.PreMacro) then
    PreMacro:SetText(table.concat(versionData.PreMacro, "\n"))
  end
  PreMacro:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.PreMacro = GSE.SplitMeIntolines(value)
  end)
  linegroup1:AddChild(PreMacro)
  contentcontainer:AddChild(linegroup1)

  local linegroup2 = AceGUI:Create("SimpleGroup")
  linegroup2:SetLayout("Flow")
  linegroup2:SetWidth(contentWidth)

  local KeyReleasebox = AceGUI:Create("MultiLineEditBox")
  KeyReleasebox:SetLabel(L["KeyRelease"])
  KeyReleasebox:SetNumLines(3)
  KeyReleasebox:DisableButton(true)
  KeyReleasebox:SetWidth(pairWidth)
  KeyReleasebox.editBox:SetScript("OnLeave", function() GSE.GUIParseText(KeyReleasebox) end)
  if not GSE.isEmpty(versionData.KeyRelease) then
    KeyReleasebox:SetText(table.concat(versionData.KeyRelease, "\n"))
  end
  KeyReleasebox:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.KeyRelease = GSE.SplitMeIntolines(value)
  end)
  linegroup2:AddChild(KeyReleasebox)

  local PostMacro = AceGUI:Create("MultiLineEditBox")
  PostMacro:SetLabel(L["PostMacro"])
  PostMacro:SetNumLines(3)
  PostMacro:DisableButton(true)
  PostMacro:SetWidth(pairWidth)
  PostMacro.editBox:SetScript("OnLeave", function() GSE.GUIParseText(PostMacro) end)
  if not GSE.isEmpty(versionData.PostMacro) then
    PostMacro:SetText(table.concat(versionData.PostMacro, "\n"))
  end
  PostMacro:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.PostMacro = GSE.SplitMeIntolines(value)
  end)
  linegroup2:AddChild(PostMacro)
  contentcontainer:AddChild(linegroup2)

  if showVersionOptions then
    addEditorHeading(contentcontainer, "Optional Rules")

    local resetGroup = AceGUI:Create("SimpleGroup")
    resetGroup:SetLayout("Flow")
    resetGroup:SetWidth(contentWidth)

    local resetLabel = AceGUI:Create("Label")
    resetLabel:SetWidth(140)
    resetLabel:SetText(L["Resets"])
    resetGroup:AddChild(resetLabel)
    addVersionCheckbox(resetGroup, L["Combat"], "Combat", 120)
    contentcontainer:AddChild(resetGroup)

    local useGroup = AceGUI:Create("SimpleGroup")
    useGroup:SetLayout("Flow")
    useGroup:SetWidth(contentWidth)

    local useLabel = AceGUI:Create("Label")
    useLabel:SetWidth(140)
    useLabel:SetText(L["Use"])
    useGroup:AddChild(useLabel)
    addVersionCheckbox(useGroup, L["Head"], "Head", 95)
    addVersionCheckbox(useGroup, L["Neck"], "Neck", 95)
    addVersionCheckbox(useGroup, L["Belt"], "Belt", 95)
    addVersionCheckbox(useGroup, L["Ring 1"], "Ring1", 95)
    addVersionCheckbox(useGroup, L["Ring 2"], "Ring2", 95)
    addVersionCheckbox(useGroup, L["Trinket 1"], "Trinket1", 95)
    addVersionCheckbox(useGroup, L["Trinket 2"], "Trinket2", 95)
    contentcontainer:AddChild(useGroup)
  end

  container:AddChild(contentcontainer)
end

function GSE.GUISelectEditorTab(container, event, group)
  if editframe.RenderingTab then
    return
  end
  editframe.RenderingTab = true
  container:ReleaseChildren()
  local selectedGroup = group and tostring(group) or "config"
  editframe.SelectedTab = selectedGroup
  selectedGroup = getSelectedEditorTab()
  editframe.SelectedTab = selectedGroup
  if GSE.isEmpty(GSE.GUIEditFrame.PendingSequenceName) and not GSE.isEmpty(GSE.GUIEditFrame.OriginalSequenceName) then
    GSE.GUIEditFrame.PendingSequenceName = GSE.GUIEditFrame.OriginalSequenceName
  end
  if GSE.isEmpty(GSE.GUIEditFrame.SequenceName) and not GSE.isEmpty(GSE.GUIEditFrame.PendingSequenceName) then
    GSE.GUIEditFrame.SequenceName = GSE.GUIEditFrame.PendingSequenceName
  end
  editframe.SuppressNameChange = true
  editframe.nameeditbox:SetText(GSE.GUIEditFrame.PendingSequenceName or GSE.GUIEditFrame.SequenceName)
  editframe.SuppressNameChange = false
  editframe.iconpicker:SetImage(GSE.GetMacroIcon(editframe.ClassID, editframe.SequenceName))
  updateSectionButtonStates(selectedGroup)
  if container.SetTitle then
    container:SetTitle(getEditorSectionTitle(selectedGroup))
    if container.titletext then
      container.titletext:SetTextColor(1.0, 0.86, 0.30)
    end
  end
  if selectedGroup == "config" then
    GSE:GUIDrawMetadataEditor(container)
  elseif selectedGroup == "new" then
    addEditorMacroVersion()
  else
    GSE:GUIDrawMacroEditor(container, selectedGroup)
  end
  editframe.RenderingTab = false

end

function GSE.GUIDeleteVersion(version)
  version = tonumber(version)
  local sequence = editframe.Sequence
  if table.getn(sequence.MacroVersions) <= 1 then
    GSE.Print(L["This is the only version of this macro.  Delete the entire macro to delete this version."])
    return
  end
  if sequence.Default == version then
    GSE.Print(L["You cannot delete the Default version of this macro.  Please choose another version to be the Default on the Configuration tab."])
    return
  end
  local printtext = L["Macro Version %d deleted."]
  if sequence.PVP == version then
    sequence.PVP = sequence.Default
    printtext = printtext .. " " .. L["PVP setting changed to Default."]
  end
  if sequence.Raid == version then
    sequence.Raid = sequence.Default
    printtext = printtext .. " " .. L["Raid setting changed to Default."]
  end
  if sequence.Mythic == version then
    sequence.Mythic = sequence.Default
    printtext = printtext .. " " .. L["Mythic setting changed to Default."]
  end
  if sequence.Heroic == version then
    sequence.Heroic = sequence.Default
    printtext = printtext .. " " .. L["Heroic setting changed to Default."]
  end
  if sequence.Dungeon == version then
    sequence.Dungeon = sequence.Default
    printtext = printtext .. " " .. L["Dungeon setting changed to Default."]
  end
  if sequence.Party == version then
    sequence.Party = sequence.Default
    printtext = printtext .. " " .. L["Party setting changed to Default."]
  end

  if sequence.Default > 1 then
    sequence.Default = tonumber(sequence.Default) - 1
  else
    sequence.Default = 1
  end

  if not GSE.isEmpty(sequence.PVP) then
    sequence.PVP = tonumber(sequence.PVP) - 1
  end
  if not GSE.isEmpty(sequence.Raid) then
    sequence.Raid = tonumber(sequence.Raid) - 1
  end
  if not GSE.isEmpty(sequence.Mythic) then
    sequence.Mythic = tonumber(sequence.Mythic) - 1
  end
  table.remove(sequence.MacroVersions, version)
  printtext = printtext .. " " .. L["This change will not come into effect until you save this macro."]
  GSE.GUIEditorPerformLayout(editframe)
  GSE.GUIEditFrame.ContentContainer:SelectTab("config")
  GSE.GUIEditFrame:SetStatusText(string.format(printtext, version))
end
