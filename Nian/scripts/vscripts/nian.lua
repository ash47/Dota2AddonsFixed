--[[
Nian Fight
]]

-------------------------------------------------------------------------------
if NianGameMode == nil then
	NianGameMode = {}
	NianGameMode.szEntityClassName = "nian"
	NianGameMode.szNativeClassName = "dota_base_game_mode"
	NianGameMode.__index = NianGameMode
end

--------------------------------------------------------------------------------

function NianGameMode:new (o)
	o = o or {}
	setmetatable(o, self)
	return o
end

--------------------------------------------------------------------------------

CAMERA_UNLOCKED = 0
CAMERA_LOCKED_TO_NIAN = 1
CAMERA_LOCKED_TO_HERO = 2

nIngotGoldConversionRate = 40

--------------------------------------------------------------------------------

function NianGameMode:InitGameMode()
	Msg( "The Lua version of Nian is booting up...\n" )

	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetHeroSelectionTime( 30.0 )
	GameRules:SetPreGameTime( 0.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 30.0 )
	GameRules:SetHeroMinimapIconSize( 250 )
	GameRules:SetTimeOfDay( 0.75 )

	local gameEnt = Entities:FindAllByClassname('dota_base_game_mode')[1]

	gameEnt:SetCameraDistanceOverride( 1400 )
	gameEnt:SetCustomBuybackCostEnabled( true )
	gameEnt:SetCustomBuybackCooldownEnabled( true )

	local function _boundPlayerFinishedIntroPanelConsoleCommand(...)
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer then
			return self:_playerFinishedIntroPanel( cmdPlayer:GetPlayerID() )
		end
	end
	Convars:RegisterCommand( "player_finished_intro_panel", _boundPlayerFinishedIntroPanelConsoleCommand, "A player finished looking at the intro panel", 0 )

	--self.hSpawner = Entities:FindByName( nil, "nian_spawn" )
	self.hSpawner = Entities:CreateByClassname('info_target')
	self.hSpawner:SetOrigin(Vector(1567.26,4.19995,402.156))
	self.hNian = nil
	self.playerReceivedGold = {}
	self.spawnNianDelay = 0
	self.cameraLock = CAMERA_UNLOCKED
	self.unlockCameraDelay = 0

	self.hHornQuest = nil
	self.hHornSubquest = nil
	self.hTailQuest = nil
	self.hTailSubquest = nil

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( NianGameMode, 'OnNPCSpawned' ), self )
	ListenToGameEvent( "nian_damaged", Dynamic_Wrap( NianGameMode, 'OnNianDamaged' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( NianGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "dota_buyback", Dynamic_Wrap( NianGameMode, 'OnBuyback' ), self )

	PrecacheUnitByName( "npc_dota_nian" )

	-- Set the thinker up
	Entities:FindAllByClassname('dota_base_game_mode')[1]:SetThink('Think', 'NianGameMode', 0.25, self)

	self.endRoundDisplayed = false
end

--------------------------------------------------------------------------------

function NianGameMode:Think()
	self:_UpdatePointDeductions();

	-- Check for players being connected.
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local bAnyPlayerConnected = false
		for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
			if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
				-- If a player is connected (2) then we're ok
				if PlayerResource:GetConnectionState( nPlayerID ) == 2 then
					bAnyPlayerConnected = true
				end
			end
		end
		if not bAnyPlayerConnected then
			Msg( "No players are connected, setting the winner to DOTA_TEAM_BADGUYS...\n" )
			GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
		end
	end

	if GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then
		-- wait N seconds for match signout, then display it without rewards, add a message that rewards are delayed

		if GameRules:GetMatchSignoutComplete() then
			self:_showRoundEndSummary( GameRules:GetNianTotalDamageTaken(), false )
		elseif GameRules:DidMatchSignoutTimeOut() then
			self:_showRoundEndSummary( GameRules:GetNianTotalDamageTaken(), true )
		end

		-- Stop thinking
		return
	end

	local now = GameRules:GetGameTime()
	if self.t0 == nil then
		self.t0 = now
	end
	local dt = now - self.t0
	self.t0 = now

	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if self.hNian == nil then

			if not Convars:GetBool( "nian_passive" ) then
				-- lock camera to nian spawn location
				if self.cameraLock == CAMERA_UNLOCKED then
					self.cameraLock = CAMERA_LOCKED_TO_NIAN
					print( "cameraLock = CAMERA_LOCKED_TO_NIAN ")
					for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
						if PlayerResource:IsValidPlayer( nPlayerID ) and PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
							PlayerResource:SetCameraTarget( nPlayerID, self.hSpawner )
						end
					end
				end
			end

			self.spawnNianDelay = self.spawnNianDelay + dt

			--self:_showRoundEndSummary( 123456 );

			-- once camera has had time to move to the nian spawn location, create him
			if self.spawnNianDelay >= 2.5 then
				self.hNian = CreateUnitByName( "npc_dota_nian", self.hSpawner:GetOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS )
				local vPos = Vector( GetWorldMaxX() - 1000, GetWorldMaxY() - 1000, self.hNian:GetOrigin(). z )
				self.hNian:SetOrigin( vPos )
				self.hNian:SetAngles( 0, 180, 0 )

				local scope = self.hNian:GetPrivateScriptScope()
				scope:DispatchOnPostSpawn()

				--------------------------------------------------------------------------------
				-- Nian Horn Health Quest
				--------------------------------------------------------------------------------

				local hHornQuestSpawnTable = {
					name = "horn_health",
					title = "DOTA_Quest_Horn_Health",
					type = 2, -- attack
				}
    			self.hHornQuest = SpawnEntityFromTableSynchronous( "quest", hHornQuestSpawnTable )
    			self.hHornSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
					show_progress_bar = true,
					progress_bar_hue_shift = 0
				} )
				self.hHornQuest:AddSubquest( self.hHornSubquest )
				self.hHornSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.hNian:GetHorn():GetHealth() )
				self.hHornSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self.hNian:GetHorn():GetMaxHealth() )

    			--------------------------------------------------------------------------------
				-- Nian Tail Health Quest
				--------------------------------------------------------------------------------

				local hTailQuestSpawnTable = {
					name = "tail_health",
					title = "DOTA_Quest_Tail_Health",
					type = 2, -- attack
				}
    			self.hTailQuest = SpawnEntityFromTableSynchronous( "quest", hTailQuestSpawnTable )
    			self.hTailSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
					show_progress_bar = true,
					progress_bar_hue_shift = 0
				} )
				self.hTailQuest:AddSubquest( self.hTailSubquest )
				self.hTailSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.hNian:GetTail():GetHealth() )
				self.hTailSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self.hNian:GetTail():GetMaxHealth() )
    		end
		end

		if self.hNian ~= nil and self.cameraLock ~= CAMERA_UNLOCKED then
			-- once we're done with the nian spawn animation, lock camera back on the hero
			self.unlockCameraDelay = self.unlockCameraDelay + dt
			if self.cameraLock == CAMERA_LOCKED_TO_NIAN and self.unlockCameraDelay >= 3.5 then
				self.cameraLock = CAMERA_LOCKED_TO_HERO
				print( "cameraLock = CAMERA_LOCKED_TO_HERO ")
				for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
					if PlayerResource:IsValidPlayer( nPlayerID ) and PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
						PlayerResource:SetCameraTarget( nPlayerID, PlayerResource:GetSelectedHeroEntity( nPlayerID ) )
					end
				end
			end

			if self.cameraLock == CAMERA_LOCKED_TO_HERO and self.unlockCameraDelay >= 5.5 then
				self.cameraLock = CAMERA_UNLOCKED
				print( "cameraLock = CAMERA_UNLOCKED ")
				for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
					if PlayerResource:IsValidPlayer( nPlayerID ) and PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
						PlayerResource:SetCameraTarget( nPlayerID, nil )
					end
				end
			end
		end

		-- update the horn and tail health quests
		if self.hNian ~= nil and not self.hNian:IsNull()
			and self.hHornSubquest ~= nil and not self.hHornSubquest:IsNull()
			and self.hTailSubquest ~= nil and not self.hTailSubquest:IsNull()
			and self.hNian:GetHorn() ~= nil and not self.hNian:GetHorn():IsNull()
			and self.hNian:GetTail() ~= nil and not self.hNian:GetTail():IsNull() then

			if self.hNian:IsHornAlive() then
				self.hHornSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.hNian:GetHorn():GetHealth() )
				self.hHornSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self.hNian:GetHorn():GetMaxHealth() )
			else
				self.hHornSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 0 )
			end

			if self.hNian:IsTailAlive() then
				self.hTailSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.hNian:GetTail():GetHealth() )
				self.hTailSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self.hNian:GetTail():GetMaxHealth() )
			else
				self.hTailSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 0 )
			end
		end

		-- Expire item drops
		for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop" ) ) do
			local lootExpiry = item.Nian_LootExpiry
			if lootExpiry ~= nil and lootExpiry < now then
				local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, item )
				ParticleManager:SetParticleControl( nFXIndex, 0, item:GetOrigin() )
				ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
				ParticleManager:ReleaseParticleIndex( nFXIndex )

				if item:GetContainedItem() then
					UTIL_RemoveImmediate( item:GetContainedItem() )
				end
				UTIL_RemoveImmediate( item )
			end
		end

		-- Check for defeat
		local bAnyHeroAlive = false
		for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
			if PlayerResource:IsValidPlayer( nPlayerID ) and PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
				local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if not entHero or entHero:IsAlive() then
					bAnyHeroAlive = true
				end
			end
		end
		if not bAnyHeroAlive then
			GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
		elseif GameRules:GetNianFightStartTime() > 0 then
			local endTime = GameRules:GetNianFightStartTime() + Convars:GetFloat( "nian_fight_duration" )
			local timeLeft = endTime - GameRules:GetGameTime()
			--print( "start time = " ..tostring(GameRules:GetNianFightStartTime()).." timeLeft="..tostring(timeLeft) )
			if timeLeft < -15 then
				GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			end
		end
	end

	-- Run again in 0.25
	return 0.25
