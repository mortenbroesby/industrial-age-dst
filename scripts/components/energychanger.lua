local EnergyChanger = Class(function(self, inst)
    self.inst = inst

    self.range = 225 -- TUNING.ENERGY_DETECTOR_RANGE
    self.detectFrequency = 2
    self.multiplier = 1
    self.accumulated = 0

    self.ischarging = false
    self.hasActiveCell = false
    self.detectTask = nil
end)

--------------------------------------------------------------------------

function EnergyChanger:SetOnFindCellFn(fn)
    self.onfindcell = fn
end

function EnergyChanger:SetOnActiveCellFn(fn)
    self.onactivecell = fn
end

--------------------------------------------------------------------------

function EnergyChanger:SetMultiplier(number)
    self.multiplier = number
end

function EnergyChanger:IsCharging(boolean)
    self.ischarging = boolean;
end

--------------------------------------------------------------------------

local function Cancel(inst, self)
    if self.detectTask ~= nil then
        self.detectTask:Cancel()
        self.detectTask = nil
    end
end

function EnergyChanger:OnRemoveFromEntity()
    Cancel(self.inst, self)
end

--------------------------------------------------------------------------

local function AccumulateEnergy(inst, self)
    self.accumulated = self.accumulated + (5 * self.multiplier)
    --print("self.ischarging: " .. tostring(self.ischarging))
    --print("self.multiplier: " .. tostring(self.multiplier))
    --print("self.accumulated: " .. tostring(self.accumulated))
    if self.accumulated >= 100 then
        self.accumulated = self.accumulated - 100
        return true
    else
        return false
    end
end

local function CheckTargetState(target, self)
    if self.ischarging then
        if target.full then return true else return false end
    else
        if target.empty then return true else return false end
    end
end

local function FindEnergyCells(inst, self)
    if inst.sg:HasStateTag("busy") then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local energycells = TheSim:FindEntities(x,y,z, self.range, {"energycell"})
    local target = nil
    local closestDistance = self.range
    for i, cell in ipairs(energycells) do
        local isOffLimits = CheckTargetState(cell, self)
        if not isOffLimits then
            local distanceToEnergyChanger = cell:GetDistanceSqToPoint(x, y, z)
            if distanceToEnergyChanger < self.range and distanceToEnergyChanger < closestDistance then
                closestDistance = distanceToEnergyChanger
                target = cell
            end
        end
    end
    if target ~= nil then
        if self.onfindcell ~= nil then
            if AccumulateEnergy(inst, self) then
                self.onfindcell(inst, target, target:GetPosition())
            end
        end
    end
    self:UpdateState(inst, self, target)
end

--------------------------------------------------------------------------

function EnergyChanger:UpdateState(inst, self, target)
    if self.onactivecell ~= nil then
        if target ~= nil then
            if not self.hasActiveCell then
                self.hasActiveCell = true
                self.onactivecell(self.inst, self.hasActiveCell)
            end
        else
            if self.hasActiveCell then
                self.hasActiveCell = false
                self.onactivecell(self.inst, self.hasActiveCell)
            end
        end
    end
end
--------------------------------------------------------------------------

function EnergyChanger:Activate()
    Cancel(self.inst, self)
    self.detectTask = self.inst:DoPeriodicTask(self.detectFrequency, FindEnergyCells, 0, self)
end

function EnergyChanger:Deactivate()
    Cancel(self.inst, self)
end

--------------------------------------------------------------------------

function EnergyChanger:OnSave()
    return {
        accumulated = self.accumulated,
        hasActiveCell = self.hasActiveCell,
    }
end

function EnergyChanger:OnLoad(data)
    if data then
        print("self.accumulated: " .. tostring(data.accumulated))
        self.accumulated = data.accumulated
        self.hasActiveCell = data.hasActiveCell
    end
end

--------------------------------------------------------------------------

return EnergyChanger