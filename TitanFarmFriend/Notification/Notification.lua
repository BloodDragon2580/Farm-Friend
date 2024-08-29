local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local FarmFriendNotification = LibStub('AceAddon-3.0'):NewAddon('FarmFriendNotification');
local FRAME_NAME = 'TitanFarmFriendAlertFrameTemplate';
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmFriendAlertFrameTemplate');
local ADDON_NAME = TitanFarmFriend_GetAddOnName();
local FRAME_HIDDEN = true;


-- **************************************************************************
-- NAME : TitanFarmFriendNotification_Show()
-- DESC : Shows a notification frame for the given item link.
-- **************************************************************************
function TitanFarmFriendNotification_Show(itemName, goal, sound, duration, glow, shine)

  TitanFarmFriendNotification_HideNotification(false);

  local itemInfo = TitanFarmFriend_GetItemInfo(itemName);
  if itemInfo ~= nil then

    TitanFarmFriendNotification_SetTitle(ADDON_NAME);
    TitanFarmFriendNotification_SetWidth(400);
    TitanFarmFriendNotification_SetText(goal .. ' ' .. itemInfo.Name);
    TitanFarmFriendNotification_SetIcon(itemInfo.IconFileDataID);

    if sound ~= nil and sound ~= '' then
      PlaySound(sound);
    end

    if glow then
      FRAME.glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild");
      FRAME.glow:SetTexCoord(0.00195313, 0.74804688, 0.19531250, 0.49609375);
      FRAME.glow:SetVertexColor(1,1,1);
      FRAME.glow:Show();
    else
      FRAME.glow:Hide();
    end

    if shine then
      FRAME.shine:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild");
      FRAME.shine:SetTexCoord(0.75195313, 0.91601563, 0.19531250, 0.35937500);
      FRAME.shine:SetPoint("BOTTOMLEFT", 0, 16);
      FRAME.shine:Show();
    else
      FRAME.shine:Hide();
    end

    FRAME_HIDDEN = false;

    FRAME:Show();
    FRAME.animIn:Play();

    if glow then
      FRAME.glow.animIn:Play();
    end
    if shine then
      FRAME.shine.animIn:Play();
    end

    FRAME.waitAndAnimOut:Play();
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_HideNotification()
-- DESC : Resets the timer and hides the notification.
-- **************************************************************************
function TitanFarmFriendNotification_HideNotification(click)
  FRAME_HIDDEN = true;
  FRAME.waitAndAnimOut:Stop();
  if click == true then
    FRAME.animOut:Play();
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_SetTitle()
-- DESC : Sets the notification title.
-- **************************************************************************
function TitanFarmFriendNotification_SetTitle(title)
  FRAME.unlocked:SetText(title);
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_SetText()
-- DESC : Sets the notification text.
-- **************************************************************************
function TitanFarmFriendNotification_SetText(text)
  FRAME.Name:SetText(text);
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_SetIcon()
-- DESC : Sets the notification icon.
-- **************************************************************************
function TitanFarmFriendNotification_SetIcon(icon)
  FRAME.Icon.Texture:SetTexture(icon);
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_SetWidth()
-- DESC : Sets the notification frame width.
-- **************************************************************************
function TitanFarmFriendNotification_SetWidth(width)
  FRAME:SetWidth(width);
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_OnMouseDown()
-- DESC : Handles the OnMouseDown event for the TitanFarmFriendAnchor frame.
-- **************************************************************************
function TitanFarmFriendNotification_OnMouseDown(self, button)

  if button == 'LeftButton' and not self.isMoving then
    self:StartMoving();
    self.isMoving = true;
  end

  if button == 'RightButton' and not self.isMoving then
    self:Hide();
    Settings.OpenToCategory(ADDON_NAME);
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_OnMouseUp()
-- DESC : Handles the OnMouseUp event for the TitanFarmFriendAnchor frame.
-- **************************************************************************
function TitanFarmFriendNotification_OnMouseUp(self, button)

  if button == 'LeftButton' and self.isMoving then
    self:StopMovingOrSizing();
    self.isMoving = false;
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_ShowAnchor()
-- DESC : Shows the Notification Anchor frame.
-- **************************************************************************
function TitanFarmFriendNotification_ShowAnchor()

  -- Set Scale for Anchor frame
  TitanFarmFriendAnchor:SetScale(FRAME:GetEffectiveScale());
  TitanFarmFriendAnchor.Name:SetText(L['FARM_FRIEND_ANCHOR_HELP_TEXT']);

  InterfaceOptionsFrame:Hide();
  TitanFarmFriendAnchor:Show();
end

-- **************************************************************************
-- NAME : TitanFarmFriendNotification_Shown()
-- DESC : Gets the notification is currently shown status.
-- **************************************************************************
function TitanFarmFriendNotification_Shown()
  if FRAME_HIDDEN == false then
    return true;
  end
  return false;
end
