local mod = ThePunished
local game = Game()
local sfx = SFXManager()
local ItemConfig = Isaac.GetItemConfig()
local ItemPool = game:GetItemPool()

local liberationUsed
local liberatedHits = 0

local function GetGridIndicesInRadius(pos, range)
    local posIndex = game:GetRoom():GetGridIndex(pos)
    local roomWidth = game:GetRoom():GetGridWidth()
    local indexTable = {}
    for i = -range, range do
        for j = -range, range do
            indexTable[#indexTable + 1] = posIndex + i + j * roomWidth
        end
    end

    return indexTable
end

-- Call when trying to charge liberation, checks if it can charge
function ThePunished:LiberationHandleCharges(player, riftLimit)
    -- if liberation has been used, dont charge
    if(liberationUsed or game:GetRoom():IsClear() == true) then
        return
    end
    -- if they only have one rift, always charge
    if(riftLimit == 1) then
        player:SetActiveCharge(2, ActiveSlot.SLOT_POCKET)
    elseif (player:GetActiveCharge(ActiveSlot.SLOT_POCKET) < 2) then
        player:SetActiveCharge(player:GetActiveCharge(ActiveSlot.SLOT_POCKET) + 1, ActiveSlot.SLOT_POCKET)
    end
end

local function OnUseLiberation()
    liberationUsed = true
    local player = mod:GetPlayerUsingItem()

    -- if there are enemies, start astral project
    if not game:GetRoom():IsClear() then
        player:AddCollectible(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION)
        Liberated = true
    end

    -- dull razor, spawn chain shards and make break sound
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, player.Position, Vector(0,0), player)
    sfx:Play(SoundEffect.SOUND_CHAIN_BREAK, 2, 0, false, 1)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_DULL_RAZOR, UseFlag.USE_NOANIM)

    -- destroy rocks + walls around you
    Indices = GetGridIndicesInRadius(player.Position, 1)
    for i = 1, #Indices do
        game:GetRoom():DestroyGrid(Indices[i], true)
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, OnUseLiberation, ThePunished.ITEM.ACTIVE.LIBERATION)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    local player = PunishedExists()
    liberationUsed = false
    Liberated = false
    -- get the Punished, empty their liberation charges, and remove astral projection if they have it
    if player ~= nil then
        local projections = player:GetCollectibleNum(Isaac.GetItemIdByName("Astral Projection"))
        for i = 1, projections do
            player:RemoveCollectible(Isaac.GetItemIdByName("Astral Projection"))
        end
        player:SetActiveCharge(0, ActiveSlot.SLOT_POCKET)
    end
end)

-- on taking damage while liberated, end it (has to be equal to 2 due to dull razor hit)
local function damageTaken(target)
    if(Liberated) then
        local player = target:ToPlayer()
        liberatedHits = liberatedHits + 1
        if(liberatedHits == 2) then
            Liberated = false
        end
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, damageTaken(), EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
    Liberated = false
end)