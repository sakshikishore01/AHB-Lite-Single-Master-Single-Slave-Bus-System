# AHB-Lite-Single-Master-Single-Slave-Bus-System
A synthesizable, pipelined AHB-Lite (AMBA 3) compliant bus infrastructure containing a single Master, a Zero-Wait-State Slave, and a Top-level interconnect interconnecting them. This project was developed, simulated, and verified using the Cadence Xcelium enterprise simulator environment.

##  Project Overview
A synthesizable, fully pipelined AMBA AHB-Lite (1 Master, 1 Slave) bus infrastructure developed, simulated, and verified within the Cadence Xcelium enterprise environment. This project showcases the high-throughput, dual-phase nature of the AHB protocol by overlapping the Address and Data phases to achieve continuous, cycle-by-cycle memory transactions.


## Key Features
Pipelined Architecture: Separates and overlaps the Address Phase and Data Phase for maximum bus utilization.  
High-Throughput Streaming: The Master FSM bypasses idle states to stream back-to-back operations dynamically when enabled.  
Integrated Hardware Math: The Master includes internal pipeline execution logic ($data\_in\_a + data\_in\_b$) stashed during the Address phase and committed during the Data phase. 
Zero-Wait-State Slave: Memory reads and writes execute instantly (HREADYOUT = 1) without stalling the bus channel.

## Architecture & Module Breakdown
The design is modularized across three primary Verilog hardware files:

1. Master Logic (ahb_master_input.v)
   Driven by an internal Finite State Machine (STATE_IDLE, STATE_ADDR, STATE_DATA) that reacts dynamically to the slave's readiness status (hreadyout). If the core interface holds enable high during a transaction payload, the state transitions instantly back to the address setup phase to handle continuous streaming.
2. Peripheral Slave Memory (ahb_slave_input.v)
Implements a $64 \times 32$-bit hardware memory array. It functions like a camera shutter—capturing incoming target metrics (HADDR, HWRITE) into shadow buffers (addr_reg, write_reg) on the rising clock edge only if the global bus loop is free (HREADY).
3. Top Interconnect Layer (ahb_top_input.v)
Acts as the systemic backplane routing signals between modules, establishing the critical closed feedback loop where the slave's ready output directly governs the master's state progression.

## ⏱️ Protocol Phase Mechanics

| Clock Cycle | Address Phase (Control Lines) | Data Phase (Payload Bus) |
| :---: | :--- | :--- |
| **Cycle 1** | Master drives `HADDR` & `HWRITE` for Transaction A | Bus is IDLE (or processing previous transfer) |
| **Cycle 2** | Master drives `HADDR` & `HWRITE` for Transaction B | Slave samples Transaction A address; Master drives/samples `HWDATA`/`HRDATA` for A |
| **Cycle 3** | Master drives `HADDR` & `HWRITE` for Transaction C | Slave samples Transaction B address; Master drives/samples `HWDATA`/`HRDATA` for B |
| **Cycle 4** | Bus drops to `IDLE` (or drives next address) | Slave samples Transaction C address; Master drives/samples `HWDATA`/`HRDATA` for C |


## Verification Environment & Simulation

