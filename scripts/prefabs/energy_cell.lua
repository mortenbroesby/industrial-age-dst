require "prefabutil"

local assets = {
    Asset("ANIM", "anim/energy_cell.zip"),
}

local function CheckEnergy(inst)
    if not inst.task then
        inst.task = inst:DoPeriodicTask(1, CheckEnergy, 1)
    end

    --[[print("Charge left:")
    print(tostring(inst.stored_charge))
    print("Empty? " .. tostring(inst.empty))]]

    if inst.stored_charge and inst.stored_charge > 0 then
        inst.empty = false
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("idle", inst.stored_charge)
        end
    else 
        inst.empty = true
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("idle", 0)
        end
    end
    if inst.stored_charge and inst.stored_charge > 0 then
        if inst.stored_charge <= (TUNING.CELL_ENERGY_MAX - 1) then
            inst.full = false
        elseif inst.stored_charge == TUNING.CELL_ENERGY_MAX then
            inst.full = true
        end
    end
end

local function OnFillEnergy(inst)
    print("Energy recieved")
    if inst.stored_charge and inst.stored_charge > 0 then
        if inst.stored_charge < TUNING.CELL_ENERGY_MAX then
            inst.stored_charge = inst.stored_charge + 1
        end
    else
        inst.stored_charge = 1
    end
    CheckEnergy(inst)
end

local function OnDepleteEnergy(inst)
    print("Energy sent")
    if inst.stored_charge and inst.stored_charge > 0 then
        inst.stored_charge = inst.stored_charge - 1
    else 
        inst.stored_charge = 0
    end
    CheckEnergy(inst)
end

local function OnHammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end
       
local function OnHit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.sg:GoToState("hit")
    --inst.stored_charge = TUNING.CELL_ENERGY_MAX -- uncomment to instantly fill cell on hit
    inst:DoTaskInTime(1.5, function()
        CheckEnergy(inst)
    end)
end

local function OnLightning(inst)
    --print("Lightning hit")
    inst.stored_charge = TUNING.CELL_ENERGY_MAX
    OnHit(inst)
end

local function OnBuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.stored_charge = 0
    inst.empty = true
    inst.full = false
    inst.sg:GoToState("place")
end

local function OnSave(inst, data)
    if inst.stored_charge then
        data.stored_charge = inst.stored_charge
    end
    if inst.depletion_value then
        data.depletion_value = inst.depletion_value
    end
end

local function OnLoad(inst, data)
    if data and data.stored_charge then
        inst.stored_charge = data.stored_charge
    end
    if data and data.depletion_value then
        inst.depletion_value = data.depletion_value
    end
    CheckEnergy(inst)
end

local function GetStatus(inst)
    if inst.stored_charge and inst.stored_charge > 0 then
        if inst.stored_charge <= (TUNING.CELL_ENERGY_MAX*25/100) then
            return "LOW"
        elseif inst.stored_charge <= (TUNING.CELL_ENERGY_MAX*50/100) then
            return "MEDIUM"
        elseif inst.stored_charge <= (TUNING.CELL_ENERGY_MAX*75/100)  then
            return "HIGH"
        elseif inst.stored_charge == (TUNING.CELL_ENERGY_MAX) then
            return "FULL"
        end
    else 
        return "EMPTY"
    end
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.6)
    MakeSnowCovered(inst, 0.4)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.depletion_value = 0
    inst.depletion_multiplier = TUNING.CELL_DEPLETION_MULTIPLIER

    inst.AnimState:SetBank("energy_cell")
    inst.AnimState:SetBuild("energy_cell")

    inst:AddTag("structure")
    inst:AddTag("lightningrod")
    inst:AddTag("energycell")
    inst:AddTag("structure")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("lightningstrike", OnLightning)
    inst:ListenForEvent("fillenergy", OnFillEnergy)
    inst:ListenForEvent("depleteenergy", OnDepleteEnergy)

    inst:SetStateGraph("SGenergy_cell")

    CheckEnergy(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab( "common/objects/energy_cell", fn, assets),
       MakePlacer("common/energy_cell_placer", "energy_cell", "energy_cell", "idle")