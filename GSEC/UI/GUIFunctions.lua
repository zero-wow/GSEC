local GSE = GSE
local L = GSE.L

local function trimSequenceName(sequenceName)
  if sequenceName == nil then
    return ""
  end
  return tostring(sequenceName):gsub("^%s*(.-)%s*$", "%1")
end

local function resolveEditorSequenceName(sequenceName)
  local resolvedName = trimSequenceName(sequenceName)
  if GSE.isEmpty(resolvedName) and GSE.GUIEditFrame then
    resolvedName = trimSequenceName(GSE.GUIEditFrame.PendingSequenceName)
  end
  if GSE.isEmpty(resolvedName) and GSE.GUIEditFrame then
    resolvedName = trimSequenceName(GSE.GUIEditFrame.SequenceName)
  end
  if GSE.isEmpty(resolvedName) and GSE.GUIEditFrame then
    resolvedName = trimSequenceName(GSE.GUIEditFrame.OriginalSequenceName)
  end
  return resolvedName
end

local function findLibraryClassIDForSequence(sequenceName)
  if GSE.isEmpty(sequenceName) or type(GSELibrary) ~= "table" then
    return nil
  end

  for libraryClassID, sequences in pairs(GSELibrary) do
    if type(sequences) == "table" and not GSE.isEmpty(sequences[sequenceName]) then
      return tonumber(libraryClassID) or libraryClassID
    end
  end

  return nil
end

local function resolveDeleteTarget(classid, sequenceName)
  local editorSequence = GSE.GUIEditFrame and GSE.GUIEditFrame.Sequence or nil
  local resolvedClassID = GSE.ResolveSequenceClassID(classid, editorSequence)
  local resolvedSequenceName = resolveEditorSequenceName(sequenceName)
  local originalSequenceName = ""

  if GSE.GUIEditFrame then
    originalSequenceName = trimSequenceName(GSE.GUIEditFrame.OriginalSequenceName)
  end

  if not GSE.isEmpty(resolvedSequenceName) then
    resolvedClassID = findLibraryClassIDForSequence(resolvedSequenceName) or resolvedClassID
  end

  if (GSE.isEmpty(resolvedSequenceName) or not (GSELibrary[resolvedClassID] and GSELibrary[resolvedClassID][resolvedSequenceName])) and not GSE.isEmpty(originalSequenceName) then
    resolvedSequenceName = originalSequenceName
    resolvedClassID = findLibraryClassIDForSequence(resolvedSequenceName) or resolvedClassID
  end

  return resolvedClassID, resolvedSequenceName
end

--- This function pops up a confirmation dialog.
function GSE.GUIDeleteSequence(classid, sequenceName)
  local resolvedClassID, resolvedSequenceName = resolveDeleteTarget(classid, sequenceName)
  if GSE.isEmpty(resolvedSequenceName) then
    if GSE.GUIEditFrame then
      GSE.GUIEditFrame:SetStatusText("No sequence selected to delete.")
    end
    return
  end

  StaticPopupDialogs["GSE-DeleteMacroDialog"].text = string.format(L["Are you sure you want to delete %s?  This will delete the macro and all versions.  This action cannot be undone."], resolvedSequenceName)
  StaticPopupDialogs["GSE-DeleteMacroDialog"].OnAccept = function()
      GSE.GUIConfirmDeleteSequence(resolvedClassID, resolvedSequenceName)
  end
  StaticPopup_Show ("GSE-DeleteMacroDialog")
  
end

--- This function then deletes the macro
function GSE.GUIConfirmDeleteSequence(classid, sequenceName)
  local resolvedClassID, resolvedSequenceName = resolveDeleteTarget(classid, sequenceName)
  if GSE.GUIViewFrame then
    GSE.GUIViewFrame:Hide()
  end
  if GSE.GUIEditFrame then
    GSE.GUIEditFrame:Hide()
  end
  if not GSE.isEmpty(resolvedSequenceName) then
    GSE.DeleteSequence(resolvedClassID, resolvedSequenceName)
  end
  GSE.GUIShowViewer()