end

--------------------------------------------------------------------------------

function NianGameMode:OnNPCSpawned( keys )
	local spawnedUnit = EntIndexToHScript( keys.entindex )

	if spawnedUnit:GetUnitName() == "npc_dota_nian" then
		spawnedUnit:AddNewModifier( unit, nil, "modifier_nian_waiting", { duration = -1 } )
		spawnedUnit:SetAdditionalBattleMusicWeight( 1000 )
	end

	if spawnedUnit:IsHero() then
		spawnedUnit:AddNewModifier( unit, nil, "modifier_provide_vision", { duration = -1 } )

		if spawnedUnit:GetPlayerID() >= 0 then
			if self.playerReceivedGold[spawnedUnit:GetPlayerID()] == nil then
				self.playerReceivedGold[spawnedUnit:GetPlayerID()] = true
				local eventPoints = PlayerResource:GetEventPointsForPlayerID( spawnedUnit:GetPlayerID() );
				local playerGold = eventPoints * nIngotGoldConversionRate;

				PlayerResource:ModifyGold( spawnedUnit:GetPlayerID(), playerGold - PlayerResource:GetReliableGold( spawnedUnit:GetPlayerID() ), true, 0 )
				PlayerResource:ModifyGold( spawnedUnit:GetPlayerID(), -PlayerResource:GetUnreliableGold( spawnedUnit:GetPlayerID() ), false, 0 )
				PlayerResource:SetCustomBuybackCost( spawnedUnit:GetPlayerID(), 1 )
				PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 0 )
			end
		end

		local level = spawnedUnit:GetLevel()
		while level < 16 do
			spawnedUnit:HeroLevelUp( false )
			level = spawnedUnit:GetLevel()
		end
	end
