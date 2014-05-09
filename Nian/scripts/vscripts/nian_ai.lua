--[[
Nian AI
]]

-- physical abilities
local ABILITY_right_claw_swipe = thisEntity:FindAbilityByName( "animated_right_claw_swipe" )
local ABILITY_left_claw_swipe = thisEntity:FindAbilityByName( "animated_left_claw_swipe" )
local ABILITY_nian_dive = thisEntity:FindAbilityByName( "nian_dive" )
local ABILITY_tail_spin = thisEntity:FindAbilityByName( "animated_tail_spin" )
local ABILITY_nian_leap = thisEntity:FindAbilityByName( "nian_leap" )

-- magical abilities
local ABILITY_nian_hurricane = thisEntity:FindAbilityByName( "nian_hurricane" )
local ABILITY_nian_apocalypse = thisEntity:FindAbilityByName( "nian_apocalypse" )

local ABILITY_nian_roar = thisEntity:FindAbilityByName( "nian_roar" )
local ABILITY_nian_charge = thisEntity:FindAbilityByName( "nian_charge" )
local ABILITY_nian_tail_swipe = thisEntity:FindAbilityByName( "nian_tail_swipe" )

local ABILITY_nian_whirlpool = thisEntity:FindAbilityByName( "nian_whirlpool" )
local ABILITY_nian_stone_gaze = thisEntity:FindAbilityByName( "nian_stone_gaze" )
local ABILITY_nian_eruption = thisEntity:FindAbilityByName( "nian_eruption" )
local ABILITY_nian_sigils = thisEntity:FindAbilityByName( "nian_sigils" )
local ABILITY_nian_waterball = thisEntity:FindAbilityByName( "nian_waterball" )

local flClawAttackSpeed = 1.0
local flMaxClawAttackSpeed = 2.0
local flClawAttackSpeedUpPerMagicalAttack = 0.025
local nextMagicAttackTime = -1
local timeBetweenMagicAttacks = 12
local magicAttackIndex = 0
local bArrived = false
local bNianLeaving = false

local magicAttacks =
{
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_waterball },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_waterball },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_sigils },
	{ ABILITY_nian_eruption },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_hurricane },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_waterball },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
	{ ABILITY_nian_eruption },
	{ ABILITY_nian_charge },
	{ ABILITY_nian_roar },
	{ ABILITY_nian_tail_swipe },
}

Convars:RegisterConvar( "nian_passive", "0", "Set the Nian to passive mode.", FCVAR_CHEAT )
Convars:RegisterConvar( "nian_verbose", "0", "Set to have the nian spew busy status", FCVAR_CHEAT )

function DispatchOnPostSpawn()
	-- physical abilities
	ABILITY_right_claw_swipe = thisEntity:FindAbilityByName( "animated_right_claw_swipe" )
	ABILITY_left_claw_swipe = thisEntity:FindAbilityByName( "animated_left_claw_swipe" )
	ABILITY_nian_dive = thisEntity:FindAbilityByName( "nian_dive" )
	ABILITY_tail_spin = thisEntity:FindAbilityByName( "animated_tail_spin" )
	ABILITY_nian_leap = thisEntity:FindAbilityByName( "nian_leap" )

	-- magical abilities
	ABILITY_nian_hurricane = thisEntity:FindAbilityByName( "nian_hurricane" )
	ABILITY_nian_apocalypse = thisEntity:FindAbilityByName( "nian_apocalypse" )

	ABILITY_nian_roar = thisEntity:FindAbilityByName( "nian_roar" )
	ABILITY_nian_charge = thisEntity:FindAbilityByName( "nian_charge" )
	ABILITY_nian_tail_swipe = thisEntity:FindAbilityByName( "nian_tail_swipe" )

	ABILITY_nian_whirlpool = thisEntity:FindAbilityByName( "nian_whirlpool" )
	ABILITY_nian_stone_gaze = thisEntity:FindAbilityByName( "nian_stone_gaze" )
	ABILITY_nian_eruption = thisEntity:FindAbilityByName( "nian_eruption" )
	ABILITY_nian_sigils = thisEntity:FindAbilityByName( "nian_sigils" )
	ABILITY_nian_waterball = thisEntity:FindAbilityByName( "nian_waterball" )

	print(ABILITY_nian_waterball)

	AddThinkToEnt( thisEntity, "NianThink" )
	print( "the nian lives...!" )
end

