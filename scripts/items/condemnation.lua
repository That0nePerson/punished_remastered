local mod = ThePunished
local game = Game()
local ItemConfig = Isaac.GetItemConfig()
local ItemPool = game:GetItemPool()

local rifts = {}
local riftExpiries = {}
local riftIsTriggered = {}
local riftLimitToPrint = 2
local liberated = false
local riftLimit = 2

-- when the next rift is
local nextRift = 0

-- Multishot
local numProjectiles = 1

local function CalculateRiftDelay(player, room)
    local riftDelay = math.floor(player.MaxFireDelay * 6.5) + 5

    -- if you're in an uncleared room, increase rift rate for a nice visual
    if room:IsClear() and riftDelay > 40 then
        riftDelay = 40
    end

    if room:IsClear() and room:GetBackdropType() == BackdropType.DARK_CLOSET then
        riftDelay = 5
    end

    return riftDelay
end

local function CalculateRiftLimit(player, room)
    local riftLimit = math.floor(85/(math.max(player.MaxFireDelay,0.1)^1.7)) + 1
    local riftLimit = riftLimit * numProjectiles
    riftLimitToPrint = riftLimit

    -- if the player can normally only have one rift, always recharge liberation immediately
    --[[
    if (riftLimit == 1) and (not liberationUsed) and (player:GetName() == "The Punished") and (not room:IsClear()) then
        liberationGiveAt = game:GetFrameCount()
    end
    ]]

    -- if in a big or long room, increase riftLimit
    if room:GetRoomShape() > 4 then
        riftLimit = math.max((riftLimit + 1), math.floor(riftLimit * 1.5))
    end

    return riftLimit
end

local function CalculateRiftPos(player, room)
    local topLeft = room:GetTopLeftPos()
    local botRight = room:GetBottomRightPos()
    topLeft = Vector( math.floor(topLeft.X), math.floor(topLeft.Y) )
    botRight = Vector( math.floor(botRight.X), math.floor(botRight.Y) )
    local riftPos = room:FindFreePickupSpawnPosition(Vector(math.random(topLeft.X, botRight.X), math.random(topLeft.Y, botRight.Y)), 0, true)
    return riftPos
end

local function DoSpawnSynergies(player, pos)
    if player:HasWeaponType(WeaponType.WEAPON_LASER) then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TECH_DOT, 0, pos, Vector(0,0), player)
    end
    if player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BRIMSTONE_SWIRL, 0, pos, Vector(0,0), player)
    end
end

local function SpawnRift(player, room, pos, vel)
    -- base effect
    local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PURGATORY, 0, pos, vel, player)
    --if not InPurgatory() then
    DoSpawnSynergies(player, pos)
    --end

    --record rifts
    if not room:IsClear() then
        table.insert(rifts, rift)
        table.insert(riftExpiries, game:GetFrameCount() + 750)
        table.insert(riftIsTriggered, false)
    end
end

local function TrySpawnRifts(player, room)
    local riftDelay = CalculateRiftDelay(player, room)
    riftLimit = CalculateRiftLimit(player, room)
    local riftPos = CalculateRiftPos(player, room)
    local riftVel = Vector(0,0)

    -- make condemnation stack with itself, being the punished counts as one stack
    local condemnationNum = math.max(1, player:GetCollectibleNum(ThePunished.ITEM.PASSIVE.CONDEMNATION) + (player:GetPlayerType() == ThePunished.PLAYER.PUNISHED and 1 or 0))
    riftDelay = math.max(math.floor(riftDelay / condemnationNum), 2)
    riftLimit = riftLimit * condemnationNum

    -- if you can spawn more rifts, do it after RiftDelay frames
    if (game:GetFrameCount() >= nextRift) then
        if #rifts < riftLimit and (
             not liberated
            or
             #rifts < 1) then
            numProjectiles = GetNumProjectiles(player)
            for _ = 1, numProjectiles do
                SpawnRift(player, room, riftPos, riftVel)
            end
            if room:IsClear() then
                --ambient effect
                if math.random(10) == 11 then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LIL_GHOST, 0, riftPos, riftVel, player)
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, riftPos, riftVel, player)
                end
            else
                --charge liberation if rifts are full
                --[[
                if (#rifts == riftLimit) and (riftLimit > 1) and (not liberationUsed) and (player:GetName() == "The Punished") then
                    liberationGiveAt = game:GetFrameCount() + 120
                end
                ]]
            end
        end

    end
end

local function PreventRiftRespawns(player)
    -- stop rifts from respawning themselves
    local riftDespawnFrames = 32
    if player:HasCollectible(Isaac.GetItemIdByName("Stop Watch")) then
        riftDespawnFrames = 37
    end

    if #riftExpiries > 0 then
        -- find out which rifts have expired
        local riftsToRemove = {}
        for i = 1, #riftExpiries do
            if riftExpiries[i] < game:GetFrameCount() and not liberated then
                table.insert(riftsToRemove, i)
            end
        end

        -- remove expired rifts
        if #riftsToRemove > 0 and #rifts > 0 then
            for i = #riftsToRemove, 1, -1 do
                rifts[riftsToRemove[i]]:Remove()
                table.remove(rifts, riftsToRemove[i])
                table.remove(riftExpiries, riftsToRemove[i])
                table.remove(riftIsTriggered, riftsToRemove[i])
            end
        end

        -- if you walk near an untriggered rift, document it as triggered and set its expiration date to verysoon(tm)
        for i = 1, #rifts do
            if player.Position:Distance(rifts[i].Position) < 50
              and not riftIsTriggered[i] then
                riftExpiries[i] = game:GetFrameCount() + riftDespawnFrames
                riftIsTriggered[i] = true

                --if liberation hasn't been used in this room and it isn't fully charged, gain one charge for walking over a rift
                --[[
                if not liberationUsed
                  and player:GetName() == "The Punished"
                  and player:GetActiveCharge(ActiveSlot.SLOT_POCKET) < 2 then
                    if riftLimitToPrint == 1 then
                        player:SetActiveCharge(2, ActiveSlot.SLOT_POCKET)
                    else
                        player:SetActiveCharge(player:GetActiveCharge(ActiveSlot.SLOT_POCKET) + 1, ActiveSlot.SLOT_POCKET)
                    end
                end
                ]]
            end
        end
    end
end

mod:addCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if player:HasCollectible(mod.ITEM.PASSIVE.CONDEMNATION) == true or player:GetPlayerType() == ThePunished.PLAYER.PUNISHED then
        local room = game:GetRoom()
        -- on room clear, reset roomEntryFrames, liberationUsed
        --[[
        if not roomCleared and room:IsClear() then
            roomCleared = true
            roomEntryFrames = game:GetFrameCount()
            liberationUsed = false
            liberationGiveAt = 10000000
            LiberationEnd(player)
        end
        ]]
        -- set challenge rooms, sacrifice rooms, and bossrush as "not cleared" so that rifts can spawn
        if (room:GetType() == RoomType.ROOM_CHALLENGE or room:GetType() == RoomType.ROOM_SACRIFICE or room:GetType() == RoomType.ROOM_BOSSRUSH)
         and room:GetAliveEnemiesCount() > 0 then
            room:SetClear(false)
        end
        TrySpawnRifts(player, room)
        PreventRiftRespawns(player)
    end
end)