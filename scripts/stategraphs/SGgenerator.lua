require("stategraphs/commonstates")

local delay_amount = 1
local delay_count = 0
local animation = {
    "low",
    "medium",
    "high",
    "full"
}

local events =
{

}

local states=
{      
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            local section = inst.components.fueled:GetCurrentSection()
            if section == 0 then
                inst.AnimState:PlayAnimation("idle", false)
            else
                if not inst.sg:HasStateTag("busy") then
                    inst.AnimState:PlayAnimation(tostring(animation[section]))
                end
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "forced_idle",
        tags = { "busy" },

        onenter = function(inst, charge_value)
            inst.AnimState:PlayAnimation("idle", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if delay_count <= delay_amount then
                    delay_count = delay_count + 1
                    inst:DoTaskInTime(0.5, function()
                        inst.sg:GoToState("forced_idle")
                    end)
                else
                    inst.sg:GoToState("idle")
                    delay_count = 0
                end
            end),
        },
    },

    State{
        name = "place",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("place")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            delay_count = 0
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("forced_idle")
            end),
        },
    },
}

return StateGraph("generator", states, events, "idle")