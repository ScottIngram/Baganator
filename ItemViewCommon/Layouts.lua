local MasqueRegistration = function() end

if LibStub then
  -- Establish a reference to Masque.
  local Masque, MSQ_Version = LibStub("Masque", true)
  if Masque ~= nil then
    -- Retrieve a reference to a new or existing group.
    local masqueGroup = Masque:Group("Baganator", "Bag")

    MasqueRegistration = function(button)
      if button.masqueApplied then
        masqueGroup:ReSkin(button)
      else
        button.masqueApplied = true
        masqueGroup:AddButton(button, nil, "Item")
      end
    end
  end
end

local function GetNameFromLink(itemLink)
  return (string.match(itemLink, "h%[(.*)%]|h"):gsub(" ?|A.-|a", ""))
end

local function RegisterHighlightSimilarItems(self)
  Baganator.CallbackRegistry:RegisterCallback("HighlightSimilarItems", function(_, itemLink)
    if not Baganator.Config.Get(Baganator.Config.Options.ICON_FLASH_SIMILAR_ALT) or itemLink == "" then
      return
    end
    local itemName = GetNameFromLink(itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink and GetNameFromLink(button.BGR.itemLink) == itemName then
        button:BGRStartFlashing()
      end
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightIdenticalItems", function(_, itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink == itemLink then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

local ReflowSettings = {
  Baganator.Config.Options.BAG_ICON_SIZE,
  Baganator.Config.Options.EMPTY_SLOT_BACKGROUND,
  Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP,
  Baganator.Config.Options.ICON_TEXT_FONT_SIZE,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.REDUCE_SPACING,
}

local RefreshContentSettings = {
  Baganator.Config.Options.HIDE_BOE_ON_COMMON,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS,
  Baganator.Config.Options.ICON_GREY_JUNK,
  Baganator.Config.Options.JUNK_PLUGIN,
}

function Baganator.ItemButtonUtil.GetPaddingAndSize()
  local iconPadding = 4

  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    iconPadding = 1
  end

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  return iconPadding, iconSize
end

local function ApplySizing(self, rowWidth, iconPadding, iconSize, flexDimension, staticDimension)
  self:SetSize(rowWidth * (iconSize + iconPadding) - iconPadding, (iconPadding + iconSize) * ((flexDimension > 0 and (staticDimension + 1) or staticDimension)))
end

local function FlowButtonsRows(self, rowWidth)
  local iconPadding, iconSize = Baganator.ItemButtonUtil.GetPaddingAndSize()

  local rows, cols = 0, 0
  if Baganator.Config.Get(Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP) then
    cols = rowWidth - #self.buttons%rowWidth
    if cols == rowWidth then
      cols = 0
    end
  end
  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    button:UpdateTextures()
    MasqueRegistration(button)
    cols = cols + 1
    if cols >= rowWidth then
      cols = 0
      rows = rows + 1
    end
  end

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, rows)
  self.oldRowWidth = rowWidth
end

local function FlowButtonsColumns(self, rowWidth)
  local iconPadding, iconSize = Baganator.ItemButtonUtil.GetPaddingAndSize()

  local columnHeight = math.ceil(#self.buttons / rowWidth)

  local rows, cols = 0, 0

  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    button:UpdateTextures()
    MasqueRegistration(button)
    rows = rows + 1
    if rows >= columnHeight then
      rows = 0
      cols = cols + 1
    end
  end

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, columnHeight - 1)
  self.oldRowWidth = rowWidth
end

local function IsDifferentCachedData(data1, data2)
  return data1 == nil or data1.itemLink ~= data2.itemLink or not data1.isBound ~= not data2.isBound or (data1.itemCount or 1) ~= (data2.itemCount or 1) or data1.quality ~= data2.quality
end

function Baganator.ItemViewCommon.Utilities.GetCategoryDataKey(data)
  return data ~= nil and (tostring(data.keyLink) .. tostring(data.isBound) .. tostring(data.itemCount or 1) .. "_" .. tostring(data.quality)) or ""
end

function Baganator.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(data)
  return data ~= nil and (tostring(data.keyLink) .. tostring(data.isBound) .. tostring(data.quality)) or ""
end

local function UpdateQuests(self)
  for _, button in ipairs(self.buttons) do
    if button.BGR and button.BGR.isQuestItem then
      local item = Item:CreateFromItemID(button.BGR.itemID)
      item:ContinueOnItemLoad(function()
        button:BGRUpdateQuests()
      end)
    end
  end
end

local function LiveBagOnEvent(self, eventName, ...)
  if eventName == "ITEM_LOCK_CHANGED" then
    local bagID, slotID = ...
    self:UpdateLockForItem(bagID, slotID)
  elseif eventName == "BAG_UPDATE_COOLDOWN" then
    self:UpdateCooldowns()
  elseif eventName == "UNIT_QUEST_LOG_CHANGED" then
    local unit = ...
    if unit == "player" then
      self:UpdateQuests()
    end
  elseif eventName == "QUEST_ACCEPTED" then
    self:UpdateQuests()
  end
end

BaganatorCachedBagLayoutMixin = {}

function BaganatorCachedBagLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.buttonsByBag = {}
  self.waitingUpdate = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorCachedBagLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorCachedBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse, newBags)
  for index in pairs(indexesToUse) do
    local bagID = indexes[index]
    if not self.buttonsByBag[bagID] or not newBags[index] or #self.buttonsByBag[bagID] ~= #newBags[index] then
      return true
    end
  end

  return false
