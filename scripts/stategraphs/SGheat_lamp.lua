require("stategraphs/commonstates")

local events =
{

}

local states=
{      
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            if inst.running then
                if inst.disabled then
                    inst.AnimState:PlayAnimation("idle_on_disabled", false)
                else
                    inst.AnimState:PlayAnimation("idle_on", false)
                end
            else
                inst.AnimState:PlayAnimation("idle_off", false)
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
            inst.AnimState:PlayAnimation("idle_off", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:DoTaskInTime(1, function()
                    inst.sg:GoToState("idle")
                end)
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
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("forced_idle")
            end),
        },
    },
}

return StateGraph("heat_lamp", states, events, "idle")