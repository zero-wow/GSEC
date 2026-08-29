local GSE = GSE
local L = GSE.L

-- A small native widget layer keeps the control panel deterministic on the 3.3 client.
-- It deliberately does not depend on AceConfig's large, padded layout widgets.
local Config = {}
GSE.ControlPanel = Config

local BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  tile = false,
  edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

Config.ColorWays = {
  ["Obsidian Dawn"] = {
    background = { 0.010, 0.013, 0.019, 0.99 }, surface = { 0.023, 0.029, 0.041, 0.985 },
    raised = { 0.040, 0.050, 0.068, 0.99 }, hover = { 0.055, 0.070, 0.094, 0.99 }, inset = { 0.006, 0.009, 0.014, 0.98 },
    border = { 0.19, 0.145, 0.09, 0.9 }, muted = { 0.075, 0.105, 0.14, 0.95 },
    selectedBorder = { 0.31, 0.23, 0.12, 0.95 }, focusBorder = { 0.34, 0.27, 0.16, 0.95 },
    activeBorder = { 0.14, 0.25, 0.34, 0.95 }, dangerBorder = { 0.31, 0.10, 0.10, 0.95 },
    gold = { 0.88, 0.61, 0.24, 1 }, accent = { 0.16, 0.31, 0.44, 1 },
    text = { 0.91, 0.91, 0.86, 1 }, dim = { 0.56, 0.63, 0.71, 1 },
    success = { 0.30, 0.82, 0.57, 1 }, warning = { 1, 0.66, 0.25, 1 }, danger = { 0.90, 0.30, 0.28, 1 },
  },
  ["Moonsteel"] = {
    background = { 0.008, 0.014, 0.024, 0.99 }, surface = { 0.018, 0.029, 0.046, 0.985 },
    raised = { 0.033, 0.048, 0.070, 0.99 }, hover = { 0.046, 0.066, 0.095, 0.99 }, inset = { 0.005, 0.010, 0.018, 0.98 },
    border = { 0.10, 0.16, 0.23, 0.9 }, muted = { 0.065, 0.105, 0.15, 0.95 },
    selectedBorder = { 0.17, 0.27, 0.38, 0.95 }, focusBorder = { 0.20, 0.32, 0.46, 0.95 },
    activeBorder = { 0.14, 0.27, 0.39, 0.95 }, dangerBorder = { 0.30, 0.10, 0.12, 0.95 },
    gold = { 0.50, 0.72, 0.94, 1 }, accent = { 0.17, 0.35, 0.52, 1 },
    text = { 0.89, 0.93, 0.98, 1 }, dim = { 0.55, 0.67, 0.79, 1 },
    success = { 0.30, 0.82, 0.67, 1 }, warning = { 0.95, 0.75, 0.36, 1 }, danger = { 0.94, 0.38, 0.40, 1 },
  },
  ["Verdant Reliquary"] = {
    background = { 0.006, 0.015, 0.011, 0.99 }, surface = { 0.015, 0.031, 0.022, 0.985 },
    raised = { 0.027, 0.048, 0.035, 0.99 }, hover = { 0.038, 0.066, 0.048, 0.99 }, inset = { 0.004, 0.010, 0.007, 0.98 },
    border = { 0.09, 0.17, 0.12, 0.9 }, muted = { 0.055, 0.12, 0.08, 0.95 },
    selectedBorder = { 0.20, 0.25, 0.12, 0.95 }, focusBorder = { 0.23, 0.29, 0.14, 0.95 },
    activeBorder = { 0.10, 0.26, 0.18, 0.95 }, dangerBorder = { 0.28, 0.09, 0.08, 0.95 },
    gold = { 0.75, 0.70, 0.32, 1 }, accent = { 0.13, 0.34, 0.23, 1 },
    text = { 0.89, 0.94, 0.86, 1 }, dim = { 0.48, 0.65, 0.56, 1 },
    success = { 0.30, 0.84, 0.52, 1 }, warning = { 0.95, 0.70, 0.27, 1 }, danger = { 0.88, 0.31, 0.29, 1 },
  },
  ["Crimson Covenant"] = {
    background = { 0.020, 0.008, 0.007, 0.99 }, surface = { 0.038, 0.016, 0.014, 0.985 },
    raised = { 0.060, 0.026, 0.022, 0.99 }, hover = { 0.082, 0.034, 0.027, 0.99 }, inset = { 0.012, 0.004, 0.004, 0.98 },
    border = { 0.22, 0.075, 0.055, 0.9 }, muted = { 0.14, 0.045, 0.038, 0.95 },
    selectedBorder = { 0.32, 0.14, 0.07, 0.95 }, focusBorder = { 0.38, 0.17, 0.08, 0.95 },
    activeBorder = { 0.30, 0.09, 0.06, 0.95 }, dangerBorder = { 0.38, 0.07, 0.06, 0.95 },
    gold = { 0.94, 0.49, 0.18, 1 }, accent = { 0.43, 0.12, 0.08, 1 },
    text = { 0.97, 0.89, 0.82, 1 }, dim = { 0.73, 0.55, 0.45, 1 },
    success = { 0.40, 0.83, 0.48, 1 }, warning = { 1, 0.66, 0.22, 1 }, danger = { 0.94, 0.29, 0.22, 1 },
  },
  ["Frostbound"] = {
    background = { 0.007, 0.013, 0.017, 0.99 }, surface = { 0.016, 0.030, 0.037, 0.985 },
    raised = { 0.029, 0.045, 0.054, 0.99 }, hover = { 0.040, 0.061, 0.072, 0.99 }, inset = { 0.004, 0.009, 0.012, 0.98 },
    border = { 0.10, 0.18, 0.21, 0.9 }, muted = { 0.06, 0.12, 0.14, 0.95 },
    selectedBorder = { 0.17, 0.29, 0.32, 0.95 }, focusBorder = { 0.19, 0.34, 0.38, 0.95 },
    activeBorder = { 0.12, 0.28, 0.31, 0.95 }, dangerBorder = { 0.30, 0.09, 0.11, 0.95 },
    gold = { 0.57, 0.80, 0.85, 1 }, accent = { 0.15, 0.38, 0.43, 1 },
    text = { 0.89, 0.96, 0.97, 1 }, dim = { 0.51, 0.68, 0.72, 1 },
    success = { 0.34, 0.84, 0.66, 1 }, warning = { 0.98, 0.72, 0.33, 1 }, danger = { 0.91, 0.35, 0.38, 1 },
  },
  ["Pure Obsidian"] = {
    background = { 0.003, 0.004, 0.005, 0.995 }, surface = { 0.009, 0.010, 0.012, 0.99 },
    raised = { 0.018, 0.019, 0.022, 0.99 }, hover = { 0.027, 0.029, 0.033, 0.99 }, inset = { 0.001, 0.002, 0.003, 0.985 },
    border = { 0.065, 0.070, 0.080, 0.92 }, muted = { 0.038, 0.043, 0.050, 0.96 },
    selectedBorder = { 0.13, 0.14, 0.16, 0.96 }, focusBorder = { 0.16, 0.17, 0.19, 0.96 },
    activeBorder = { 0.11, 0.12, 0.14, 0.96 }, dangerBorder = { 0.20, 0.060, 0.065, 0.96 },
    gold = { 0.76, 0.75, 0.72, 1 }, accent = { 0.14, 0.15, 0.17, 1 },
    text = { 0.90, 0.90, 0.88, 1 }, dim = { 0.48, 0.49, 0.51, 1 },
    success = { 0.34, 0.76, 0.57, 1 }, warning = { 0.91, 0.65, 0.31, 1 }, danger = { 0.88, 0.31, 0.33, 1 },
  },
  ["Blackglass"] = {
    background = { 0.004, 0.005, 0.007, 0.995 }, surface = { 0.010, 0.012, 0.016, 0.99 },
    raised = { 0.019, 0.022, 0.028, 0.99 }, hover = { 0.029, 0.034, 0.042, 0.99 }, inset = { 0.002, 0.003, 0.005, 0.985 },
    border = { 0.075, 0.085, 0.10, 0.92 }, muted = { 0.045, 0.052, 0.064, 0.96 },
    selectedBorder = { 0.17, 0.18, 0.20, 0.96 }, focusBorder = { 0.21, 0.23, 0.26, 0.96 },
    activeBorder = { 0.12, 0.16, 0.20, 0.96 }, dangerBorder = { 0.26, 0.075, 0.08, 0.96 },
    gold = { 0.68, 0.70, 0.73, 1 }, accent = { 0.20, 0.23, 0.28, 1 },
    text = { 0.90, 0.90, 0.91, 1 }, dim = { 0.48, 0.50, 0.53, 1 },
    success = { 0.34, 0.76, 0.57, 1 }, warning = { 0.91, 0.65, 0.31, 1 }, danger = { 0.88, 0.31, 0.33, 1 },
  },
  ["Smoked Bronze"] = {
    background = { 0.009, 0.007, 0.005, 0.995 }, surface = { 0.020, 0.015, 0.010, 0.99 },
    raised = { 0.034, 0.026, 0.017, 0.99 }, hover = { 0.049, 0.036, 0.023, 0.99 }, inset = { 0.005, 0.004, 0.003, 0.985 },
    border = { 0.15, 0.105, 0.06, 0.92 }, muted = { 0.09, 0.065, 0.04, 0.96 },
    selectedBorder = { 0.25, 0.17, 0.08, 0.96 }, focusBorder = { 0.31, 0.22, 0.11, 0.96 },
    activeBorder = { 0.24, 0.15, 0.07, 0.96 }, dangerBorder = { 0.29, 0.075, 0.05, 0.96 },
    gold = { 0.78, 0.58, 0.32, 1 }, accent = { 0.35, 0.23, 0.11, 1 },
    text = { 0.93, 0.89, 0.82, 1 }, dim = { 0.57, 0.50, 0.42, 1 },
    success = { 0.39, 0.77, 0.50, 1 }, warning = { 0.92, 0.65, 0.28, 1 }, danger = { 0.89, 0.30, 0.24, 1 },
  },
  ["Abyssal Teal"] = {
    background = { 0.003, 0.010, 0.011, 0.995 }, surface = { 0.009, 0.022, 0.024, 0.99 },
    raised = { 0.016, 0.036, 0.039, 0.99 }, hover = { 0.024, 0.052, 0.055, 0.99 }, inset = { 0.002, 0.006, 0.007, 0.985 },
    border = { 0.06, 0.15, 0.16, 0.92 }, muted = { 0.035, 0.095, 0.10, 0.96 },
    selectedBorder = { 0.11, 0.25, 0.25, 0.96 }, focusBorder = { 0.14, 0.31, 0.31, 0.96 },
    activeBorder = { 0.09, 0.27, 0.28, 0.96 }, dangerBorder = { 0.27, 0.075, 0.08, 0.96 },
    gold = { 0.47, 0.75, 0.73, 1 }, accent = { 0.10, 0.37, 0.38, 1 },
    text = { 0.86, 0.94, 0.93, 1 }, dim = { 0.43, 0.59, 0.58, 1 },
    success = { 0.31, 0.78, 0.59, 1 }, warning = { 0.88, 0.68, 0.32, 1 }, danger = { 0.87, 0.31, 0.32, 1 },
  },
}