function CollectWaypoints()
	local result = {}
	local i = 1
	local wp = nil
	while true do
		wp = Entities:FindByName( nil, string.format("wp%d", i ) )
		if not wp then
			return result
		end
		table.insert( result, wp:GetOrigin() )
		i = i + 1
	end
end

POSITIONS = CollectWaypoints()

function NianThink()
	if Convars:GetBool( "nian_passive" ) then
		if Convars:GetBool( "nian_verbose" ) then
			local activeAbility = thisEntity:GetCurrentActiveAbility()
			print( "The Nian is passive." )
			if activeAbility ~= nil then
				print( "  activeAbility = "..activeAbility:GetClassname() )
			end
		end
		return 0.5
	end

	if not bArrived then
		JumpIntoTheMap()
		return 3.0
	end

	if thisEntity:HasModifier( "modifier_nian_waiting" ) then
		if Convars:GetBool( "nian_verbose" ) then
			print( "Nian is waiting" )
		end
		return 0.1
	end

	if ABILITY_nian_charge:IsChanneling() or ABILITY_nian_apocalypse:IsChanneling() or ABILITY_nian_roar:IsChanneling() or ABILITY_nian_hurricane:IsChanneling() or ABILITY_nian_whirlpool:IsChanneling() then
		if Convars:GetBool( "nian_verbose" ) then
			print( "Nian is channeling..." )
		end
		return 0.1
	end

	if thisEntity:HasModifier( "modifier_nian_big_flinch" ) or thisEntity:HasModifier( "modifier_nian_knockdown" ) or thisEntity:HasModifier( "modifier_nian_frenzy" )
		or thisEntity:HasModifier( "modifier_animated_tail_spin" ) or thisEntity:HasModifier( "modifier_nian_dive" ) or thisEntity:HasModifier( "modifier_medusa_stone_gaze" )
		or thisEntity:HasModifier( "modifier_animated_left_claw_swipe" ) or thisEntity:HasModifier( "modifier_animated_right_claw_swipe" ) or thisEntity:HasModifier( "modifier_nian_leap" ) then
		if Convars:GetBool( "nian_verbose" ) then
			print( "Nian is busy with a modifier" )
		end
		return 0.1
	end

	local activeAbility = thisEntity:GetCurrentActiveAbility()
	if activeAbility and activeAbility ~= ABILITY_right_claw_swipe and activeAbility ~= ABILITY_left_claw_swipe and activeAbility ~= ABILITY_tail_spin  and activeAbility ~= ABILITY_nian_charge then
		print( "Nian is busy with "..thisEntity:GetCurrentActiveAbility():GetAbilityName() )
		return 0.1
	end

	if bNianLeaving then
		thisEntity:AddNoDraw()
		thisEntity:GetHorn():AddNoDraw()
		thisEntity:GetTail():AddNoDraw()

		FireGameEvent( "nian_leaping_out_of_map", { } )
		local centerMessage = {
			message = "#nian_driven_away",
			duration = 6.3
		}
		FireGameEvent( "show_center_message", centerMessage )
		GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )

		return 10000.0
	end

	-- is it time to PEACE OUT?
	local endTime = GameRules:GetNianFightStartTime() + Convars:GetFloat( "nian_fight_duration" )
	if GameRules:GetGameTime() >= endTime then
		print( "Nian fight is over" )
		JumpOutOfTheMap()
		return 3.0
	end

	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false )
	if #enemies == 0 then
		print( "the nian found no enemies...!" )
		return 0.5
	end

	if nextMagicAttackTime == -1 then
		nextMagicAttackTime = GameRules:GetGameTime() + timeBetweenMagicAttacks
	end

	if GameRules:GetGameTime() < nextMagicAttackTime then
		return DoPhysicalAttack( enemies )
	end

	IncreaseClawAttackSpeed()
	nextMagicAttackTime = -1

	return DoMagicalAttackFromList( enemies )
end

