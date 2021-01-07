# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

inkling "2.0"

using Math
using Goal

# thresholds
const MaxDeviation = 5.0

type SimState {
    Tset: number,
    Troom: number,
    Toutdoor: number,
    total_cost: number
}

type ObservableState {
    Tdiff: number,
    Toutdoor: number,
    total_cost_fraction: number
}

type SimAction {
    command: number<cool=1.0, heat=2.0, off=3.0,>
}

type SimConfig {
    input_Toutdoor: number,
    input_Tset: number
}

# Transform Tdiff and total_cost according the outdoor temperature.
# The goal is to drive Troom below Tset on hot days and above Tset on cold days.
function TransformState(State: SimState): ObservableState {
    if State.Toutdoor > 73 {
        return {
            Tdiff: State.Troom - State.Tset,
            Toutdoor: State.Toutdoor,
            total_cost_fraction: State.total_cost / 4,
        } 
    } else {
        return {
            Tdiff: State.Tset - State.Troom, 
            Toutdoor: State.Toutdoor,
            total_cost_fraction: State.total_cost / 27,
        } 
    }
}

graph (input: ObservableState): SimAction {
    concept adjust(input): SimAction {
        curriculum {
            source simulator (action: SimAction, config: SimConfig): SimState {
                # package "bem_final"
            }

            state TransformState

            training {
                # Limit episodes to 288 iterations, which is 1 day (24 hours).
                EpisodeIterationLimit: 288,
                NoProgressIterationLimit: 600000
            }

            goal (State: SimState) {
                drive `Temp Deviation`:
                    TransformState(State).Tdiff in Goal.RangeBelow(MaxDeviation)
            }

            lesson adjust_easy {
                scenario {
                    input_Toutdoor: 60.0,
                }
            }
            lesson adjust_medium {
                scenario {
                    input_Toutdoor: number<50.0 .. 70.0>,
                }
            }
            lesson adjust_mediumhard {
                scenario {
                    input_Toutdoor: number<40.0 .. 80.0>,
                }
            }
            lesson adjust_hard {
                scenario {
                    input_Toutdoor: number<30.0 .. 95.0>,
                }
            }
            lesson adjust_hardest {
                scenario {
                    input_Toutdoor: number<25.0 .. 100.0>,
                }
            }
        }
    }
    output adjust
}
