require "prefabutil"

local assets = {
    Asset("ANIM", "anim/generator.zip"),
    Asset("SOUNDPACKAGE", "sound/generator.fev"),
    Asset("SOUND", "sound/generator.fsb"),
}

local heat_table = { 70, 85, 100, 115 }
local radius_table = { 0.5, 3, 5, 8 }
local multiplier_table = { 2.2, 2.5, 2.7, 3 }
local status_table = { "EMBERS", "LOW", "NORMAL", "HIGH" }

local function GetHeatFn(inst)
    return heat_table[inst.stored_section] or 0
end

local function CheckSection(inst)
    --print("Stored section: " .. tostring(inst.stored_section))
    if inst.sg:HasStateTag("busy") then
        inst:DoTaskInTime(1, CheckSection, 1)
        return
    else 
        inst.sg:GoToState("idle")
    end
    if (inst.stored_section > 0) then
        inst.SoundEmitter:PlaySound("generator/generator/humming","humming")
        inst.Light:Enable(true)
        inst.Light:SetRadius(radius_table[inst.stored_section])
        inst.components.energychanger:SetMultiplier(multiplier_table[inst.stored_section])
        inst.components.energychanger:Activate()
    else
        inst.SoundEmitter:KillSound("humming")
        inst.Light:Enable(false)
        inst.Light:SetRadius(0)
        inst.components.energychanger:SetMultiplier(1)
        inst.components.energychanger:Deactivate()
    end
end

local function OnExtinguish(inst)
    if inst.components.fueled then
        inst.Light:Enable(false)
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function OnHammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst.SoundEmitter:KillSound("humming")
    inst:Remove()
end

local function OnHit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.SoundEmitter:KillSound("humming")
    inst.sg:GoToState("hit")
    CheckSection(inst)
end

local function OnBuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.sg:GoToState("place")
end

local function OnSave(inst, data)
    if inst.stored_section > 0 then
        data.stored_section = inst.stored_section
    end
end

local function OnLoad(inst, data)
    if data and data.stored_section then
        inst.stored_section = data.stored_section
        CheckSection(inst)
    else
        inst.sg:GoToState("idle")
    end
end

function GetRange(inst, viewer) -- move to component
    local pos = Point(inst.Transform:GetWorldPosition())
    local range_indicators = TheSim:FindEntities(pos.x,pos.y,pos.z, 2, {"range_indicator"})
    if #range_indicators < 1 then
        local range = SpawnPrefab("range_indicator")
        range.Transform:SetPosition(pos.x, pos.y, pos.z)
    end
    return inst.components.fueled ~= nil and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= .25 and "LOWFUEL" or "ON"
end

local function GetStatus(inst)
    GetRange(inst)
    return (inst.stored_section == 0 and "OUT")
        or (inst.stored_section <= #status_table and status_table[inst.stored_section])
        or nil
end

local function OnFindCell(inst, target, cellPos)
    --print("Energy sent!")
    target:PushEvent("fillenergy", { cellPos = cellPos })
end

local function fn(Sim)
    local inst = CreateEntity()
 
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.8)
    MakeSnowCovered(inst, 0.8)

    inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(5.7)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(255/255, 255/255, 255/255)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.AnimState:SetBank("generator")
    inst.AnimState:SetBuild("generator")

    inst:AddTag("generator")
    inst:AddTag("structure")

    inst.stored_section = 0

    inst:AddComponent("energychanger")
    inst.components.energychanger:SetOnFindCellFn(OnFindCell)
    inst.components.energychanger:SetMultiplier(1)
    inst.components.energychanger:IsCharging(true)

    inst:AddComponent("burnable")
    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    inst:ListenForEvent("onextinguish", OnExtinguish)

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.GENERATOR_FUEL_MAX
    inst.components.fueled.accepting = true
   
    inst.components.fueled.rate = TUNING.GENERATOR_FUEL_RATE
    inst.components.fueled:SetSections(4)
    inst.components.fueled.ontakefuelfn = function() 
        CheckSection(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") 
    end

    inst.components.fueled:SetUpdateFn(function()
        if inst.components.burnable and inst.components.fueled then
            CheckSection(inst)
        end
    end)

    inst.components.fueled:SetSectionCallback(function(section)
        inst.stored_section = section
        if section == 0 then
            inst.components.burnable:Extinguish()
        else
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end
        end
    end)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5) -- set to 5
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:SetStateGraph("SGgenerator")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("common/objects/generator", fn, assets),
    MakePlacer("common/generator_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, 1.55)
    --MakePlacer("common/generator_placer", "generator", "generator", "idle")