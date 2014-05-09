function OnSpellStart( keys )
	local point = keys.target_points[1]
	local hero = keys.caster
	local ability = keys.ability
	
	local vSpawnLocation = hero:GetOrigin()
	local firework = CreateUnitByName( "npc_dota_firework_with_fuse", vSpawnLocation, false, hero, hero, hero:GetTeamNumber() )
	firework.projectileTarget = point
	ability:ApplyDataDrivenModifier( hero, firework, "modifier_firework_rocket_fuse", {} )
end

function GetFireworkProjectileTarget( arg, pointList )
	local firework = arg.target
	return { firework.projectileTarget }
end