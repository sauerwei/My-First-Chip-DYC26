# 09-ants
**Authors:**
Sophie Otten, Laura Pfisterer, Johann Rittenschober, Philipp Stasswender

This project is part of the block seminar [Design your Chip](https://moodle.hm.edu/course/view.php?id=24690) (February
2026). 

## Project Idea

This chip implements and demonstrates an Ant Colony Optimization (ACO)-inspired simulation on hardware. A configurable number of simulated ants explore a 204×160 grid, deposit pheromones, and collectively find paths between a nest and a food source using a simplified ACO algorithm. The simulation state is rendered to a 640×480 VGA display at 60Hz via a double-buffered framebuffer. All simulation parameters (number of ants, pheromone decay rate, heuristic weights, nest/food positions, display colors) are configurable at runtime via dedicated input pins.
The chip runs on a single 25 MHz clock derived from the VGA pixel clock. Several SRAM macros store the pheromone grid and the double-buffered framebuffer respectively.

The following figure shows the major components as well as an overview of the inputs and outputs of the chip: 
![figure_chip](chip.png)


## Pin List

### Power Pins

| Pin | Direction | Description |
|-----|-----------|-------------|
| `VDD` | Power | Core supply voltage (1.2V) |
| `VSS` | Ground | Core ground |
| `IOVDD` | Power | IO ring supply voltage |
| `IOVSS` | Ground | IO ring ground |

### Clock & Reset

| Pin | Direction | Description |
|-----|-----------|-------------|
| `clk_PAD` | Input | 25 MHz system clock (VGA pixel clock) |
| `rst_n_PAD` | Input | Active-low asynchronous reset |

### Simulation Parameters

| Pin | Direction | Description |
|-----|-----------|-------------|
| `ants_PADs[8:0]` | Input | Number of active ants (0–511) |
| `alpha_PADs[3:0]` | Input | Pheromone weight α for ACO decision |
| `beta_PADs[3:0]` | Input | Heuristic weight β for ACO decision |
| `q_PADs[3:0]` | Input | Pheromone deposit quantity Q |
| `rho_PADs[3:0]` | Input | Pheromone evaporation rate ρ |

### Nest & Food Positions

| Pin | Direction | Description |
|-----|-----------|-------------|
| `nest_x_PADs[7:0]` | Input | X coordinate of nest (0–203) |
| `nest_y_PADs[7:0]` | Input | Y coordinate of nest (0–159) |
| `food_x_PADs[7:0]` | Input | X coordinate of food source (0–203) |
| `food_y_PADs[7:0]` | Input | Y coordinate of food source (0–159) |

### Display Color Controls

| Pin | Direction | Description |
|-----|-----------|-------------|
| `rgb_bg_PADs[5:0]` | Input | Background color (2 bits per RGB channel) |
| `rgb_pheromones_PADs[5:0]` | Input | Pheromone trail color |
| `rgb_nest_PADs[5:0]` | Input | Nest icon color |
| `rgb_food_PADs[5:0]` | Input | Food source icon color |
| `rgb_ants_PADs[5:0]` | Input | Ant icon color |

### VGA Output

| Pin | Direction | Description |
|-----|-----------|-------------|
| `vga_PADs[7:0]` | Output | VGA output signal (TinyVGA PMOD format: `{hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}`) |



## Notes

- VGA output targets 640×480 @ 60 Hz. The 204×160 simulation grid is upscaled 3× with 14px black pillarboxes left and right.
- All input pins are sampled synchronously and should be held stable during operation.
- After reset, the chip waits approximately 2 seconds (boot delay) before beginning simulation and rendering, to allow all internal SRAM initialization to complete.


## Known Limitations

**Ant return path not functional.** The return behavior of ants is not fully implemented. Ants are able to find the food source and deposit pheromones on their way back towards the nest, but they do not successfully navigate back to the nest.

**LibreLane flow did not complete successfully.** The physical implementation flow (synthesis, place & route) could not be run through to completion within the project timeframe. The flow consistently got stuck during the synthesis step and the root cause could not be fully resolved before the end of the project.

