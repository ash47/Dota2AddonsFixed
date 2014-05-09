function OnSpellStart( keys )
	local point = keys.target_points[1]
	local hero = keys.caster
	local ability = keys.ability
	
	local vSpawnLocation = hero:GetOrigin()
	local firework = CreateUnitByName( "npc_dota_firework_with_fuse", vSpawnLocation, false, hero, hero, hero:GetTeamNumber() )
	firework.projectileTarget = point
	ability:ApplyDataDrivenModifier( hero, firework, "modifier_firework_rocket3_fuse", {} )
end

function GetFireworkProjectileTargetRandom( arg, pointList )
	local firework = arg.target
	local angleLeft = QAngle( 0, -RandomInt(-17,17), 0 )
	local angleMiddle = QAngle( 0, -RandomInt(-17,17), 0 )
	local angleRight = QAngle( 0, -RandomInt(-17,17), 0 )
	
	local vLeft = RotatePosition( firework:GetOrigin(), angleLeft, firework.projectileTarget )
	local vMiddle = RotatePosition( firework:GetOrigin(), angleMiddle, firework.projectileTarget )
	local vRight = RotatePosition( firework:GetOrigin(), angleRight, firework.projectileTarget )
	return { vLeft, vMiddle, vRight }
end

function GetFireworkProjectileTarget( arg, pointList )
	local firework = arg.target
	local angleLeft = QAngle( 0, -17, 0 )
	local angleRight = QAngle( 0, 17, 0 )
	
	local vLeft = RotatePosition( firework:GetOrigin(), angleLeft, firework.projectileTarget )
	local vRight = RotatePosition( firework:GetOrigin(), angleRight, firework.projectileTarget )
	return { vLeft, firework.projectileTarget, vRight }
end