end


--- Format the text against the GSE Sequence Spec.
function GSE.GUIParseText(editbox)
  if GSEOptions.RealtimeParse and editbox then
    local text = GSE.UnEscapeString(editbox:GetText() or "")
    local returntext = GSE.TranslateString(text, GetLocale(), GetLocale(), true)
    -- TranslateString adds GSE color markup for display/export paths; keep editor fields plain text.
    returntext = GSE.UnEscapeString(returntext)
    editbox:SetText(returntext)
    editbox:SetCursorPosition(string.len(returntext))
  end
end

function GSE.GUILoadEditor(key, incomingframe, recordedstring)
  local classid
  local sequenceName
  local sequence
  GSE.GUIEditFrame.save = false
  
  if GSE.isEmpty(key) then
    classid = GSE.GetCurrentClassID()
    sequenceName = trimSequenceName(GSE.getSequenceName())
    GSE.isNewFirstTimeCreated = true
    sequence = {
      ["Author"] = GSE.GetCharacterName(),
      ["Talents"] = GSE.GetCurrentTalents(),
      ["Default"] = 1,
      ["SpecID"] = GSE.GetCurrentSpecID();
      ["MacroVersions"] = {
        [1] = {
          ["PreMacro"] = {},
          ["PostMacro"] = {},
          ["KeyPress"] = {},
          ["KeyRelease"] = {},
          ["StepFunction"] = "Sequential",
          [1] = "/say Hello",
        }
      },
    }
    if not GSE.isEmpty(recordedstring) then
      sequence.MacroVersions[1][1] = nil
      sequence.MacroVersions[1] = GSE.SplitMeIntolines(recordedstring)
    end
  else
    elements = GSE.split(key, ",")
    classid = tonumber(elements[1])
    sequenceName = trimSequenceName(elements[2])
	
    -- Check if the library and sequence exist before cloning
    if GSELibrary[classid] and GSELibrary[classid][sequenceName] then
      sequence = GSE.CloneSequence(GSELibrary[classid][sequenceName], true)
    end
    
    -- If sequence is still nil, don't create a fallback - this prevents corruption
    if not sequence then
      GSE.Print("Error: Could not load sequence '" .. (sequenceName or "unknown") .. "' for class " .. (classid or "unknown") .. ". Please recreate this sequence.")
      -- Close the editor and return to viewer
      if GSE.GUIEditFrame then
        GSE.GUIEditFrame:Hide()
      end
      if GSE.GUIViewFrame then
        GSE.GUIViewFrame:Show()
      end
      return
    end
    GSE.isNewFirstTimeCreated = false
  end

  if GSE.isEmpty(sequenceName) then
    GSE.Print("Error: attempted to load a sequence with an empty name.")
    if GSE.GUIEditFrame then
      GSE.GUIEditFrame:Hide()
    end
    if GSE.GUIViewFrame then
      GSE.GUIViewFrame:Show()
    end
    return
  end
  GSE.GUIEditFrame.SequenceName = sequenceName
  GSE.GUIEditFrame.PendingSequenceName = sequenceName
  GSE.GUIEditFrame.OriginalSequenceName = sequenceName
  GSE.GUIEditFrame.Sequence = sequence
  GSE.GUIEditFrame.ClassID = classid
  GSE.GUIEditFrame.Default = sequence.Default or 1
  GSE.GUIEditFrame.PVP = sequence.PVP or sequence.Default or 1
  GSE.GUIEditFrame.Mythic = sequence.Mythic or sequence.Default or 1
  GSE.GUIEditFrame.Raid = sequence.Raid or sequence.Default or 1
  GSE.GUIEditFrame.Dungeon = sequence.Dungeon or sequence.Default or 1
  GSE.GUIEditFrame.Heroic = sequence.Heroic or sequence.Default or 1
  GSE.GUIEditFrame.Party = sequence.Party or sequence.Default or 1
  GSE.GUIEditFrame.SelectedTab = "config"
  GSE.GUIEditFrame.AutoFocusSequenceName = GSE.isNewFirstTimeCreated and true or false
  GSE.GUIEditFrame.ShowVersionOptions = {}
  GSE.GUIEditFrame.SuppressSectionSelection = false
  GSE.GUIEditorPerformLayout(GSE.GUIEditFrame)
  if incomingframe and incomingframe.Hide then
    incomingframe:Hide()
  end
  if not InCombatLockdown() then
    GSE.GUIEditFrame:Show()
  end

