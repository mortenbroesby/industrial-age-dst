require "prefabutil"

local assets = {
    Asset("ANIM", "anim/heat_lamp.zip"),
}

local function GetHeatFn(inst)
    if inst.disabled or not inst.running then 
        return 0
    else 
        return 60
    end
end

local function OnTurnOn(inst)
    if not inst.disabled then
        inst.Light:Enable(true)
    end
    inst.running = true
    inst.sg:GoToState("idle")
    inst.components.energychanger:Activate()
end

local function OnTurnOff(inst)
    inst.Light:Enable(false)
    inst.running = false
    inst.sg:GoToState("idle")
    inst.components.energychanger:Deactivate()
end

local function OnHammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onForcedTurnOff(inst)
    if not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("idle")
    else 
        inst:DoTaskInTime(0.5, function()
            onForcedTurnOff(inst)
        end)
    end
end
       
local function OnHit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.sg:GoToState("hit")
    inst.components.machine.ison = false
    inst.running = false
    inst:DoTaskInTime(0.5, function()
        inst.Light:Enable(false)
    end)
    onForcedTurnOff(inst)
end

local function OnBuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.running = true
    inst.disabled = true
    inst.sg:GoToState("place")
end

local function OnSave(inst, data)
    if inst.running then
        data.running = inst.running
    end
end

local function OnLoad(inst, data)
    if data and data.running then
        inst.running = data.running
    else
        inst.running = false
    end
    inst.sg:GoToState("idle")
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
    if inst.running then
        if inst.disabled then return "DISABLED" else return "ACTIVE" end
    else
        return "PASSIVE"
    end
end

local function OnFindCell(inst, target, cellPos)
    --print("Energydrain sent!")
    target:PushEvent("depleteenergy", { cellPos = cellPos })
end

local function OnActiveCell(inst, hasActiveCell)
    --print("OnActiveCell: " .. tostring(hasActiveCell))
    inst.Light:Enable(hasActiveCell)
    inst.disabled = not hasActiveCell
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
 
    MakeObstaclePhysics(inst, 0.6)
    MakeSnowCovered(inst, 0.6)

    inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(8)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(.7)
    inst.Light:SetColour(255/255, 255/255, 255/255)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.range = TUNING.HEAT_LAMP_RANGE

    inst.AnimState:SetBank("heat_lamp")
    inst.AnimState:SetBuild("heat_lamp")

    inst:AddTag("heatedlamp")
    inst:AddTag("structure")

    inst:AddComponent("energychanger")
    inst.components.energychanger:SetOnFindCellFn(OnFindCell)
    inst.components.energychanger:SetOnActiveCellFn(OnActiveCell)
    inst.components.energychanger:SetMultiplier(2.5) -- needs more than two sections to allow charging of cells
    inst.components.energychanger:IsCharging(false)

    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = OnTurnOn
    inst.components.machine.turnofffn = OnTurnOff
    inst.components.machine.cooldowntime = 0
    inst.components.machine.ison = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:SetStateGraph("SGheat_lamp")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab( "common/objects/heat_lamp", fn, assets),
       MakePlacer("common/heat_lamp_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, 1.55)
       --MakePlacer("common/heat_lamp_placer", "heat_lamp", "heat_lamp", "idle")