function DoPhysicalAttack( enemies )

	local closeEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false )

	local vDirection = thisEntity:GetForwardVector()
	local vRight = thisEntity:GetRightVector()
	local vLeft = -vRight
	local flQuadrantDistance = 200
	local target

	--local vColor = Vector( 255, 255, 255 )
	--DebugDrawCircle( thisEntity:GetOrigin(), vColor, 255, 700, false, 5.0 )

	local vFrontRightQuadrant = thisEntity:GetOrigin() + (( vDirection + vRight ) * flQuadrantDistance )
	local vFrontLeftQuadrant = thisEntity:GetOrigin() + (( vDirection + vLeft ) * flQuadrantDistance )
	local vBackRightQuadrant = thisEntity:GetOrigin() + (( -vDirection + vRight ) * flQuadrantDistance )
	local vBackLeftQuadrant = thisEntity:GetOrigin() + (( -vDirection + vLeft ) * flQuadrantDistance )

	local frontRightEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vFrontRightQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local frontLeftEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vFrontLeftQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local backRightEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vBackRightQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local backLeftEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vBackLeftQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )

	local diveEnemies = {}

	for i=1,#enemies do
		local dist = ( enemies[i]:GetOrigin() - thisEntity:GetOrigin() ):Length()

		if dist > 500 then
			table.insert( diveEnemies, enemies[i] )
		end
	end

	local nRightClawAttackWeight = #closeEnemies
	if not ABILITY_right_claw_swipe:IsFullyCastable() then
		nRightClawAttackWeight = 0
	end

	local nLeftClawAttackWeight = #closeEnemies
	if not ABILITY_left_claw_swipe:IsFullyCastable() then
		nLeftClawAttackWeight = 0
	end

	--(far enemies minus close enemies)
	local nDiveWeight = #diveEnemies
	if not ABILITY_nian_dive:IsFullyCastable() then
		nDiveWeight = 0
	end

	local nTailSpinWeight = #closeEnemies
	if not ABILITY_tail_spin:IsFullyCastable() then
		nTailSpinWeight = 0
	end
	if not thisEntity:IsTailAlive() then
		nTailSpinWeight = 0
	end

	local nWeightMax = nRightClawAttackWeight + nLeftClawAttackWeight + nTailSpinWeight + nDiveWeight
	local nRoll = RandomInt( 0, nWeightMax - 1 )

	if nRoll < nRightClawAttackWeight then
		--Attack with right claw
		--Look in front first
		if #frontRightEnemies > 0 then
			target = frontRightEnemies[1]
		elseif #backRightEnemies > 0 then
			target = backRightEnemies[1]
		else
			target = closeEnemies[RandomInt(1, #closeEnemies)]
		end

		return RightClawAttack( target )
	end
	nRoll = nRoll - nRightClawAttackWeight

	if nRoll < nLeftClawAttackWeight then
		--Attack with left claw
		--Look in front first
		if #frontLeftEnemies > 0 then
			target = frontLeftEnemies[1]
		elseif #backLeftEnemies > 0 then
			target = backLeftEnemies[1]
		else
			target = closeEnemies[RandomInt(1, #closeEnemies)]
		end

		return LeftClawAttack( target )
	end
	nRoll = nRoll - nLeftClawAttackWeight

	if nRoll < nTailSpinWeight then
		return TailSpin()
	end
	nRoll = nRoll - nTailSpinWeight

	target = diveEnemies[RandomInt(1, #diveEnemies)]
	return Dive( target )
end

function IncreaseClawAttackSpeed()
	flClawAttackSpeed = flClawAttackSpeed + flClawAttackSpeedUpPerMagicalAttack
	if flClawAttackSpeed > flMaxClawAttackSpeed then
		flClawAttackSpeed = flMaxClawAttackSpeed
	end
end

function DoMagicalAttackFromList( enemies )
	local vDirection = thisEntity:GetForwardVector()
	local vRight = thisEntity:GetRightVector()
	local vLeft = -vRight
	local flQuadrantDistance = 200
	local target

	local vBackRightQuadrant = thisEntity:GetOrigin() + (( -vDirection + vRight ) * flQuadrantDistance )
	local vBackLeftQuadrant = thisEntity:GetOrigin() + (( -vDirection + vLeft ) * flQuadrantDistance )

	local backRightEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vBackRightQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local backLeftEnemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, vBackLeftQuadrant, enemies[1], 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )

	local apocEnemies = {}
	local chargeEnemies = {}
	local stonegazeEnemies = {}

	for i=1,#enemies do
		if enemies[i]:IsAlive() then

			local dist = ( enemies[i]:GetOrigin() - thisEntity:GetOrigin() ):Length()

			table.insert( chargeEnemies, enemies[i] )
			if dist < 3500 then
				table.insert( apocEnemies, enemies[i] )
			end
			if dist < 700 then
				table.insert( stonegazeEnemies, enemies[i] )
			end
		end
	end

	magicAttackIndex = magicAttackIndex + 1
	-- loop if we get to the end of the list
	if magicAttackIndex > #magicAttacks then
		magicAttackIndex = 1
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_hurricane then
		return Hurricane()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_charge then
		if #chargeEnemies > 0 then
			target = chargeEnemies[RandomInt(1, #chargeEnemies)]
			return Charge( target )
		end
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_roar then
		return Roar()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_tail_swipe then
		if thisEntity:IsTailAlive() then
			return TailSwipe()
		else
			return 1.0
		end
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_whirlpool then
		return Whirlpool()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_waterball then
		return Waterball()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_sigils then
		return Sigils()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_eruption then
		return Eruption()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_apocalypse then
		return Apocalypse()
	end

	if magicAttacks[magicAttackIndex][1] == ABILITY_nian_stone_gaze then
		return StoneGaze()
	end

	print( "Nian had no magical attack to do index = "..magicAttackIndex )
	return 1.0
end

function RightClawAttack( unit )
	print( "the nian wants to use its right claw!" )
	if unit ~= nil then
		print ( "the nian is beginning to attack!" )
		ABILITY_right_claw_swipe:SetPlaybackRate( flClawAttackSpeed );
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ABILITY_right_claw_swipe:entindex(),
			TargetIndex = unit:entindex()
		})
	else
		print( "the target wasn't there!" )
	end

	return 1
end

function LeftClawAttack( unit )
	print( "the nian wants to use its left claw!" )
	if unit ~= nil then
		print ( "the nian is beginning to attack!" )
		ABILITY_left_claw_swipe:SetPlaybackRate( flClawAttackSpeed );
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ABILITY_left_claw_swipe:entindex(),
			TargetIndex = unit:entindex()
		})
	else
		print( "the target wasn't there!" )
	end

	return 1
end

function Dive( unit )
	if unit == nil then
		return;
	end

	local dist = ( unit:GetOrigin() - thisEntity:GetOrigin() ):Length()

	print( "the nian wants to dive to "..unit:GetClassname() )
	local flDivePlaybackRate = flClawAttackSpeed

	local minDist = 2000
	local maxDist = 10000
	if dist > minDist then

		local reducePlaybackSpeed = ( dist - minDist ) / ( maxDist - minDist )
		if reducePlaybackSpeed > 0.8 then
			reducePlaybackSpeed = 0.8
		end
		flDivePlaybackRate = flDivePlaybackRate - reducePlaybackSpeed
	end

	ABILITY_nian_dive:SetPlaybackRate( flDivePlaybackRate );
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = ABILITY_nian_dive:entindex(),
		TargetIndex = unit:entindex()
	})
	return 1.0
end

function JumpIntoTheMap()
	print( "the nian wants to jump into the map!" )

	local hSpawner = Entities:FindByName( nil, "nian_spawn" )
	local vPos = GetGroundPosition( hSpawner:GetOrigin(), thisEntity )
	ABILITY_nian_leap:SetPlaybackRate( 1.0 );
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = ABILITY_nian_leap:entindex(),
		Position = vPos
	})

	bArrived = true
