
local SimplerMap = LibStub("AceAddon-3.0"):NewAddon("SimplerMap", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")

local zoneData = {
   -- Eastern Kingdoms
   [1416] = { min = 30, max = 40 },                         -- Alterac Mountains
   [1417] = { min = 30, max = 40 },                         -- Arathi Highlands
   [1418] = { min = 35, max = 45 },                         -- Badlands
   [1419] = { min = 45, max = 55 },                         -- Blasted Lands
   [1428] = { min = 50, max = 58 },                         -- Burning Steppes
   [1430] = { min = 55, max = 60 },                         -- Deadwind Pass
   [1426] = { min =  1, max = 10 },                         -- Dun Morogh
   [1431] = { min = 18, max = 30 },                         -- Duskwood
   [1423] = { min = 53, max = 60 },                         -- Eastern Plaguelands
   [1429] = { min =  1, max = 10 },                         -- Elwynn Forest
   [1424] = { min = 20, max = 35 },                         -- Hillsbrad Foothills
   [1432] = { min = 10, max = 20 },                         -- Loch Modan
   [1433] = { min = 15, max = 25 },                         -- Redridge Mountains
   [1427] = { min = 45, max = 50 },                         -- Searing Gorge
   [1421] = { min = 10, max = 20 },                         -- Silverpine Forest
   [1434] = { min = 30, max = 45 },                         -- Stranglethorn Vale
   [1435] = { min = 35, max = 45 },                         -- Swamp of Sorrows
   [1425] = { min = 40, max = 50 },                         -- The Hinterlands
   [1420] = { min =  1, max = 10 },                         -- Tirisfal Glades
   [1436] = { min = 10, max = 20 },                         -- Westfall
   [1422] = { min = 51, max = 58 },                         -- Western Plaguelands
   [1437] = { min = 20, max = 30 },                         -- Wetlands

   -- Kalimdor
   [1440] = { min = 18, max = 30 },                         -- Ashenvale
   [1447] = { min = 45, max = 55 },                         -- Azshara
   [1439] = { min = 10, max = 20 },                         -- Darkshore
   [1443] = { min = 30, max = 40 },                         -- Desolace
   [1411] = { min =  1, max = 10 },                         -- Durotar
   [1445] = { min = 35, max = 45 },                         -- Dustwallow Marsh
   [1448] = { min = 48, max = 55 },                         -- Felwood
   [1444] = { min = 40, max = 50 },                         -- Feralas
   [1450] = { min = 55, max = 60 },                         -- Moonglade
   [1412] = { min =  1, max = 10 },                         -- Mulgore
   [1451] = { min = 55, max = 60 },                         -- Silithus
   [1442] = { min = 15, max = 27 },                         -- Stonetalon Mountains
   [1446] = { min = 40, max = 50 },                         -- Tanaris
   [1438] = { min =  1, max = 10 },                         -- Teldrassil
   [1413] = { min = 10, max = 25 },                         -- The Barrens
   [1441] = { min = 24, max = 35 },                         -- Thousand Needles
   [1449] = { min = 48, max = 55 },                         -- Un'Goro Crater
   [1452] = { min = 55, max = 60 }                          -- Winterspring
}

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

local UpdateZoneLabel = function(label)
   local map = label.dataProvider:GetMap()

   if (not map:IsCanvasMouseFocus()) then
      label:EvaluateLabels()
      return
   end

   local name, description
   local uiMapID = map:GetMapID()

   local cursorX, cursorY = map:GetNormalizedCursorPosition()
   local mapInfo = C_Map.GetMapInfoAtPosition(uiMapID, cursorX, cursorY)

   if (mapInfo and (mapInfo.mapID ~= uiMapID)) then
      name = mapInfo.name

      local playerMinLevel, playerMaxLevel

      if (zoneData[mapInfo.mapID]) then
         playerMinLevel = zoneData[mapInfo.mapID].min
         playerMaxLevel = zoneData[mapInfo.mapID].max
      end

      if (name and playerMinLevel and playerMaxLevel and (playerMinLevel > 0) and (playerMaxLevel > 0)) then
         if (playerMinLevel ~= playerMaxLevel) then
            name = name.." ("..playerMinLevel.."-"..playerMaxLevel..")"
         else
            name = name.." ("..playerMaxLevel..")"
         end
      end
   else
      name = MapUtil.FindBestAreaNameAtMouse(uiMapID, cursorX, cursorY)
   end

   label:SetLabel(MAP_AREA_LABEL_TYPE.AREA_NAME, name)
   label:EvaluateLabels()
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

   for provider in next, WorldMapFrame.dataProviders do
      if provider.setAreaLabelCallback then
         provider.Label:SetScript("OnUpdate", UpdateZoneLabel)
      end
   end
end

function SimplerMap:RefreshMap()
   local duration = 0.5;
   local restOpacity = 1.0;

   PlayerMovementFrameFader.AddDeferredFrame(
      WorldMapFrame, self.db.profile.fadeOpacity, restOpacity, duration)
   WorldMapFrame:SetScale(self.db.profile.scale)
end
