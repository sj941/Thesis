# Sam Jones Thesis 2025
set D ordered;
       # Power demand at each time period (kW)
   # Power demand at each time period (kW)
param max_capacity := 10;  # Max battery capacity in kWh
param max_discharge := 5; # Max discharge rate in kW
param initial_charge := 5;
param dt = 24/48; /* Half hourly time steps */
param price {D};
param grid_connection_capacity = 15;
param final_min_charge := 2;

# #trial hot water heater
# param HWH_power := 3;         # Power in kW
# param HWH_duration := 4;      # Number of time steps (e.g., 2 hours = 4 steps)
# param HWH_energy := 12;       # Total energy in kWh
# var hwh_start {d in D} binary;     # 1 if heater starts at time d
# var hwh_on {d in D} binary;        # 1 if heater is ON at time d

#PV
param PV{d in D} >= 0;

# # AC unit (central AC unit using a standard 1.5-3.5KW)
# # must do at least 20kW of cooling over the course of the day
# param AC_energy = 20;          # Total kWh required for the day
# param AC_power_min = 1.5;     # Minimum AC power in kW
# param AC_power_max = 3.0;     # Maximum AC power in kW
param eps := 1e-3;
# var ac_power {d in D} >= 0, <= AC_power_max;  # AC power can be 0 (OFF) or between 1.5–3.5 (ON)

var battery_charge {D} >= 0, <= max_capacity;  # Battery state of charge (kWh)
var discharge_rate {D} >= -max_discharge, <= max_discharge; # Battery discharge (kW)
var grid_power {D} >= 0, <= grid_connection_capacity;                       # Power drawn from the grid (kW)


# Demand Data
param Pd{d in D} >= 0;  /* Electrical demand (daily load profile) in kW */
param PgM = 15;  /* Maximum capacity of grid connection in kW */


minimize grid_usage:
    sum {d in D} price[d] * grid_power[d];

# subject to DemandBalance {d in D}:
#     grid_power[d] + discharge_rate[d] = Pd[d];
subject to DemandBalance {d in D}:
    PV[d] + grid_power[d] + discharge_rate[d] = Pd[d] + hwh_on[d]*HWH_power + ac_power[d];

subject to InitialBattery:
    battery_charge[first(D)] = initial_charge;
subject to BatteryDynamics {d in D: ord(d) > 1}:
    battery_charge[d] = battery_charge[prev(d)] - discharge_rate[prev(d)]*dt;
subject to FinalBattery:
    battery_charge[last(D)] >= final_min_charge;
#trial hot water heater
#subject to SingleHeaterStart:
#    sum {d in D} hwh_start[d] = 1;
subject to HeaterEnergy:
    sum {d in D} hwh_on[d] * HWH_power * dt = HWH_energy;

#AC 
# Constraint that says the AC can be off or operating on within Pmax and Pmin
# constraint relaxed for convexity
subject to AC_MinPower_IfOn {d in D}:
    ac_power[d] <= eps or ac_power[d] >= AC_power_min;
subject to AC_TotalEnergy:
    sum {d in D} ac_power[d] * dt = AC_energy;


