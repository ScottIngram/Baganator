local _, addonTable = ...

local E, L, V, P, G
local S
local B
local LSM

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local icons = {}
local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_SCALE_CHANGED")
frame:SetScript("OnEvent", function()
  C_Timer.After(0, function()
    for _, frame in ipairs(icons) do
      local c1, c2, c3 = frame.backdrop:GetBackdropBorderColor()
      frame.backdrop:SetTemplate(nil, true, nil, nil, nil, nil, nil, true)
      frame.backdrop:SetIgnoreParentScale(true)
      frame.backdrop:SetScale(UIParent:GetScale())
      frame.backdrop:SetBackdropBorderColor(c1, c2, c3)
    end
  end)
end)

local hidden = CreateFrame("Frame")
hidden:Hide()
local skinners = {
  ItemButton = function(frame)
    frame.bgrElvUISkin = true
    frame.SlotBackground:SetParent(hidden)
    S:HandleItemButton(frame, true)
    S:HandleIconBorder(frame.IconBorder)
    if frame.SetItemButtonTexture then
      hooksecurefunc(frame, "SetItemButtonTexture", function()
        frame.icon:SetTexCoord(unpack(E.TexCoords))
      end)
    end
    if frame.JunkIcon then
      frame.JunkIcon:SetAtlas('bags-junkcoin', true)
    end
    -- Fix search overlay being removed by ElvUI in classic
    if Baganator.Constants.IsClassic then
      frame.searchOverlay:SetColorTexture(0, 0, 0, 0.8)
    end
    local cooldown = frame.Cooldown or frame:GetName() and _G[frame:GetName() .. "Cooldown"]
    if cooldown then
      E:RegisterCooldown(cooldown)
    end
    if frame.BGRUpdateQuests then
      local questTexture = frame:GetName() and _G[frame:GetName() .. "IconQuestTexture"] or frame.IconQuestTexture
      hooksecurefunc(frame, "BGRUpdateQuests", function()
        if questTexture:IsShown() then
          local textureID = questTexture:GetTexture()
          if textureID == 368362 then -- quest border only
            questTexture:SetTexture(E.Media.Textures.BagQuestIcon)
          else
            questTexture:Hide()
          end
          frame.IconBorder:SetVertexColor(unpack(B.QuestColors['questStarter']))
        end
      end)
    end
    table.insert(icons, frame)
    frame.backdrop:SetIgnoreParentScale(true)
    frame.backdrop:SetScale(UIParent:GetScale())
  end,
  IconButton = function(frame)
    S:HandleButton(frame)
  end,
  Button = function(frame)
    S:HandleButton(frame)
  end,
  ButtonFrame = function(frame)
    S:HandlePortraitFrame(frame)
  end,
  SearchBox = function(frame)
    S:HandleEditBox(frame)
  end,
  EditBox = function(frame)
    S:HandleEditBox(frame)
  end,
  TabButton = function(frame)
    S:HandleTab(frame)
  end,
  TopTabButton = function(frame)
    S:HandleTab(frame)
  end,
  SideTabButton = function(frame)
    frame.Background:Hide()

    frame.Icon:ClearAllPoints()
    frame.Icon:SetPoint("CENTER")
    frame.Icon:SetSize(25, 25)
    frame.Icon:SetTexCoord(unpack(E.TexCoords))

    frame.SelectedTexture:ClearAllPoints()
    frame.SelectedTexture:SetPoint("CENTER")
    frame.SelectedTexture:SetSize(25, 25)
    frame.SelectedTexture:SetTexture(E.Media.Textures.Melli)
    frame.SelectedTexture:SetVertexColor(1, .82, 0, 0.6)

    S:HandleTab(frame)
    frame:SetTemplate("Transparent")
  end,
  TrimScrollBar = function(frame)
    S:HandleTrimScrollBar(frame)
  end,
  CheckBox = function(frame)
    S:HandleCheckBox(frame)
  end,
  Slider = function(frame)
    S:HandleSliderFrame(frame)
  end,
  InsetFrame = function(frame)
    if frame.NineSlice then
      frame.NineSlice:SetTemplate("Transparent")
    else
      S:HandleInsetFrame(frame)
    end
  end,
  CornerWidget = function(frame, tags)
    if frame:IsObjectType("FontString") and addonTable.Config.Get("skins.elvui.use_bag_font") then
      frame:FontTemplate(LSM:Fetch('font', E.db.bags.countFont), addonTable.Config.Get("icon_text_font_size"), E.db.bags.countFontOutline)
    end
  end,
  DropDownWithPopout = function(button)
    button.HighlightTexture:SetAlpha(0)
    button.NormalTexture:SetAlpha(0)

    local r, g, b, a = unpack(E.media.backdropfadecolor)
    button.Popout:StripTextures()
    button.Popout:SetTemplate('Transparent')
    button.Popout:SetBackdropColor(r, g, b, max(a, 0.9))

    local expandArrow = button:CreateTexture(nil, "ARTWORK")
    expandArrow:SetTexture(E.Media.Textures.ArrowUp)
    expandArrow:SetRotation(S.ArrowRotation.down)
    expandArrow:Size(15)
    expandArrow:SetPoint("RIGHT", -10, 0)

    S:HandleButton(button, nil, nil, nil, true)
    button.backdrop:SetInside(nil, 4, 4)
  end,
  Divider = function(tex)
    tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", 0, 0)
    tex:SetHeight(1)
    tex:SetColorTexture(1, 0.93, 0.73, 0.45)
  end,
}

local function LoadSkin()
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    addonTable.Constants.ButtonFrameOffset = 0

    E, L, V, P, G = unpack(ElvUI)
    S = E:GetModule("Skins")
    B = E:GetModule('Bags')
    LSM = E.Libs.LSM

    if C_AddOns.IsAddOnLoaded("Masque") then
      local Masque = LibStub("Masque", true)
      local masqueGroup = Masque:Group("Baganator", "Bag")
      if not masqueGroup.db.Disabled then
        skinners.ItemButton = function() end
      end
    else
      hooksecurefunc("SetItemButtonTexture", function(frame)
        if frame.bgrElvUISkin then
          (frame.icon or frame.Icon):SetTexCoord(unpack(E.TexCoords))
        end
      end)
    end

    local function SkinFrame(details)
      local func = skinners[details.regionType]
      if func then
        func(details.region, details.tags and ConvertTags(details.tags) or {})
      end
    end

    addonTable.Skins.RegisterListener(SkinFrame)

    for _, details in ipairs(addonTable.Skins.GetAllFrames()) do
      SkinFrame(details)
    end
  end)
end

if (select(4, C_AddOns.GetAddOnInfo("ElvUI"))) then
  addonTable.Skins.RegisterSkin(BAGANATOR_L_ELVUI, "elvui", LoadSkin, {
    {
      type = "checkbox",
      text = BAGANATOR_L_USE_EXPRESSWAY_FONT_ON_ITEMS,
      option = "use_bag_font",
      rightText = BAGANATOR_L_RELOAD_REQUIRED,
      default = false,
    },
  }, true)
end
