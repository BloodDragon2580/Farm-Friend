local TITAN_FARM_Friend_ID = 'FarmFriend';
local ADDON_NAME = 'Titan Farm Friend';
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local TitanFarmFriend = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_Friend_ID, 'AceConsole-3.0', 'AceHook-3.0', 'AceTimer-3.0', 'AceEvent-3.0');
local ADDON_VERSION = C_AddOns.GetAddOnMetadata('TitanFarmFriend', 'Version');
local OPTION_ORDER = {};
local ITEMS_AVAILABLE = 12;
local ITEM_DISPLAY_STYLES = {};
local NOTIFICATION_QUEUE = {};
local NOTIFICATION_TRIGGERED = {};
local CHAT_COMMAND = 'ff';
local CHAT_COMMANDS = {
  track = {
    Args = '<' .. L['FARM_Friend_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_Friend_COMMAND_TRACK_ARGS'] .. '>',
    Description = L['FARM_Friend_COMMAND_TRACK_DESC']
  },
  quantity = {
    Args = '<' .. L['FARM_Friend_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_Friend_COMMAND_GOAL_ARGS'] .. '>',
    Description = L['FARM_Friend_COMMAND_GOAL_DESC']
  },
  primary = {
    Args = '<' .. L['FARM_Friend_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '>',
    Description = L['FARM_Friend_COMMAND_PRIMARY_DESC']
  },
  reset = {
    Args = '<' .. L['FARM_Friend_COMMAND_RESET_ARGS'] .. '>',
    Description = L['FARM_Friend_COMMAND_RESET_DESC']
  },
  settings = {
    Args = '',
    Description = L['FARM_Friend_COMMAND_SETTINGS_DESC']
  },
  version = {
    Args = '',
    Description = L['FARM_Friend_COMMAND_VERSION_DESC']
  },
  help = {
    Args = '',
    Description = L['FARM_Friend_COMMAND_HELP_DESC']
  }
};
local ADDON_SETTING_PANEL;

-- **************************************************************************
-- NAME : TitanFarmFriend:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanFarmFriend:OnInitialize()
  LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, TitanFarmFriend:GetConfigOption());
  local _, category = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME);
  ADDON_SETTING_PANEL = category;

  self:RegisterDialogs();

  for i = 1, ITEMS_AVAILABLE do
    NOTIFICATION_TRIGGERED[i] = false;
  end

  ITEM_DISPLAY_STYLES[1] = L['FARM_Friend_ITEM_DISPLAY_STYLE_1'];
  ITEM_DISPLAY_STYLES[2] = L['FARM_Friend_ITEM_DISPLAY_STYLE_2'];

  -- Register chat command
  self:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand');

  -- Register events
  self:RegisterEvent('BAG_UPDATE', 'BagUpdate');
end

-- **************************************************************************
-- NAME : TitanFarmFriend_OnLoad()
-- DESC : Registers the plugin upon it loading.
-- **************************************************************************
function TitanFarmFriend_OnLoad(self)
	self.registry = {
		id = TITAN_FARM_Friend_ID,
		category = 'Information',
		version = TITAN_VERSION,
		menuText = ADDON_NAME,
		buttonTextFunction = 'TitanFarmFriend_GetButtonText',
		tooltipTitle = ADDON_NAME,
		tooltipTextFunction = 'TitanFarmFriend_GetTooltipText',
		icon = 'Interface\\AddOns\\TitanFarmFriend\\TitanFarmFriend',
		iconWidth = 0,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = true,
			DisplayOnRightSide = true
		},
		savedVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = true,
			DisplayOnRightSide = false,
			Item1 = '',
			Item2 = '',
			Item3 = '',
			Item4 = '',
			Item5 = '',
			Item6 = '',
			Item7 = '',
			Item8 = '',
			Item9 = '',
			Item10 = '',
			Item11 = '',
			Item12 = '',
			ItemQuantity1 = 0,
			ItemQuantity2 = 0,
			ItemQuantity3 = 0,
			ItemQuantity4 = 0,
			ItemQuantity5 = 0,
			ItemQuantity6 = 0,
			ItemQuantity7 = 0,
			ItemQuantity8 = 0,
			ItemQuantity9 = 0,
			ItemQuantity10 = 0,
			ItemQuantity11 = 0,
			ItemQuantity12 = 0,
      ItemShowInBarIndex = 1,
      ItemDisplayStyle = 2,
			GoalNotification = true,
			IncludeBank = false,
			ShowQuantity = true,
			GoalNotificationSound = SOUNDKIT.ALARM_CLOCK_WARNING_3,
			PlayNotificationSound = true,
      NotificationDisplayDuration = 5,
      NotificationGlow = true,
      NotificationShine = true,
      FastTrackingMouseButton = 'RightButton',
      FastTrackingKeys = {
        ctrl = false,
        shift = false,
        alt = true,
      },
		}
	};
end

-- **************************************************************************
-- NAME : TitanFarmFriend:OnEnable()
-- DESC : Is called when the Plugin gets enabled.
-- **************************************************************************
function TitanFarmFriend:OnEnable()
  self:SecureHook('HandleModifiedItemClick', 'ModifiedClick');
  self:ScheduleRepeatingTimer('NotificationTask', 1);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:OnDisable()
-- DESC : Is called when the Plugin gets disabled.
-- **************************************************************************
function TitanFarmFriend:OnDisable()
  self:CancelAllTimers();
end