Config.ColorwayOrder = {
  "Pure Obsidian", "Blackglass", "Obsidian Dawn", "Smoked Bronze", "Abyssal Teal",
  "Moonsteel", "Verdant Reliquary", "Crimson Covenant", "Frostbound",
}
Config.ColorwayDescriptions = {
  ["Pure Obsidian"] = "MONOCHROME BLACK",
  ["Blackglass"] = "NEUTRAL BLACK",
  ["Obsidian Dawn"] = "WARM OBSIDIAN",
  ["Smoked Bronze"] = "BLACKENED BRONZE",
  ["Abyssal Teal"] = "DEEP TEAL",
  ["Moonsteel"] = "MIDNIGHT BLUE",
  ["Verdant Reliquary"] = "FOREST BLACK",
  ["Crimson Covenant"] = "OXBLOOD BLACK",
  ["Frostbound"] = "COLD CHARCOAL",
}
Config.frames, Config.texts, Config.textures, Config.buttons, Config.controls = {}, {}, {}, {}, {}

local function palette()
  local name = GSEOptions.Colorway or "Obsidian Dawn"
  return Config.ColorWays[name] or Config.ColorWays["Obsidian Dawn"]
end

function Config:GetPalette()
  return palette()
end

local function applyColor(target, color)
  target:SetTextColor(color[1], color[2], color[3], color[4])
