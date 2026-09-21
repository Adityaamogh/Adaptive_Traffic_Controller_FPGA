# FPGA-Based Adaptive Traffic Signal Controller

A hardware-accelerated, real-time adaptive traffic signal management system implemented in **Verilog HDL** and deployed on the **Intel Cyclone IV E FPGA (DE2-115)**.

The system receives vehicle counts from an external computer vision application through **UART (9600 baud)**, computes adaptive green signal timings, and supports **priority preemption for emergency vehicles**.

---

## Key Hardware Specifications

| Parameter | Value |
|-----------|-------|
| **Target FPGA** | Intel Cyclone IV E (EP4CE115F29C7) |
| **Development Board** | Terasic DE2-115 |
| **Tools Used** | Intel Quartus Prime 18.1, ModelSim |
| **Logic Utilization** | ~1,508 Logic Elements (<2% of FPGA) |
| **Maximum Clock Frequency** | 121 MHz (TimeQuest STA) |
| **UART Interface** | 9600 baud, 8-N-1 |

---

## System Architecture

```text
External Vision / PC
        │
 UART RX (9600 baud)
        │
+-------------------+
|      uart_rx      |
+-------------------+
        │
   rx_data, rx_valid
        │
+-------------------+
|   packet_parser   |
+-------------------+
        │
 Vehicle Counts (v0-v3)
        │
+-------------------+
|    traffic_FSM    |
+-------------------+
        │
 Signal States & Timer
        │
+-------------------+
|    de2115_top     |
+-------------------+
        │
 LEDs & 7-Segment Displays
```

---

## Repository Structure

```text
FPGA-Adaptive-Traffic-Controller/

├── rtl/
│   ├── de2115_top.v
│   ├── traffic_system.v
│   ├── packet_parser.v
│   ├── uart_rx.v
│   └── traffic_FSM_standalone.v
│
├── constraints/
│   ├── traffic_system.qsf
│   └── traffic_system.sdc
│
├── bitstream/
│   └── traffic_system.sof
│
├── traffic_system.qpf
├── traffic_system.qsf
```

---

## FSM and Adaptive Timing Algorithm

The controller dynamically adjusts signal timings using vehicle density.

### Dynamic Congestion Threshold

```text
dynamic_threshold = ((v0 + v1 + v2 + v3) / 8) + 7
```

### Adaptive Green Signal Timing

```text
green_time = BASE + (FACTOR × vehicle_count) + YELLOW_TIME
```

Default parameters:

- **BASE** = 5 s
- **FACTOR** = 2 s per vehicle
- **YELLOW_TIME** = 2 s

### Priority Scheduling

- If a lane exceeds the dynamic congestion threshold, it is immediately prioritized.
- Otherwise, the FSM allocates the next green signal to the lane with the highest vehicle count.

---

## Build and Run (Quartus Prime)

1. Open **Intel Quartus Prime**.
2. Select **File → Open Project** and open `traffic_system.qpf`.
3. Click **Processing → Start Compilation** (`Ctrl + L`).
4. Open **Tools → Programmer**.
5. Connect the **DE2-115** board using USB-Blaster.
6. Program the FPGA using `bitstream/traffic_system.sof`.