end

--------------------------------------------------------------------------------

function NianGameMode:OnEntityKilled( keys )
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	if killedUnit and killedUnit:IsRealHero() then
		local newItem = CreateItem( "item_tombstone", killedUnit, killedUnit )
		newItem:SetPurchaseTime( 0 )
		newItem:SetPurchaser( killedUnit )
		local tombstone = SpawnEntityFromTableSynchronous( "dota_item_tombstone_drop", {} )
		tombstone:SetContainedItem( newItem )
		tombstone:SetAngles( 0, RandomFloat( 0, 360 ), 0 )
		FindClearSpaceForUnit( tombstone, killedUnit:GetAbsOrigin(), true )
	end
end

--------------------------------------------------------------------------------

function NianGameMode:OnBuyback( keys )
	local buybackHero = EntIndexToHScript( keys.entindex )
	print( "found the event" )
	if buybackHero and buybackHero:IsHero() then
		print( "found the hero" )
		local nPlayerID = buybackHero:GetPlayerOwnerID()
		if nPlayerID ~= nil then
			print( "increment cost" )
			--PlayerResource:SetCustomBuybackCost( nPlayerID, 99999 )
			PlayerResource:SetCustomBuybackCooldown( nPlayerID, 1500 )
		end
	end
end



--------------------------------------------------------------------------------