end

function Config:RegisterFrame(frame, fill, border)
  local colors = palette()
  local fillName = fill or "surface"
  local borderName = border or "muted"
  frame:SetBackdrop(BACKDROP)
  Config.frames[frame] = { fill = fillName, border = borderName }
  frame:SetBackdropColor(unpack(colors[fillName] or colors.surface))
  frame:SetBackdropBorderColor(unpack(colors[borderName] or colors.muted))
  return frame
end

function Config:RegisterText(text, color)
  local colorName = color or "text"
  Config.texts[text] = colorName
  if text and text.SetTextColor then
    applyColor(text, palette()[colorName] or palette().text)
  end
  return text
end

function Config:RegisterTexture(texture, color)
  local colorName = color or "text"
  Config.textures[texture] = colorName
  if texture and texture.SetVertexColor then
    texture:SetVertexColor(unpack(palette()[colorName] or palette().text))
  end
  return texture
end

function Config:ApplyTheme()
  local colors = palette()
  for frame, style in pairs(Config.frames) do
    local fill, border = colors[style.fill] or colors.surface, colors[style.border] or colors.muted
    frame:SetBackdropColor(fill[1], fill[2], fill[3], fill[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
  end
  for text, colorName in pairs(Config.texts) do
    if text and text.SetTextColor then
      applyColor(text, colors[colorName] or colors.text)
    end
  end
  for texture, colorName in pairs(Config.textures) do
    if texture and texture.SetVertexColor then
      texture:SetVertexColor(unpack(colors[colorName] or colors.text))
    end
  end
  for button in pairs(Config.buttons) do
    if button.RefreshTheme then button:RefreshTheme() end
  end
  for _, control in ipairs(Config.controls) do
    if control.Refresh then control:Refresh() end
  end
end

local function makeText(parent, font, size, color)
  local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
  if size then text:SetFont(text:GetFont(), size) end
  Config:RegisterText(text, color)
  return text
end
Config.MakeText = makeText

function Config:MakeButton(parent, text, onClick, kind)
  local button = CreateFrame("Button", nil, parent)
  button:SetHeight(20)
  Config:RegisterFrame(button, "raised", kind == "danger" and "dangerBorder" or "muted")
  button.label = makeText(button, "GameFontNormalSmall", nil, "text")
  button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.label:SetText(text)
  button.kind = kind or "normal"
  button:SetScript("OnClick", onClick)
  button:SetScript("OnEnter", function(self) self.hovered = true self:RefreshTheme() end)
  button:SetScript("OnLeave", function(self) self.hovered = false self:RefreshTheme() end)
  function button:RefreshTheme()
    local colors = palette()
    if self.colorwayName then
      self.selected = (GSEOptions.Colorway or "Obsidian Dawn") == self.colorwayName
    end
    local fill = colors[self.hovered and "hover" or "raised"] or colors.raised
    local border
    if self.kind == "danger" then
      border = colors.dangerBorder or colors.danger
    elseif self.selected then
      border = colors.selectedBorder or colors.gold
    else
      border = colors.muted
    end
    self:SetBackdropColor(unpack(fill))
    self:SetBackdropBorderColor(unpack(border))
    applyColor(self.label, self.selected and colors.gold or colors.text)
  end
  Config.buttons[button] = true
  button:RefreshTheme()
  return button
end

function Config:MakeThemeCard(parent, colorwayName)
  local card = CreateFrame("Button", nil, parent)
  card:SetSize(174, 44)
  card:SetBackdrop(BACKDROP)
  card.colorwayName = colorwayName

  local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local titleFont, _, titleFlags = title:GetFont()
  if titleFont then title:SetFont(titleFont, 10, titleFlags) end
  title:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -6)
  title:SetWidth(128)
  title:SetJustifyH("LEFT")
  title:SetText(colorwayName)
  card.title = title

  local descriptor = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local descriptorFont, _, descriptorFlags = descriptor:GetFont()
  if descriptorFont then descriptor:SetFont(descriptorFont, 8, descriptorFlags) end
  descriptor:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 6)
  descriptor:SetWidth(112)
  descriptor:SetJustifyH("LEFT")
  descriptor:SetText(Config.ColorwayDescriptions[colorwayName] or "DARK")
  card.descriptor = descriptor

  local state = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local stateFont, _, stateFlags = state:GetFont()
  if stateFont then state:SetFont(stateFont, 8, stateFlags) end
  state:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 6)
  state:SetJustifyH("RIGHT")
  card.state = state

  local activeMark = card:CreateTexture(nil, "ARTWORK")
  activeMark:SetTexture("Interface\\Buttons\\WHITE8x8")
  activeMark:SetWidth(2)
  activeMark:SetPoint("TOPLEFT", card, "TOPLEFT", 2, -2)
  activeMark:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 2, 2)
  card.activeMark = activeMark

  card.swatches = {}
  for index, colorName in ipairs({ "gold", "accent", "text" }) do
    local swatch = card:CreateTexture(nil, "ARTWORK")
    swatch:SetTexture("Interface\\Buttons\\WHITE8x8")
    swatch:SetSize(7, 7)
    swatch:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8 - ((index - 1) * 10), -7)
    swatch.colorName = colorName
    card.swatches[index] = swatch
  end

  function card:RefreshTheme()
    local colors = Config.ColorWays[self.colorwayName] or Config.ColorWays["Obsidian Dawn"]
    local selected = (GSEOptions.Colorway or "Obsidian Dawn") == self.colorwayName
    local fill = colors[self.hovered and "hover" or "surface"] or colors.surface
    local border = selected and (colors.selectedBorder or colors.border) or colors.muted
    self:SetBackdropColor(unpack(fill))
    self:SetBackdropBorderColor(unpack(border))
    self.title:SetTextColor(unpack(colors.text))
    self.descriptor:SetTextColor(unpack(colors.dim))
    self.state:SetTextColor(unpack(colors.gold))
    self.state:SetText(selected and "ACTIVE" or "")
    self.activeMark:SetVertexColor(unpack(colors.gold))
    if selected then self.activeMark:Show() else self.activeMark:Hide() end
    for _, swatch in ipairs(self.swatches) do
      swatch:SetVertexColor(unpack(colors[swatch.colorName]))
    end
  end

  card:SetScript("OnClick", function(self)
    GSEOptions.Colorway = self.colorwayName
    Config:ApplyTheme()
    Config:SetStatus("Theme changed to " .. self.colorwayName .. ".", "success")
  end)
  card:SetScript("OnEnter", function(self) self.hovered = true self:RefreshTheme() end)
  card:SetScript("OnLeave", function(self) self.hovered = false self:RefreshTheme() end)
  Config.buttons[card] = true
  card:RefreshTheme()
  return card