end

function BaganatorCachedBagLayoutMixin:MarkBagsPending(section, updatedWaiting)
  for bag in pairs(updatedWaiting[section]) do
    self.waitingUpdate[bag] = true
  end
end

function BaganatorCachedBagLayoutMixin:RebuildLayout(newBags, indexes, indexesToUse, rowWidth)
  self.buttons = {}
  self.buttonsByBag = {}
  self.buttonPool:ReleaseAll()

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  local rows, cols = 0, 0
  for bagIndex = 1, #newBags do
    local bagButtons = {}
    if indexesToUse[bagIndex] and indexes[bagIndex] then
      self.buttonsByBag[indexes[bagIndex]] = bagButtons
      for slotIndex = 1, #newBags[bagIndex] do
        local button = self.buttonPool:Acquire()
        button:Show()

        table.insert(self.buttons, button)
        bagButtons[slotIndex] = button
      end
    end
  end

  FlowButtonsRows(self, rowWidth)
end

function BaganatorCachedBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = Syndicator.API.GetCharacter(character)

  if not characterData then
    return
  end

  local sectionData = characterData[section]

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if self.prevState.character ~= character or self.prevState.section ~= section or
      self:CompareButtonIndexes(indexes, indexesToUse, sectionData) then
    self:RebuildLayout(sectionData, indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsRows(self, rowWidth)
  end

  if self.refreshContent then
    self.refreshContent = false
    self.waitingUpdate = {}
    for index in pairs(indexesToUse) do
      self.waitingUpdate[indexes[index]] = true
    end
  end

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      -- bag may be nil due to past caching error (now fixed)
      if bag ~= nil then
        for index, slotInfo in ipairs(sectionData[bagIndex]) do
          local button = bag[index]
          button:SetItemDetails(slotInfo)
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    local c = 0
    for _ in pairs(indexesToUse) do
      c = c+ 1
    end
    print("cached bag layout took", c, section, debugprofilestop() - start)
  end

  self.waitingUpdate = {}
  self.prevState = {
    character = character,
    section = section,
  }
end

function BaganatorCachedBagLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorCachedBagLayoutMixin:OnShow()
  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, highlightBagIDs)
    for bagID, bag in pairs(self.buttonsByBag) do
      for slotID, button in ipairs(bag) do
        button:BGRSetHighlight(highlightBagIDs[bagID])
      end
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedBagLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

BaganatorLiveBagLayoutMixin = {}

local LIVE_LAYOUT_EVENTS = {
  "BAG_UPDATE_COOLDOWN",
  "UNIT_QUEST_LOG_CHANGED",
  "QUEST_ACCEPTED",
}

function BaganatorLiveBagLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByBag = {}
  self.bagSizesUsed = {}
  self.waitingUpdate = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveBagLayoutMixin:SetPool(buttonPool)
  self.buttonPool = buttonPool
end

function BaganatorLiveBagLayoutMixin:UpdateCooldowns()
  for _, button in ipairs(self.buttons) do
    if button.BGR ~= nil then
      button:BGRUpdateCooldown()
    end
  end
end

BaganatorLiveBagLayoutMixin.UpdateQuests = UpdateQuests

BaganatorLiveBagLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveBagLayoutMixin:OnShow()
  FrameUtil.RegisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  self:UpdateCooldowns()
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("update cooldowns show", debugprofilestop() - start)
  end
  self:UpdateQuests()

  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, bagIDs)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(bagIDs[button:GetParent():GetID()])
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)
end

function BaganatorLiveBagLayoutMixin:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  for _, button in ipairs(self.buttons) do
    button:ClearNewItem()
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("remove new item", debugprofilestop() - start)
  end

  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightBagItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("ClearHighlightBag", self)
end

function BaganatorLiveBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorLiveBagLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorLiveBagLayoutMixin:UpdateLockForItem(bagID, slotID)
  if not self.buttonsByBag[bagID] then
    return
  end

  local itemButton = self.buttonsByBag[bagID][slotID]
  if itemButton then
    local info = C_Container.GetContainerItemInfo(bagID, slotID);
    local locked = info and info.isLocked;
    SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
  end
end

function BaganatorLiveBagLayoutMixin:Deallocate()
  self.indexFramesPool:ReleaseAll()
  for _, button in ipairs(self.buttons) do
    self.buttonPool:Release(button)
  end
  self.buttons = {}
  self.bagSizesUsed = {}
  self.buttonsByBag = {}
end

function BaganatorLiveBagLayoutMixin:RebuildLayout(indexes, indexesToUse, rowWidth)
  self:Deallocate()

  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] then
      self.buttonsByBag[bagID] = {}
      local indexFrame = self.indexFramesPool:Acquire()
      indexFrame:SetID(indexes[index])
      indexFrame:Show()

      local size = C_Container.GetContainerNumSlots(bagID)
      for slotIndex = 1, size do
        local b = self.buttonPool:Acquire()
        b:SetID(slotIndex)
        b:SetParent(indexFrame)
        b:Show()
        table.insert(self.buttons, b)

        self.buttonsByBag[bagID][slotIndex] = b
      end
      self.bagSizesUsed[index] = size
    end
  end

  FlowButtonsRows(self, rowWidth)
end

function BaganatorLiveBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse)
  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] and self.bagSizesUsed[index] ~= C_Container.GetContainerNumSlots(bagID) or (self.buttonsByBag[bagID] and not indexesToUse[index]) then
      return true
    end
  end

  return false
end

function BaganatorLiveBagLayoutMixin:MarkBagsPending(section, updatedWaiting)
  for bag in pairs(updatedWaiting[section]) do
    self.waitingUpdate[bag] = true
  end
end

function BaganatorLiveBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = Syndicator.API.GetCharacter(character)

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if self:CompareButtonIndexes(indexes, indexesToUse) or self.prevState.character ~= character or self.prevState.section ~= section then
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("rebuild")
    end
    self:RebuildLayout(indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsRows(self, rowWidth)
  end

  local refreshContent = self.refreshContent
  if self.refreshContent then
    self.refreshContent = false
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  end

  local sectionData = characterData[section]

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      if #bag == #sectionData[bagIndex] then
        for index, cacheData in ipairs(sectionData[bagIndex]) do
          local button = bag[index]
          if IsDifferentCachedData(button.BGR, cacheData) then
            button:SetItemDetails(cacheData)
          elseif refreshContent then
            Baganator.ItemButtonUtil.ResetCache(button, cacheData)
          end
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("live bag layout took", section, debugprofilestop() - start)
  end

  self.prevState = {
    character = character,
    section = section,
  }
  self.waitingUpdate = {}
end

function BaganatorLiveBagLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

BaganatorLiveCategoryLayoutMixin = {}

function BaganatorLiveCategoryLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  self.dummyButtonPool = Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByKey = {}
  self.indexFrames = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveCategoryLayoutMixin:SetPool(buttonPool)
  self.buttonPool = buttonPool
end

function BaganatorLiveCategoryLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorLiveCategoryLayoutMixin:UpdateCooldowns()
  for _, button in ipairs(self.buttons) do
    if button.BGR ~= nil and button.BGRUpdateCooldown then
      button:BGRUpdateCooldown()
    end
  end
end

BaganatorLiveCategoryLayoutMixin.UpdateQuests = UpdateQuests

BaganatorLiveCategoryLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveCategoryLayoutMixin:UpdateLockForItem(bagID, slotID)
  if not self.buttons then
    return
  end

  for _, itemButton in ipairs(self.buttons) do
    if itemButton:GetParent():GetID() == bagID and itemButton:GetID() == slotID then
      local info = C_Container.GetContainerItemInfo(bagID, slotID);
      local locked = info and info.isLocked;
      SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
    end
  end
end

function BaganatorLiveCategoryLayoutMixin:OnShow()
  FrameUtil.RegisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  self:UpdateCooldowns()
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("update cooldowns show", debugprofilestop() - start)
  end
  self:UpdateQuests()

  RegisterHighlightSimilarItems(self)
end

function BaganatorLiveCategoryLayoutMixin:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorLiveCategoryLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil or setting == Baganator.Config.Options.SORT_METHOD then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorLiveCategoryLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorLiveCategoryLayoutMixin:SetupButton(button)
  if button.hooked then
    return
  end

  button.hooked = true
  button:HookScript("OnClick", function(_, mouseButton)
    if not button.BGR.itemLink then
      return
    end

    if mouseButton == "LeftButton" and C_Cursor.GetCursorItem() ~= nil then
      Baganator.CallbackRegistry:TriggerEvent("CategoryAddItemStart", button.BGR.category, button.BGR.itemID, button.BGR.itemLink)
    end
  end)
end

function BaganatorLiveCategoryLayoutMixin:SetupDummyButton(button)
  if button.setup then
    return
  end
  button.setup = true
  button.isDummy = true

  button:SetScript("OnClick", function()
    if C_Cursor.GetCursorItem() ~= nil then
      Baganator.CallbackRegistry:TriggerEvent("CategoryAddItemEnd", button.dummyType == "add" and button.BGR.category or nil)
      ClearCursor()
    end
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.label)
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button.ModifiedIcon = button:CreateTexture(nil, "OVERLAY")
  button.ModifiedIcon:SetPoint("CENTER")
end

function BaganatorLiveCategoryLayoutMixin:ApplyDummyButtonSettings(button, cacheData)
  if button.dummyType == cacheData.dummyType then
    return
  end

  button.dummyType = cacheData.dummyType
  if cacheData.dummyType == "remove" then
    button.ModifiedIcon:SetAtlas("transmog-icon-remove")
    button.ModifiedIcon:SetSize(25, 25)
  elseif cacheData.dummyType == "add" then
    button.ModifiedIcon:SetAtlas("Garr_Building-AddFollowerPlus")
    button.ModifiedIcon:SetSize(37, 37)
  end
end

function BaganatorLiveCategoryLayoutMixin:DeallocateUnusedButtons(cacheList)
  local used = {}
  for _, cacheData in ipairs(cacheList) do
    local key = Baganator.ItemViewCommon.Utilities.GetCategoryDataKey(cacheData)
    used[key] = (used[key] or 0) + 1
  end
  for key, list in pairs(self.buttonsByKey) do
    if not used[key] or used[key] < #list then
      local max = used[key] and #list - used[key] or 0
      for index = #list, max + 1, -1 do
        local button = list[index]
        if not button.isDummy then
          self.buttonPool:Release(button)
        else
          self.dummyButtonPool:Release(button)
        end
        table.remove(list)
      end
      if #list == 0 then
        self.buttonsByKey[key] = nil
      end
      self.anyRemoved = true
    end
  end
  self.buttons = {}
end

function BaganatorLiveCategoryLayoutMixin:ShowGroup(cacheList, rowWidth, category)
  local toSet = {}
  local toResetCache = {}
  self.buttons = {}
  for _, cacheData in ipairs(cacheList) do
    local key = Baganator.ItemViewCommon.Utilities.GetCategoryDataKey(cacheData)
    local newButton
    if self.buttonsByKey[key] then
      newButton = self.buttonsByKey[key][1]
      table.remove(self.buttonsByKey[key], 1)
      if #self.buttonsByKey[key] == 0 then
        self.buttonsByKey[key] = nil
      end
      if self.refreshContent then
        table.insert(toResetCache, {newButton, cacheData})
      end
    else
      if cacheData.isDummy then
        newButton = self.dummyButtonPool:Acquire()
        newButton.label = cacheData.label
        self:SetupDummyButton(newButton)
      else
        newButton = self.buttonPool:Acquire()
        self:SetupButton(newButton)
      end
      newButton:Show()
      table.insert(toSet, {newButton, cacheData})
    end
    if cacheData.isDummy  then
      self:ApplyDummyButtonSettings(newButton, cacheData)
    elseif not self.indexFrames[cacheData.bagID] then
      local indexFrame = self.indexFramesPool:Acquire()
      indexFrame:Show()
      indexFrame:SetID(cacheData.bagID)
      self.indexFrames[cacheData.bagID] = indexFrame
    end
    newButton:SetParent(self.indexFrames[cacheData.bagID] or self)
    newButton:SetID(cacheData.slotID or 0)
    if not cacheData.isDummy then
      SetItemButtonDesaturated(newButton, cacheData.itemID ~= nil and C_Item.IsLocked({bagID = cacheData.bagID, slotIndex = cacheData.slotID}))
    end
    table.insert(self.buttons, newButton)
  end

  if #toSet > 0 or self.anyRemoved or self.reflow or rowWidth ~= self.prevRowWidth then
    self.reflow = false
    self.anyRemoved = false
    FlowButtonsRows(self, rowWidth)
    for _, details in ipairs(toSet) do
      details[1]:SetItemDetails(details[2])
    end
  end

  for _, details in ipairs(toResetCache) do
    Baganator.ItemButtonUtil.ResetCache(details[1], details[2])
  end

  self.refreshContent = false

  self.buttonsByKey = {}
  for index, button in ipairs(self.buttons) do
    button.BGR.category = category
    local key = Baganator.ItemViewCommon.Utilities.GetCategoryDataKey(cacheList[index])
    self.buttonsByKey[key] = self.buttonsByKey[key] or {}
    table.insert(self.buttonsByKey[key], button)
  end
end

BaganatorCachedCategoryLayoutMixin = {}

function BaganatorCachedCategoryLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByKey = {}
  self.indexFrames = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedCategoryLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorCachedCategoryLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedCategoryLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorCachedCategoryLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil or setting == Baganator.Config.Options.SORT_METHOD then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorCachedCategoryLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorCachedCategoryLayoutMixin:ShowGroup(cacheList, rowWidth)
  self.buttonPool:ReleaseAll()
  self.buttons = {}
  for _, cacheData in ipairs(cacheList) do
    table.insert(self.buttons, (self.buttonPool:Acquire()))
  end

  FlowButtonsRows(self, rowWidth)

  for index, button in ipairs(self.buttons) do
    button:Show()
    button:SetItemDetails(cacheList[index])
  end
end

BaganatorGeneralGuildLayoutMixin = {}

function BaganatorGeneralGuildLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "cached"
end

function BaganatorGeneralGuildLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorGeneralGuildLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorGeneralGuildLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorGeneralGuildLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorGeneralGuildLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorGeneralGuildLayoutMixin:RebuildLayout(rowWidth)
  self.buttons = {}
  self.buttonPool:ReleaseAll()

  for index = 1, Syndicator.Constants.MaxGuildBankTabItemSlots do
    local button = self.buttonPool:Acquire()
    button:Show()
    button:SetID(index)
    table.insert(self.buttons, button)
  end

  FlowButtonsColumns(self, rowWidth)
end

function BaganatorGeneralGuildLayoutMixin:ShowGuild(guild, tabIndex, rowWidth)
  local start = debugprofilestop()

  local guildData = Syndicator.API.GetGuild(guild)

  if #self.buttons ~= Syndicator.Constants.MaxGuildBankTabItemSlots then
    self.refreshContent = true
    self:RebuildLayout(rowWidth)
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsColumns(self, rowWidth)
  end

  if not guildData then
    return
  end

  if self.prevState.guild ~= guild or self.prevState.tabIndex ~= tabIndex then
    self.refreshContent = true
  end

  if self.refreshContent then
    self.refreshContent = false

    local tab = guildData.bank[tabIndex] and guildData.bank[tabIndex].slots or {}
    for index, cacheData in ipairs(tab) do
      local button = self.buttons[index]
      button:SetItemDetails(cacheData, tabIndex)
    end
    if #tab == 0 then
      for _, button in ipairs(self.buttons) do
        button:SetItemDetails({}, tabIndex)
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print(self.layoutType .. " guild layout took", tabIndex, debugprofilestop() - start)
  end

  self.prevState = {
    guild = guild,
    tabIndex = tabIndex,
  }
end

BaganatorLiveGuildLayoutMixin = CreateFromMixins(BaganatorGeneralGuildLayoutMixin)

function BaganatorLiveGuildLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetLiveGuildItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "live"

  self:RegisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
end

function BaganatorLiveGuildLayoutMixin:OnEvent(eventName, ...)
  if eventName == "GUILDBANK_ITEM_LOCK_CHANGED" and self.prevState and self.prevState.guild ~= nil and self.prevState.guild ~= "" then
    self.refreshContent = true
    self:ShowGuild(self.prevState.guild, self.prevState.tabIndex, self.oldRowWidth)
    self.SearchMonitor:StartSearch(self.SearchMonitor.text)
  end
end

BaganatorLiveWarbandLayoutMixin = {}

function BaganatorLiveWarbandLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetLiveWarbandItemButtonPool(self)
  self.indexFrame = CreateFrame("Frame", nil, self)
  self.buttons = {}
  self.waitingUpdate = true
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

BaganatorLiveWarbandLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveWarbandLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorLiveWarbandLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorLiveWarbandLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorLiveWarbandLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorLiveWarbandLayoutMixin:UpdateLockForItem(bagID, slotID)
  if self.buttons[1] and bagID == self.buttons[1]:GetBankTabID() then
    local itemButton = self.buttons[slotID]
    if itemButton then
      local info = C_Container.GetContainerItemInfo(bagID, slotID);
      local locked = info and info.isLocked;
      SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
    end
  end
end

function BaganatorLiveWarbandLayoutMixin:RebuildLayout(tabSize, rowWidth)
  if tabSize == 0 then
    return
  end

  for slotIndex = 1, tabSize do
    local b = self.buttonPool:Acquire()
    b:SetID(slotIndex)
    b:SetParent(self.indexFrame)
    b:Show()
    table.insert(self.buttons, b)
  end

  FlowButtonsRows(self, rowWidth)

  self.initialized = true
end

function BaganatorLiveWarbandLayoutMixin:MarkTabsPending(updatedWaiting)
  self.waitingUpdate = updatedWaiting.bags[self.prevState.bagID] == true
end

function BaganatorLiveWarbandLayoutMixin:ShowTab(tabIndex, indexes, rowWidth)
  local start = debugprofilestop()

  local warbandData = Syndicator.API.GetWarband(1).bank

  if #warbandData == 0 then
    return
  end

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if not self.initialized then
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("rebuild")
    end
    self:RebuildLayout(#warbandData[tabIndex].slots, rowWidth)
    self.waitingUpdate = true
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsRows(self, rowWidth)
  end

  local refreshContent = self.refreshContent
  if self.refreshContent then
    self.refreshContent = false
    self.waitingUpdate = true
  end

  if self.waitingUpdate or self.prevState.tabIndex ~= tabIndex then
    local bagID = indexes[tabIndex]
    self.indexFrame:SetID(bagID)
    for index, cacheData in ipairs(warbandData[tabIndex].slots) do
      local button = self.buttons[index]
      button:SetBankTabID(bagID)
      if IsDifferentCachedData(button.BGR, cacheData) then
        button:SetItemDetails(cacheData)
      elseif refreshContent then
        Baganator.ItemButtonUtil.ResetCache(button, cacheData)
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("live warband layout took", debugprofilestop() - start)
  end

  self.prevState = {
    tabIndex = tabIndex,
    bagID = indexes[tabIndex],
  }
  self.waitingUpdate = false
end

function BaganatorLiveWarbandLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

BaganatorCachedWarbandLayoutMixin = {}

function BaganatorCachedWarbandLayoutMixin:OnLoad()
  self.buttonPool = Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedWarbandLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedWarbandLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorCachedWarbandLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
end

function BaganatorCachedWarbandLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorCachedWarbandLayoutMixin:RebuildLayout(tabSize, rowWidth)
  if tabSize == 0 then
    return
  end

  for slotIndex = 1, tabSize do
    local b = self.buttonPool:Acquire()
    b:Show()
    table.insert(self.buttons, b)
  end

  FlowButtonsRows(self, rowWidth)

  self.initialized = true
end

function BaganatorCachedWarbandLayoutMixin:ShowTab(tabIndex, indexes, rowWidth)
  local start = debugprofilestop()

  local warbandData = Syndicator.API.GetWarband(1).bank

  if #warbandData == 0 then
    return
  end

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if not self.initialized then
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("rebuild")
    end
    self:RebuildLayout(#warbandData[tabIndex].slots, rowWidth)
    self.waitingUpdate = true
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsRows(self, rowWidth)
  end

  local refreshContent = self.refreshContent
  if self.refreshContent then
    self.refreshContent = false
    self.waitingUpdate = true
  end

  for index, cacheData in ipairs(warbandData[tabIndex].slots) do
    local button = self.buttons[index]
    button:SetItemDetails(cacheData)
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("cached warband layout took", debugprofilestop() - start)
  end
end

function BaganatorCachedWarbandLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

BaganatorSearchLayoutMonitorMixin = {}

function BaganatorSearchLayoutMonitorMixin:OnLoad()
  self.pendingItems = {}
  self.text = ""
end

function BaganatorSearchLayoutMonitorMixin:OnUpdate()
  for itemButton in pairs(self.pendingItems)do
    if not itemButton:SetItemFiltered(self.text) then
      self.pendingItems[itemButton] = nil
    end
  end
  if next(self.pendingItems) == nil then
    self:SetScript("OnUpdate", nil)
  end
end

function BaganatorSearchLayoutMonitorMixin:StartSearch(text)
  local start = debugprofilestop()
  self.text = text
  self.pendingItems = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton:SetItemFiltered(text) then
      self.pendingItems[itemButton] = true
    end
  end
  if next(self.pendingItems) then
    self:SetScript("OnUpdate", self.OnUpdate)
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("search monitor start", debugprofilestop() - start)
  end
end

BaganatorBagSearchLayoutMonitorMixin = CreateFromMixins(BaganatorSearchLayoutMonitorMixin)

function BaganatorBagSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch then
      table.insert(matches, {
        bagID = itemButton:GetParent():GetID(),
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
        hasNoValue = itemButton.BGR.hasNoValue,
        isBound = itemButton.BGR.isBound,
      })
    end
  end
  return matches
end

BaganatorGuildSearchLayoutMonitorMixin = CreateFromMixins(BaganatorSearchLayoutMonitorMixin)

function BaganatorGuildSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch then
      table.insert(matches, {
        tabIndex = self:GetParent().prevState.tabIndex,
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
      })
    end
  end
  return matches
end
