
local SimplerMap = LibStub("AceAddon-3.0"):NewAddon("SimplerMap", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")

function SimplerMap:GetOptions()
   local opts = {
      type = "group",
      args = {
         appearence = {
            name = "Appearence",
            desc = "Controls the apperance of the map.",
            type = "group",
            order = 0,
            args = {
               fadeOpacity = {
                  name = "Fade Opacity",
                  desc = "Controls the opacity of the mini map while the character is moving.",
                  min = 0,
                  max = 1,
                  isPercent = true,
                  type = "range",
                  order = 1,
                  get = function(info)
                     return self.db.profile.fadeOpacity
                  end,
                  set = function(info, val)
                     self.db.profile.fadeOpacity = val
                     self:RefreshMap()
                  end,
               },
               scale = {
                  name = "Map Scale",
                  desc = "Sets the size of the map.",
                  min = 0,
                  max = 1,
                  type = "range",
                  order = 2,
                  get = function(info)
                     return self.db.profile.scale
                  end,
                  set = function(info, val)
                     self.db.profile.scale = val
                     self:RefreshMap()
                  end,
               },
            },
         },
      },
   }

   opts.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
   return opts
end

function SimplerMap:GetDBDefaults()
   return {
      profile = {
         fadeOpacity = 0.6,
         scale = 1.0,
      },
   }
end

function SimplerMap:OnInitialize()
   self.configAppName = "SimplerMap"

   self.db = LibStub("AceDB-3.0"):New("SimplerMap", self:GetDBDefaults(), true)
   self.opts = self:GetOptions()

   AceConfig:RegisterOptionsTable(self.configAppName, self.opts)
   self.configDialog = AceConfigDialog:AddToBlizOptions(self.configAppName)

   self.db.RegisterCallback(self, "OnProfileChanged", "RefreshMap")
   self.db.RegisterCallback(self, "OnProfileCopied", "RefreshMap")
   self.db.RegisterCallback(self, "OnProfileReset", "RefreshMap")

   self:RegisterEvent("PLAYER_LOGIN", self.RefreshMap, self)

   WorldMapFrame.BlackoutFrame.Blackout:SetAlpha(0)
   WorldMapFrame.BlackoutFrame:EnableMouse(false)

   WorldMapFrame.ScrollContainer.GetCursorPosition = function(f)
      local x,y = MapCanvasScrollControllerMixin.GetCursorPosition(f);
      local s = WorldMapFrame:GetScale();
      return x/s, y/s;
   end
end

function SimplerMap:RefreshMap()
   local duration = 0.5;
   local restOpacity = 1.0;

   PlayerMovementFrameFader.AddDeferredFrame(
      WorldMapFrame, self.db.profile.fadeOpacity, restOpacity, duration)
   WorldMapFrame:SetScale(self.db.profile.scale)
end
