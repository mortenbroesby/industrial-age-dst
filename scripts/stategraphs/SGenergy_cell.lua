require("stategraphs/commonstates")

local events =
{

}

local states=
{      
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst, charge_value)
            if charge_value then
                inst.sg.statemem.charge_value = charge_value
                inst.AnimState:PlayAnimation(tostring(inst.sg.statemem.charge_value))
            else
                inst.AnimState:PlayAnimation("idle", false)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle", inst.sg.statemem.charge_value or 0)
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
                inst.sg:GoToState("idle")
            end),
        },
    },
}

return StateGraph("energy_cell", states, events, "idle")