end

function Config:ShowHelp(owner, title, detail)
  if not detail or detail == "" then return end
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(title or "GSE", 1, 0.82, 0)
  GameTooltip:AddLine(detail, 0.9, 0.9, 0.9, true)
  GameTooltip:Show()
end

function Config:CreateSection(page, y, title, detail)
  local titleText = makeText(page, "GameFontNormal", 12, "gold")
  titleText:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -y)
  titleText:SetText(title)
  local line = page:CreateTexture(nil, "ARTWORK")
  line:SetTexture("Interface\\Buttons\\WHITE8x8")
  line:SetHeight(1)
  line:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
  line:SetPoint("RIGHT", page, "RIGHT", -6, 0)
  Config:RegisterTexture(line, "muted")
  return y + 18
end

function Config:AttachWheel(frame)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    Config:ScrollBy(-delta * 42)
  end)
end

function Config:CreateToggle(page, y, title, detail, getter, setter, reloadSequences)
  local row = CreateFrame("Button", nil, page)
  row:SetHeight(22)
  row:SetPoint("TOPLEFT", page, "TOPLEFT", 5, -y)
  row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -y)
  Config:RegisterFrame(row, "inset", "muted")
  Config:AttachWheel(row)
  local label = makeText(row, "GameFontNormalSmall", nil, "text")
  label:SetPoint("LEFT", row, "LEFT", 7, 0)
  label:SetText(title)
  local state = makeText(row, "GameFontNormalSmall", 11, "success")
  state:SetPoint("RIGHT", row, "RIGHT", -9, 0)
  row:SetScript("OnClick", function()
    if reloadSequences and InCombatLockdown() then
      Config:SetStatus("Leave combat before changing active macro behavior.", "warning")
      return
    end
    setter(not getter())
    if reloadSequences then GSE.ReloadSequences() end
    row:Refresh()
  end)
  row:SetScript("OnEnter", function(self) self.hovered = true self:Refresh() Config:ShowHelp(self, title, detail) end)
  row:SetScript("OnLeave", function(self) self.hovered = false self:Refresh() GameTooltip:Hide() end)
  function row:Refresh()
    local on = getter() and true or false
    state:SetText(on and "ON" or "OFF")
    Config.texts[state] = on and "success" or "dim"
    local colors = palette()
    self:SetBackdropColor(unpack(colors[self.hovered and "hover" or "inset"] or colors.inset))
    self:SetBackdropBorderColor(unpack(colors[on and "activeBorder" or "muted"] or colors.muted))
    applyColor(state, colors[on and "success" or "dim"])
  end
  table.insert(Config.controls, row)
  row:Refresh()
  return y + 24
end

