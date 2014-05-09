-- This chunk of code forces the reloading of all modules when we reload script.
if g_reloadState == nil then
	g_reloadState = {}
	for k,v in pairs( package.loaded ) do
		g_reloadState[k] = v
	end
else
	for k,v in pairs( package.loaded ) do
		if g_reloadState[k] == nil then
			package.loaded[k] = nil
		end
	end
end

-- A function to re-lookup a function by name every time.
function Dynamic_Wrap( mt, name )
	if Convars:GetFloat( 'developer' ) == 1 then
		local function w(...) return mt[name](...) end
		return w
	else
		return mt[name]
	end
end

function completeHack(name, func, delay, scope)
	local thinker = Entities:FindAllByClassname('dota_base_game_mode')[1]
    local n = '2'
    local doit = true
    local function thinkFix()
    	if not doit then return end

        -- Requeue this think
        thinker:SetContextThink(name..n, thinkFix, delay)

        -- Cycle events
        if n == '' then
        	n = '2'
        else
        	n = ''
        end

        -- Run normal think
        func(scope)
    end

    thinker:SetContextThink(name, thinkFix, delay)

    return function()
    	doit = false
	end
end

require( "nian" )
