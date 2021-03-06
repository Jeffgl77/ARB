local ARB_channel, ARB_focus, ARB_sendWhisper

---------------------
-- utility functions
---------------------
function RGBPercToHex(r, g, b)
   r = r <= 1 and r >= 0 and r or 0
   g = g <= 1 and g >= 0 and g or 0
   b = b <= 1 and b >= 0 and b or 0
   return string.format("%02x%02x%02x", math.ceil(r*255), math.ceil(g*255), math.ceil(b*255))
end

function ARB_classColor() 
   local class, classFileName = UnitClass("player")
   local color = RAID_CLASS_COLORS[classFileName]
   return RGBPercToHex(color.r,color.g,color.b)
end

function ARB_show(text, sendIt)
   local c = ARB_classColor()

   -- get highest allowed channel to send messages
   if (UnitIsRaidOfficer('player') or UnitIsGroupLeader('player')) then
      ARB_channel = 'RAID_WARNING'
   elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
      ARB_channel = 'INSTANCE_CHAT'
   elseif GetNumGroupMembers()>5 then
      ARB_channel = 'RAID'
   elseif GetNumGroupMembers()>0 then
      ARB_channel = 'PARTY'
   else
      ARB_channel = 'SAY'
   end

   -- determine if we are self messaging
   if sendIt == 1 then
      if (ARB_sendWhisper == true and ARB_focus ~= false) then
         SendChatMessage(text,"WHISPER",nil,ARB_focus)
         ARB_sendWhisper = false
      end
      SendChatMessage(text,ARB_channel)
      if ARB_channel == 'SAY' then
         SendChatMessage(text,'YELL')
      end
   else
      print("|cff" ..c.. " <<ARB>> : " ..text.. "|r")
   end

end

function ARB_getCount(array)
   local count = 0 for _ in pairs(array) do count = count + 1 end return count
end

function ARB_moveIt(frame)
   frame:EnableMouse(true)
   frame:SetMovable(true)
   frame:RegisterForDrag("LeftButton")
   frame:SetScript("OnDragStart", frame.StartMoving)
   frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function ARB_BtnCoordsX(btnNumber,btnSpacing,btnWidth)
   return (btnNumber * btnSpacing) + (btnWidth * (btnNumber - 1))
end

function ARB_BtnCoordsY(btnRow,btnSpacing,btnHeight)
   return (btnRow * btnSpacing) + (btnHeight * (btnRow - 1))
end

function ARB_getFocus()
   if UnitExists("focus") then
      ARB_focus = GetUnitName("focus",true)
   else
      ARB_focus = false
   end
end

function ARB_setBtnTex(frame)
   frame:SetNormalTexture("Interface\\Addons\\ARB\\Media\\Themes\\SyncUI\\ButtonNormal")
   frame:SetPushedTexture("Interface\\Addons\\ARB\\Media\\Themes\\SyncUI\\ButtonPushed")
   frame:EnableMouse()
end

function ARB_setBtnFont(frame)
   local class, classFileName = UnitClass("player")
   local color = RAID_CLASS_COLORS[classFileName]
   local ARB_font = ARB_f:CreateFontString()
   ARB_font:SetFont("Interface\\Addons\\ARB\\Media\\Fonts\\Roboto.ttf",10)
   frame:SetFontString(ARB_font)
   frame:SetScript("OnEnter", function() ARB_f:SetAlpha(1) ARB_font:SetTextColor(color.r,color.g,color.b,1) end)
   frame:SetScript("OnLeave", function() ARB_f:SetAlpha(.1) ARB_font:SetTextColor(1,1,1,1) end)
end