end

function GSE.getSequenceName()
  
  local names1 = GSE.GetSequenceNames()
  local numberOfSeqs = 0
  local currentSpecID, specname, specicon = GSE.GetCurrentSpecID()
  local newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters("New"..specname))
  local newSeqName = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters("New"..specname))
  local newSeqNumber=numberOfSeqs+1
  if not GSE.isEmpty(GSELibrary[0]) then
    numberOfSeqs = 0
    for k,v in pairs(GSELibrary[0]) do
      numberOfSeqs = numberOfSeqs + 1
      if v.MacroVersions and type(v.MacroVersions) == "table" then
        for i,j in ipairs(v.MacroVersions) do
          GSELibrary[0][k].MacroVersions[tonumber(i)] = GSE.UnEscapeSequence(j)
        end
      end
    end
  end
  if numberOfSeqs <= 0 then
    if not GSE.isEmpty(GSELibrary[GSE.GetCurrentClassID()]) then
      for k,v in GSE.pairsByKeys(names1) do
        numberOfSeqs = numberOfSeqs + 1 
      end
    end
  end
  newSeqNumber=numberOfSeqs+1
  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters("New"..specname..newSeqNumber..GetTime()))
  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters(newSeqNameTemp))
  for k,v in GSE.pairsByKeys(names1) do
    local elements = GSE.split(k, ",")
    local classid = tonumber(elements[1])
    local sequencename = elements[2]
	if newSeqNameTemp == sequencename then
	  newSeqNumber=numberOfSeqs+1
	  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters("New"..specname..newSeqNumber..GetTime()))
	  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters(newSeqNameTemp))
	end
  end
  for name, sequence in pairs(GSELibrary[GSE.GetCurrentClassID()]) do
    if newSeqNameTemp == name then
	  newSeqNumber = numberOfSeqs+1
	  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters("New"..specname..newSeqNumber..GetTime()))
	  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters(newSeqNameTemp))
	end
  end
  newSeqNameTemp = GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters(newSeqNameTemp))
  newSeqName =  GSE.TrimWhiteSpace(GSE.LowerAndReplaceSpecialCharacters(newSeqNameTemp))
  return newSeqName
end

function GSE.GUIUpdateSequenceList()
  local names = GSE.GetSequenceNames()
  GSE.GUIViewFrame.SequenceListbox:SetList(names)
end

function GSE.GUIToggleClasses(buttonname)
  if buttonname == "class" then
    classradio:SetValue(true)
    specradio:SetValue(false)
  else
    classradio:SetValue(false)
    specradio:SetValue(true)
  end
end