function Config:CreateChoice(page, y, title, detail, getter, setter, values, onChanged)
  local row = CreateFrame("Button", nil, page)
  row:SetHeight(22)
  row:SetPoint("TOPLEFT", page, "TOPLEFT", 5, -y)
  row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -y)
  Config:RegisterFrame(row, "inset", "muted")
  Config:AttachWheel(row)
  local label = makeText(row, "GameFontNormalSmall", nil, "text")
  label:SetPoint("LEFT", row, "LEFT", 7, 0)
  label:SetText(title)
  local state = makeText(row, "GameFontNormalSmall", 10, "success")
  state:SetPoint("RIGHT", row, "RIGHT", -9, 0)
  local keys = {}
  for _, entry in ipairs(values) do table.insert(keys, entry[1]) end
  row:SetScript("OnClick", function()
    local current = getter()
    local index = 1
    for candidate, key in ipairs(keys) do if key == current then index = candidate break end end
    setter(keys[(index % #keys) + 1])
    if onChanged then onChanged() end
    row:Refresh()
  end)
  row:SetScript("OnEnter", function(self) self.hovered = true self:Refresh() Config:ShowHelp(self, title, detail) end)
  row:SetScript("OnLeave", function(self) self.hovered = false self:Refresh() GameTooltip:Hide() end)
  function row:Refresh()
    local current = getter()
    local display = tostring(current or "")
    for _, entry in ipairs(values) do if entry[1] == current then display = entry[2] break end end
    state:SetText(display)
    local colors = palette()
    self:SetBackdropColor(unpack(colors[self.hovered and "hover" or "inset"] or colors.inset))
    self:SetBackdropBorderColor(unpack(colors[self.hovered and "focusBorder" or "muted"] or colors.muted))
    applyColor(state, colors.gold)
  end
  table.insert(Config.controls, row)
  row:Refresh()
  return y + 24
end

function Config:CreateAction(page, y, title, detail, action, kind)
  local row = CreateFrame("Frame", nil, page)
  row:SetHeight(22)
  row:SetPoint("TOPLEFT", page, "TOPLEFT", 5, -y)
  row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -y)
  Config:RegisterFrame(row, "inset", "muted")
  local label = makeText(row, "GameFontNormalSmall", nil, "text")
  label:SetPoint("LEFT", row, "LEFT", 7, 0)
  label:SetText(title)
  local button = Config:MakeButton(row, "RUN", action, kind)
  button:SetWidth(82)
  button:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  Config:AttachWheel(button)
  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self) Config:ShowHelp(self, title, detail) end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return y + 24
end

local function parseColor(value)
  value = value or "|cffffffff"
  return tonumber("0x" .. string.sub(value, 5, 6)) / 255, tonumber("0x" .. string.sub(value, 7, 8)) / 255, tonumber("0x" .. string.sub(value, 9, 10)) / 255
end

local function setColor(option, r, g, b)
  GSEOptions[option] = string.format("|cff%02x%02x%02x", math.floor((r * 255) + 0.5), math.floor((g * 255) + 0.5), math.floor((b * 255) + 0.5))
end

function Config:CreateColor(page, y, title, option)
  local row = CreateFrame("Button", nil, page)
  row:SetHeight(22)
  row:SetPoint("TOPLEFT", page, "TOPLEFT", 5, -y)
  row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -5, -y)
  Config:RegisterFrame(row, "inset", "muted")
  Config:AttachWheel(row)
  local label = makeText(row, "GameFontNormalSmall", nil, "text")
  label:SetPoint("LEFT", row, "LEFT", 8, 0)
  label:SetText(title)
  local swatch = CreateFrame("Frame", nil, row)
  swatch:SetSize(34, 16)
  swatch:SetPoint("RIGHT", row, "RIGHT", -5, 0)
  Config:RegisterFrame(swatch, "raised", "muted")
  local fill = swatch:CreateTexture(nil, "ARTWORK")
  fill:SetTexture("Interface\\Buttons\\WHITE8x8")
  fill:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
  fill:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)
  row:SetScript("OnClick", function()
    local r, g, b = parseColor(GSEOptions[option])
    local old = { r, g, b }
    ColorPickerFrame.func = function()
      local nr, ng, nb = ColorPickerFrame:GetColorRGB()
      setColor(option, nr, ng, nb)
      row:Refresh()
    end
    ColorPickerFrame.cancelFunc = function(previous)
      previous = previous or old
      setColor(option, previous[1], previous[2], previous[3])
      row:Refresh()
    end
    ColorPickerFrame.previousValues = old
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
  end)
  function row:Refresh()
    local r, g, b = parseColor(GSEOptions[option])
    fill:SetVertexColor(r, g, b, 1)
  end
  table.insert(Config.controls, row)
  row:Refresh()
  return y + 24
end

function Config:SetStatus(text, color)
  if not Config.status then return end
  Config.status:SetText(text or "")
  Config.texts[Config.status] = color or "dim"
  applyColor(Config.status, palette()[color or "dim"])
end

function Config:ScrollBy(amount)
  if not Config.slider or not Config.frame:IsShown() then return end
  local minimum, maximum = Config.slider:GetMinMaxValues()
  Config.slider:SetValue(math.max(minimum, math.min(maximum, Config.slider:GetValue() + amount)))
end

function Config:BuildOverview(page)
  local y = Config:CreateSection(page, 12, "CONTROL CENTER", "The practical settings most players change. Changes save immediately.")
  y = Config:CreateToggle(page, y, "Reset On Leaving Combat", "Return active sequences to their first step.", function() return GSEOptions.resetOOC end, function(v) GSEOptions.resetOOC = v end, true)
  y = Config:CreateToggle(page, y, "Require A Target", "Prevent macros firing without a current target.", function() return GSEOptions.requireTarget end, function(v) GSEOptions.requireTarget = v end, true)
  y = Config:CreateToggle(page, y, "Use Both Trinkets", "Include slots 13 and 14 in KeyRelease.", function() return GSEOptions.use13 or GSEOptions.use14 end, function(v) GSEOptions.use13, GSEOptions.use14 = v, v end, true)
  y = Config:CreateSection(page, y + 8, "SEQUENCE LIST", "What appears in the GSE Control sequence list.")
  y = Config:CreateToggle(page, y, "Show GLOBAL Macros", "Include account-wide sequences in the editor list.", function() return GSEOptions.filterList["Global"] end, function(v) GSEOptions.filterList["Global"] = v end)
  y = Config:CreateChoice(page, y, "Auto-Built Templates", "ALL adds every tracked generated template. CURRENT shows only this character's generated set. HIDE removes generated templates from the list.", function()
    local mode = GSEOptions.autoBuiltTemplateFilter
    if mode == "ALL" or mode == "HIDE" then return mode end
    return "CURRENT"
  end, function(value)
    GSEOptions.autoBuiltTemplateFilter = value
  end, { { "ALL", "ALL" }, { "CURRENT", "CURRENT" }, { "HIDE", "HIDE" } }, function()
    if Config.SequenceEditor and Config.SequenceEditor.RefreshList then Config.SequenceEditor:RefreshList() end
  end)
  y = Config:CreateToggle(page, y, "Use Verbose Exports", "Export readable Lua instead of compact data.", function() return GSEOptions.UseVerboseFormat end, function(v) GSEOptions.UseVerboseFormat = v end)
  return y + 8
end

function Config:BuildMacroBehavior(page)
  local y = Config:CreateSection(page, 12, "EXECUTION", "These choices update active sequence buttons and are locked while in combat.")
  local rows = {
    { "Require A Target", "Do not execute without a selected target.", "requireTarget" },
    { "Mute Sound Errors", "Suppress range and resource error speech.", "hideSoundErrors" },
    { "Hide UI Errors", "Suppress red UI error text while using sequences.", "hideUIErrors" },
    { "Clear UI Errors", "Clear accumulated UI error messages.", "clearUIErrors" },
    { "Use Head Item", "Include slot 1 in KeyRelease.", "use1" }, { "Use Neck Item", "Include slot 2 in KeyRelease.", "use2" },
    { "Use Belt Item", "Include slot 6 in KeyRelease.", "use6" }, { "Use First Ring", "Include slot 11 in KeyRelease.", "use11" },
    { "Use Second Ring", "Include slot 12 in KeyRelease.", "use12" }, { "Use First Trinket", "Include slot 13 in KeyRelease.", "use13" },
    { "Use Second Trinket", "Include slot 14 in KeyRelease.", "use14" },
  }
  for _, row in ipairs(rows) do
    local optionKey = row[3]
    y = Config:CreateToggle(page, y, row[1], row[2], function() return GSEOptions[optionKey] end, function(v) GSEOptions[optionKey] = v end, true)
  end
  return y + 8
