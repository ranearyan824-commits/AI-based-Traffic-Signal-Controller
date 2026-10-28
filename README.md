# Learn to Build an AI-Based Traffic Signal Controller Using VLSI

## Project Overview

This project demonstrates the design and simulation of a density-adaptive traffic signal controller using Verilog HDL and VLSI design principles. It incorporates a Finite State Machine (FSM), a reusable timer module, vehicle-density classification, pedestrian-request handling, and a simulation testbench.

The controller adjusts green-light durations according to traffic density and provides a dedicated pedestrian crossing phase. The project is designed for educational purposes and can be simulated using Icarus Verilog or developed further using FPGA design tools such as Xilinx Vivado and Intel Quartus.

**Note:** The current implementation uses a rule-based density classifier rather than a trained machine-learning model. In a practical AI-based system, a camera or edge-AI processor would detect vehicles and send the estimated vehicle count to the Verilog controller.

## Project Structure

```text
traffic_signal_ai_vlsi/
├── rtl/
│   ├── traffic_timer.v
│   ├── density_logic.v
│   ├── traffic_fsm_final.v
│   ├── traffic_system_top_final.v
│   └── traffic_system_with_count.v
├── tb/
│   ├── traffic_system_tb_final.v
│   └── density_tb.v
└── docs/
    └── PROJECT_REPORT.md
```

## Functional Specifications

The system consists of the following functional blocks:

- **Vehicle Density Classifier:** Classifies traffic as low, medium, or high based on the vehicle count.
- **Adaptive Green-Light Timing:** Allocates different green-light durations according to the detected traffic density.
- **Finite State Machine:** Controls transitions between the red, yellow, green, and pedestrian phases.
- **Timer Module:** Provides timing control for each traffic signal phase.
- **Pedestrian Request Handling:** Stores pedestrian requests and serves them during the appropriate phase.
- **Reset Function:** Uses an active-high asynchronous reset to initialize the controller.
- **Simulation Testbench:** Verifies signal transitions, timing behavior, and selected safety conditions.

### Traffic Density Classification

| Vehicle Count | Density Level | Green Duration |
|---|---|---|
| 0–9 | Low (`00`) | 5 clock cycles |
| 10–29 | Medium (`01`) | 10 clock cycles |
| 30 or more | High (`10`) | 20 clock cycles |

The remaining phase durations are:

| Signal Phase | Duration |
|---|---:|
| Yellow light | 3 clock cycles |
| Red light | 8 clock cycles |
| Pedestrian crossing | 6 clock cycles |

These values are intended for simulation and demonstration. Actual timing depends on the FPGA clock frequency and the requirements of the intended application.

## RTL Module Description

### 1. `traffic_timer.v`

Implements a reusable timer that counts clock cycles and indicates when the specified duration has elapsed.

### 2. `density_logic.v`

Converts the 8-bit vehicle count into a two-bit density classification: low, medium, or high.

### 3. `traffic_fsm_final.v`

Implements the finite state machine responsible for managing traffic signal sequences, timing transitions, and pedestrian requests.

### 4. `traffic_system_top_final.v`

Acts as the top-level module when the vehicle-density classification is provided externally.

**Inputs:** `clk`, `reset`, `vehicle_density[1:0]`, `pedestrian_request`

**Outputs:** `red`, `yellow`, `green`, `pedestrian_active`

### 5. `traffic_system_with_count.v`

Integrates the density classifier with the traffic controller, allowing the system to accept a raw vehicle count directly.

**Inputs:** `clk`, `reset`, `vehicle_count[7:0]`, `pedestrian_request`

**Outputs:** `red`, `yellow`, `green`, `pedestrian_active`

Use this module when the controller receives a vehicle count from an external detection system. Use `traffic_system_top_final` when the density classification is already available.

## Simulation Using Icarus Verilog

Install Icarus Verilog and ensure that both `iverilog` and `vvp` are available in your system's command line.

From the project root directory, compile and run the main traffic controller testbench:

```bash
iverilog -g2012 -o traffic_sim \
  rtl/traffic_timer.v \
  rtl/traffic_fsm_final.v \
  rtl/traffic_system_top_final.v \
  tb/traffic_system_tb_final.v

vvp traffic_sim
```

The simulation generates a VCD waveform file named `traffic_system.vcd`, which can be inspected using GTKWave:

```bash
gtkwave traffic_system.vcd
```

To test the density classifier independently, run:

```bash
iverilog -g2012 -o density_sim \
  rtl/density_logic.v \
  tb/density_tb.v

vvp density_sim
```

To simulate the integrated vehicle-count design, include `rtl/density_logic.v` and `rtl/traffic_system_with_count.v` along with the required timer and FSM modules and a suitable testbench.

## FPGA Implementation Workflow

1. Create a project in Xilinx Vivado, Intel Quartus, or the FPGA tool required by your course.
2. Add all Verilog files from the `rtl/` directory as design sources.
3. Add the appropriate testbench from the `tb/` directory as a simulation source.
4. Select `traffic_system_top_final` or `traffic_system_with_count` as the top module, depending on the selected input interface.
5. Run behavioral simulation and examine the generated waveforms.
6. Verify the controller's state transitions, timing intervals, and pedestrian-request behavior.
7. For FPGA implementation, configure the clock constraints and assign the required input and output pins according to the development board.

## Verification and Testing

The project includes testbenches to evaluate the main controller and the density-classification logic.

The main testbench prints signal changes, generates a VCD waveform, and checks selected conditions, including:

- Green and yellow signals must not be active simultaneously.
- The vehicle red signal must remain asserted during the pedestrian phase.
- Traffic-density thresholds must be handled correctly.
- Signal transitions must follow the controller's state sequence.
- Pedestrian requests must be handled according to the specified control logic.

Additional tests should verify reset behavior, timer boundaries, and consecutive pedestrian requests. These checks help identify design errors before FPGA implementation.

## Applications

- Intelligent traffic management demonstrations
- VLSI and digital-system design education
- Verilog HDL and FSM design practice
- FPGA-based traffic signal prototypes
- Educational projects combining external vehicle detection with digital control

## Conclusion

This project demonstrates how Verilog RTL, finite state machines, timers, and density classification can be combined to create an adaptive traffic signal controller. It provides a foundation for learning digital design, simulation, and FPGA implementation. Integrating a real vehicle-detection or edge-AI module would extend the project toward a practical AI-assisted traffic management system.

**Safety consideration:** This is an educational prototype, not a certified traffic-control system. Real-world deployment requires independent fault handling, appropriate fail-safe behavior, validated timing, and professional safety engineering.