-- **************************************************************************
-- NAME : TitanFarmFriend:RegisterDialogs()
-- DESC : Registers the addons dialog boxes.
-- **************************************************************************
function TitanFarmFriend:RegisterDialogs()

  StaticPopupDialogs[ADDON_NAME .. 'ResetAllConfirm'] = {
    text = L['TITAN_FARM_Friend_CONFIRM_ALL_RESET'],
    button1 = L['TITAN_FARM_Friend_YES'],
    button2 = L['TITAN_FARM_Friend_NO'],
    OnAccept = function()
      TitanFarmFriend:ResetConfig(false);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
  StaticPopupDialogs[ADDON_NAME .. 'ResetAllItemsConfirm'] = {
    text = L['TITAN_FARM_Friend_CONFIRM_RESET'],
    button1 = L['TITAN_FARM_Friend_YES'],
    button2 = L['TITAN_FARM_Friend_NO'],
    OnAccept = function()
      TitanFarmFriend:ResetConfig(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
  StaticPopupDialogs[ADDON_NAME .. 'SetItemIndex'] = {
    text = L['TITAN_FARM_Friend_CHOOSE_ITEM_INDEX'],
    button1 = L['TITAN_FARM_Friend_OK'],
    button2 = L['TITAN_FARM_Friend_CANCEL'],
    hasEditBox = true,
    OnShow = TitanFarmFriend_SetItemIndexOnShow,
    OnAccept = TitanFarmFriend_SetItemIndexOnAccept,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend_SetItemIndexOnShow()
-- DESC : Callback function for the SetItemIndex OnShow event.
-- **************************************************************************
function TitanFarmFriend_SetItemIndexOnShow(self)

  -- Get first position without an item as preferred default value
  local defaultIndex = 1;
  for i = 1, ITEMS_AVAILABLE do
    if TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i)) == '' then
      defaultIndex = i;
      break;
    end
  end

  -- Set default value for dialog edit box
  getglobal(self:GetName() .. 'EditBox'):SetText(tostring(defaultIndex));
end

-- **************************************************************************
-- NAME : TitanFarmFriend_SetItemIndexOnAccept()
-- DESC : Callback function for the SetItemIndex OnAccept event.
-- **************************************************************************
function TitanFarmFriend_SetItemIndexOnAccept(self, data)
  local index = tonumber(getglobal(self:GetName() .. 'EditBox'):GetText());
  if TitanFarmFriend:IsIndexValid(index) == true then
    local text = L['FARM_Friend_ITEM_SET_MSG']:gsub('!itemName!', data);
    TitanFarmFriend:SetItem(index, nil, data);
    TitanFarmFriend:Print(text);
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
  else
    local text = L['FARM_Friend_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
    TitanFarmFriend:Print(text);
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetID()
-- DESC : Gets the Titan Plugin ID.
-- **************************************************************************
function TitanFarmFriend_GetID()
  return TITAN_FARM_Friend_ID;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetAddOnName()
-- DESC : Gets the Titan Plugin AdOn name.
-- **************************************************************************
function TitanFarmFriend_GetAddOnName()
  return ADDON_NAME;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetConfigOption()
-- DESC : Gets the configuration array for the AceConfig lib.
-- **************************************************************************
function TitanFarmFriend_SetItemIndexOnShow(self)

  -- Get first position without an item as preferred default value
  local defaultIndex = 1;
  for i = 1, ITEMS_AVAILABLE do
    if TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i)) == '' then
      defaultIndex = i;
      break;
    end
  end

  -- Set default value for dialog edit box
  getglobal(self:GetName() .. 'EditBox'):SetText(tostring(defaultIndex));
end

-- **************************************************************************
-- NAME : TitanFarmFriend_SetItemIndexOnAccept()
-- DESC : Callback function for the SetItemIndex OnAccept event.
-- **************************************************************************
function TitanFarmFriend_SetItemIndexOnAccept(self, data)
  local index = tonumber(getglobal(self:GetName() .. 'EditBox'):GetText());
  if TitanFarmFriend:IsIndexValid(index) == true then
    local text = L['FARM_Friend_ITEM_SET_MSG']:gsub('!itemName!', data);
    TitanFarmFriend:SetItem(index, nil, data);
    TitanFarmFriend:Print(text);
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
  else
    local text = L['FARM_Friend_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
    TitanFarmFriend:Print(text);
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetID()
-- DESC : Gets the Titan Plugin ID.
-- **************************************************************************
function TitanFarmFriend_GetID()
  return TITAN_FARM_Friend_ID;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetAddOnName()
-- DESC : Gets the Titan Plugin AdOn name.
-- **************************************************************************
function TitanFarmFriend_GetAddOnName()
  return ADDON_NAME;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetConfigOption()
-- DESC : Gets the configuration array for the AceConfig lib.
-- **************************************************************************
function TitanFarmFriend:GetConfigOption()
	return {
		name = ADDON_NAME,
		handler = TitanFarmFriend,
    childGroups = 'tab',
		type = 'group',
		args = {
      info_version = {
        type = 'description',
        name = L['FARM_Friend_VERSION'] .. ': ' .. ADDON_VERSION,
        order = TitanFarmFriend:GetOptionOrder('main'),
      },
      info_author = {
        type = 'description',
        name = L['FARM_Friend_AUTHOR'] .. ': ' .. C_AddOns.GetAddOnMetadata('TitanFarmFriend', 'Author'),
        order = TitanFarmFriend:GetOptionOrder('main'),
      },
      tab_general = {
        name = L['FARM_Friend_SETTINGS'],
        type = 'group',
        order = TitanFarmFriend:GetOptionOrder('main'),
        args = {
          general_show_item_icon = {
            type = 'toggle',
            name = L['FARM_Friend_SHOW_ICON'],
            desc = L['FARM_Friend_SHOW_ICON_DESC'],
            get = 'GetShowItemIcon',
            set = 'SetShowItemIcon',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_show_item_name = {
            type = 'toggle',
            name = L['FARM_Friend_SHOW_NAME'],
            desc = L['FARM_Friend_SHOW_NAME_DESC'],
            get = 'GetShowItemName',
            set = 'SetShowItemName',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_show_colored_text = {
            type = 'toggle',
            name = L['FARM_Friend_SHOW_COLORED_TEXT'],
            desc = L['FARM_Friend_SHOW_COLORED_TEXT_DESC'],
            get = 'GetShowColoredText',
            set = 'SetShowColoredText',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_show_goal = {
            type = 'toggle',
            name = L['FARM_Friend_SHOW_GOAL'],
            desc = L['FARM_Friend_SHOW_GOAL_DESC'],
            get = 'GetShowQuantity',
            set = 'SetShowQuantity',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_track_bank = {
            type = 'toggle',
            name = L['FARM_Friend_INCLUDE_BANK'],
            desc = L['FARM_Friend_INCLUDE_BANK_DESC'],
            get = 'GetIncludeBank',
            set = 'SetIncludeBank',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_display_style = {
            type = 'select',
            style = 'radio',
            name = L['FARM_Friend_ITEM_DISPLAY_STYLE'],
            desc = L['FARM_Friend_ITEM_DISPLAY_STYLE_DESC'],
            get = 'GetItemDisplayStyle',
            set = 'SetItemDisplayStyle',
            width = 'full',
            values = ITEM_DISPLAY_STYLES,
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_7 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_shortcuts_heading = {
            type = 'header',
            name = L['FARM_Friend_SHORTCUTS'],
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_fast_tracking_shortcut_mouse_button = {
            type = 'select',
            style = 'radio',
            name = L['FARM_Friend_FAST_TRACKING_MOUSE_BUTTON'],
            get = 'GetFastTrackingMouseButton',
            set = 'SetFastTrackingMouseButton',
            width = 'full',
            values = {
              LeftButton = L['FARM_Friend_KEY_LEFT_MOUSE_BUTTON'],
              RightButton = L['FARM_Friend_KEY_RIGHT_MOUSE_BUTTON'],
            },
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_space_8 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
          general_fast_tracking_shortcut_keys = {
            type = 'multiselect',
            name = L['FARM_Friend_FAST_TRACKING_SHORTCUTS'],
            desc = L['FARM_Friend_FAST_TRACKING_SHORTCUTS_DESC'],
            set = 'SetKeySetting',
            get = 'GetKeySetting',
            values = {
              alt = L['FARM_Friend_KEY_ALT'],
              ctrl = L['FARM_Friend_KEY_CTRL'],
              shift = L['FARM_Friend_KEY_SHIFT'],
            },
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('general'),
          },
			  },
			},
      tab_items = {
        name = L['FARM_Friend_ITEMS'],
        type = 'group',
        order = TitanFarmFriend:GetOptionOrder('main'),
        args = {
          items_tracking_description = {
            type = 'description',
            name = L['FARM_Friend_TRACKING_DESC'],
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_1 = TitanFarmFriend:GetTrackedItemField(1),
          items_track_count_1 = TitanFarmFriend:GetTrackedItemQuantityField(1),
          items_track_show_bar_1 = TitanFarmFriend:GetTrackedItemShowBarField(1),
          items_clear_button_1 = TitanFarmFriend:GetTrackedItemClearButton(1),
          items_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_2 = TitanFarmFriend:GetTrackedItemField(2),
          items_track_count_2 = TitanFarmFriend:GetTrackedItemQuantityField(2),
          items_track_show_bar_2 = TitanFarmFriend:GetTrackedItemShowBarField(2),
          items_clear_button_2 = TitanFarmFriend:GetTrackedItemClearButton(2),
          items_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_3 = TitanFarmFriend:GetTrackedItemField(3),
          items_track_count_3 = TitanFarmFriend:GetTrackedItemQuantityField(3),
          items_track_show_bar_3 = TitanFarmFriend:GetTrackedItemShowBarField(3),
          items_clear_button_3 = TitanFarmFriend:GetTrackedItemClearButton(3),
          items_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_4 = TitanFarmFriend:GetTrackedItemField(4),
          items_track_count_4 = TitanFarmFriend:GetTrackedItemQuantityField(4),
          items_track_show_bar_4 = TitanFarmFriend:GetTrackedItemShowBarField(4),
          items_clear_button_4 = TitanFarmFriend:GetTrackedItemClearButton(4),
          items_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_5 = TitanFarmFriend:GetTrackedItemField(5),
          items_track_count_5 = TitanFarmFriend:GetTrackedItemQuantityField(5),
          items_track_show_bar_5 = TitanFarmFriend:GetTrackedItemShowBarField(5),
          items_clear_button_5 = TitanFarmFriend:GetTrackedItemClearButton(5),
          items_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_6 = TitanFarmFriend:GetTrackedItemField(6),
          items_track_count_6 = TitanFarmFriend:GetTrackedItemQuantityField(6),
          items_track_show_bar_6 = TitanFarmFriend:GetTrackedItemShowBarField(6),
          items_clear_button_6 = TitanFarmFriend:GetTrackedItemClearButton(6),
          items_space_7 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_7 = TitanFarmFriend:GetTrackedItemField(7),
          items_track_count_7 = TitanFarmFriend:GetTrackedItemQuantityField(7),
          items_track_show_bar_7 = TitanFarmFriend:GetTrackedItemShowBarField(7),
          items_clear_button_7 = TitanFarmFriend:GetTrackedItemClearButton(7),
          items_space_8 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_8 = TitanFarmFriend:GetTrackedItemField(8),
          items_track_count_8 = TitanFarmFriend:GetTrackedItemQuantityField(8),
          items_track_show_bar_8 = TitanFarmFriend:GetTrackedItemShowBarField(8),
          items_clear_button_8 = TitanFarmFriend:GetTrackedItemClearButton(8),
          items_space_9 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_9 = TitanFarmFriend:GetTrackedItemField(9),
          items_track_count_9 = TitanFarmFriend:GetTrackedItemQuantityField(9),
          items_track_show_bar_9 = TitanFarmFriend:GetTrackedItemShowBarField(9),
          items_clear_button_9 = TitanFarmFriend:GetTrackedItemClearButton(9),
          items_space_10 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_10 = TitanFarmFriend:GetTrackedItemField(10),
          items_track_count_10 = TitanFarmFriend:GetTrackedItemQuantityField(10),
          items_track_show_bar_10 = TitanFarmFriend:GetTrackedItemShowBarField(10),
          items_clear_button_10 = TitanFarmFriend:GetTrackedItemClearButton(10),
          items_space_11 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_11 = TitanFarmFriend:GetTrackedItemField(11),
          items_track_count_11 = TitanFarmFriend:GetTrackedItemQuantityField(11),
          items_track_show_bar_11 = TitanFarmFriend:GetTrackedItemShowBarField(11),
          items_clear_button_11 = TitanFarmFriend:GetTrackedItemClearButton(11),
          items_space_12 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('items'),
          },
          items_track_12 = TitanFarmFriend:GetTrackedItemField(12),
          items_track_count_12 = TitanFarmFriend:GetTrackedItemQuantityField(12),
          items_track_show_bar_12 = TitanFarmFriend:GetTrackedItemShowBarField(12),
          items_clear_button_12 = TitanFarmFriend:GetTrackedItemClearButton(12),
        },
      },
      tab_notifications = {
        name = L['FARM_Friend_NOTIFICATIONS'],
        type = 'group',
        order = TitanFarmFriend:GetOptionOrder('main'),
        args = {
          notifications_notification_status = {
            type = 'toggle',
            name = L['FARM_Friend_NOTIFICATION'],
            desc = L['FARM_Friend_NOTIFICATION_DESC'],
            get = 'GetNotificationStatus',
            set = 'SetNotificationStatus',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_notification_display_duration = {
            type = 'input',
            name = L['FARM_Friend_PLAY_NOTIFICATION_DISPLAY_DURATION'],
            desc = L['FARM_Friend_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC'],
            get = 'GetNotificationDisplayDuration',
            set = 'SetNotificationDisplayDuration',
            validate = 'ValidateNumber',
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_notification_glow = {
            type = 'toggle',
            name = L['FARM_Friend_NOTIFICATION_GLOW'],
            desc = L['FARM_Friend_NOTIFICATION_GLOW_DESC'],
            get = 'GetNotificationGlow',
            set = 'SetNotificationGlow',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_notification_shine = {
            type = 'toggle',
            name = L['FARM_Friend_NOTIFICATION_SHINE'],
            desc = L['FARM_Friend_NOTIFICATION_SHINE_DESC'],
            get = 'GetNotificationShine',
            set = 'SetNotificationShine',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_play_notification_sound = {
            type = 'toggle',
            name = L['FARM_Friend_PLAY_NOTIFICATION_SOUND'],
            desc = L['FARM_Friend_PLAY_NOTIFICATION_SOUND_DESC'],
            get = 'GetPlayNotificationSoundStatus',
            set = 'SetPlayNotificationSoundStatus',
            width = 'full',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_notification_sound = {
            type = 'select',
            name = L['TITAN_FRIEND_NOTIFICATION_SOUND'],
            style = 'dropdown',
            values = TitanFarmFriend:GetSounds(),
            set = 'SetNotificationSound',
            get = 'GetNotificationSound',
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
          notifications_move_notification = {
            type = 'execute',
            name = L['FARM_Friend_MOVE_NOTIFICATION'],
            desc = L['FARM_Friend_MOVE_NOTIFICATION_DESC'],
            func = function() TitanFarmFriendNotification_ShowAnchor() end,
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('notifications'),
          },
        }
      },
      tab_actions = {
        name = L['FARM_Friend_ACTIONS'],
        type = 'group',
        order = TitanFarmFriend:GetOptionOrder('main'),
        args = {
          actions_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
          },
          actions_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_test_alert = {
            type = 'execute',
            name = L['FARM_Friend_TEST_NOTIFICATION'],
            desc = L['FARM_Friend_TEST_NOTIFICATION_DESC'],
            func = 'TestNotification',
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('actions'),
          },
          actions_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
          },
          actions_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_reset_items = {
            type = 'execute',
            name = L['FARM_Friend_RESET_ALL_ITEMS'],
            desc = L['FARM_Friend_RESET_ALL_ITEMS_DESC'],
            func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllItemsConfirm'); end,
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('actions'),
          },
          actions_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
            width = 'full',
          },
          actions_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_reset_all = {
            type = 'execute',
            name = L['FARM_Friend_RESET_ALL'],
            desc = L['FARM_Friend_RESET_ALL_DESC'],
            func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllConfirm'); end,
            width = 'double',
            order = TitanFarmFriend:GetOptionOrder('actions'),
          },
        }
      },
      tab_about = {
        name = L['FARM_Friend_ABOUT'],
        type = 'group',
        order = TitanFarmFriend:GetOptionOrder('about'),
        args = {
          about_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('about'),
          },
          about_info_version_title = {
            type = 'description',
            name = L['FARM_Friend_VERSION'],
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'half',
          },
          about_info_version = {
            type = 'description',
            name = ADDON_VERSION,
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'double',
          },
          about_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmFriend:GetOptionOrder('about'),
          },
          about_info_author_title = {
            type = 'description',
            name = L['FARM_Friend_AUTHOR'],
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'half',
          },
          about_info_author = {
            type = 'description',
            name = C_AddOns.GetAddOnMetadata('TitanFarmFriend', 'Author'),
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'double',
          },
          about_space_3 = {
            type = 'description',
            name = '\n\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
          },
          about_info_localization_title = {
            type = 'description',
            fontSize = 'medium',
            name = TitanUtils_GetGoldText(L['FARM_Friend_LOCALIZATION']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_deDE = {
            type = 'description',
            fontSize = 'small',
            name = TitanUtils_GetGreenText(L['FARM_Friend_GERMAN']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_supporters_deDE = {
            type = 'description',
            name = '   • BloodDragon2580\n\n\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_enUS = {
            type = 'description',
            fontSize = 'small',
            name = TitanUtils_GetGreenText(L['FARM_Friend_ENGLISH']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_supporters_enUS = {
            type = 'description',
            name = '   • Keldor\n\n\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_ruRU = {
            type = 'description',
            fontSize = 'small',
            name = TitanUtils_GetGreenText(L['FARM_Friend_RUSSIAN']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_supporters_ruRU = {
            type = 'description',
            name = '   • ZamestoTV\n\n\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_support_title = {
            type = 'description',
            fontSize = 'medium',
            name = TitanUtils_GetGoldText(L['FARM_Friend_SUPPORT']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_support_text = {
            type = 'description',
            name = '   • ' .. L['FARM_Friend_SUPPORT_TEXT'] .. '\n\n\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_chat_commands_title = {
            type = 'description',
            fontSize = 'medium',
            name = TitanUtils_GetGoldText(L['FARM_Friend_CHAT_COMMANDS']) .. '\n',
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_chat_commands = {
            type = 'description',
            name = TitanFarmFriend:GetChatCommandsHelp(false),
            order = TitanFarmFriend:GetOptionOrder('about'),
            width = 'full',
          },
        }
      },
		}
	};
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetTrackedItemField()
-- DESC : A helper function to generate a item input field for the blizzard option panel.
-- **************************************************************************
function TitanFarmFriend:GetTrackedItemField(index)
  return {
    type = 'input',
    name = L['FARM_Friend_ITEM'],
    desc = L['FARM_Friend_ITEM_TO_TRACK_DESC'],
    get = function() return TitanFarmFriend:GetItem(index) end,
    set = function(info, input) TitanFarmFriend:SetItem(index, info, input) end,
    validate = 'ValidateItem',
    usage = L['FARM_Friend_ITEM_TO_TRACK_USAGE'],
    width = 'double',
    order = TitanFarmFriend:GetOptionOrder('items'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetTrackedItemQuantityField()
-- DESC : A helper function to generate a item count input field for the blizzard option panel.
-- **************************************************************************
function TitanFarmFriend:GetTrackedItemQuantityField(index)
  return {
    type = 'input',
    name = L['FARM_Friend_QUANTITY'],
    desc = L['FARM_Friend_COMMAND_GOAL_DESC'],
    get = function() return TitanFarmFriend:GetItemQuantity(index) end,
    set = function(info, input) TitanFarmFriend:SetItemQuantity(index, info, input) end,
    validate = 'ValidateNumber',
    usage = L['FARM_Friend_ALERT_COUNT_USAGE'],
    width = 'half',
    order = TitanFarmFriend:GetOptionOrder('items'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetTrackedItemShowBarField()
-- DESC : A helper function to generate a item show in Titan bar checkbox for the blizzard option panel.
-- **************************************************************************
function TitanFarmFriend:GetTrackedItemShowBarField(index)
  return {
    type = 'toggle',
    name = L['FARM_Friend_SHOW_IN_BAR'],
    desc = L['FARM_Friend_SHOW_IN_BAR_DESC'],
    get = function() return TitanFarmFriend:GetItemShowInBar(index) end,
    set = function(info, input) TitanFarmFriend:SetItemShowInBar(index, info, input) end,
    width = 'half',
    order = TitanFarmFriend:GetOptionOrder('items'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetTrackedItemClearButton()
-- DESC : A helper function to generate a button for the blizzard option panel to reset the tracked item.
-- **************************************************************************
function TitanFarmFriend:GetTrackedItemClearButton(index)
  return {
    type = 'execute',
    name = L['FARM_Friend_RESET'],
    desc = L['FARM_Friend_RESET_DESC'],
    func = function() TitanFarmFriend:ResetItem(index) end,
    order = TitanFarmFriend:GetOptionOrder('items'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetOptionOrder()
-- DESC : A helper function to order the option items in the order as listed in the array.
-- **************************************************************************
function TitanFarmFriend:GetOptionOrder(category)

  if not OPTION_ORDER.category then
    OPTION_ORDER.category = 0
  end

	OPTION_ORDER.category = OPTION_ORDER.category + 1;
	return OPTION_ORDER.category;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetButtonText()
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanFarmFriend_GetButtonText(id)

	local str = '';
  local items = {};
  local showIcon = TitanGetVar(TITAN_FARM_Friend_ID, 'ShowIcon');
  local itemDisplayStyle = tonumber(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemDisplayStyle'));
  local activeIndex = TitanGetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex');

  -- Create item table
  for i = 1, ITEMS_AVAILABLE do
    if (itemDisplayStyle == 1 and activeIndex == i) or (itemDisplayStyle == 2 or itemDisplayStyle == 3) then
      local item = TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i));
      if item ~= nil and item ~= '' then
        items[i] = {
          Name = item,
          Quantity = tonumber(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(i))),
        };
      end
    end
  end

  for i, item in pairs(items) do
  	local itemStr = TitanFarmFriend:GetItemString(item, showIcon);
  	if itemStr ~= nil and itemStr ~= '' then
  		if i > 1 then
  		  str = str .. '   ';
  		end
  		str = str .. itemStr;
  	end
  end

  -- No item found
  if str == '' then
    if showIcon then
			str = str .. TitanFarmFriend:GetIconString('Interface\\AddOns\\TitanFarmFriend\\TitanFarmFriend', true);
		end

		str = str .. ADDON_NAME;
  end

	return str;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNameFromItemLink()
-- DESC : Gets the item link without the brackets.
-- **************************************************************************
function TitanFarmFriend:GetNameFromItemLink(itemLink)
  local itemLinkNoBrackets = itemLink:gsub("%[(.-)%]", "%1")
  return itemLinkNoBrackets;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetItemString()
-- DESC : Gets the item string to display on the Titan Panel button.
-- **************************************************************************
function TitanFarmFriend:GetItemString(item, showIcon)

  local str = '';
  local itemInfo = TitanFarmFriend_GetItemInfo(item.Name);

  -- Invalid item or no item defined
  if itemInfo ~= nil then

    local showColoredText = TitanGetVar(TITAN_FARM_Friend_ID, 'ShowColoredText');
    local itemCount = TitanFarmFriend_GetCount(itemInfo);

    if showIcon then
      str = str .. TitanFarmFriend:GetIconString(itemInfo.IconFileDataID, true);
    end

    str = str .. TitanFarmFriend:GetBarValue(itemCount, showColoredText);

    if TitanGetVar(TITAN_FARM_Friend_ID, 'ShowQuantity') and item.Quantity > 0 then
      str = str .. ' / ' .. TitanFarmFriend:GetBarValue(item.Quantity, showColoredText);
    end

    if TitanGetVar(TITAN_FARM_Friend_ID, 'ShowLabelText') then
      str = str .. ' ' .. TitanFarmFriend:GetNameFromItemLink(item.Name);
    end
  end

  return str;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanFarmFriend:GetIconString(icon, space)
  local fontSize = TitanPanelGetVar('FontSize') + 6;
	local str = '|T' .. icon .. ':' .. fontSize .. '|t';
	if space == true then
		str = str .. ' ';
	end
	return str;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetBarValue()
-- DESC : Gets a value with highlighted color for the Titan Bar.
-- **************************************************************************
function TitanFarmFriend:GetBarValue(value, colored)
	if colored then
		value = TitanUtils_GetHighlightText(value);
	end
	return value;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanFarmFriend_OnClick(self, button)
	if (button == 'LeftButton') then
    Settings.OpenToCategory(ADDON_SETTING_PANEL);
 	end
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetItemInfo()
-- DESC : Gets information for the given item name.
-- **************************************************************************
function TitanFarmFriend_GetItemInfo(name)

  if name then

    local itemName, itemLink = GetItemInfo(name);

    if itemLink == nil then
      return nil;
    else

      local countBags = GetItemCount(itemLink);
      local countTotal = GetItemCount(itemLink, true);
      local _, itemID = strsplit(':', itemLink);
      local info = {
        ItemID = itemID,
        Name = TitanFarmFriend:GetNameFromItemLink(itemLink),
        Link = itemLink,
        IconFileDataID = GetItemIcon(itemLink),
        CountBags = countBags,
        CountTotal = countTotal,
        CountBank = (countTotal - countBags),
      };

      return info;
    end
  end

  return nil;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanFarmFriend_GetTooltipText()

	local str = TitanUtils_GetGreenText(L['FARM_Friend_TOOLTIP_DESC']) .. '\n' ..
              TitanUtils_GetGreenText(L['FARM_Friend_TOOLTIP_MODIFIER']) .. '\n\n';
  local strTmp = '';
  local itemInfo = TitanFarmFriend_GetItemInfo(TitanGetVar(TITAN_FARM_Friend_ID, 'Item'));
  local hasItem = false;

  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i));

    -- No item set for this index
    if item ~= nil and item ~= '' then
      local itemInfo = TitanFarmFriend_GetItemInfo(item);

      -- Invalid item or no item defined
      if itemInfo ~= nil then
        local goalValue = L['FARM_Friend_NO_GOAL'];
    		local goal = tonumber(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(i)));

    		if goal > 0 then
    			goalValue = goal;
    		end

        strTmp = strTmp .. '\n';
    		strTmp = strTmp .. L['FARM_Friend_ITEM'] .. ':\t' .. TitanFarmFriend:GetIconString(itemInfo.IconFileDataID, true) .. TitanUtils_GetHighlightText(itemInfo.Name) .. '\n';
    		strTmp = strTmp .. L['FARM_Friend_INVENTORY'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBags) .. '\n';
    		strTmp = strTmp .. L['FARM_Friend_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBank) .. '\n';
    		strTmp = strTmp .. L['FARM_Friend_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountTotal) .. '\n';
    		strTmp = strTmp .. L['FARM_Friend_ALERT_COUNT'] .. ':\t' .. TitanUtils_GetHighlightText(goalValue) .. '\n';
        hasItem = true;
  		end
    end
  end

  if hasItem == true then
    str = str .. TitanUtils_GetHighlightText(L['FARM_Friend_SUMMARY']);
    str = str .. '\n------------------------------------';
    str = str .. strTmp;
  else
    str = str .. L['FARM_Friend_NO_ITEM_TRACKED'];
  end

	return str;
end

-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareFarmFriendMenu()
-- DESC : Display right click menu options
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareFarmFriendMenu(frame, level, menuList)

	if level == 1 then

		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_FARM_Friend_ID].menuText, level);

		info = {};
		info.notCheckable = true;
		info.text = L['TITAN_PANEL_OPTIONS'];
		info.menuList = 'Options';
		info.hasArrow = 1;
    UIDropDownMenu_AddButton(info);

    info = {};
		info.notCheckable = true;
		info.text = L['FARM_Friend_NOTIFICATIONS'];
		info.menuList = 'Notifications';
		info.hasArrow = 1;
    UIDropDownMenu_AddButton(info);

    info = {};
		info.notCheckable = true;
		info.text = L['FARM_Friend_ACTIONS'];
		info.menuList = 'Actions';
		info.hasArrow = 1;
    UIDropDownMenu_AddButton(info);

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddToggleIcon(TITAN_FARM_Friend_ID);
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_FARM_Friend_ID);
		TitanPanelRightClickMenu_AddToggleColoredText(TITAN_FARM_Friend_ID);
		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddCommand(L['FARM_Friend_RESET'], TITAN_FARM_Friend_ID, 'TitanFarmFriend_ResetConfig');
		TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_FARM_Friend_ID, TITAN_PANEL_MENU_FUNC_HIDE);

	elseif level == 2 then

    if menuList == 'Options' then

      TitanPanelRightClickMenu_AddTitle(L['TITAN_PANEL_OPTIONS'], level);

  		info = {};
  		info.text = L['FARM_Friend_SHOW_GOAL'];
  		info.func = TitanFarmFriend_ToggleShowQuantity;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'ShowQuantity');
      UIDropDownMenu_AddButton(info, level);

  		info = {};
  		info.text = L['FARM_Friend_INCLUDE_BANK'];
  		info.func = TitanFarmFriend_ToggleIncludeBank;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'IncludeBank');
      UIDropDownMenu_AddButton(info, level);

    elseif menuList == 'Notifications' then

      info = {};
  		info.text = L['FARM_Friend_NOTIFICATION'];
  		info.func = TitanFarmFriend_ToggleGoalNotification;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotification');
      UIDropDownMenu_AddButton(info, level);

      UIDropDownMenu_AddSeparator(level);

      info = {};
  		info.text = L['FARM_Friend_NOTIFICATION_GLOW'];
  		info.func = TitanFarmFriend_ToggleNotificationGlow;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationGlow');
  		UIDropDownMenu_AddButton(info, level);

      info = {};
  		info.text = L['FARM_Friend_NOTIFICATION_SHINE'];
  		info.func = TitanFarmFriend_ToggleNotificationShine;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationShine');
  		UIDropDownMenu_AddButton(info, level);

      info = {};
  		info.text = L['FARM_Friend_PLAY_NOTIFICATION_SOUND'];
  		info.func = TitanFarmFriend_TogglePlayNotificationSound;
  		info.checked = TitanGetVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound');
  		UIDropDownMenu_AddButton(info, level);

    elseif menuList == 'Actions' then

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_Friend_TEST_NOTIFICATION'];
    	info.value = 'SettingsCustom';
    	info.func = function() TitanFarmFriend:TestNotification(); end;
      UIDropDownMenu_AddButton(info, level);

      UIDropDownMenu_AddSeparator(level);

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_Friend_RESET_ALL_ITEMS'];
    	info.value = '';
    	info.func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllItemsConfirm'); end;
      UIDropDownMenu_AddButton(info, level);

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_Friend_RESET_ALL'];
    	info.value = '';
    	info.func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllConfirm'); end;
      UIDropDownMenu_AddButton(info, level);
    end
	end
end

-- **************************************************************************
-- NAME : TitanFarmFriend:BagUpdate()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanFarmFriend:BagUpdate()
  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i));
    if item ~= nil and item ~= '' then
      local quantity = tonumber(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(i)));
      if quantity > 0 then
        local itemInfo = TitanFarmFriend_GetItemInfo(item);
        if itemInfo ~= nil then
          local count = TitanFarmFriend_GetCount(itemInfo);
          if count >= quantity then
            self:QueueNotification(itemInfo.ItemID, item, quantity);
          else
            NOTIFICATION_QUEUE[itemInfo.ItemID] = nil;
            NOTIFICATION_TRIGGERED[itemInfo.ItemID] = false;
          end
        end
      end
    end
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend_GetCount()
-- DESC : Gets the item count.
-- **************************************************************************
function TitanFarmFriend_GetCount(itemInfo)

  local includeBank = TitanGetVar(TITAN_FARM_Friend_ID, 'IncludeBank');
  local count = itemInfo.CountBags;

  if includeBank == 1 or includeBank == true then
    count = itemInfo.CountTotal;
  end

  return count;
end

-- **************************************************************************
-- NAME : TitanFarmFriend_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanFarmFriend_OnShow(self)

  -- SOUNDKIT Fix for Patch 7.3
  -- Since 7.3 the sound is a number so check if we have a string
  -- from AddON version <= 1.1.6
  local sound = TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound');
  if sound ~= nil then
    if not tonumber(sound) then
      TitanSetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound', SOUNDKIT.ALARM_CLOCK_WARNING_3);
    end
  end

	TitanPanelButton_OnShow(self);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ValidateItem()
-- DESC : Checks if the entered item name is valid.
-- **************************************************************************
function TitanFarmFriend:ValidateItem(info, input)

	local _, itemLink = GetItemInfo(input);

	if itemLink ~= nil then
		return true;
	end

	TitanFarmFriend:Print(L['FARM_Friend_ITEM_NOT_EXISTS']);
	return false;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ValidateNumber()
-- DESC : Checks if the entered value a valid and positive number.
-- **************************************************************************
function TitanFarmFriend:ValidateNumber(info, input)

  local number = tonumber(input);
  if not number or number < 0 then
    TitanFarmFriend:Print(L['FARM_Friend_INVALID_NUMBER']);
    return false;
  end

  return true;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetItem()
-- DESC : Gets the item.
-- **************************************************************************
function TitanFarmFriend:GetItem(index)
  return TitanGetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(index));
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetItem()
-- DESC : Sets the item.
-- **************************************************************************
function TitanFarmFriend:SetItem(index, info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(index), input);
  TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
  NOTIFICATION_TRIGGERED[index] = false;
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ResetItem()
-- DESC : Resets the item with the given index.
-- **************************************************************************
function TitanFarmFriend:ResetItem(index)
  TitanSetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(index), '');
  TitanSetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(index), '0');

  if tostring(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex')) == tostring(index) then
    TitanSetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex', 1);
  end

  TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
  NOTIFICATION_TRIGGERED[index] = false;
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetItemQuantity()
-- DESC : Gets the item goal.
-- **************************************************************************
function TitanFarmFriend:GetItemQuantity(index)
  return tostring(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(index)));
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetItemQuantity()
-- DESC : Sets the item goal.
-- **************************************************************************
function TitanFarmFriend:SetItemQuantity(index, info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(index), tonumber(input));
  TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
  NOTIFICATION_TRIGGERED[index] = false;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetItemShowInBar()
-- DESC : Gets the item show in bar status.
-- **************************************************************************
function TitanFarmFriend:GetItemShowInBar(index)
  if tostring(TitanGetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex')) == tostring(index) then
    return true;
  end
  return false;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetItemShowInBar()
-- DESC : Sets the item show in bar status.
-- **************************************************************************
function TitanFarmFriend:SetItemShowInBar(index, info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex', index);
  TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetNotificationStatus()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmFriend:SetNotificationStatus(info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'GoalNotification', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNotificationStatus()
-- DESC : Gets the notification status.
-- **************************************************************************
function TitanFarmFriend:GetNotificationStatus()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotification');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetItemDisplayStyle()
-- DESC : Sets the item display style.
-- **************************************************************************
function TitanFarmFriend:SetItemDisplayStyle(info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'ItemDisplayStyle', input);
  TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetItemDisplayStyle()
-- DESC : Gets the item display style.
-- **************************************************************************
function TitanFarmFriend:GetItemDisplayStyle()
  return TitanGetVar(TITAN_FARM_Friend_ID, 'ItemDisplayStyle');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetFastTrackingMouseButton()
-- DESC : Sets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmFriend:SetFastTrackingMouseButton(info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'FastTrackingMouseButton', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetFastTrackingMouseButton()
-- DESC : Gets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmFriend:GetFastTrackingMouseButton()
  return TitanGetVar(TITAN_FARM_Friend_ID, 'FastTrackingMouseButton');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetKeySetting()
-- DESC : Sets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmFriend:SetKeySetting(info, key, state)

  local options = TitanGetVar(TITAN_FARM_Friend_ID, 'FastTrackingKeys');

  if (options[key] ~= nil) then
    options[key] = state;
  end

  TitanSetVar(TITAN_FARM_Friend_ID, 'FastTrackingKeys', options);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetKeySetting()
-- DESC : Gets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmFriend:GetKeySetting(info, key)

  local options = TitanGetVar(TITAN_FARM_Friend_ID, 'FastTrackingKeys');

  if (options[key] ~= nil) then
    return options[key];
  end

  return false;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetPlayNotificationSoundStatus()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmFriend:SetPlayNotificationSoundStatus(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetPlayNotificationSoundStatus()
-- DESC : Gets the play notification sound status.
-- **************************************************************************
function TitanFarmFriend:GetPlayNotificationSoundStatus()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetNotificationDisplayDuration()
-- DESC : Sets the notification display duration.
-- **************************************************************************
function TitanFarmFriend:SetNotificationDisplayDuration(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationDisplayDuration', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNotificationDisplayDuration()
-- DESC : Gets the notification display duration.
-- **************************************************************************
function TitanFarmFriend:GetNotificationDisplayDuration()
	return tostring(TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationDisplayDuration'));
end

-- **************************************************************************
-- NAME : TitanFarmFriend_TogglePlayNotificationSound()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmFriend_TogglePlayNotificationSound()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetNotificationSound()
-- DESC : Sets the notification sound.
-- **************************************************************************
function TitanFarmFriend:SetNotificationSound(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound', input);
	PlaySound(input, 'master');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNotificationSound()
-- DESC : Gets the notification sound.
-- **************************************************************************
function TitanFarmFriend:GetNotificationSound()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmFriend:SetNotificationGlow(info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationGlow', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNotificationGlow()
-- DESC : Gets the notification glow effect status.
-- **************************************************************************
function TitanFarmFriend:GetNotificationGlow()
  return TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationGlow');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmFriend:SetNotificationShine(info, input)
  TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationShine', input);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetNotificationShine()
-- DESC : Gets the notification shine effect status.
-- **************************************************************************
function TitanFarmFriend:GetNotificationShine()
  return TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationShine');
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ToggleGoalNotification()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmFriend_ToggleGoalNotification()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'GoalNotification');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ToggleNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmFriend_ToggleNotificationGlow()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'NotificationGlow');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ToggleNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmFriend_ToggleNotificationShine()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'NotificationShine');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetShowItemIcon()
-- DESC : Sets the show item icon status.
-- **************************************************************************
function TitanFarmFriend:SetShowItemIcon(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowIcon', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetShowItemIcon()
-- DESC : Gets the show item icon status.
-- **************************************************************************
function TitanFarmFriend:GetShowItemIcon()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'ShowIcon');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetShowItemName()
-- DESC : Sets the show item name status.
-- **************************************************************************
function TitanFarmFriend:SetShowItemName(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowLabelText', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetShowItemName()
-- DESC : Gets the show item name status.
-- **************************************************************************
function TitanFarmFriend:GetShowItemName()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'ShowLabelText');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetShowColoredText()
-- DESC : Sets the show colored text status.
-- **************************************************************************
function TitanFarmFriend:SetShowColoredText(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowColoredText', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetShowColoredText()
-- DESC : Gets the show colored text status.
-- **************************************************************************
function TitanFarmFriend:GetShowColoredText()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'ShowColoredText');
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmFriend:SetShowQuantity(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowQuantity', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetShowQuantity()
-- DESC : Gets the show goal status.
-- **************************************************************************
function TitanFarmFriend:GetShowQuantity()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'ShowQuantity');
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ToggleShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmFriend_ToggleShowQuantity()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'ShowQuantity');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:SetTrackBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmFriend:SetIncludeBank(info, input)
	TitanSetVar(TITAN_FARM_Friend_ID, 'IncludeBank', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetTrackBank()
-- DESC : Gets the track items in bank status.
-- **************************************************************************
function TitanFarmFriend:GetIncludeBank()
	return TitanGetVar(TITAN_FARM_Friend_ID, 'IncludeBank');
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ToggleIncludeBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmFriend_ToggleIncludeBank()
	TitanToggleVar(TITAN_FARM_Friend_ID, 'IncludeBank');
	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmFriend:ResetConfig(itemsOnly)

  if itemsOnly == false then
    TitanSetVar(TITAN_FARM_Friend_ID, 'GoalNotification', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowQuantity', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'IncludeBank', false);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowIcon', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowLabelText', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ShowColoredText', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound', 'ALARM_CLOCK_WARNING_3');
  	TitanSetVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationDisplayDuration', 5);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex', 1);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'ItemDisplayStyle', 2);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationGlow', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'NotificationShine', true);
  	TitanSetVar(TITAN_FARM_Friend_ID, 'FastTrackingMouseButton', 'RightButton');
  	TitanSetVar(TITAN_FARM_Friend_ID, 'FastTrackingKeys', {
      ctrl = false,
      shift = false,
      alt = true,
    });
  end

  -- Reset items
  for i = 1, ITEMS_AVAILABLE do
    TitanSetVar(TITAN_FARM_Friend_ID, 'Item' .. tostring(i), '');
    TitanSetVar(TITAN_FARM_Friend_ID, 'ItemQuantity' .. tostring(i), 0);
    NOTIFICATION_TRIGGERED[i] = false;
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanFarmFriend_ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmFriend_ResetConfig()
	TitanFarmFriend:ResetConfig(false);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:TestNotification()
-- DESC : Raises a test notification.
-- **************************************************************************
function TitanFarmFriend:TestNotification()
  TitanFarmFriend:ShowNotification(0, L['FARM_Friend_NOTIFICATION_DEMO_ITEM_NAME'], 200, true);
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ModifiedClick()
-- DESC : Is called when an item is clicked with modifier key.
-- **************************************************************************
function TitanFarmFriend:ModifiedClick(itemLink, itemLocation)

  -- item location can be nil for bags/bank/mail and is not nil for inventory slots, make an explicit check
  if itemLocation and itemLocation.IsBagAndSlot and (not itemLocation:IsBagAndSlot()) then
    return;
  end

  local fastTrackingMouseButton = TitanGetVar(TITAN_FARM_Friend_ID, 'FastTrackingMouseButton');
  local fastTrackingKeys = TitanGetVar(TITAN_FARM_Friend_ID, 'FastTrackingKeys');
  local conditions = false;

  -- Check modifier keys
  for key, state in pairs(fastTrackingKeys) do
    if (key == 'alt') then
      if (state == true) then
        conditions = IsAltKeyDown();
      else
        conditions = not IsAltKeyDown();
      end;

      if (conditions == false) then
        break;
      end;

    elseif (key == 'ctrl') then
      if (state == true) then
        conditions = IsControlKeyDown();
      else
        conditions = not IsControlKeyDown();
      end;

      if (conditions == false) then
        break;
      end

    elseif (key == 'shift') then
      if (state == true) then
        conditions = IsShiftKeyDown();
      else
        conditions = not IsShiftKeyDown();
      end;

      if (conditions == false) then
        break;
      end
    end
  end

  if GetMouseButtonClicked() == fastTrackingMouseButton and not CursorHasItem() and conditions == true then
    if itemLink ~= nil then
      local dialog = StaticPopup_Show(ADDON_NAME .. 'SetItemIndex', tostring(ITEMS_AVAILABLE));
      if dialog then
        dialog.data = itemLink;
      end
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend:QueueNotification()
-- DESC : Queues a notification.
-- **************************************************************************
function TitanFarmFriend:QueueNotification(index, item, quantity)
  NOTIFICATION_QUEUE[index] = {
    Index = index,
    Item = item,
    Quantity = quantity,
  };
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ShowNotification()
-- DESC : Raises a notification.
-- **************************************************************************
function TitanFarmFriend:ShowNotification(index, item, quantity, demo)

  local triggerStatus = true;
  if (NOTIFICATION_TRIGGERED[index] == nil or NOTIFICATION_TRIGGERED[index] == false) then
    triggerStatus = false;
  end

  local notificationEnabled = TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotification');
  if (notificationEnabled == true and triggerStatus == false) or demo == true then

    local playSound = TitanGetVar(TITAN_FARM_Friend_ID, 'PlayNotificationSound');
    local notificationDisplayDuration = tonumber(TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationDisplayDuration'));
    local notificationGlow = TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationGlow');
    local notificationShine = TitanGetVar(TITAN_FARM_Friend_ID, 'NotificationShine');
    local sound = nil;

    if demo == true then
      item = L['FARM_Friend_NOTIFICATION_DEMO_ITEM_NAME'];
    end

    if playSound == true then
      sound = TitanGetVar(TITAN_FARM_Friend_ID, 'GoalNotificationSound');
    end

    if demo == false then
      NOTIFICATION_TRIGGERED[index] = true;
    end

    TitanFarmFriendNotification_Show(item, quantity, sound, notificationDisplayDuration, notificationGlow, notificationShine);
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend:NotificationTask()
-- DESC : Is called by the timer to handle the next notification.
-- **************************************************************************
function TitanFarmFriend:NotificationTask()
  if TitanFarmFriendNotification_Shown() == false then
    for index, notification in pairs(NOTIFICATION_QUEUE) do
      TitanFarmFriend:ShowNotification(notification.Index, notification.Item, notification.Quantity, false);
      NOTIFICATION_QUEUE[index] = nil;
      break;
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend:ChatCommand()
-- DESC : Handles AddOn commands.
-- **************************************************************************
function TitanFarmFriend:ChatCommand(input)

  local cmd, value, arg1 = TitanFarmFriend:GetArgs(input, 3);

  -- Show help
  if not cmd or cmd == 'help' then

    TitanFarmFriend:Print(L['FARM_Friend_COMMAND_LIST'] .. '\n');
    TitanFarmFriend:GetChatCommandsHelp(true);

  -- Prints version information
  elseif cmd == 'version' then
    TitanFarmFriend:Print(ADDON_VERSION);

  -- Reset AddOn settings
  elseif cmd == 'reset' then

    if value == 'all' then
      TitanFarmFriend:ResetConfig(false);
    else
      TitanFarmFriend:ResetConfig(true);
    end

    TitanFarmFriend:Print(L['FARM_Friend_CONFIG_RESET_MSG']);

  elseif cmd == 'primary' then

    local index = tonumber(value);

    if TitanFarmFriend:IsIndexValid(index) == true then
      local text = L['FARM_Friend_ITEM_PRIMARY_SET_MSG']:gsub('!position!', tostring(index));
      TitanSetVar(TITAN_FARM_Friend_ID, 'ItemShowInBarIndex', index);
      TitanFarmFriend:Print(text);
      TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
      LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
    else
      local text = L['FARM_Friend_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
      TitanFarmFriend:Print(text);
    end

  -- Set goal quantity
  elseif cmd == 'quantity' then

    if value ~= nil then
      local status = TitanFarmFriend:ValidateNumber(nil, arg1);
      if status == true then
        local index = tonumber(value);
        if TitanFarmFriend:IsIndexValid(index) == true then
          TitanFarmFriend:SetItemQuantity(index, nil, arg1);
          TitanFarmFriend:Print(L['FARM_Friend_GOAL_SET']);
          TitanPanelButton_UpdateButton(TITAN_FARM_Friend_ID);
          LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
        else
          local text = L['FARM_Friend_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
          TitanFarmFriend:Print(text);
        end
      end
    else
      TitanFarmFriend:Print(L['FARM_Friend_COMMAND_GOAL_PARAM_MISSING']);
    end

  -- Set tracked item
  elseif cmd == 'track' then

    if value ~= nil then
      print(TitanFarmFriend_GetItemInfo(arg1))
      local itemInfo = TitanFarmFriend_GetItemInfo(arg1);
      if itemInfo ~= nil then
        local index = tonumber(value);
        if TitanFarmFriend:IsIndexValid(index) == true then
          TitanFarmFriend:SetItem(index, nil, itemInfo.Name);
          local text = L['FARM_Friend_ITEM_SET_MSG']:gsub('!itemName!', itemInfo.Link);
          TitanFarmFriend:Print(text);
        else
          local text = L['FARM_Friend_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
          TitanFarmFriend:Print(text);
        end
      else
        TitanFarmFriend:Print(L['FARM_Friend_ITEM_NOT_EXISTS']);
      end
    else
      TitanFarmFriend:Print(L['FARM_Friend_TRACK_ITEM_PARAM_MISSING']);
    end
  elseif cmd == 'settings' then
    Settings.OpenToCategory(ADDON_SETTING_PANEL);
  end
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetChatCommandsHelp()
-- DESC : Returns the help text of the chat commands.
-- **************************************************************************
function TitanFarmFriend:GetChatCommandsHelp(printOut)

  local helpStr = '';

  for command, info in pairs(CHAT_COMMANDS) do
    helpStr = helpStr .. TitanUtils_GetGreenText('/' .. CHAT_COMMAND) .. ' ' .. TitanUtils_GetRedText(command);
    if info.Args ~= '' then
      helpStr = helpStr .. ' ' .. TitanUtils_GetGoldText(info.Args);
    end
    helpStr = helpStr .. ' - ' .. info.Description;
    if printOut then
      print(helpStr);
      helpStr = '';
    else
      helpStr = helpStr .. '\n';
    end
  end

  return helpStr;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:IsIndexValid()
-- DESC : Returns the index status.
-- **************************************************************************
function TitanFarmFriend:IsIndexValid(index)
  if index ~= nil and index > 0 and index <= ITEMS_AVAILABLE then
    return true;
  end
  return false;
end

-- **************************************************************************
-- NAME : TitanFarmFriend:GetSounds()
-- DESC : Get a list of available sounds.
-- **************************************************************************
function TitanFarmFriend:GetSounds()

	local sounds = {};

	for k, v in pairs(SOUNDKIT) do
		sounds[v] = k;
	end

	return sounds;
end
