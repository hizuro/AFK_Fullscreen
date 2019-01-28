
-- saved variables
afkfullscreenDB = {};

-- local variables
local addon, ns = ...;
local L = ns.L;
local media,ticker,demoticker = "Interface\\AddOns\\"..addon.."\\media\\";
local v,b = GetBuildInfo();
ns.version_build = tonumber(gsub(v,"%.","")..b); -- vvvbbbbb
local PlayerPositionFix = {
	{0,0.00,-0.08}, -- unknown
	{0,0.05,-0.10}, -- male
	{0,0.00,-0.10}, -- female
};
local demoKeys, keys = {},{};
local default = "SimpleBlack";
local ACD = LibStub("AceConfigDialog-3.0");
local LDB_Object,LDB = nil,LibStub("LibDataBroker-1.1");
local LDBI = LibStub("LibDBIcon-1.0", true);


-------------------------------------------------
-- misc local functions
-------------------------------------------------
local debugMode = "@project-version@"=="@".."project-version".."@";
function ns.print(...)
	local colors,t,c = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"},{},1;
	for i,v in ipairs({...}) do
		v = tostring(v);
		if i==1 and v~="" then
			tinsert(t,"|cff0099ff"..addon.."|r:"); c=2;
		end
		if not v:match("||c") then
			v,c = "|cff"..colors[c]..v.."|r", c<#colors and c+1 or 1;
		end
		tinsert(t,v);
	end
	print(unpack(t));
end

function ns.debug(...)
	if debugMode then
		ns.print("<debug>",...);
	end
end

local function UnpackSkin(obj,isDemo)
	local t,k = {},keys;
	if isDemo then
		k=demoKeys;
	end

	if type(obj)=="string" then
		obj = {strsplit("|",obj)};
	end
	for i,v in ipairs(obj)do
		t[k[i][1]]={k[i][2],false};
		if v:find(":") then
			local T={};
			for _,s in ipairs({strsplit(";",v)})do
				local K,V = strsplit(":",s); T[K]=V;
			end
			t[k[i][1]] = {k[i][2],T};
		elseif v=="true" then
			t[k[i][1]] = {k[i][2],true};
		end
	end
	return t;
end