function NianGameMode:DropLoot( lootItemType, position )
	local newItem = CreateItem( lootItemType, nil, nil )
	newItem:SetPurchaseTime( 0 )
	local drop = CreateItemOnPosition( position )
	if drop then
		drop:SetContainedItem( newItem )
		newItem:LaunchLoot( false, 300, 0.75, position + RandomVector( RandomFloat( 300, 500 ) ) )
		drop.Nian_LootExpiry = GameRules:GetGameTime() + 20 -- 20 seconds
	end
end

--------------------------------------------------------------------------------

function NianGameMode:OnNianDamaged( keys )
	local p = Vector( keys.damage_x, keys.damage_y, keys.damage_z )
	if RandomInt( 1, 1000 ) <= 10 then
		self:DropLoot( "item_greater_salve", p )
	end
	if RandomInt( 1, 1000 ) <= 10 then
		self:DropLoot( "item_greater_clarity", p )
	end
end

--------------------------------------------------------------------------------

function NianGameMode:_playerFinishedIntroPanel( nPlayerID )
end

--------------------------------------------------------------------------------

-- if bShowLoot is false, we timed out on match signout, so show an explanation message instead of loots

function NianGameMode:_showRoundEndSummary( nDamageDone, bTimeout )

	--self.endRoundDisplayed = true

	local roundEndSummary = {
		nDamageDone = nDamageDone,
		bTimeout = bTimeout
	}

	local vPlayerHeroData = {}

	for i,heroEntity in ipairs( HeroList:GetAllHeroes() ) do
		if heroEntity and heroEntity:IsRealHero() then
			local nPlayerID = heroEntity:GetPlayerID()
			local heroTable = {
				nPlayerID = nPlayerID
			}
			table.insert( vPlayerHeroData, heroTable )
		end
	end

	for i = 1,#vPlayerHeroData do
		local heroData = vPlayerHeroData[i]
		if heroData.nPlayerID then
			roundEndSummary["Player_"..heroData.nPlayerID.."_HeroName"] = PlayerResource:GetSelectedHeroName( heroData.nPlayerID )

			-- add loot drops
			local premiumPointsGranted = PlayerResource:GetEventPremiumPointsGranted( heroData.nPlayerID )
			local rankGranted = PlayerResource:GetEventRankGranted( heroData.nPlayerID )

			roundEndSummary["Player_"..heroData.nPlayerID.."_PremiumPoints"] = premiumPointsGranted
			roundEndSummary["Player_"..heroData.nPlayerID.."_Rank"] = rankGranted
		end
	end

	print( "_showRoundEndSummary:" )

	FireGameEvent( "spring_festival_show_end_panel", roundEndSummary )
end

--------------------------------------------------------------------------------

function NianGameMode:_UpdatePointDeductions()

	if not self.eventPointData then
		self.eventPointData = {
		}
	end

	local pointTable = {
		0,
		0,
		0,
		0,
		150,
		450,
		1000,
		2500
	}

	-- keep a running total of event points for each player
	for i,heroEntity in ipairs( HeroList:GetAllHeroes() ) do
		if heroEntity and heroEntity:IsRealHero() then
			local nPlayerID = heroEntity:GetPlayerID()

			if not self.eventPointData["Player"..nPlayerID] then self.eventPointData["Player"..nPlayerID] = {} end

			local nPoints = -pointTable[GameRules:GetDifficulty()+1]
			local nPremiumPoints = 0

			self.eventPointData["Player"..nPlayerID]["total_event_points"] = nPoints
			self.eventPointData["Player"..nPlayerID]["total_premium_event_points"] = nPremiumPoints
		end
	end

	UpdateEventPoints( self.eventPointData );

end

--EntityFramework:RegisterScriptClass( NianGameMode )

