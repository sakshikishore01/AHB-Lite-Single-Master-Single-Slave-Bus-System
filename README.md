# AHB-Lite-Single-Master-Single-Slave-Bus-System
A synthesizable, pipelined AHB-Lite (AMBA 3) compliant bus infrastructure containing a single Master, a Zero-Wait-State Slave, and a Top-level interconnect interconnecting them. This project was developed, simulated, and verified using the Cadence Xcelium enterprise simulator environment.

##  Project Overview
A synthesizable, fully pipelined AMBA AHB-Lite (1 Master, 1 Slave) bus infrastructure developed, simulated, and verified within the Cadence Xcelium enterprise environment. This project showcases the high-throughput, dual-phase nature of the AHB protocol by overlapping the Address and Data phases to achieve continuous, cycle-by-cycle memory transactions.  Key FeaturesPipelined Architecture: Separates and overlaps the Address Phase and Data Phase for maximum bus utilization.  High-Throughput Streaming: The Master FSM bypasses idle states to stream back-to-back operations dynamically when enabled.  Integrated Hardware Math: The Master includes internal pipeline execution logic ($data\_in\_a + data\_in\_b$) stashed during the Address phase and committed during the Data phase.  Zero-Wait-State Slave: Memory reads and writes execute instantly (HREADYOUT = 1) without stalling the bus channel.  ## 🏗️ Architecture & Module BreakdownThe design is modularized across three primary Verilog hardware files:1. Master Logic (ahb_master_input.v)Driven by an internal Finite State Machine (STATE_IDLE, STATE_ADDR, STATE_DATA) that reacts dynamically to the slave's readiness status (hreadyout). If the core interface holds enable high during a transaction payload, the state transitions instantly back to the address setup phase to handle continuous streaming.  2. Peripheral Slave Memory (ahb_slave_input.v)Implements a $64 \times 32$-bit hardware memory array. It functions like a camera shutter—capturing incoming target metrics (HADDR, HWRITE) into shadow buffers (addr_reg, write_reg) on the rising clock edge only if the global bus loop is free (HREADY).  3. Top Interconnect Layer (ahb_top_input.v)Acts as the systemic backplane routing signals between modules, establishing the critical closed feedback loop where the slave's ready output directly governs the master's state progression.  ## ⏱️ Protocol Phase MechanicsBecause AHB uses a pipelined structure, transactions are split across consecutive cycles:CycleAddress Phase (Control Lines)Data Phase (Payload Bus)Cycle $N$Master drives HADDR & HWRITE  Previous transaction's data payload is transferred.  Cycle $N+1$Slave samples HADDR into shadow registers.  Master drives/samples HWDATA/HRDATA for transaction $N$.  ## 🛠️ Verification Environment & SimulationThe verification testbench (tb_input.v) applies directed stimulus by driving automated task sequences to stream distinct string payloads, subsequently reading them back to confirm total data preservation.  Target Simulation Run:Pipelined Writes: Computes and writes 32-bit words that spell out "HELL", "O_SA", and "KSHI" across addresses 0x04, 0x08, and 0x0C.  Streaming Reads: Issues back-to-back read commands to the target addresses to stream the data out back to the master's master_dout port.  Critical Skew Timing: Uses precise hold-skew delays (#1) and explicit clock gating cycles to keep pipeline stages aligned perfectly without race conditions.  Cadence Xcelium Compilation Flow:The simulation can be reproduced within a Cadence environment via the command-line utilizing your log profiles:  Bash# 1. Compile the Verilog Source files
ncvlog -work worklib -cdslib /home/nielit/sakshi_project/ahb/cds.lib -logfile ncvlog.log -errormax 15 -update -linedebug -status ahb_master_input.v ahb_slave_input.v ahb_top_input.v tb_input.v

# 2. Elaborate the design snapshot with read/write database access allowed
ncelab -work worklib -cdslib /home/nielit/sakshi_project/ahb/cds.lib -logfile ncelab.log -errormax 15 -access +wc -status worklib.tb_input

# 3. Invoke interactive GUI simulation 
ncsim -gui -cdslib /home/nielit/sakshi_project/ahb/cds.lib -logfile ncsim.log -errormax 15 -status worklib.tb_input:module
Automation & Waveform Extraction (ncsim.key / nclaunch.key):The simulation runs the following automated Tcl database commands to extract hardware wave structures into SimVision:  Tcldatabase -open waves -into waves.shm -default
probe -create -shm tb_input.uut.bus_haddr tb_input.uut.bus_hrdata tb_input.uut.bus_hready tb_input.uut.bus_htrans tb_input.uut.bus_hwdata tb_input.uut.bus_hwrite tb_input.uut.clk tb_input.uut.master_dout tb_input.uut.rst_n tb_input.uut.tb_addr tb_input.uut.tb_data_a tb_input.uut.tb_data_b tb_input.uut.tb_enable tb_input.uut.tb_wr
run
exit
The simulation completes cleanly via $finish at 410 ns without errors.  ## 📁 Repository StructurePlaintext├── design/
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
## 🚀 Running the ProjectClone this repository onto your Linux workstation containing Cadence tools.Confirm your environment variables point to your local Xcelium installation.Make sure your local cds.lib maps correctly to worklib.  Run the commands listed in the Verification Environment section to launch SimVision and view your pipelined waveforms!
