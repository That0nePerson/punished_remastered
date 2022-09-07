local mod = ThePunished
local game = Game()
local ItemConfig = Isaac.GetItemConfig()
local ItemPool = game:GetItemPool()


local lastAction = -1
local directionPush = "none"
local doubleTapStart = false
local lastInputTime = 0

local actions = {
    ButtonAction.ACTION_LEFT,
    ButtonAction.ACTION_RIGHT,
    ButtonAction.ACTION_UP,
    ButtonAction.ACTION_DOWN
    -- add or remove any actions as desired
}

local function AnyPunishedDo(foo)
    AnyPlayerDo(function(player)
        if player:GetPlayerType() == ThePunished.PLAYER.PUNISHED then
            foo(player)
        end
    end)
end

local function PunishedInit(player)
    player:AddTrinket(TrinketType.TRINKET_WISH_BONE)
    player:SetPocketActiveItem(ThePunished.ITEM.ACTIVE.LIBERATION, ActiveSlot.SLOT_POCKET, false)
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
    if not continued then
		AnyPunishedDo(function(player)
			PunishedInit(player)
        end)
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(player)
    --if not player:IsDead()	then
		for i, action in ipairs(actions) do
			if Input.IsActionTriggered(action, player.ControllerIndex) then
				if doubleTapStart == true then
					-- second press
					if lastAction == action then
						lastAction = -1 -- reset so a triple tap doesn't active twice
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, player.Position, Vector(0,0), player)

                        --local endpoint = mod:InitFrost(player) --spawns the frost attack
                        --[[
                        for _, ent in pairs(Isaac.FindInRadius(player.Position, 200, 24)) do -- pushes pick up items away from the player.
                            if (endpoint:Distance(ent.Position) < 10 or ((endpoint + player.Position)/2):Distance(ent.Position) < 25) then
                                if ent.Type == EntityType.ENTITY_PICKUP then
                                    local pickup = ent:ToPickup()
                                    local velocityCringe = player:GetLastDirection()
                                    pickup:AddVelocity(velocityCringe)
                                end
                            end
                        end
                        ]]

                        --if type(endpoint) == "boolean" then return end
						
					else -- first time press, save for later
						lastAction = action
						lastInputTime = Isaac.GetTime()
					end
				end
			else
				-- nothing was pressed, ready to receive new input
				doubleTapStart = true
				if lastAction > -1 and Isaac.GetTime() - lastInputTime > 300 then -- 300 is the time sensitivity between taps
					lastAction = -1 -- no action
					lastInputTime = 0
				end
			end
		end
    --end
end)