# Project Report
## Learn to Build an AI-Based Traffic Signal Controller using VLSI

### 1. Abstract
This project demonstrates a digital traffic signal controller designed in Verilog RTL. A finite-state machine (FSM) controls the red, yellow, and green outputs. Green duration adapts to a vehicle-density category, and a pedestrian request is latched and served in a dedicated pedestrian phase. A reusable programmable timer generates phase-expiry pulses. The design is organized into reusable modules and verified with simulation testbenches.

### 2. Problem statement
Fixed-time traffic lights do not respond to changing traffic demand. The project models a simple adaptive controller that assigns longer green intervals to higher vehicle density and provides a pedestrian crossing phase when requested.

### 3. Objectives
- Design a synthesizable FSM for traffic-light sequencing.
- Use vehicle-density input to select a green interval.
- Implement a reusable timer module.
- Latch pedestrian requests and serve them safely in the FSM sequence.
- Verify expected behavior using Verilog testbenches and waveform inspection.
- Provide a modular RTL structure suitable for FPGA/VLSI learning.

### 4. Block-level architecture
`vehicle_count` → `density_logic` → `traffic_fsm_final` → traffic light outputs.

The FSM selects a phase and a `timer_limit`. `traffic_timer` counts clock cycles and produces `timer_expired`; the FSM uses that pulse to advance to the next phase. A pedestrian request is latched and considered at the end of the red phase. During the pedestrian phase, the vehicle red signal and `pedestrian_active` are asserted together.

### 5. Module description
**`density_logic.v`** — Converts an 8-bit vehicle count into three classes: low (`00`) for 0–9, medium (`01`) for 10–29, and high (`10`) for 30 or more.

**`traffic_timer.v`** — A parameterized-width counter. It resets its counter on expiry and emits a one-clock `timer_expired` pulse. A zero timer limit expires immediately.

**`traffic_fsm_final.v`** — Implements GREEN → YELLOW → RED, with RED transitioning to PEDESTRIAN when a request is pending, otherwise back to GREEN. PEDESTRIAN returns to GREEN after its timer expires. Output decoding is Moore-style.

**`traffic_system_top_final.v`** — Connects the FSM and timer using named ports.

**`traffic_system_with_count.v`** — Optional wrapper that places the density classifier before the integrated controller.

### 6. Timing policy used for demonstration
| Phase / class | Duration (clock cycles) |
|---|---:|
| Green, low density | 5 |
| Green, medium density | 10 |
| Green, high density | 20 |
| Yellow | 3 |
| Red | 8 |
| Pedestrian crossing | 6 |

The values are parameter defaults for simulation and must not be interpreted as seconds. If the clock is 50 MHz, for example, a 5-cycle phase would last only 100 ns; practical timing values need clock-based scaling and road-safety engineering.

### 7. Verification plan
1. Apply reset and verify that the controller starts in RED.
2. Change density between low, medium, and high and observe the selected green timing.
3. Apply a pedestrian request and verify that it is retained until serviced.
4. Verify that pedestrian service occurs with red asserted.
5. Inspect the VCD waveform for phase transitions and timer pulses.
6. Run the density testbench at counts 0, 9, 10, 29, 30, and 255 to check threshold behavior.

The integrated testbench includes assertions that green and yellow are never simultaneously active and that pedestrian mode implies red. These are useful starter checks, not a complete safety verification suite.

### 8. What makes the design “AI-based” and current limitation
The included RTL is adaptive but rule-based: vehicle count is converted to a density class using thresholds. It is not itself a trained AI model. To make the full system AI-based, a camera or sensor and an external AI inference stage must detect/count vehicles and communicate a count or density class to the RTL. A practical architecture is camera → edge AI / vehicle-count estimator → FPGA input interface → density logic/FSM/timer → isolated signal-driver stage. The AI and physical signal-driver stages are outside the current RTL scope.

### 9. Applications
- Digital design and FSM education.
- FPGA demonstration of adaptive control logic.
- Prototype for integrating an external vehicle-count estimator.
- RTL simulation and waveform-analysis exercises.

### 10. Future enhancements
- Replace thresholds with a validated sensor/AI-generated count.
- Add multi-lane arbitration and emergency-vehicle priority.
- Add watchdog, sensor-failure fallback, conflicting-light interlocks, and safe startup behavior.
- Add assertions and constrained-random verification.
- Scale timer parameters using the board clock and add synchronizers for asynchronous inputs.
- Synthesize, place, route, and measure resource/timing results on a selected FPGA/ASIC flow.

### 11. Conclusion
The project combines a timer, an adaptive FSM, pedestrian-request handling, top-level integration, and simulation testbenches. It provides a clear modular foundation for learning traffic-control RTL. It is an educational prototype only and is not certified for controlling real-world traffic signals.
