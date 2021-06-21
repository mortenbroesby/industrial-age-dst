local assets= {
    Asset("ANIM", "anim/firefighter_range.zip")
}

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    trans:SetScale(1.55,1.55,1.55)
    
    inst.entity:AddNetwork()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    anim:SetBank("firefighter_placement")
    anim:SetBuild("firefighter_range")
    anim:PlayAnimation("idle")
    
    anim:SetOrientation(ANIM_ORIENTATION.OnGround)
    anim:SetLayer(LAYER_BACKGROUND)
    anim:SetSortOrder(3)
    
    inst.persists = false
    inst:AddTag("FX")
    inst:AddTag("range_indicator")
    
    inst:DoTaskInTime(10, function() inst:Remove() end)
    
    return inst
end

return Prefab( "common/range_indicator", fn, assets) 