end

function JumpOutOfTheMap()
	print( "the nian wants to jump out of the map!" )
	local vPos = Vector( GetWorldMaxX() - 1000, GetWorldMaxY() - 1000, thisEntity:GetOrigin(). z )
	ABILITY_nian_leap:SetPlaybackRate( 0.7 );
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = ABILITY_nian_leap:entindex(),
		Position = vPos
	})

	bNianLeaving = true
end

function Roar()
	print( "the nian wants to use roar!" )
	ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ABILITY_nian_roar:entindex()
		})

	return 1
end

function Apocalypse()
	print( "the nian wants to use apocalypse!" )
	thisEntity:CastAbilityNoTarget( ABILITY_nian_apocalypse, -1 )
	--[[ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ABILITY_nian_apocalypse:entindex()
		}) ]]

	return 1
end

function TailSpin()
	print( "the nian wants to use tail spin!" )
	ABILITY_tail_spin:SetPlaybackRate( flClawAttackSpeed );
	ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ABILITY_tail_spin:entindex()
		})

	return 2.5
end

function Charge( unit )
	if unit ~= nil then
		print( "the nian wants to charge at "..tostring(unit) )
		ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = ABILITY_nian_charge:entindex(),
				TargetIndex = unit:entindex()
			})
	end
	return 1
end

