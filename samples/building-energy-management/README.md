# building-energy-management

## Objective

Train a brain to replace the thermostat controller for the heating and cooling a thermal model of a house with varying outdoor temperatures over the course of two days. The objective is to minimize the dollar cost, but also provide comfort by tracking the set point temperature. Heating is four times as expensive as cooling, which reflects how typically energy bills are more expensive in Winter. Given the temperature swings throughout the day, the AC can struggle with meeting the set point temperature due to the nature of the thermostat controller.

## Action

| Action | Discrete Value | Units |
|----------------------------|-------------------------------|-------------------------------|
| off | 3 | [-] |
| heater_blower | 2 | [-] |
| ac_blower | 1 | [-] |
...

## State

| State | Units |
|----------------------------|-------------------------------|
| Tset | [F] |
| Troom | [F] |
| Toutdoor | [F] |
| cost | [$] |
...

## Constraints

- Can only use AC or heater one at a time
- Tset is based on [energy.gov](https://www.energy.gov/energysaver/thermostats) recommended thermostat settings:
  - Summer: 78F during the day, 86F at night
  - Winter: 68F during the day, 60 at night
  - In the simulation, we follow the Summer Tset if Toutdoor > 73 and the Winter Tset if not.
- Troom within < 5 degrees F of set point

## Configuration Parameters

- length of house [m]
- width of house [m]
- height of house [m]
- number of windows [-]
- conduction coefficient of wall insulation [J/hr/m/C]
- thickness of wall insulation [m]
- Tset [F]
- Toutdoor [F]

## Switching between Benchmark and Bonsai Block

The controller block in buildingEnergyManagement.slx allows you to use the same file for both the benchmark thermostat and the bonsai brain. Simply right click on the block, then choose Variant-> Label Mode Active Choice -> Bonsai.

<img src="img/controller.png" alt="drawing" width="700"/>

## Benchmark

- Mean Absolute Error = 3.4517F
- Cost = $3.92

<img src="img/benchmark.png" alt="drawing" width="500"/>

## Hot

- Mean Absolute Error = 3.0913F
- Cost = $2.42

<img src="img/hot.png" alt="drawing" width="500"/>

## Cold

- Mean Absolute Error = 3.5867F
- Cost = $22.71

<img src="img/cold.png" alt="drawing" width="500"/>

## Acknowledgements

[Mathworks Example](https://www.mathworks.com/help/simulink/slref/thermal-model-of-a-house.html)