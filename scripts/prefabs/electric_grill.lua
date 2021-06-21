require "prefabutil"

local assets = {
    Asset("ANIM", "anim/heat_lamp.zip"),
}

local function GetHeatFn(inst)
    if inst.disabled or not inst.running then 
        return 0
    else 
        return 40
    end
end

local function PushDrainCell(inst)
    local x,y,z = inst:GetPosition():Get()
    local energycells = TheSim:FindEntities(x,y,z, inst.range, {"energycell"})
    local energycell = nil
    local energycell_found = false
    if #energycells > 0 then
        local closest_distance = inst.range
        local energycells_charged = 0
        for i, v in ipairs(energycells) do
            if not v.empty then
                local distanceToHeatlamp = v:GetDistanceSqToPoint(x, y, z)
                if distanceToHeatlamp < inst.range and distanceToHeatlamp < closest_distance then
                    --print("Discovered cell " .. tostring(v))
                    --print(distanceToHeatlamp)
                    energycells_charged = energycells_charged + 1
                    closest_distance = distanceToHeatlamp
                    energycell_found = true
                    energycell = v -- store found energy cell
                end
            end
        end

        if (energycells_charged < 1) then
            energycell_found = false
        end

        if (energycell_found) then
            inst.disabled = false
            inst.Light:Enable(true)
            energycell:PushEvent("depleteenergy", {energycell=energycell})
            --print("Asked for energy @: " .. tostring(energycell))
        else 
            inst.disabled = true
            inst.Light:Enable(false)
            --print("No cells with energy found")
        end

    else
        inst.disabled = true
        inst.Light:Enable(false)
        ---print("No cells found")
    end
end

local function BurnEnergy(inst)
    inst:DoTaskInTime(2, function()
        BurnEnergy(inst)
    end)
    if inst.running then
        PushDrainCell(inst)
    end
end

local function onturnon(inst)
    if not inst.disabled then
        inst.Light:Enable(true)
    end
    inst.running = true
    inst.AnimState:PlayAnimation("idle_on")
end

local function onturnoff(inst)
    inst.Light:Enable(false)
    inst.running = false
    inst.AnimState:PlayAnimation("idle_off")
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end
       
local function onhit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    --inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PlayAnimation("idle_on")
end

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.AnimState:PlayAnimation("place")
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
    if inst.running then
        inst.AnimState:PlayAnimation("idle_on")
    else 
        inst.AnimState:PlayAnimation("idle_off")
    end
end

local function GetStatus(inst)
    if not inst.running then
        return "PASSIVE"
    elseif not inst.disabled and inst.running then
        return "ACTIVE"
    elseif inst.disabled and inst.running then
        return "DISABLED"
    end
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

    inst.running = true
    inst.disabled = true

    inst:AddComponent("oven")
    inst.components.heater.heatfn = GetHeatFn

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = onturnon
    inst.components.machine.turnofffn = onturnoff
    inst.components.machine.cooldowntime = 0
    inst.components.machine.ison = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)

    BurnEnergy(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab( "common/objects/heat_lamp", fn, assets),
       MakePlacer("common/heat_lamp_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, 1.55)