function MoveTowardsNearestEnemy( unit )
	print( "the nian doesn't know what to do!" )
	if unit ~= nil then
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = unit:GetOrigin()
		})
	else
		print (  "the target wasn't there!" )
	end

	return 1
end

function TailSwipe()
	print( "the nian wants to use tail swipe!" )
	ABILITY_tail_spin:SetPlaybackRate( flClawAttackSpeed );
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_tail_swipe:entindex()
	})

	return 2.5
end

function Whirlpool()
	print( "the nian wants to use whirlpool!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_whirlpool:entindex()
	})

	return 1
end

function Eruption()
	print( "the nian wants to use eruption!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_eruption:entindex()
	})

	return 1
end

function Hurricane()
	print( "the nian wants to use hurricane!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_hurricane:entindex()
	})

	return 1
end


function StoneGaze()
	print( "the nian wants to use stonegaze!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_stone_gaze:entindex()
	})

	return 1
end

function Sigils()
	print( "the nian wants to use sigils!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_sigils:entindex()
	})

	return 1.0
end

function Waterball()
	print( "the nian wants to use waterball!" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ABILITY_nian_waterball:entindex()
	})

	return 10.0
end

-------------------------------------------------------------------------------------------

local projectileInterval = 0.02
local projectileAngle = 0
local projectileAngleStep = 5
local projectileNextTime = -1
local projectileCount = 0
local projectileCountMax = 12
local projectileReverseDirectionCount = 0
local projectileReverseDirectionMax = 10
local projectileMinSpeed = 600
local projectileMaxSpeed = 600
local spiralCastCount = 0
local gapsCastCount = 0
local spewCastCount = 0
local roarSoundTime = -1

-------------------------------------------------------------------------------------------


function OnSpiralSpellStart()
	projectileInterval = 0.2
	projectileAngle = 0
	projectileAngleStep = 6.5 + spiralCastCount
	projectileReverseDirectionCount = 0
	projectileReverseDirectionMax = 10 - spiralCastCount
	projectileMinSpeed = 600
	projectileMaxSpeed = 600

	if projectileReverseDirectionMax < 5 then
		projectileReverseDirectionMax = 5
	end

	spiralCastCount = spiralCastCount + 1
end

function OnSpiralChannelThink()
	local now = GameRules:GetGameTime()
	if projectileNextTime <= now then
		projectileNextTime = now + projectileInterval

		local angle = QAngle( 0, projectileAngle, 0 )
		projectileAngle = projectileAngle + projectileAngleStep

		projectileReverseDirectionCount = projectileReverseDirectionCount + 1
		if projectileReverseDirectionCount >= projectileReverseDirectionMax then
			projectileAngleStep = -projectileAngleStep
			projectileReverseDirectionCount = 0
		end

		local speed = RandomFloat( projectileMinSpeed, projectileMaxSpeed )
		local info = {
			EffectName = "nian_roar_projectile_no_explode",
			Ability = ABILITY_nian_roar,
			vSpawnOrigin = thisEntity:GetOrigin(),
			fDistance = 99999,
			fStartRadius = 50,
			fEndRadius = 150,
			Source = thisEntity,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER
		}

		for nDirection = 0, 5 do
			info.vVelocity = ( RotatePosition( Vector( 0, 0, 0 ), angle, Vector( 1, 0, 0 ) ) ) * speed

			ProjectileManager:CreateLinearProjectile( info )

			angle.y = angle.y + 60
		end
	end
end

-------------------------------------------------------------------------------------------

function OnGapsSpellStart()
	projectileAngle = 0
	projectileAngleStep = 20 + gapsCastCount * 2
	projectileInterval = 1.0
	projectileReverseDirectionCount = 0
	projectileReverseDirectionMax = 10
	projectileMinSpeed = 500 + gapsCastCount * 10
	projectileMaxSpeed = 500 + gapsCastCount * 10

	gapsCastCount = gapsCastCount + 1
end

