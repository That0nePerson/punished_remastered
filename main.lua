local mod = RegisterMod("The Punished", 1)

local persistentModData = {}
local persistentDataKeys = {"savedata", "CACHED_PLAYERTYPE_CACHE", "INITIALISED_UNLOCKS", "LOADED_SAVEDATA", "AchievementTrackers"}
if ThePunished then
	for _, key in pairs(persistentDataKeys) do
		persistentModData[key] = ThePunished[key]
	end
end

ThePunished = mod

for _, key in pairs(persistentDataKeys) do
	ThePunished[key] = persistentModData[key]
end

local game = Game()

-- Iterate through all players
function AnyPlayerDo(foo)
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		foo(player)
	end
end

function PunishedExists()
    local player
    for i = 1, game:GetNumPlayers() do
        if Isaac.GetPlayer(i):GetName() == "The Punished" then
            player = Isaac.GetPlayer(i)
            break
        end
    end
    return player
end

-- Get number of multishot projeciles (why the fuck isnt this in the api)
function GetNumProjectiles(player)
    local monstrosLung = CollectibleType.COLLECTIBLE_MONSTROS_LUNG
    local mutantSpider = CollectibleType.COLLECTIBLE_MUTANT_SPIDER
    local innerEye = CollectibleType.COLLECTIBLE_INNER_EYE
    local _2020 = CollectibleType.COLLECTIBLE_20_20

    local hasMonstros = player:HasCollectible(monstrosLung)

    local baseProjectiles
    if hasMonstros then
        baseProjectiles = 14
    else
        if player:HasCollectible(mutantSpider) and player:HasCollectible(innerEye) then
            baseProjectiles = 5
        elseif player:HasCollectible(mutantSpider) then
            baseProjectiles = 4
        elseif player:HasCollectible(innerEye) then
            baseProjectiles = 3
        elseif player:HasCollectible(_2020) then
            baseProjectiles = 2
        else
            baseProjectiles = 1
        end
    end

    local stackingItemProjectiles
    if hasMonstros then
        stackingItemProjectiles = math.floor(2.4 * (
            5 * (math.max(0, player:GetCollectibleNum(monstrosLung) - 1)) +
            2 * player:GetCollectibleNum(mutantSpider) +
            player:GetCollectibleNum(innerEye) +
            player:GetCollectibleNum(_2020)
        ))
    else
        stackingItemProjectiles =
            2 * (math.max(0, player:GetCollectibleNum(mutantSpider) - 1)) +
            math.max(0, (player:GetCollectibleNum(innerEye) - 1)) +
            math.max(0, (player:GetCollectibleNum(_2020) - 1))
    end

    local luckBasedProjectiles = 0
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_EYE) then
        local momsChance = math.min(math.max(0, 50 + 25 * player.Luck), 100)
        if math.random(0, 99) < momsChance then
           luckBasedProjectiles = luckBasedProjectiles + 1
        end
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_LOKIS_HORNS) then
        local lokisChance = math.min(math.max(0, 25 + 5 * player.Luck), 100)
        if math.random(0, 99) < lokisChance then
           luckBasedProjectiles = luckBasedProjectiles + 3
        end
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_SORE) then
        if math.random(1,3) == 1 then
            if hasMonstros then
                luckBasedProjectiles = luckBasedProjectiles + baseProjectiles + stackingItemProjectiles
            else
                local eyeSoreSeed = math.random(0,5)
                if eyeSoreSeed < 3 then
                    luckBasedProjectiles = luckBasedProjectiles + 1
                elseif eyeSoreSeed < 5 then
                    luckBasedProjectiles = luckBasedProjectiles + 2
                else
                    luckBasedProjectiles = luckBasedProjectiles + 3
                end
            end
        end
    end

    local numProjectiles = baseProjectiles + stackingItemProjectiles + luckBasedProjectiles
    return numProjectiles
end

function mod:GetPlayerUsingItem()
	local player = Isaac.GetPlayer(0)
	for i = 1, game:GetNumPlayers() do
		local p = Isaac.GetPlayer(i - 1)
		if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, p.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, p.ControllerIndex) then
			player = p
			player:GetData().WasHoldingButton = true
			break
		end
	end
	return player
end

-- Load other lua files
print("loading scripts")
local scripts = {
    "scripts.punished",
    "scripts.constants",
    "scripts.items.condemnation",
    "scripts.items.liberation"
}

for i,v in ipairs(scripts) do
    include(v)
end