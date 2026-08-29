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

local EDITOR_ACTION_BAR_SIDE_INSET = 15
local EDITOR_ACTION_BAR_BOTTOM_OFFSET = 17
local EDITOR_ACTION_BAR_HEIGHT = 20
local EDITOR_ACTION_BAR_SPACING = 6
local EDITOR_ACTION_BAR_MIN_BUTTON_WIDTH = 88
local EDITOR_ACTION_BAR_MAX_BUTTON_WIDTH = 132

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
local function getEditorMaxHeight()
  return math.min(GetScreenHeight() - 80, 700)
end

local function getEditorMaxWidth()
  return GetScreenWidth() - 80
end

local function getEditorDefaultWidth()
  return math.min(getEditorMaxWidth(), 860)
end

local maxHeight = getEditorMaxHeight()
local maxWidth = getEditorMaxWidth()
local defaultHeight = maxHeight
local defaultWidth = getEditorDefaultWidth()
editframe.frame:SetMaxResize(maxWidth, maxHeight)
-- Set minimum size to prevent content overflow
editframe.frame:SetMinResize(600, 420)
editframe:SetCallback("OnShow", function()
  local currentMaxHeight = getEditorMaxHeight()
  local currentMaxWidth = getEditorMaxWidth()
  editframe.frame:SetMaxResize(currentMaxWidth, currentMaxHeight)
  if editframe.frame:GetHeight() <= 0 or editframe.frame:GetHeight() > currentMaxHeight then
    editframe.frame:SetHeight(math.min(defaultHeight, currentMaxHeight))
  end
  if editframe.frame:GetWidth() <= 0 or editframe.frame:GetWidth() > currentMaxWidth then
    editframe.frame:SetWidth(math.min(defaultWidth, currentMaxWidth))
  end
  if editframe.RefreshEditorShell then
    editframe.RefreshEditorShell()
  end
  if editframe.AutoFocusSequenceName and editframe.nameeditbox and editframe.nameeditbox.editbox then
    editframe.nameeditbox.editbox:SetFocus()
    editframe.nameeditbox.editbox:HighlightText()
    editframe.AutoFocusSequenceName = false
  end
end)
editframe.frame:SetScript("OnSizeChanged", function ()
  if editframe.HandlingResize then
    return
  end
  editframe.HandlingResize = true
  editframe.Left, editframe.Bottom, editframe.Width, editframe.Height = editframe.frame:GetBoundsRect()
  local screenHeight = GetScreenHeight()
  local screenWidth = GetScreenWidth()
  local maxHeight = math.min(screenHeight - 80, 700)
  local maxWidth = screenWidth - 80
  
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
  
  -- Update TabGroup height and layout
  if editframe.updateTabGroupHeight then
    editframe.updateTabGroupHeight()
  end
  editframe:DoLayout()
  
  -- Trigger a layout refresh on the TabGroup's content
  if editframe.ContentContainer and editframe.ContentContainer.LayoutFinished then
    editframe.ContentContainer:Fire("OnHeightSet")
  end
  if editframe.ActiveViewport and editframe.ActiveViewport.SetHeight then
    local contentHeight = 0
    if editframe.ContentContainer and editframe.ContentContainer.content and editframe.ContentContainer.content.GetHeight then
      contentHeight = editframe.ContentContainer.content:GetHeight() or 0
    end
    if contentHeight <= 0 then
      contentHeight = editframe.Height - 240
    end
    editframe.ActiveViewport:SetHeight(math.max(280, contentHeight - 12))
  end
  if editframe.RefreshEditorShell then
    editframe.RefreshEditorShell()
  end
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

local function getEditorTabViewportHeight(container)
  local contentHeight = 0
  if container and container.content and container.content.GetHeight then
    contentHeight = container.content:GetHeight() or 0
  end
  if contentHeight <= 0 then
    contentHeight = editframe.Height - 240
  end
  return math.max(280, contentHeight - 12)
end

local function getEditorTabViewportWidth(container)
  local contentWidth = 0
  if container and container.content and container.content.GetWidth then
    contentWidth = container.content:GetWidth() or 0
  end
  if contentWidth <= 0 then
    contentWidth = editframe.Width - 80
  end
  return math.max(520, contentWidth - 12)
end

local function createEditorTabScrollPage(container, statusTable)
  local viewportHeight = getEditorTabViewportHeight(container)
  local viewportWidth = getEditorTabViewportWidth(container)
  local pageWidth = math.max(500, math.min(640, viewportWidth - 24))

  local viewport = AceGUI:Create("SimpleGroup")
  viewport:SetFullWidth(true)
  viewport:SetHeight(viewportHeight)
  viewport:SetLayout("Fill")

  local scrollframe = AceGUI:Create("ScrollFrame")
  scrollframe:SetLayout("Flow")
  scrollframe:SetFullWidth(true)
  if scrollframe.SetAutoAdjustHeight then
    scrollframe:SetAutoAdjustHeight(false)
  end
  if statusTable then
    scrollframe:SetStatusTable(statusTable)
  end
  viewport:AddChild(scrollframe)

  local page = AceGUI:Create("SimpleGroup")
  page:SetLayout("Flow")
  page:SetWidth(pageWidth)
  scrollframe:AddChild(page)

  container:AddChild(viewport)
  editframe.ActiveViewport = viewport
  editframe.ActiveScrollWidget = scrollframe

  return page, pageWidth, scrollframe
end

local function forwardActiveEditorScroll(delta)
  local scrollWidget = editframe.ActiveScrollWidget
  if scrollWidget and scrollWidget.MoveScroll then
    scrollWidget:MoveScroll(delta)
  end
end

local function hookEditorWheelFrame(frame)
  if not frame or frame == editframe.ActiveScrollWidget or frame.GSEEditorWheelHooked or not frame.HookScript then
    return
  end
  if frame.EnableMouseWheel then
    frame:EnableMouseWheel(true)
  end
  frame:HookScript("OnMouseWheel", function(_, delta)
    forwardActiveEditorScroll(delta)
  end)
  frame.GSEEditorWheelHooked = true
end

local function attachEditorWheelForwarding(frame, visited, skipFrame)
  if not frame or not frame.GetChildren then
    return
  end

  visited = visited or {}
  if visited[frame] then
    return
  end
  visited[frame] = true

  if frame ~= skipFrame then
    hookEditorWheelFrame(frame)
  end

  local children = { frame:GetChildren() }
  for _, child in ipairs(children) do
    attachEditorWheelForwarding(child, visited, skipFrame)
  end
end

local function bindActivePageWheelForwarding(container)
  local skipFrame = editframe.ActiveScrollWidget and editframe.ActiveScrollWidget.scrollframe
  local visited = {}
  if editframe.frame then
    attachEditorWheelForwarding(editframe.frame, visited, skipFrame)
  end
  if container and container.frame then
    attachEditorWheelForwarding(container.frame, visited, skipFrame)
  end
  if container and container.content then
    attachEditorWheelForwarding(container.content, visited, skipFrame)
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

local function getCurrentEditorSequenceName()
  -- The visible field is authoritative.  AceGUI can defer its change callback
  -- until focus changes, so saving must never prefer an older cached value.
  local sequenceName = ""
  if editframe.nameeditbox then
    sequenceName = editframe.nameeditbox:GetText()
  end
  if GSE.isEmpty(sequenceName) then
    sequenceName = editframe.PendingSequenceName
  end
  if GSE.isEmpty(sequenceName) then
    sequenceName = editframe.SequenceName
  end
  if GSE.isEmpty(sequenceName) and not GSE.isEmpty(editframe.OriginalSequenceName) then
    sequenceName = editframe.OriginalSequenceName
  end
  return sequenceName
end

local function saveCurrentSequence()
  editframe.Sequence.ManualIntervention = true
  local sequenceName = getCurrentEditorSequenceName()
  if GSE.isEmpty(sequenceName) and not GSE.isEmpty(editframe.OriginalSequenceName) then
    sequenceName = editframe.OriginalSequenceName
    if editframe.nameeditbox then
      editframe.SuppressNameChange = true
      editframe.nameeditbox:SetText(sequenceName)
      editframe.SuppressNameChange = false
    end
  end
  sequenceName = tostring(sequenceName or ""):gsub("^%s*(.-)%s*$", "%1")
  sequenceName = sequenceName:gsub(" ", "_"):gsub(",", "_")
  if editframe.nameeditbox and editframe.nameeditbox:GetText() ~= sequenceName then
    editframe.SuppressNameChange = true
    editframe.nameeditbox:SetText(sequenceName)
    editframe.SuppressNameChange = false
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
  if editframe.ContentContainer and editframe.ContentContainer.SelectTab then
    editframe.ContentContainer:SelectTab(newVersion)
  end
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
    createEditorActionButton(CLOSE, function() editframe:Hide() end),
  }

  layoutEditorActionBar()