end

function Config:BuildLibrary(page)
  local y = Config:CreateSection(page, 12, "LIBRARY", "What GSE displays, creates, and maintains.")
  local rows = {
    { "Show ALL Macros", "List all class and specialization sequences.", function() return GSEOptions.filterList["All"] end, function(v) GSEOptions.filterList["All"] = v end },
    { "Show Class Macros", "Include all sequences for your current class.", function() return GSEOptions.filterList["Class"] end, function(v) GSEOptions.filterList["Class"] = v end },
    { "Show GLOBAL Macros", "Include account-wide sequences.", function() return GSEOptions.filterList["Global"] end, function(v) GSEOptions.filterList["Global"] = v end },
    { "Create GLOBAL Buttons", "Create executable buttons for global sequences.", function() return GSEOptions.CreateGlobalButtons end, function(v) GSEOptions.CreateGlobalButtons = v end },
    { "Use Account Macro Overflow", "Use account macros when character slots are full.", function() return GSEOptions.overflowPersonalMacros end, function(v) GSEOptions.overflowPersonalMacros = v end },
    { "Create Class Macro Stubs", "Automatically create a macro stub for class sequences.", function() return GSEOptions.autoCreateMacroStubsClass end, function(v) GSEOptions.autoCreateMacroStubsClass = v end },
    { "Create GLOBAL Macro Stubs", "Automatically create account macro stubs for global sequences.", function() return GSEOptions.autoCreateMacroStubsGlobal end, function(v) GSEOptions.autoCreateMacroStubsGlobal = v end },
    { "Use Question-Mark Icons", "Let Blizzard dynamically update macro icons.", function() return GSEOptions.setDefaultIconQuestionMark end, function(v) GSEOptions.setDefaultIconQuestionMark = v end },
    { "Delete Orphaned Macros On Logout", "Remove unlinked GSE stubs during logout.", function() return GSEOptions.deleteOrphansOnLogout end, function(v) GSEOptions.deleteOrphansOnLogout = v end },
  }
  for _, row in ipairs(rows) do
    local getter, setter = row[3], row[4]
    y = Config:CreateToggle(page, y, row[1], row[2], getter, setter)
  end
  y = Config:CreateSection(page, y + 8, "LAUNCHER", "Broker tooltip and login behavior.")
  y = Config:CreateToggle(page, y, "Show GSE Users In LDB", "List group members using GSE in the launcher tooltip.", function() return GSEOptions.showGSEUsers end, function(v) GSEOptions.showGSEUsers = v end)
  y = Config:CreateToggle(page, y, "Show OOC Queue In LDB", "Show pending out-of-combat work in the launcher tooltip.", function() return GSEOptions.showGSEoocqueue end, function(v) GSEOptions.showGSEoocqueue = v end)
  y = Config:CreateToggle(page, y, "Hide Login Message", "Do not print GSE startup messages.", function() return GSEOptions.HideLoginMessage end, function(v) GSEOptions.HideLoginMessage = v end)
  return y + 8
end

function Config:BuildReset(page)
  local y = Config:CreateSection(page, 12, "RESET INPUTS", "Any enabled input returns an active sequence to its first step.")
  y = Config:CreateAction(page, y, "Update Macro Stubs", "Apply reset-input support to this character's existing macro stubs.", function() GSE.UpdateMacroString() Config:SetStatus("Macro stubs checked.", "success") end)
  local groups = {
    { "MOUSE", { { "Left Mouse", "LeftButton" }, { "Right Mouse", "RightButton" }, { "Middle Mouse", "MiddleButton" }, { "Mouse Button 4", "Button4" }, { "Mouse Button 5", "Button5" } } },
    { "ALT", { { "Any Alt", "Alt" }, { "Left Alt", "LeftAlt" }, { "Right Alt", "RightAlt" } } },
    { "CONTROL", { { "Any Control", "Control" }, { "Left Control", "LeftControl" }, { "Right Control", "RightControl" } } },
    { "SHIFT", { { "Any Shift", "Shift" }, { "Left Shift", "LeftShift" }, { "Right Shift", "RightShift" } } },
  }
  for _, group in ipairs(groups) do
    y = Config:CreateSection(page, y + 8, group[1], nil)
    for _, item in ipairs(group[2]) do
      local modifierKey = item[2]
      y = Config:CreateToggle(page, y, item[1], "Reset on this macro click input.", function() return GSEOptions.MacroResetModifiers[modifierKey] end, function(v) GSEOptions.MacroResetModifiers[modifierKey] = v end)
    end
  end
  return y + 8
end

