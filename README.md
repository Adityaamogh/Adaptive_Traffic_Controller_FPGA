# FPGA-Based Adaptive Traffic Signal Controller

A hardware-accelerated, real-time adaptive traffic signal management system implemented in **Verilog HDL** and deployed on the **Intel Cyclone IV E FPGA (DE2-115)**. 

The architecture interfaces with an external computer vision stream via **UART (9600 baud)**, dynamically computes lane green times using a mathematical weight function, and schedules traffic signals with priority preemption for emergency scenarios.

---

## ?? Key Hardware Specifications & Synthesis Results

* **Target Device:** Intel Cyclone IV E (EP4CE115F29C7) on Terasic DE2-115 Board
* **Synthesis \& Toolflow:** Intel Quartus Prime 18.1 / ModelSim
* **Logic Utilization:** ~1,508 Logic Elements (< 2% FPGA fabric)
* **Static Timing Analysis (STA):** Achieved **121 MHz** worst-case clock frequency ({\max}$) via TimeQuest with zero timing/slack violations
* **Interface:** Standard 8-N-1 UART at 9600 baud

---

## ?? System Architecture

The hardware pipeline is partitioned into four modular stages:

`
[ External Vision / PC ] 
             (UART RX @ 9600 baud, 8-N-1)
          ?
+-------------------+
      uart_rx          Synchronizes and deserializes incoming byte stream
+-------------------+
             rx_data, rx_valid
          ?
+-------------------+
    packet_parser      Validates 6-byte packet: [0xAA][v0][v1][v2][v3][Checksum]
+-------------------+
             v0, v1, v2, v3 (Vehicle counts)
          ?
+-------------------+
     traffic_FSM       Computes dynamic threshold, timing, and lane states
+-------------------+
             green, yellow, red, timer, state
          ?
+-------------------+
     de2115_top        Drives onboard LEDs (LEDR/LEDG) and 7-Segment Displays (HEX0-HEX5)
+-------------------+
`

---

## ?? Repository Structure

`
FPGA-Adaptive-Traffic-Controller/
 
+-- rtl/                                  # Verilog HDL source modules
    +-- de2115_top.v                      # Top-level module for DE2-115 board
    +-- traffic_system.v                  # Core FSM with dynamic threshold calculation
    +-- packet_parser.v                   # 6-byte UART packet decoder & checksum checker
    +-- uart_rx.v                         # Parameterized 9600-baud UART receiver
    +-- traffic_FSM_standalone.v          # Standalone FSM module for testbenches
 
+-- constraints/                          # Hardware constraints
    +-- traffic_system.qsf                # Pin assignments & device configuration
    +-- traffic_system.sdc                # Synopsys Design Constraints (50 MHz clock)
 
+-- bitstream/                            # Ready-to-program FPGA files
    +-- traffic_system.sof                # SRAM Object File for Quartus Programmer
 
+-- traffic_system.qpf                    # Quartus Prime Project File
+-- traffic_system.qsf                    # Quartus Prime Settings File
+-- README.md                             # Documentation
`

---

## ?? FSM & Timing Algorithm

The core state machine continuously evaluates lane congestion:

1. **Dynamic Congestion Threshold:**
   $$\text{dyn\_thresh} = \left(\frac{v_0 + v_1 + v_2 + v_3}{8}\right) + 7$$

2. **Adaptive Green Timing:**
   $$\text{calc\_time}(v) = \text{BASE} + (\text{FACTOR} \times v) + \text{YELLOW\_TIME}$$
   *(Default: $\text{BASE} = 5\text{s}$, $\text{FACTOR} = 2\text{s/vehicle}$, $\text{YELLOW\_TIME} = 2\text{s}$)*

3. **Priority Overrides:** If a lane exceeds the dynamic threshold, the FSM transitions directly to that lane; otherwise, it prioritizes the lane with the highest queue.
---

## ?? How to Build & Run in Quartus Prime

1. Open **Intel Quartus Prime**.
2. Go to **File** $\rightarrow$ **Open Project** and select 	raffic_system.qpf.
3. Click **Processing** $\rightarrow$ **Start Compilation** (Ctrl + L).
4. Once compiled, open **Tools** $\rightarrow$ **Programmer**.
5. Connect your **DE2-115** board via USB-Blaster and program itstream/traffic_system.sof.
