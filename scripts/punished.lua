local mod = ThePunished
local game = Game()
local ItemConfig = Isaac.GetItemConfig()
local ItemPool = game:GetItemPool()


local function AnyPunishedDo(foo)
    AnyPlayerDo(function(player)
        if player:GetPlayerType() == ThePunished.PLAYER.PUNISHED then
            foo(player)
        end
    end)
end

local function PunishedInit(player)
    player:AddTrinket(TrinketType.TRINKET_WISH_BONE)
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
    if not continued then

		AnyPunishedDo(function(player)
			PunishedInit(player)
        end)
    end
end)