---------------------
-- frame functions
---------------------
function ARB_makeFrame()
   local ARB_maxButtonsPerRow = 4
   local ARB_buttonSpacing = 5
   local ARB_buttonWidth = 60
   local ARB_buttonHeight = 30
   local ARB_buttons = {
      "Taunt",
      "Stack",
      "Spread",
      "Adds",
      "Chains",
      "Tanks",
      "Priority",
      "Ready"
   }
   local ARB_numButtons = ARB_getCount(ARB_buttons)
   local ARB_numRows = ((ARB_numButtons < ARB_maxButtonsPerRow) and 1 or math.ceil(ARB_numButtons/ARB_maxButtonsPerRow))
   local ARB_frameWidth = (ARB_maxButtonsPerRow * ARB_buttonWidth) + ((ARB_maxButtonsPerRow + 1) * ARB_buttonSpacing)
   local ARB_frameHeight = (ARB_numRows * ARB_buttonHeight) + ((ARB_numRows + 1) * ARB_buttonSpacing)

   local ARB_f = CreateFrame("FRAME","ARB_f",UIParent)
   ARB_f:SetSize(ARB_frameWidth,ARB_frameHeight)
   ARB_f:SetPoint("CENTER",0,0)
   ARB_f:SetBackdrop({bgFile = [[Interface\AddOns\ARB\Media\Themes\SyncUI\Background]], edgeFile = [[Interface\AddOns\ARB\Media\Themes\SyncUI\Edge]], edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
   ARB_f:EnableMouse()
   ARB_f:SetAlpha(.1)
   ARB_f:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
   ARB_f:SetScript("OnLeave", function(self) self:SetAlpha(.1) end)
   ARB_f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   
   -- allow frame to be moved
   ARB_moveIt(ARB_f)

   -- create buttons
   -- btn : Taunt
   local ARB_taunt = CreateFrame("BUTTON","ARB_taunt",ARB_f)
   ARB_taunt:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_taunt:SetPoint("TOPLEFT",ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_taunt)
   ARB_setBtnFont(ARB_taunt)
   ARB_taunt:SetText(ARB_buttons[1])
   ARB_taunt:RegisterForClicks("AnyDown")
   ARB_taunt:SetScript("OnClick", function()
      ARB_getFocus()
      if ARB_focus ~= false then
         ARB_sendWhisper = true
         ARB_show("{rt3} %f, "..ARB_buttons[1].."! {rt3}",1)
      else        
         ARB_show("{rt3} "..ARB_buttons[1].."! {rt3}",1)
      end
   end)
   ARB_taunt:SetAlpha(1)
   if (UnitIsRaidOfficer('player') == false or UnitIsGroupLeader('player') == false) then
      ARB_taunt:Disable()
   end

   -- btn : Stack
   local ARB_stack = CreateFrame("BUTTON","ARB_stack",ARB_f)
   ARB_stack:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_stack:SetPoint("TOPLEFT",ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_stack)
   ARB_setBtnFont(ARB_stack)
   ARB_stack:SetText(ARB_buttons[2])
   ARB_stack:RegisterForClicks("AnyDown")
   ARB_stack:SetScript("OnClick", function(self,button) ARB_show("{rt1} "..(button == "LeftButton" and "Stack on tanks!" or "Stack!").." {rt1}",1) end)
   ARB_stack:SetAlpha(1)


   -- btn : Spread
   local ARB_spread = CreateFrame("BUTTON","ARB_spread",ARB_f)
   ARB_spread:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_spread:SetPoint("TOPLEFT",ARB_BtnCoordsX(3,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_spread)
   ARB_setBtnFont(ARB_spread)
   ARB_spread:SetText(ARB_buttons[3])
   ARB_spread:RegisterForClicks("AnyDown")
   ARB_spread:SetScript("OnClick", function(self,button) ARB_show("{rt8} "..(button == "LeftButton" and "Ranged, spread out!" or "Spread out!").." {rt8}",1) end)
   ARB_spread:SetAlpha(1)

   -- btn : Adds
   local ARB_adds = CreateFrame("BUTTON","ARB_adds",ARB_f)
   ARB_adds:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_adds:SetPoint("TOPLEFT",ARB_BtnCoordsX(4,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_adds)
   ARB_setBtnFont(ARB_adds)
   ARB_adds:SetText(ARB_buttons[4])
   ARB_adds:RegisterForClicks("AnyDown")
   ARB_adds:SetScript("OnClick", function() ARB_show(gsub("{rt7} Use {spell:34477} / {spell:57934} or run the adds to the tank(s)! {rt7}","{spell:(%d+)}",GetSpellLink),1) end)
   ARB_adds:SetAlpha(1)

   -- btn : Chains
   local ARB_chains = CreateFrame("BUTTON","ARB_chains",ARB_f)
   ARB_chains:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_chains:SetPoint("TOPLEFT",ARB_BtnCoordsX(1,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_chains)
   ARB_setBtnFont(ARB_chains)
   ARB_chains:SetText(ARB_buttons[5])
   ARB_chains:RegisterForClicks("AnyDown")
   ARB_chains:SetScript("OnClick", function() ARB_show("{rt4} Break your chains! {rt4}",1) end)
   ARB_chains:SetAlpha(1)

   -- btn : Tanks [LEFTBUTTONDOWN-mark self and focus(if exists), RIGHTBUTTONDOWN-remove raid target icons from self and focus(if exists)]
   local ARB_tanks = CreateFrame("BUTTON","ARB_tanks",ARB_f)
   ARB_tanks:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_tanks:SetPoint("TOPLEFT",ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_tanks)
   ARB_setBtnFont(ARB_tanks)
   ARB_tanks:SetText(ARB_buttons[6])
   ARB_tanks:RegisterForClicks("AnyDown")
   ARB_tanks:SetScript("OnMouseDown", function(self,button)
      ARB_getFocus()
      if button == "LeftButton" then 
         if GetRaidTargetIndex("player") == nil then
            SetRaidTarget("player",2) 
         end
         if GetRaidTargetIndex("player") ~= nil then
            ARB_show(GetUnitName("player").." marked")
         end
         if ARB_focus ~= false then
            if GetRaidTargetIndex("focus") == nil then
               SetRaidTarget("focus",5)
            end
            if GetRaidTargetIndex("focus") ~= nil then            
               ARB_show(ARB_focus.." marked")
            end
         end
      end

      if button == "RightButton" then
         SetRaidTarget("player",0)
         if ARB_focus ~= false then
            SetRaidTarget("focus",0) 
         end
         ARB_show("Lucky Charms removed.")
      end
   end)
   ARB_tanks:SetAlpha(1)

   -- btn : Priority
   local ARB_priority = CreateFrame("BUTTON","ARB_priority",ARB_f)
   ARB_priority:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_priority:SetPoint("TOPLEFT",ARB_BtnCoordsX(3,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_priority)
   ARB_setBtnFont(ARB_priority)
   ARB_priority:SetText(ARB_buttons[7])
   ARB_priority:RegisterForClicks("AnyDown")
   ARB_priority:SetScript("OnClick", function(self,button) SetRaidTarget("target",(button == "LeftButton") and 8 or 7) end)
   ARB_priority:SetAlpha(1)

   -- btn : readycheck
   local ARB_readycheck = CreateFrame("BUTTON","ARB_readycheck",ARB_f,"SecureActionButtonTemplate")
   ARB_readycheck:SetSize(ARB_buttonWidth,ARB_buttonHeight)
   ARB_readycheck:SetPoint("TOPLEFT",ARB_BtnCoordsX(4,ARB_buttonSpacing,ARB_buttonWidth),-ARB_BtnCoordsX(2,ARB_buttonSpacing,ARB_buttonHeight))
   ARB_setBtnTex(ARB_readycheck)
   ARB_setBtnFont(ARB_readycheck)
   ARB_readycheck:SetText(ARB_buttons[8])
   ARB_readycheck:SetAttribute("type","macro")
   ARB_readycheck:SetAttribute("macrotext", IsShiftKeyDown() and "/dbm pull 10" or "/readycheck")
   ARB_readycheck:SetAlpha(1)

   ARB_f:Hide()
end

function ARB_isDev()
   local battleTag = select(2, BNGetInfo())
   local counter = 1
   local len = string.len(battleTag)
   
   for i = 1, len, 3 do 
      counter = math.fmod(counter*8161, 4294967279) + (string.byte(battleTag,i)*16776193) + ((string.byte(battleTag,i+1) or (len-i+256))*8372226) + ((string.byte(battleTag,i+2) or (len-i+256))*3932164)
   end
   
   if (math.fmod(counter, 4294967291) == 745847904) then
      return true
   end
   return false
end

--=================================
-- slash commands
--=================================
SlashCmdList['MYADDON_SLASHCMD'] = function(m)
   if m == 'show' then 
      ARB_f:Show()
   elseif m == 'hide' then 
      ARB_f:Hide()
   else
      ARB_show("Error: Unknown Command")
   end
end
SLASH_MYADDON_SLASHCMD1 = '/arb'

--=================================
-- load the frame
--=================================
if (not ARB_f) then
   ARB_makeFrame()
   local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("ARB")
   local version = GetAddOnMetadata("ARB", "version")
   ARB_show(title.." ("..name..") "..version)
   --ARB_show("Welcome "..GetUnitName("player")..", would you like to test future releases, before they come out? Contact me in game. ( Illithid#1351 )")
end

