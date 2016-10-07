--Blizzard Event Strings
local beginCombat = "PLAYER_REGEN_DISABLED";
local leaveCombat = "PLAYER_REGEN_ENABLED";
local combatLog = "COMBAT_LOG_EVENT_UNFILTERED";

--Player data vars
local playerGUID = 0;
local totalStagger = 0
local maxHealth = 0
local currentHealth = 0
local healthPercent = 0
local brewCharges = 0
local ironskinOn = false
local ironskinDuration = 0

--UI Strings
local healthPercentString = nil
local staggerString = nil
local brewString = nil

--Helper function for rounding to given decimal place
function round(value, decimal)
	if(decimal) then
		return math.floor((value * 10^decimal)+ 0.5) / (10^decimal)
	else
		return math.floor(value + 0.5)
	end
end

--Calculate Stagger DOT from Combat Log and display the percent of total health; % of health taken from stagger per second
local function UpdateStagger(self, event, ...)
	local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2 = select(1, ...)
	if event == combatLog then
		local spellName = select(13, ...)
		local amount = select(15, ...)
		if destGUID == playerGUID then 
			if spellName == "Stagger" and totalStagger >= 0 then
				maxHealth = UnitHealthMax("player")
				local staggerDot = amount
				local staggerPercent = round(((staggerDot / maxHealth) * 100) * 2, 1)
				BrewMasterStaggerString:SetText(staggerPercent.."%")
			end
		end
	end
end

--Get player health and total stagger every frame
local function BrewMaster_OnUpdate(self, event, ...)
	--Get and calc health
	maxHealth = UnitHealthMax("player")
	currentHealth = UnitHealth("player")
	healthPercent = round((currentHealth / maxHealth) * 100, 1)
	
	--Get Stagger and brew count
	totalStagger = UnitStagger("player")
	brewCharges = GetSpellCharges("Purifying Brew")
	
	--Set HP Percent and brewCharges every frame
	BrewMasterHealthPercentString:SetText(healthPercent.."%")
	BrewMasterBrewString:SetText(brewCharges)

	--If staggger is gone, set to 0
	if totalStagger == 0 then
		BrewMasterStaggerString:SetText("0.0%")
	end
end

--Register Events on load 
function BrewMaster_OnLoad(self, event, ...)
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent(beginCombat);
	self:RegisterEvent(leaveCombat);
end

--On event function
function BrewMaster_OnEvent(self, event, ...)
--On addon load, get player guid, and setup info strings
	if event == "ADDON_LOADED" and ... == "BrewMaster" then
		--Unregister from addon load (only happens once)
		self:UnregisterEvent("ADDON_LOADED")
		playerGUID = UnitGUID("player")
		BrewMaster:SetScript("OnUpdate", BrewMaster_OnUpdate)
		
		--Create HP Percent string
		healthPercentString = BrewMaster:CreateFontString("BrewMasterHealthPercentString", "ARTWORK", "GameFontNormal")
		healthPercentString:SetPoint("TOP", "BrewMaster", "TOP", 0, 0)
		BrewMasterHealthPercentString:SetFont("Fonts\\FRIZQT__.ttf", 16, nil)
		BrewMasterHealthPercentString:SetText("0.0%")
		
		--Create stagger string
		staggerString = BrewMaster:CreateFontString("BrewMasterStaggerString", "ARTWORK", "GameFontNormal")
		staggerString:SetPoint("CENTER", "BrewMaster", "CENTER", 0, 0)
		BrewMasterStaggerString:SetFont("Fonts\\FRIZQT__.ttf", 32, nil)
		BrewMasterStaggerString:SetText("0.0%")
		
		--Create Brew String
		brewString = BrewMaster:CreateFontString("BrewMasterBrewString", "ARTWORK", "GameFontNormal")
		brewString:SetPoint("BOTTOM", "BrewMaster", "BOTTOM", 0, 0)
		BrewMasterBrewString:SetFont("Fonts\\FRIZQT__.ttf", 16, nil)
		BrewMasterBrewString:SetText("0")
		
		--Show frames/strings
		BrewMaster:Show()
		staggerString:Show()
		brewString:Show()
		healthPercentString:show();
	end
	
	--Check combat log only while in combat
	if event == beginCombat then
		self:RegisterEvent(combatLog)
	end
	
	--Stop checking combat log after combat
	if event == leaveCombat then
		self:UnregisterEvent(combatLog)
	end
	
	--If combat logging (in combat), update stagger
	if event == combatLog then
		UpdateStagger(self, event, ...)
	end
end