function Config:BuildAppearance(page)
  local y = Config:CreateSection(page, 12, "COLORWAYS", "Preview and apply a complete interface palette.")
  for index, name in ipairs(Config.ColorwayOrder) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    local card = Config:MakeThemeCard(page, name)
    card:SetPoint("TOPLEFT", page, "TOPLEFT", 5 + (column * 180), -y - (row * 49))
  end
  y = y + (math.ceil(#Config.ColorwayOrder / 3) * 49) + 2
  y = Config:CreateSection(page, y + 8, "SYNTAX COLORS", "Colors used by the sequence editor and exports.")
  local rows = {
    { "Title", "TitleColour" }, { "Author", "AuthorColour" }, { "Command", "CommandColour" }, { "Emphasis", "EmphasisColour" }, { "Normal Text", "NormalColour" },
    { "Spell", "KEYWORD" }, { "Unknown", "UNKNOWN" }, { "Icon", "CONCAT" }, { "Spec / Class ID", "NUMBER" }, { "String", "STRING" }, { "Conditional", "COMMENT" },
    { "Indent", "INDENT" }, { "Step Function", "EQUALS" }, { "Language", "STANDARDFUNCS" }, { "Blizzard Function", "WOWSHORTCUTS" },
  }
  for _, row in ipairs(rows) do y = Config:CreateColor(page, y, row[1], row[2]) end
  return y + 8
end

function Config:BuildDiagnostics(page)
  local y = Config:CreateSection(page, 12, "DIAGNOSTICS", "Enable only while troubleshooting. Debug output can be noisy.")
  local rows = {
    { "Enable GSE Debug", "Write enabled module diagnostics.", function() return GSEOptions.debug end, function(v) GSEOptions.debug = v end },
    { "Print Debug To Chat", "Send selected debug output to the chat window.", function() return GSEOptions.sendDebugOutputToChatWindow end, function(v) GSEOptions.sendDebugOutputToChatWindow = v end },
    { "Store Debug Output", "Store debug output for use by other addons.", function() return GSEOptions.sendDebugOutputToDebugOutput end, function(v) GSEOptions.sendDebugOutputToDebugOutput = v end },
    { "Print KeyPress Inputs", "Print modifiers and click input on each macro press.", function() return GSEOptions.DebugPrintModConditionsOnKeyPress end, function(v) GSEOptions.DebugPrintModConditionsOnKeyPress = v end },
  }
  for _, row in ipairs(rows) do
    local getter, setter = row[3], row[4]
    y = Config:CreateToggle(page, y, row[1], row[2], getter, setter)
  end
  y = Config:CreateSection(page, y + 8, "MODULES", "Choose the diagnostic sources to emit.")
  for module, enabled in pairs(GSEOptions.DebugModules or {}) do
    local moduleName = module
    y = Config:CreateToggle(page, y, moduleName, "Enable output from this module.", function() return GSEOptions.DebugModules[moduleName] end, function(v) GSEOptions.DebugModules[moduleName] = v end)
  end
  if GSEOptions.AddInPacks then
    y = Config:CreateSection(page, y + 8, "ADDON PACKS", "Reload a registered macro collection.")
    for _, pack in pairs(GSEOptions.AddInPacks) do
      local packName, packVersion = pack.Name, pack.Version
      y = Config:CreateAction(page, y, packName, "Reload registered collection version " .. tostring(packVersion or "unknown") .. ".", function() GSE:SendMessage(GSE.Static.ReloadMessage, packName) end)
    end
  end
  return y + 8
end

Config.PageBuilders = {
  overview = Config.BuildOverview, behavior = Config.BuildMacroBehavior, library = Config.BuildLibrary,
  reset = Config.BuildReset, appearance = Config.BuildAppearance, diagnostics = Config.BuildDiagnostics,
}
Config.Navigation = { { "overview", "General" }, { "behavior", "Behavior" }, { "library", "Library" }, { "reset", "Reset Inputs" }, { "appearance", "Appearance" }, { "diagnostics", "Diagnostics" } }

function Config:ShowPageError(page, key, message)
  if not page then return end
  if not page.errorOverlay then
    local overlay = CreateFrame("Frame", nil, page)
    overlay:SetAllPoints(page)
    overlay:SetFrameLevel(page:GetFrameLevel() + 20)
    Config:RegisterFrame(overlay, "background", "dangerBorder")
    local heading = makeText(overlay, "GameFontNormal", 13, "danger")
    heading:SetPoint("TOPLEFT", overlay, "TOPLEFT", 12, -12)
    heading:SetText("THIS PAGE COULD NOT LOAD")
    local detail = makeText(overlay, "GameFontNormalSmall", 10, "text")
    detail:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10)
    detail:SetPoint("RIGHT", overlay, "RIGHT", -12, 0)
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    overlay.detail = detail
    page.errorOverlay = overlay
  end
  page.errorOverlay.detail:SetText(tostring(message or "Unknown error"))
  page.errorOverlay:Show()
  Config:SetStatus("The " .. tostring(key) .. " page failed to load. See chat for the exact error.", "danger")
  if not page.errorReported then
    page.errorReported = true
    GSE.Print("/gsec " .. tostring(key) .. " error: " .. tostring(message), "GSE")
  end
end

function Config:ShowPage(key)
  if not Config.frame then return end
  Config.selectedPage = key
  for pageKey, page in pairs(Config.pages) do
    if pageKey == key then page:Show() else page:Hide() end
  end
  local page = Config.pages[key]
  if not page then return end
  local height = page.contentHeight or 1
  Config.scrollChild:SetHeight(math.max(height, Config.scroll:GetHeight()))
  Config.slider:SetValue(0)
  Config:UpdateScrollRange()
  for pageKey, button in pairs(Config.navButtons) do
    button.selected = pageKey == key
    button:RefreshTheme()
  end
  if page.buildError then
    Config:ShowPageError(page, key, page.buildError)
  else
    if page.errorOverlay then page.errorOverlay:Hide() end
  end
  if not page.buildError and page.OnSelected then
    local ok, message = pcall(page.OnSelected, page)
    if not ok then Config:ShowPageError(page, key, message) end
  end
  Config:ApplyTheme()
end

function Config:SetPageScrollbarVisible(visible)
  visible = visible and true or false
  if not Config.scroll or not Config.scrollChild then return end
  if Config.scrollbarVisible ~= visible then
    Config.scrollbarVisible = visible
    local workspace = Config.scroll:GetParent()
    Config.scroll:ClearAllPoints()
    Config.scroll:SetPoint("TOPLEFT", workspace, "TOPLEFT", 1, -1)
    Config.scroll:SetPoint("BOTTOMRIGHT", workspace, "BOTTOMRIGHT", visible and -16 or -1, 1)
  end
  local width = Config.scroll:GetWidth()
  if width and width > 0 then Config.scrollChild:SetWidth(math.max(100, width)) end
end

function Config:UpdateScrollRange()
  if not Config.scroll or not Config.slider then return end
  local selectedPage = Config.pages and Config.pages[Config.selectedPage]
  local contentHeight = (selectedPage and selectedPage.contentHeight) or 1
  local visibleHeight = Config.scroll:GetHeight() or 1
  local maximum = math.max(0, contentHeight - visibleHeight)
  Config.slider:SetMinMaxValues(0, maximum)
  Config.slider:SetValueStep(1)
  Config:SetPageScrollbarVisible(maximum > 0)
  if maximum > 0 then
    Config.slider:Show()
  else
    Config.slider:Hide()
    Config.slider:SetValue(0)
  end
end

function Config:Build()
  if Config.frame then return Config.buildComplete end
  Config.buildComplete = false
  local frame = CreateFrame("Frame", "GSEControlPanel", UIParent)
  Config.frame = frame
  frame:Hide()
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetSize(math.min(700, GetScreenWidth() - 24), math.min(460, GetScreenHeight() - 24))
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  Config:RegisterFrame(frame, "background", "border")

  local header = CreateFrame("Frame", nil, frame)
  header:SetHeight(32)
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  Config:RegisterFrame(header, "surface", "border")
  header:EnableMouse(true)
  header:SetScript("OnMouseDown", function() frame:StartMoving() end)
  header:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
  local title = makeText(header, "GameFontNormal", 15, "gold")
  title:SetPoint("LEFT", header, "LEFT", 9, 1)
  title:SetText("GSE CONTROL")
  local subtitle = makeText(header, "GameFontNormalSmall", 10, "dim")
  subtitle:SetPoint("LEFT", title, "RIGHT", 8, 0)
  subtitle:SetText("SEQUENCES + SETTINGS")
  local close = Config:MakeButton(header, "CLOSE", function() frame:Hide() end, "danger")
  close:SetWidth(62)
  close:SetPoint("RIGHT", header, "RIGHT", -5, 0)

  local nav = CreateFrame("Frame", nil, frame)
  nav:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
  nav:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 24)
  nav:SetWidth(104)
  Config:RegisterFrame(nav, "surface", "muted")
  Config.navButtons = {}
  for index, entry in ipairs(Config.Navigation) do
    local pageKey = entry[1]
    local button = Config:MakeButton(nav, entry[2], function() Config:ShowPage(pageKey) end)
    button:SetPoint("TOPLEFT", nav, "TOPLEFT", 4, -5 - ((index - 1) * 22))
    button:SetPoint("TOPRIGHT", nav, "TOPRIGHT", -4, -5 - ((index - 1) * 22))
    Config.navButtons[pageKey] = button
  end

  local workspace = CreateFrame("Frame", nil, frame)
  workspace:SetPoint("TOPLEFT", nav, "TOPRIGHT", 1, 0)
  workspace:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 24)
  Config:RegisterFrame(workspace, "background", "muted")
  local scroll = CreateFrame("ScrollFrame", nil, workspace)
  Config.scroll = scroll
  scroll:SetPoint("TOPLEFT", workspace, "TOPLEFT", 1, -1)
  scroll:SetPoint("BOTTOMRIGHT", workspace, "BOTTOMRIGHT", -16, 1)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(_, delta) Config:ScrollBy(-delta * 42) end)
  local child = CreateFrame("Frame", nil, scroll)
  Config.scrollChild = child
  child:SetWidth(math.max(560, frame:GetWidth() - 124))
  child:SetHeight(1)
  scroll:SetScrollChild(child)
  Config.scrollbarVisible = nil
  scroll:SetScript("OnSizeChanged", function(_, width)
    child:SetWidth(math.max(100, width))
    Config:UpdateScrollRange()
  end)
  local slider = CreateFrame("Slider", nil, workspace)
  Config.slider = slider
  slider:SetOrientation("VERTICAL")
  slider:SetWidth(10)
  slider:SetPoint("TOPRIGHT", workspace, "TOPRIGHT", -3, -6)
  slider:SetPoint("BOTTOMRIGHT", workspace, "BOTTOMRIGHT", -3, 6)
  Config:RegisterFrame(slider, "inset", "muted")
  slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
  local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
  if thumb then thumb:SetSize(10, 18) end
  slider:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
  if thumb then Config:RegisterTexture(thumb, "gold") end

  Config.pages = {}
  local builtPages = {}
  local function buildPage(key)
    local builder = Config.PageBuilders[key]
    if builtPages[key] or not builder then return end
    builtPages[key] = true
    local page = CreateFrame("Frame", nil, child)
    page:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, 0)
    page:SetHeight(1)
    page:Hide()
    Config.pages[key] = page
    local ok, height = pcall(builder, Config, page)
    if ok then
      page.contentHeight = tonumber(height) or 1
    else
      page.contentHeight = 160
      page.buildError = tostring(height)
      page.OnSelected = nil
      Config:ShowPageError(page, key, height)
    end
    page:SetHeight(page.contentHeight)
  end
  for _, entry in ipairs(Config.Navigation) do
    buildPage(entry[1])
  end
  for key in pairs(Config.PageBuilders) do
    buildPage(key)
  end

  local footer = CreateFrame("Frame", nil, frame)
  footer:SetHeight(22)
  footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  Config:RegisterFrame(footer, "surface", "border")
  Config.status = makeText(footer, "GameFontNormalSmall", 10, "dim")
  Config.status:SetPoint("LEFT", footer, "LEFT", 6, 0)
  Config.status:SetText("Changes save immediately. Active macro settings are protected during combat.")
  local openLegacy = Config:MakeButton(footer, "LEGACY", function() LibStub("AceConfigDialog-3.0"):Open("GSE") end)
  openLegacy:SetWidth(66)
  openLegacy:SetPoint("RIGHT", footer, "RIGHT", -4, 0)

  frame:SetScript("OnShow", function()
    Config:ApplyTheme()
    Config:ShowPage(Config.selectedPage or "sequences")
  end)
  Config.buildComplete = true
  Config:ShowPage(Config.PageBuilders.sequences and "sequences" or "overview")
  return true
end

function GSE.OpenControlPanel()
  local ok, message = pcall(function()
    Config:Build()
    if not Config.buildComplete then error("control panel construction did not complete") end
    Config.frame:Show()
  end)
  if not ok then
    if Config.frame then Config.frame:Hide() end
    GSE.Print("/gsec could not open: " .. tostring(message), "GSE")
  end
end

-- The old AceConfig command remains available as /gseo.  /gsec is the focused UI.
GSE:RegisterChatCommand("gsec", function() GSE.OpenControlPanel() end)
