# Risk Adaptive Task Allocation - IROS 2021

This includes all the code that was used to generate the results found in the following paper: 
> Max Rudolph, Sonia Chernova, and Harish Ravichandar, "Desperate Times Call for Desperate Measures:Towards Risk-Adaptive Task Allocation", IROS 2021.

## Numerical Experiments
The code for the numerical results can be found in `iros_monte_carlo/mmonte_carlo_sim.m` and the code for plotting the results is in `iros_monte_carlo/plot_results.m`. Be sure to change the data ID if you wish to plot data that you generate. Simply look in the `/data/` folder to find the most recent data structure that corresponds to your run. The structure currently in the folder corresponds to the exact data we used for the IROS submission

## Robot Experiments
To run the Robotarium experiment, run `iros_robot_experiment/iros_robot_experiment.m`. To run the sampling experiment, run `iros_robot_experiment/iros_robot_sampling.m`