The verification testbench (tb_input.v) applies directed stimulus by driving automated task sequences to stream distinct string payloads, subsequently reading them back to confirm total data preservation.  
Target Simulation Run:
1. Pipelined Writes: Computes and writes 32-bit words that spell out "HELL", "O_SA", and "KSHI" across addresses 0x04, 0x08, and 0x0C.
2. Streaming Reads: Issues back-to-back read commands to the target addresses to stream the data out back to the master's master_dout port.
3. Critical Skew Timing: Uses precise hold-skew delays (#1) and explicit clock gating cycles to keep pipeline stages aligned perfectly without race conditions. 

## Cadence Xcelium Compilation Flow:
The simulation can be reproduced within a Cadence environment via the command-line utilizing your log profiles:
| Step | Cadence Tool | Execution Command | Purpose & Phase Mechanics |
| :---: | :---: | :--- | :--- |
| **1** | **ncvlog** | `ncvlog -work worklib -cdslib ./cds.lib -logfile ncvlog.log -errormax 15 -update -linedebug -status ahb_master_input.v ahb_slave_input.v ahb_top_input.v tb_input.v` | **Compilation:** Parses the Verilog source design and testbench files, checks for syntax errors, and compiles them into the target working library (`worklib`). |
| **2** | **ncelab** | `ncelab -work worklib -cdslib ./cds.lib -logfile ncelab.log -errormax 15 -access +wc -status worklib.tb_input` | **Elaboration:** Builds the design hierarchy, connects the ports between the master, slave, and interconnect top layer, and creates a simulation snapshot with read/write (`+wc`) access enabled. |
| **3** | **ncsim** | `ncsim -gui -cdslib ./cds.lib -logfile ncsim.log -errormax 15 -status worklib.tb_input:module` | **Simulation:** Launches the interactive SimVision GUI graphical workspace environment to execute the testbench stimulus and analyze the pipelined waveforms. |

## Automation & Waveform Extraction (ncsim.key / nclaunch.key):
The simulation runs the following automated Tcl database commands to extract hardware wave structures into SimVision:

database -open waves -into waves.shm -default
probe -create -shm tb_input.uut.bus_haddr tb_input.uut.bus_hrdata tb_input.uut.bus_hready tb_input.uut.bus_htrans tb_input.uut.bus_hwdata tb_input.uut.bus_hwrite tb_input.uut.clk tb_input.uut.master_dout tb_input.uut.rst_n tb_input.uut.tb_addr tb_input.uut.tb_data_a tb_input.uut.tb_data_b tb_input.uut.tb_enable tb_input.uut.tb_wr
run
exit

## Repository structure
```
.
├── design/
│   ├── ahb_master_input.v   # Master pipeline FSM and ALU logic
│   ├── ahb_slave_input.v    # 64x32 Zero-wait state internal memory slave
│   └── ahb_top_input.v      # Core interconnect top module routing wires
├── testbench/
│   └── tb_input.v           # Verification testbench with pipelined task drivers
└── sim/
    ├── nclaunch.key         # Cadence Xcelium execution setup script
    ├── ncsim.key            # Waveform database and signal probe configuration
    ├── ncvlog.log           # Compiler runtime execution logs
    ├── ncelab.log           # Elaboration snapshot log file
    └── ncsim.log            # Simulator runtime log profile
```

##  Running the Project

Follow these steps to run the compilation, elaboration, and simulation within your Linux workstation containing your Cadence tools environment.

### Step 1: Clean/Prepare Your Work Directory
Ensure your local `cds.lib` file is present in your working directory and correctly maps to your target library:
```bash
echo "DEFINE worklib ./worklib" > cds.lib
mkdir -p worklib
```
### Step 2: Compile the Verilog Source Files
Run ncvlog to parse the master, slave, top interconnect, and testbench modules:
```
ncvlog -work worklib -cdslib ./cds.lib -logfile ncvlog.log -errormax 15 -update -linedebug -status ahb_master_input.v ahb_slave_input.v ahb_top_input.v tb_input.v
```
### Step 3: Elaborate the Hardware Design Hierarchy
Run ncelab to establish structural connectivity and build the simulation snapshot with read/write access database hooks enabled:
```
ncelab -work worklib -cdslib ./cds.lib -logfile ncelab.log -errormax 15 -access +wc -status worklib.tb_input
```
### Step 4: Run the Interactive Simulation
Invoke ncsim to open up the SimVision GUI window environment, load your signal probes, and run the verification sequence:
```
ncsim -gui -cdslib ./cds.lib -logfile ncsim.log -errormax 15 -status worklib.tb_input:module
```


## ---

## Verification Results & Log Analysis

### 1. Active Log Analysis & Run Benchmarks (`ncsim.log`)
* **Simulation Completion:** Fully completed via the `$finish(1)` system directive at exactly **`410 ns`** (at time step `410 NS + 0`) with zero functional runtime or synchronization errors.
* **Simulation Memory Footprint:** Lean host performance profile hitting a peak of **`317.1 MB`** (`38.6 MB` program allocation + `274.9 MB` active data arrays) during structural SHM waveform dumping operations.

### 2. Structural Netlist Analysis (`hal.design_facts` & `hal.log`)
Evaluating the elaborated design database through the **Cadence HAL Lint Analyzer** shows the specific physical parameters of the hardware layout:
* **Register Footprint:** The entire structure resolves to exactly **`2191 single-bit D Flip-Flops`**. This register utilization is dominated by the internal synchronous memory array ($64 \times 32$-bit matrix) stashed inside the peripheral slave module.
* **Clock & Reset Domains:** The structural tool verified that a single system clock tree (`tb_input.clk`) safely controls all **2191 FFs**. The asynchronous active-low system reset tree (`tb_input.uut.rst_n`) properly routes throughout the hierarchy to initialize the Master's state machine logic and the Slave's internal data registers.
* **Lint Profile:** The lint checks complete successfully. Reported warnings indicate harmless format parameters (such as `MAXLEN` indicating code lines slightly exceeding 80 characters, and standard `FFWNSR`/`NEGCLK` tool logging parameters). No functional blocking layout defects or syntax errors exist.

---

##  Engineering Analysis & Final Conclusions

### 1. Protocol Efficiency & Pipelining Mechanics
The project successfully maps out a fully compliant, high-speed **AMBA 3 AHB-Lite** single-master single-slave bus interconnect matrix. By separating the execution path into an automated Address Phase and Data Phase, the Master overlaps consecutive transactions. Because the slave requires zero wait-states (`HREADYOUT = 1`), the system achieves an ideal **CPI (Cycles Per Instruction/Transfer) of 1** during active bursting, maximizing the usable interconnect data bandwidth.

### 2. Pipelined Hardware ALU Math
Rather than streaming plain static registers, the master includes an integrated arithmetic processing unit (`data_in_a + data_in_b`). To navigate the protocol's pipelining rules—where data payload lines cannot be driven until the target address is actively acknowledged by the slave—an elegant data stashing register framework (`hwdata_buffer` and `write_phase_reg`) was built. The mathematical summation triggers safely during the **Address Phase**, registers smoothly, and commits onto the physical `HWDATA` lines during the subsequent **Data Phase**, separating arithmetic logic computation delays from protocol handshake constraints.

### 3. Hazard Mitigation via Shadow Buffering
To prevent critical bus contention and pipeline data overwrites, the peripheral memory slave features an exceptional synchronous snapshot buffer system (`addr_reg`, `write_reg`). The slave samples incoming metrics from the moving address lines **only** if the bus ready feedback loop is open (`HREADY == 1`). This completely isolates the underlying memory write path from moving master bus states mid-transfer, securing data preservation.

### 4. Summary Takeaway
The successful lint profiles under Cadence HAL and zero-error simulation completion at **410 ns** confirm that the hardware system is structurally sound, protocol-compliant, and fully verified. It reflects industrial-grade fluency with standard EDA environments (**ncvlog**, **ncelab**, **ncsim**, **HAL**, and **SimVision** SHM database tracking).

<img width="1920" height="1080" alt="Screenshot from 2026-06-04 11-58-55" src="https://github.com/user-attachments/assets/088cdebb-1bbb-4c03-9276-67adf4b8e735" />