local function SetPanelSkin(frame,name,isDemo)
	if not ns.panelSkins[name] then
		name = default;
	end
	if frame.currentSkin~=name then
		frame.currentSkin = name;
		local skin,show = UnpackSkin(ns.panelSkins[name],isDemo);
		for i,v in pairs(skin)do
			if v[2]~=false then
				local obj, v = unpack(v);
				show=false;
				if i~="BackgroundModel" and (i:find("^Background") or i:find("Border")) then
					if v.Texture or v.Atlas then
						if v.Atlas then
							local l,r,t,b,HTile,VTile
							v.Texture, v.Width, v.Height, l, r, t, b, HTile, VTile = GetAtlasInfo(v.Atlas);
							if v.HTile==nil then v.HTile = HTile; end
							if v.VTile==nil then v.VTile = VTile; end
							v.Coords = {l,r,t,b};
						end

						obj:SetTexture("Interface\\buttons\\white8x8",false);

						obj:SetTexture(v.Texture,true);

						if type(v.Coords)=="string" or type(v.Coords)=="table" then
							local t = {};
							if type(v.Coords)=="string" then
								for n,c in ipairs({strsplit(",",v.Coords)})do
									tinsert(t,tonumber(c));
								end
							else
								t=v.Coords;
							end
							obj:SetTexCoord(unpack(t));
						end

						v.Width = tonumber(v.Width);
						v.Height = tonumber(v.Height);
						if v.Width then obj:SetWidth(v.Width); end
						if v.Height then obj:SetHeight(v.Height); end

						if v.HTile~=nil then
							obj:SetHorizTile(v.HTile=="true" or v.HTile==true);
						end

						if v.VTile~=nil then
							obj:SetVertTile(v.VTile=="true" or v.VTile==true);
						end
						v.Scale = tonumber(v.Scale);
						if v.Scale and i:find("^Background") then
							obj:GetParent():SetScale(v.Scale);
						end

						if v.Color then
							local t = {};
							for n,c in ipairs({strsplit(",",v.Color)})do
								tinsert(t,tonumber(c));
							end
							obj:SetVertexColor(unpack(t));
						else
							obj:SetAlpha( tonumber(v.Alpha) or 1 );
						end

						if obj.point then
							for I=1, obj:GetNumPoints() do
								local point={obj:GetPoint(I)};
								if point[1]==obj.point then
									point[4] = tonumber(v.X) or obj.pointDefaultX;
									point[5] = tonumber(v.Y) or obj.pointDefaultY;
									if obj.point=="RIGHT" then
										point[4] = -point[4];
									end
									if obj.point=="BOTTOM" then
										point[5] = -point[5];
									end
									obj:SetPoint(unpack(point));
								end
							end
						end

						show=true;
					elseif v.Color then
						local t = {};
						for n,c in ipairs({strsplit(",",v.Color)})do
							tinsert(t,tonumber(c));
						end
						obj:SetTexture("Interface\\Buttons\\White8x8");
						obj:SetVertexColor(unpack(t));
						show=true;
					end
				elseif i=="BackgroundModel" then
					obj:ClearModel();
					obj:SetModel(v.Model);
					obj.SetToShow=true;
				elseif i=="InsetShadow" or i=="OutsetShadow" then
					v.Y = tonumber(v.Y);
					v.H = tonumber(v.H);
					if v.Y==nil then v.Y = 0; end
					obj[1]:SetHeight(v.H or obj[1].defaultHeight);
					obj[2]:SetHeight(v.H or obj[2].defaultHeight);
					obj[1]:SetShown(v.Show=="true");
					obj[2]:SetShown(v.Show=="true");
					if i=="InsetShadow" then
						obj[1]:SetPoint("TOP",frame.PanelHolder, 0, v.Y );
						obj[2]:SetPoint("BOTTOM",frame.PanelHolder, 0,  - v.Y );
					else
						obj[1]:SetPoint("BOTTOM",frame.PanelHolder,"TOP", 0, v.Y );
						obj[2]:SetPoint("TOP",frame.PanelHolder,"BOTTOM", 0, - v.Y );
					end
				end
				if obj.SetShown then
					obj:SetShown(show);
				end
			else
				v[1]:Hide();
			end
		end
	end
end

local function TickerFunc(_,demoFrame)
	local self = demoFrame or AFKFullscreenFrame
	if self:IsShown() then
		self.PanelInfos.AFKText:SetText(L["AFK since"]);
		self.PanelInfos.AFKTimer:SetText(SecondsToTime(time()-self.timer));
		self.PanelInfos.Date:SetText(_G["WEEKDAY_"..date("%A"):upper()]..", "..date("%Y-%m-%d"));
		self.PanelInfos.Time:SetText(date("%H:%M:%S"));
	end
end

local function DemoTickerFunc()
	local standalonePanel = ACD.OpenFrames and ACD.OpenFrames[addon] and ACD.OpenFrames[addon].frame:IsVisible();
	local blizzPanel = ACD.BlizOptions and ACD.BlizOptions[addon] and ACD.BlizOptions[addon][addon].frame:IsVisible();
	if not (standalonePanel or blizzPanel) then
		AFKFullscreenDemoFrame:Hide();  -- hide demo frame after closed option panel
	else
		TickerFunc(nil,AFKFullscreenDemoFrame.Child);
	end
end

local function CheckAFK(self,PEW)
	if UnitIsAFK("player") and not self:IsShown() then
		self:Show();
		if PEW then
			self:Hide();
			C_Timer.After(0.5,function()
				self:Show();
			end);
		end
		if not InCombatLockdown() and afkfullscreenDB.hide_ui then
			SetUIVisibility(false)
		end
	elseif self:IsShown() then
		self.FadeOut:Play();
		if not UIParent:IsVisible() then
			SetUIVisibility(true)
		end
	end
end

local function DataBrokerInit()
	LDB_Object = LDB:NewDataObject(addon,{
		type	= "launcher",
		icon	= "Interface\\Icons\\Ability_Foundryraid_Dormant",
		label	= L[addon],
		text	= L[addon],
		OnTooltipShow = function(tt)
			local line = "|cff69ccf0%s|r |cffffffff|||r |cfff0a55f%s|r";
			tt:AddLine(L[addon]);
			tt:AddLine(line:format(L["Click"],L["to open config"]));
		end,
		OnClick = function(_, button)
			ns.toggleOptions();
		end
	});

	if (LDBI) then
		if afkfullscreenDB.Minimap==nil then
			afkfullscreenDB.Minimap={hide=false};
		end
		LDBI:Register(addon, LDB_Object, afkfullscreenDB.Minimap);
	end