function OnGapsChannelThink()
	local now = GameRules:GetGameTime()
	if projectileNextTime <= now then
		projectileNextTime = now + projectileInterval

		local angle = QAngle( 0, projectileAngle, 0 )
		projectileAngle = projectileAngle + projectileAngleStep

		if RandomFloat( 0, 100 ) > 50 then
			projectileAngleStep = -projectileAngleStep
		end

		local speed = RandomFloat( projectileMinSpeed, projectileMaxSpeed )
		local info = {
			EffectName = "nian_roar_projectile_no_explode",
			Ability = ABILITY_nian_roar,
			vSpawnOrigin = thisEntity:GetOrigin(),
			fDistance = 99999,
			fStartRadius = 50,
			fEndRadius = 150,
			Source = thisEntity,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER
		}

		for nDirection = 0, 35 do
			local diff = AngleDiff( angle.y, projectileAngle )
			local bGap = ( diff >= -10 and diff <= 10 )
			bGap = bGap or ( diff >= 110 and diff <= 130 )
			bGap = bGap or ( diff >= -130 and diff <= -110 )
			if not bGap then
				info.vVelocity = ( RotatePosition( Vector( 0, 0, 0 ), angle, Vector( 1, 0, 0 ) ) ) * speed

				ProjectileManager:CreateLinearProjectile( info )
			end

			angle.y = angle.y + 10
		end
	end
end

-------------------------------------------------------------------------------------------

function OnSpewSpellStart()
	projectileAngle = 270
	projectileAngleStep = 12
	projectileInterval = 0.04 - spewCastCount * 0.002
	projectileCountMax = 10 + spewCastCount
	projectileMinSpeed = 600
	projectileMaxSpeed = 600

	if projectileInterval < 0.02 then
		projectileInterval = 0.02
	end

	spewCastCount = spewCastCount + 1
end

function OnSpewChannelThink()

	local now = GameRules:GetGameTime()
	if projectileNextTime <= now then
		projectileNextTime = now + projectileInterval

		local angle = QAngle( 0, RandomFloat( 0, 360 ), 0 )
		projectileAngle = projectileAngle + projectileAngleStep

		local speed = RandomFloat( projectileMinSpeed, projectileMaxSpeed )
		local info = {
			EffectName = "nian_roar_projectile_no_explode",
			Ability = ABILITY_nian_roar,
			vSpawnOrigin = thisEntity:GetOrigin(),
			fDistance = 99999,
			fStartRadius = 50,
			fEndRadius = 150,
			Source = thisEntity,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER,
			fMaxSpeed = 1200,
			fExpireTime = now + 13.0,
		}

		info.vVelocity = ( RotatePosition( Vector( 0, 0, 0 ), angle, Vector( 1, 0, 0 ) ) ) * speed
		info.vAcceleration = info.vVelocity * -0.15

		ProjectileManager:CreateLinearProjectile( info )

		angle.y = angle.y + 40

		projectileCount = projectileCount + 1
		if projectileCount >= projectileCountMax then
			projectileCount = 0
			projectileNextTime = projectileNextTime + 0.3
		end
	end
end

-------------------------------------------------------------------------------------------


local roarTypes = {
	{ start = nil, channel = nil },
	{ start = OnSpiralSpellStart, channel = OnSpiralChannelThink },
	{ start = OnGapsSpellStart, channel = OnGapsChannelThink },
	{ start = OnSpewSpellStart, channel = OnSpewChannelThink },
}

-------------------------------------------------------------------------------------------

function OnRoarSpellStart()
	print( "nian_ai::OnRoarSpellStart" )
	local nRoarType = ( ( ABILITY_nian_roar:GetCastCount() - 1 ) % 4 ) + 1

	projectileCount = 0
	projectileNextTime = GameRules:GetGameTime()

	print( "  nRoarType = "..nRoarType )
	print( "  start function = "..tostring( roarTypes[ nRoarType ].start ) )

	if roarTypes[ nRoarType ].start then
		roarTypes[ nRoarType ].start()
	end
end

function OnRoarChannelThink()
	local nRoarType = ( ( ABILITY_nian_roar:GetCastCount() - 1 ) % 4 ) + 1

	if roarTypes[ nRoarType ].channel then
		roarTypes[ nRoarType ].channel()
	end

	if GameRules:GetGameTime() >= roarSoundTime then
		roarSoundTime = GameRules:GetGameTime() + 1.3

		local nFXIndex = ParticleManager:CreateParticle( "nian_tailswipe_thunder_clap", PATTACH_CUSTOMORIGIN, NULL )
		ParticleManager:SetParticleControl( nFXIndex, 0, thisEntity:GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 300, 300, 300 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		thisEntity:EmitSound( "Nian.RoarProjectiles.Cast" )
	end
end