function GSE.GUIUpdateSequenceDefinition(classid, SequenceName, sequence, sourceSequenceName, sourceEditor)
  local activeEditor = sourceEditor or GSE.GUIEditFrame
  local resolvedSequenceName = sourceEditor and trimSequenceName(SequenceName) or resolveEditorSequenceName(SequenceName)
  resolvedSequenceName = resolvedSequenceName:gsub(" ", "_"):gsub(",", "_")

  local function setStatus(message)
    if activeEditor and activeEditor.SetStatusText then
      activeEditor:SetStatusText(message)
    end
  end

  if GSE.isEmpty(sequence) then
    setStatus("Sequence data is missing.")
    return false
  end

  if GSE.isEmpty(resolvedSequenceName) then
    if activeEditor and not GSE.isEmpty(activeEditor.OriginalSequenceName) then
      resolvedSequenceName = trimSequenceName(activeEditor.OriginalSequenceName)
      activeEditor.SequenceName = resolvedSequenceName
      activeEditor.PendingSequenceName = resolvedSequenceName
      if activeEditor.nameeditbox then
        activeEditor.nameeditbox:SetText(resolvedSequenceName)
      end
    end
  end

  if GSE.isEmpty(resolvedSequenceName) then
    local message = "Sequence Name cannot be empty."
    setStatus(message)
    GSE.Print(message, "GSE")
    return false
  end

  -- Changes have been made so save them
  if sequence.MacroVersions and type(sequence.MacroVersions) == "table" then
    for k,v in ipairs(sequence.MacroVersions) do
      sequence.MacroVersions[k] = GSE.TranslateSequenceFromTo(v, GetLocale(), "enUS", resolvedSequenceName)
      sequence.MacroVersions[k] = GSE.UnEscapeSequence(sequence.MacroVersions[k])
    end
  end

  if not GSE.isEmpty(resolvedSequenceName) then
    if GSE.isEmpty(classid) then
      classid = GSE.GetCurrentClassID()
    end
    classid = GSE.ResolveSequenceClassID(classid, sequence)
    if not GSE.isEmpty(resolvedSequenceName) then
      local originalSequenceName = trimSequenceName(sourceSequenceName)
      local originalClassID
      if GSE.isEmpty(originalSequenceName) and activeEditor then
        originalSequenceName = trimSequenceName(activeEditor.OriginalSequenceName)
      end
      if not GSE.isEmpty(originalSequenceName) then
        originalClassID = findLibraryClassIDForSequence(originalSequenceName)
      end

      -- A rename must never replace an unrelated sequence that already owns the
      -- requested name.  The queue repeats this guard to cover delayed saves.
      if originalSequenceName ~= resolvedSequenceName then
        local existingClassID = findLibraryClassIDForSequence(resolvedSequenceName)
        if existingClassID then
          local message = "A sequence named " .. resolvedSequenceName .. " already exists. Choose a different name."
          setStatus(message)
          GSE.Print(message, "GSE")
          return false
        end
      end

      if activeEditor then
        activeEditor.SequenceName = resolvedSequenceName
        activeEditor.PendingSequenceName = resolvedSequenceName
        activeEditor.OriginalSequenceName = resolvedSequenceName
      end
      local vals = {}
      vals.action = "Replace"
      vals.sequencename = resolvedSequenceName
      vals.sequence = sequence
      vals.classid = classid
      if originalSequenceName ~= "" and originalSequenceName ~= resolvedSequenceName then
        vals.previousname = originalSequenceName
        vals.previousclassid = originalClassID or classid
      end
      table.insert(GSE.OOCQueue, vals)
      setStatus(string.format(L["Sequence %s saved."], resolvedSequenceName))
      return true
    end
  end
  return false
end


function GSE.GUIGetColour(option)
  hex = string.gsub(option, "#","")
  return tonumber("0x".. string.sub(option,5,6))/255, tonumber("0x"..string.sub(option,7,8))/255, tonumber("0x"..string.sub(option,9,10))/255
end

function  GSE.GUISetColour(option, r, g, b)
  option = string.format("|c%02x%02x%02x%02x", 255 , r*255, g*255, b*255)
end


function GSE:OnInitialize()
    GSE.GUIRecordFrame:Hide()
    GSE.GUIVersionFrame:Hide()
    GSE.GUIEditFrame:Hide()
    GSE.GUIViewFrame:Hide()
end


function GSE.OpenOptionsPanel()
  if GSE.OpenControlPanel then
    GSE.OpenControlPanel()
    return
  end
  LibStub:GetLibrary("AceConfigDialog-3.0"):Open("GSE")

end