end

-------------------------------------------------
-- model mixin functions
-------------------------------------------------
AFKFullscreenModelMixin = {};

function AFKFullscreenModelMixin:PlayerOnShow()
	self:ClearModel();
	self:SetUnit("player");
	self:SetPortraitZoom(0.7);
	self:SetRotation(0.5);
	self:SetPosition(unpack(PlayerPositionFix[UnitSex("player")]));
	self:RefreshCamera();
end

function AFKFullscreenModelMixin:ClockOnShow()
	self:ClearModel();
	self:SetModel("spells\\Garrison_Shipment_Pending_State");
	self:SetPortraitZoom(1);
	self:SetRotation(0.5);
	if ns.version_build<70000000 then
		self:SetPosition(5.15,0.12,1.795); -- wod
	else
		self:SetPosition(2.8,0,.71); -- legion
	end
	self:RefreshCamera();
end

function AFKFullscreenModelMixin:BackgroundOnShow()
	self:RefreshCamera();
end

function AFKFullscreenModelMixin:FullscreenOnShow()
	self:RefreshCamera();
end

function AFKFullscreenModelMixin:OnEvent()
	self:RefreshCamera();
end

function AFKFullscreenModelMixin:OnLoad()
	self:RefreshCamera();
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
end


-------------------------------------------------
-- flasher mixin functions
-------------------------------------------------
AFKFullscreenFlasherMixin = {};
function AFKFullscreenFlasherMixin:OnShow()
	self.style="pulse";
	self.AnimTexture1:SetTexture(media.."fullscreen-"..afkfullscreenDB.fullscreenwarning_texture);
	self.AnimTexture1:SetVertexColor(unpack(afkfullscreenDB.fullscreenwarning_color));
	self[self.style]:Play();
end

function AFKFullscreenFlasherMixin:OnHide()
	self[self.style]:Stop();
end


-------------------------------------------------
-- Demo frame mixin functions
-------------------------------------------------
AFKFullscreenDemoFrameMixin = {};

function AFKFullscreenDemoFrameMixin:OnLoad()
	demoKeys = {
		{"BackgroundModel",   self.Child.PanelBackgroundModel},
		{"BackgroundLayer1",  self.Child.PanelBackground.Layer1},
		{"BackgroundLayer2",  self.Child.PanelBackground.Layer2},
		{"BackgroundLayer3",  self.Child.PanelBackground.Layer3},
		{"BorderTopLeft",     self.Child.PanelBorderEdge.TopLeft},
		{"BorderTopRight",    self.Child.PanelBorderEdge.TopRight},
		{"BorderBottomLeft",  self.Child.PanelBorderEdge.BottomLeft},
		{"BorderBottomRight", self.Child.PanelBorderEdge.BottomRight},
		{"BorderTop",         self.Child.PanelBorder.Top},
		{"BorderBottom",      self.Child.PanelBorder.Bottom},
		{"BorderLeft",        self.Child.PanelBorder.Left},
		{"BorderRight",       self.Child.PanelBorder.Right},
		{"Overlay",           self.Child.PanelOverlay.Texture},
		{"InsetShadow",       {self.Child.PanelShadow.InsetTop,self.Child.PanelShadow.InsetBottom}},
		{"OutsetShadow",      {self.Child.PanelShadow.OutsetTop,self.Child.PanelShadow.OutsetBottom}}
	};
end

function AFKFullscreenDemoFrameMixin:OnShow()
	SetPanelSkin(self.Child,afkfullscreenDB.infopanel_skin,true);

	self.Child.PanelInfos.Character:Hide();
	self.Child.PanelInfos.Realm:Hide();
	self.Child.PanelInfos.Time:Hide();
	self.Child.PanelInfos.Date:Hide();

	self.Child.FadeIn:Play();
	if afkfullscreenDB.show_fullscreenwarning then
		self.Child.FullScreenWarning:Show();
	end

	self.Child.timer=GetTime()-1;
	self.Child.elapse=1;
	if self.Child.PanelBackgroundModel.SetToShow then
		self.Child.PanelBackgroundModel:Show();
	end

	if not demoticker then
		demoticker = C_Timer.NewTicker(1,DemoTickerFunc);
		demoticker.startAFK = time();
		DemoTickerFunc();
	end