end

local function configureEditorFrameFooter()
  local children = { editframe.frame:GetChildren() }
  for _, child in ipairs(children) do
    if child and child.GetObjectType and child:GetObjectType() == "Button" then
      local text = child.GetText and child:GetText()
      if text == CLOSE then
        editframe.FooterCloseButton = child
      elseif child.GetScript and child:GetScript("OnEnter") and child:GetScript("OnLeave") then
        editframe.FooterStatusBar = child
      end
    end
  end

  if editframe.FooterCloseButton then
    editframe.FooterCloseButton:Hide()
    editframe.FooterCloseButton:EnableMouse(false)
  end

  if editframe.FooterStatusBar then
    editframe.FooterStatusBar:Hide()
    editframe.FooterStatusBar:EnableMouse(false)
  end

  ensureEditorActionBar()
end

editframe.RefreshEditorShell = function()
  configureEditorFrameFooter()
end

function GSE.GUIEditorPerformLayout(frame)
  frame:ReleaseChildren()
  editframe.nameeditbox = nil
  editframe.iconpicker = nil
  editframe.ActiveViewport = nil
  local displayedSequenceName = editframe.PendingSequenceName
  if GSE.isEmpty(displayedSequenceName) then
    displayedSequenceName = editframe.SequenceName
  end
  if GSE.isEmpty(displayedSequenceName) and not GSE.isEmpty(editframe.OriginalSequenceName) then
    displayedSequenceName = editframe.OriginalSequenceName
    editframe.SequenceName = displayedSequenceName
  end
  editframe.PendingSequenceName = displayedSequenceName

  local tabgrp =  AceGUI:Create("TabGroup")
  tabgrp:SetLayout("Flow")
  tabgrp:SetTabs(GSE.GUICreateEditorTabs())
  editframe.ContentContainer = tabgrp


  tabgrp:SetCallback("OnGroupSelected",  function (container, event, group)
    GSE.GUISelectEditorTab(container, event, group)
  end)
  tabgrp:SetFullWidth(true)
  tabgrp.noAutoHeight = true
  local function updateTabGroupHeight()
    local availableHeight = getEditorContentHeight()
    if availableHeight <= 0 then
      availableHeight = editframe.Height - 180
    end
    tabgrp:SetHeight(math.max(320, availableHeight - 8))
  end
  updateTabGroupHeight()
  editframe.updateTabGroupHeight = updateTabGroupHeight

  frame:AddChild(tabgrp)
  tabgrp:SelectTab(getSelectedEditorTab())
  if editframe.RefreshEditorShell then
    editframe.RefreshEditorShell()
  end
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
  editframe.ConfigScrollStatus = editframe.ConfigScrollStatus or {}
  local page, pageWidth = createEditorTabScrollPage(container, editframe.ConfigScrollStatus)
  local pairWidth = math.max(240, math.floor((pageWidth - 16) / 2))

  local displayedSequenceName = getCurrentEditorSequenceName()

  local headergroup = AceGUI:Create("SimpleGroup")
  headergroup:SetLayout("Flow")
  headergroup:SetWidth(pageWidth)

  local nameeditbox = AceGUI:Create("EditBox")
  nameeditbox:SetLabel(L["Sequence Name"])
  nameeditbox:SetWidth(math.max(260, pageWidth - 110))
	-- Defend against another AceGUI copy returning a previously numeric-only widget.
  if nameeditbox.editbox and nameeditbox.editbox.SetNumeric then
    nameeditbox.editbox:SetNumeric(false)
  end
  nameeditbox:SetCallback("OnTextChanged", function(widget, _, value)
    if editframe.SuppressNameChange then
      return
    end
    editframe.PendingSequenceName = value
    editframe.SequenceName = value
  end)
  nameeditbox:DisableButton(true)
  editframe.SuppressNameChange = true
  nameeditbox:SetText(displayedSequenceName or "")
  editframe.SuppressNameChange = false
  if nameeditbox.editbox and nameeditbox.editbox.HookScript then
    nameeditbox.editbox:HookScript("OnMouseUp", function(widget)
      widget:SetFocus()
    end)
  end
  editframe.nameeditbox = nameeditbox
  headergroup:AddChild(nameeditbox)

  local iconpicker = AceGUI:Create("Icon")
  iconpicker:SetLabel(L["Macro Icon"])
  iconpicker:SetImageSize(64, 64)
  iconpicker.frame:RegisterForDrag("LeftButton")
  iconpicker.frame:SetScript("OnDragStart", function()
    local pickupSequenceName = editframe.OriginalSequenceName
    if GSE.isEmpty(pickupSequenceName) then
      pickupSequenceName = getCurrentEditorSequenceName()
    end
    if not GSE.isEmpty(pickupSequenceName) then
      PickupMacro(pickupSequenceName)
    end
  end)
  local iconSequenceName = editframe.OriginalSequenceName
  if GSE.isEmpty(iconSequenceName) then
    iconSequenceName = editframe.SequenceName
  end
  iconpicker:SetImage(GSE.GetMacroIcon(editframe.ClassID, iconSequenceName))
  editframe.iconpicker = iconpicker
  headergroup:AddChild(iconpicker)
  page:AddChild(headergroup)

  local metasimplegroup = AceGUI:Create("SimpleGroup")
  metasimplegroup:SetLayout("Flow")
  metasimplegroup:SetWidth(pageWidth)

  local speciddropdown = AceGUI:Create("Dropdown")
  speciddropdown:SetLabel(L["Specialisation / Class ID"])
  speciddropdown:SetWidth(pairWidth)
  speciddropdown:SetList(GSE.GetSpecNames())
  speciddropdown:SetCallback("OnValueChanged", function (obj,event,key)
    local sid = Statics.SpecIDHashList[key]
    specdropdownvalue = key;
    editframe.SpecID = sid
    editframe.Sequence.SpecID = sid

    if tonumber(sid) > 12 then
      editframe.ClassID = GSE.GetClassIDforSpec(tonumber(sid))
    else
      editframe.ClassID = tonumber(sid)
    end
  end)
  speciddropdown:SetValue(Statics.wotlkSpecIDList[editframe.Sequence.SpecID])
  metasimplegroup:AddChild(speciddropdown)

  local talentseditbox = AceGUI:Create("EditBox")
  talentseditbox:SetLabel(L["Talents"])
  talentseditbox:SetWidth(pairWidth)
  talentseditbox:DisableButton( true)
  metasimplegroup:AddChild(talentseditbox)
  talentseditbox:SetText(editframe.Sequence.Talents)
  talentseditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Talents = key
  end)
  page:AddChild(metasimplegroup)

  local helpgroup1 = AceGUI:Create("SimpleGroup")
  helpgroup1:SetLayout("Flow")
  helpgroup1:SetWidth(pageWidth)

  local helplinkeditbox = AceGUI:Create("EditBox")
  helplinkeditbox:SetLabel(L["Help Link"])
  helplinkeditbox:SetWidth(pairWidth)
  helplinkeditbox:DisableButton( true)
  if not GSE.isEmpty(editframe.Sequence.Helplink) then
    helplinkeditbox:SetText(editframe.Sequence.Helplink)
  end
  helplinkeditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Helplink = key
  end)
  helpgroup1:AddChild(helplinkeditbox)

  local authoreditbox = AceGUI:Create("EditBox")
  authoreditbox:SetLabel(L["Author"])
  authoreditbox:SetWidth(pairWidth)
  authoreditbox:DisableButton( true)
  if not GSE.isEmpty(editframe.Sequence.Author) then
    authoreditbox:SetText(editframe.Sequence.Author)
  end
  authoreditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Author = key
  end)
  helpgroup1:AddChild(authoreditbox)
  page:AddChild(helpgroup1)

  local helpeditbox = AceGUI:Create("MultiLineEditBox")
  helpeditbox:SetLabel(L["Help Information"])
  helpeditbox:SetWidth(pageWidth)
  helpeditbox:DisableButton( true)
  helpeditbox:SetNumLines(4)
  helpeditbox:SetFullWidth(true)
  if not GSE.isEmpty(editframe.Sequence.Help) then
    helpeditbox:SetText(editframe.Sequence.Help)
  end
  helpeditbox:SetCallback("OnTextChanged", function (obj,event,key)
    editframe.Sequence.Help = key
  end)
  page:AddChild(helpeditbox)

  local defgroup1 = AceGUI:Create("SimpleGroup")
  defgroup1:SetLayout("Flow")
  defgroup1:SetWidth(pageWidth)

  local defaultdropdown = AceGUI:Create("Dropdown")
  defaultdropdown:SetLabel(L["Default Version"])
  defaultdropdown:SetWidth(pairWidth)
  defaultdropdown:SetList(GSE.GetVersionList())
  defaultdropdown:SetValue(tostring(editframe.Default))
  defgroup1:AddChild(defaultdropdown)
  defaultdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    editframe.Sequence.Default = tonumber(key)
    editframe.Default = tonumber(key)
  end)

  local raiddropdown = AceGUI:Create("Dropdown")
  raiddropdown:SetLabel(L["Raid"])
  raiddropdown:SetWidth(pairWidth)
  raiddropdown:SetList(GSE.GetVersionList())
  raiddropdown:SetValue(tostring(editframe.Raid))
  defgroup1:AddChild(raiddropdown)
  raiddropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Raid = nil
    else
      editframe.Sequence.Raid = tonumber(key)
      editframe.Raid = tonumber(key)
    end
  end)
  page:AddChild(defgroup1)

  local defgroup2 = AceGUI:Create("SimpleGroup")
  defgroup2:SetLayout("Flow")
  defgroup2:SetWidth(pageWidth)

  local mythicdropdown = AceGUI:Create("Dropdown")
  mythicdropdown:SetLabel(L["Mythic"])
  mythicdropdown:SetWidth(pairWidth)
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
  defgroup2:AddChild(mythicdropdown)

  local pvpdropdown = AceGUI:Create("Dropdown")
  pvpdropdown:SetLabel(L["PVP"])
  pvpdropdown:SetWidth(pairWidth)
  pvpdropdown:SetList(GSE.GetVersionList())
  pvpdropdown:SetValue(tostring(editframe.PVP))
  defgroup2:AddChild(pvpdropdown)
  page:AddChild(defgroup2)

  pvpdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.PVP = nil
    else
      editframe.Sequence.PVP = tonumber(key)
      editframe.PVP = tonumber(key)
    end
  end)

  local defgroup3 = AceGUI:Create("SimpleGroup")
  defgroup3:SetLayout("Flow")
  defgroup3:SetWidth(pageWidth)

  local dungeondropdown = AceGUI:Create("Dropdown")
  dungeondropdown:SetLabel(L["Dungeon"])
  dungeondropdown:SetWidth(pairWidth)
  dungeondropdown:SetList(GSE.GetVersionList())
  dungeondropdown:SetValue(tostring(editframe.Dungeon))
  defgroup3:AddChild(dungeondropdown)
  dungeondropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Dungeon = nil
    else
      editframe.Sequence.Dungeon = tonumber(key)
      editframe.Dungeon = tonumber(key)
    end
  end)

  local heroicdropdown = AceGUI:Create("Dropdown")
  heroicdropdown:SetLabel(L["Heroic"])
  heroicdropdown:SetWidth(pairWidth)
  heroicdropdown:SetList(GSE.GetVersionList())
  heroicdropdown:SetValue(tostring(editframe.Heroic))
  defgroup3:AddChild(heroicdropdown)
  heroicdropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Heroic = nil
    else
      editframe.Sequence.Heroic = tonumber(key)
      editframe.Heroic = tonumber(key)
    end
  end)
  page:AddChild(defgroup3)

  local defgroup4 = AceGUI:Create("SimpleGroup")
  defgroup4:SetLayout("Flow")
  defgroup4:SetWidth(pageWidth)

  local partydropdown = AceGUI:Create("Dropdown")
  partydropdown:SetLabel(L["Party"])
  partydropdown:SetWidth(pairWidth)
  partydropdown:SetList(GSE.GetVersionList())
  partydropdown:SetValue(tostring(editframe.Party))
  defgroup4:AddChild(partydropdown)
  partydropdown:SetCallback("OnValueChanged", function (obj,event,key)
    if editframe.Sequence.Default == tonumber(key) then
      editframe.Sequence.Party = nil
    else
      editframe.Sequence.Party = tonumber(key)
      editframe.Party = tonumber(key)
    end
  end)
  page:AddChild(defgroup4)
  bindActivePageWheelForwarding(container)
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

  editframe.VersionScrollStatus = editframe.VersionScrollStatus or {}
  editframe.VersionScrollStatus[version] = editframe.VersionScrollStatus[version] or {}

  local page, pageWidth = createEditorTabScrollPage(container, editframe.VersionScrollStatus[version])
  local pairWidth = math.max(240, math.floor((pageWidth - 16) / 2))
  local checkboxWidth = 96
  local versionData = editframe.Sequence.MacroVersions[version]

  local linegroup1 = AceGUI:Create("SimpleGroup")
  linegroup1:SetLayout("Flow")
  linegroup1:SetWidth(pageWidth)
  linegroup1:SetAutoAdjustHeight(false)

  local stepdropdown = AceGUI:Create("Dropdown")
  stepdropdown:SetLabel(L["Step Function"])
  stepdropdown:SetWidth(pairWidth)
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
  linegroup1:AddChild(stepdropdown)

  local looplimit = AceGUI:Create("EditBox")
  looplimit:SetLabel(L["Inner Loop Limit"])
  looplimit:DisableButton(true)
  looplimit:SetMaxLetters(4)
  looplimit:SetWidth(100)
  linegroup1:AddChild(looplimit)
  if not GSE.isEmpty(versionData.LoopLimit) then
    looplimit:SetText(tonumber(versionData.LoopLimit))
  end
  looplimit.editbox:SetNumeric()
  looplimit:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.LoopLimit = value
  end)

  local delversionbutton = AceGUI:Create("Button")
  delversionbutton:SetText(L["Delete Version"])
  delversionbutton:SetWidth(150)
  delversionbutton:SetCallback("OnClick", function()
    GSE.GUIDeleteVersion(version)
  end)
  linegroup1:AddChild(delversionbutton)
  page:AddChild(linegroup1)

  local linegroup2 = AceGUI:Create("SimpleGroup")
  linegroup2:SetLayout("Flow")
  linegroup2:SetWidth(pageWidth)
  linegroup2:SetAutoAdjustHeight(false)

  local KeyPressbox = AceGUI:Create("MultiLineEditBox")
  KeyPressbox:SetLabel(L["KeyPress"])
  KeyPressbox:SetNumLines(2)
  KeyPressbox:DisableButton(true)
  KeyPressbox:SetWidth(pairWidth)
  KeyPressbox.editBox:SetScript( "OnLeave",  function() GSE.GUIParseText(KeyPressbox) end)
  if not GSE.isEmpty(versionData.KeyPress) then
    KeyPressbox:SetText(table.concat(versionData.KeyPress, "\n"))
  end
  KeyPressbox:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.KeyPress = GSE.SplitMeIntolines(value)
  end)
  linegroup2:AddChild(KeyPressbox)

  local PreMacro = AceGUI:Create("MultiLineEditBox")
  PreMacro:SetLabel(L["PreMacro"])
  PreMacro:SetNumLines(2)
  PreMacro:DisableButton(true)
  PreMacro:SetWidth(pairWidth)
  PreMacro.editBox:SetScript( "OnLeave",  function() GSE.GUIParseText(PreMacro) end)
  if not GSE.isEmpty(versionData.PreMacro) then
    PreMacro:SetText(table.concat(versionData.PreMacro, "\n"))
  end
  PreMacro:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.PreMacro = GSE.SplitMeIntolines(value)
  end)
  linegroup2:AddChild(PreMacro)
  page:AddChild(linegroup2)

  local spellbox = AceGUI:Create("MultiLineEditBox")
  spellbox:SetLabel(L["Sequence"])
  spellbox:SetNumLines(8)
  spellbox:DisableButton(true)
  spellbox:SetWidth(pageWidth)
  spellbox:SetFullWidth(true)
  spellbox.editBox:SetScript( "OnLeave",  function() GSE.GUIParseText(spellbox) end)
  if not GSE.isEmpty(versionData) then
    spellbox:SetText(table.concat(versionData, "\n"))
  end
  spellbox:SetCallback("OnTextChanged", function (sel, object, value)
    if versionData and type(versionData) == "table" then
      for k,v in ipairs(versionData) do
        versionData[k] = nil
      end
    end
    local newpairs = GSE.SplitMeIntolines(value)
    for k,v in ipairs(newpairs) do
      versionData[k] = v
    end
  end)
  page:AddChild(spellbox)

  local linegroup3 = AceGUI:Create("SimpleGroup")
  linegroup3:SetLayout("Flow")
  linegroup3:SetWidth(pageWidth)
  linegroup3:SetAutoAdjustHeight(false)

  local KeyReleasebox = AceGUI:Create("MultiLineEditBox")
  KeyReleasebox:SetLabel(L["KeyRelease"])
  KeyReleasebox:SetNumLines(2)
  KeyReleasebox:DisableButton(true)
  KeyReleasebox:SetWidth(pairWidth)
  KeyReleasebox.editBox:SetScript( "OnLeave",  function() GSE.GUIParseText(KeyReleasebox) end)
  if not GSE.isEmpty(versionData.KeyRelease) then
    KeyReleasebox:SetText(table.concat(versionData.KeyRelease, "\n"))
  end
  KeyReleasebox:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.KeyRelease = GSE.SplitMeIntolines(value)
  end)
  linegroup3:AddChild(KeyReleasebox)

  local PostMacro = AceGUI:Create("MultiLineEditBox")
  PostMacro:SetLabel(L["PostMacro"])
  PostMacro:SetNumLines(2)
  PostMacro:DisableButton(true)
  PostMacro:SetWidth(pairWidth)
  PostMacro.editBox:SetScript( "OnLeave",  function() GSE.GUIParseText(PostMacro) end)
  if not GSE.isEmpty(versionData.PostMacro) then
    PostMacro:SetText(table.concat(versionData.PostMacro, "\n"))
  end
  PostMacro:SetCallback("OnTextChanged", function (sel, object, value)
    versionData.PostMacro = GSE.SplitMeIntolines(value)
  end)
  linegroup3:AddChild(PostMacro)
  page:AddChild(linegroup3)

  local resetgroup = AceGUI:Create("SimpleGroup")
  resetgroup:SetLayout("Flow")
  resetgroup:SetWidth(pageWidth)

  local heading2 = AceGUI:Create("Label")
  heading2:SetText(L["Resets"])
  heading2:SetWidth(70)
  resetgroup:AddChild(heading2)

  local combatresetcheckbox = AceGUI:Create("CheckBox")
  combatresetcheckbox:SetType("checkbox")
  combatresetcheckbox:SetWidth(checkboxWidth)
  combatresetcheckbox:SetTriState(true)
  combatresetcheckbox:SetLabel(L["Combat"])
  combatresetcheckbox:SetValue(versionData.Combat)
  combatresetcheckbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Combat = value
  end)
  resetgroup:AddChild(combatresetcheckbox)
  page:AddChild(resetgroup)

  local usegroup = AceGUI:Create("SimpleGroup")
  usegroup:SetLayout("Flow")
  usegroup:SetWidth(pageWidth)

  local heading1 = AceGUI:Create("Label")
  heading1:SetText(L["Use"])
  heading1:SetWidth(70)
  usegroup:AddChild(heading1)

  local headcheckbox = AceGUI:Create("CheckBox")
  headcheckbox:SetType("checkbox")
  headcheckbox:SetWidth(checkboxWidth)
  headcheckbox:SetTriState(true)
  headcheckbox:SetLabel(L["Head"])
  headcheckbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Head = value
  end)
  headcheckbox:SetValue(versionData.Head)
  usegroup:AddChild(headcheckbox)

  local neckcheckbox = AceGUI:Create("CheckBox")
  neckcheckbox:SetType("checkbox")
  neckcheckbox:SetWidth(checkboxWidth)
  neckcheckbox:SetTriState(true)
  neckcheckbox:SetLabel(L["Neck"])
  neckcheckbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Neck = value
  end)
  neckcheckbox:SetValue(versionData.Neck)
  usegroup:AddChild(neckcheckbox)

  local beltcheckbox = AceGUI:Create("CheckBox")
  beltcheckbox:SetType("checkbox")
  beltcheckbox:SetWidth(checkboxWidth)
  beltcheckbox:SetTriState(true)
  beltcheckbox:SetLabel(L["Belt"])
  beltcheckbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Belt = value
  end)
  beltcheckbox:SetValue(versionData.Belt)
  usegroup:AddChild(beltcheckbox)

  local ring1checkbox = AceGUI:Create("CheckBox")
  ring1checkbox:SetType("checkbox")
  ring1checkbox:SetWidth(checkboxWidth)
  ring1checkbox:SetTriState(true)
  ring1checkbox:SetLabel(L["Ring 1"])
  ring1checkbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Ring1 = value
  end)
  ring1checkbox:SetValue(versionData.Ring1)
  usegroup:AddChild(ring1checkbox)

  local ring2checkbox = AceGUI:Create("CheckBox")
  ring2checkbox:SetType("checkbox")
  ring2checkbox:SetWidth(checkboxWidth)
  ring2checkbox:SetTriState(true)
  ring2checkbox:SetLabel(L["Ring 2"])
  ring2checkbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Ring2 = value
  end)
  ring2checkbox:SetValue(versionData.Ring2)
  usegroup:AddChild(ring2checkbox)

  local trinket1checkbox = AceGUI:Create("CheckBox")
  trinket1checkbox:SetType("checkbox")
  trinket1checkbox:SetWidth(checkboxWidth)
  trinket1checkbox:SetTriState(true)
  trinket1checkbox:SetLabel(L["Trinket 1"])
  trinket1checkbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Trinket1 = value
  end)
  trinket1checkbox:SetValue(versionData.Trinket1)
  usegroup:AddChild(trinket1checkbox)

  local trinket2checkbox = AceGUI:Create("CheckBox")
  trinket2checkbox:SetType("checkbox")
  trinket2checkbox:SetWidth(checkboxWidth)
  trinket2checkbox:SetTriState(true)
  trinket2checkbox:SetLabel(L["Trinket 2"])
  trinket2checkbox:SetCallback("OnValueChanged", function (sel, object, value)
    versionData.Trinket2 = value
  end)
  trinket2checkbox:SetValue(versionData.Trinket2)
  usegroup:AddChild(trinket2checkbox)
  page:AddChild(usegroup)
  bindActivePageWheelForwarding(container)
end

function GSE.GUISelectEditorTab(container, event, group)
  container:ReleaseChildren()
  editframe.SelectedTab = tostring(group)
  editframe.nameeditbox = nil
  editframe.iconpicker = nil
  editframe.ActiveViewport = nil
  editframe.ActiveScrollWidget = nil
  if group == "config" then
    GSE:GUIDrawMetadataEditor(container)
  elseif group == "new" then
    addEditorMacroVersion()
  else
    GSE:GUIDrawMacroEditor(container, group)
  end

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