end

function AFKFullscreenDemoFrameMixin:OnHide()
	self.Child.PanelInfos.AFKTimer:SetText("");
	self.Child.FullScreenWarning:Hide();
	self.Child.PanelPlayerModel:Hide();
	self.Child.PanelClockModel:Hide();
	self.Child.PanelBackgroundModel:Hide();
	if demoticker then
		demoticker:Cancel();
		demoticker = nil;
	end
end


-------------------------------------------------
-- Main frame functions
-------------------------------------------------
AFKFullscreenFrameMixin = {};

function AFKFullscreenFrameMixin:OnLoad()
	self:SetScale(UIParent:GetEffectiveScale());
	keys = {
		{"BackgroundModel",   self.PanelBackgroundModel},
		{"BackgroundLayer1",  self.PanelBackground.Layer1},
		{"BackgroundLayer2",  self.PanelBackground.Layer2},
		{"BackgroundLayer3",  self.PanelBackground.Layer3},
		{"BorderTopLeft",     self.PanelBorderEdge.TopLeft},
		{"BorderTopRight",    self.PanelBorderEdge.TopRight},
		{"BorderBottomLeft",  self.PanelBorderEdge.BottomLeft},
		{"BorderBottomRight", self.PanelBorderEdge.BottomRight},
		{"BorderTop",         self.PanelBorder.Top},
		{"BorderBottom",      self.PanelBorder.Bottom},
		{"BorderLeft",        self.PanelBorder.Left},
		{"BorderRight",       self.PanelBorder.Right},
		{"Overlay",           self.PanelOverlay.Texture},
		{"InsetShadow",       {self.PanelShadow.InsetTop,self.PanelShadow.InsetBottom}},
		{"OutsetShadow",      {self.PanelShadow.OutsetTop,self.PanelShadow.OutsetBottom}}
	};
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function AFKFullscreenFrameMixin:OnShow()
	self:SetScale(UIParent:GetEffectiveScale());
	SetPanelSkin(self,afkfullscreenDB.skin);
	self.FadeIn:Play();
	if afkfullscreenDB.show_fullscreenwarning then
		self.FullScreenWarning:Show();
	end
	self.timer=GetTime()-1;
	self.elapse=1;
	self.PanelPlayerModel:Show();
	self.PanelClockModel:Show();
	self.PanelInfos.Realm:Show();
	self.PanelInfos.Date:Show();

	if self.PanelBackgroundModel.SetToShow then
		self.PanelBackgroundModel:Show();
	end
end

function AFKFullscreenFrameMixin:OnHide()
	self.PanelInfos.AFKTimer:SetText("");
	self.FullScreenWarning:Hide();
	self.PanelPlayerModel:Hide();
	self.PanelClockModel:Hide();
	self.PanelBackgroundModel:Hide();
	if ticker then
		ticker:Cancel();
		ticker = nil;
	end
end

function AFKFullscreenFrameMixin:OnEvent(event, arg1)
	if event=="ADDON_LOADED" and arg1==addon then
		ns.dbIntegrityCheck(); -- defined in options.lua

		ns.registerOptions(); -- defined in options.lua

		ns.registerSlashCommand();

		DataBrokerInit();

		self.PanelInfos.Character:SetText(UnitName("player"));
		self.PanelInfos.Realm:SetText(GetRealmName());

		if afkfullscreenDB.show_addonloaded then
			ns.print(L["AddOn loaded..."]);
		end
	elseif event=="PLAYER_ENTERING_WORLD" then
		C_Timer.After(0.314159,function()
			CheckAFK(self,true);
		end);
		if not IsInOptionPanel then
			IsInOptionPanel = true;
		end
	elseif event=="PLAYER_FLAGS_CHANGED" then
		C_Timer.After(0.314159,function()
			CheckAFK(self);
		end);
	elseif event=="PLAYER_REGEN_DISABLED" then
		securecall("SetUIVisibility",true);
	end
end

