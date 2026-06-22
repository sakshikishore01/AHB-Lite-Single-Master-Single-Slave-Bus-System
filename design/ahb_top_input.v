`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 21:33:03
// Design Name: 
// Module Name: ahb_top_input
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ahb_top_input (
    input wire        clk,
    input wire        rst_n,
    
   // Control Interface Inputs (Passed directly down to the Master) 
    input wire        tb_enable,
    input wire [31:0] tb_data_a,
    input wire [31:0] tb_data_b,
    input wire        tb_wr,
    input wire [31:0] tb_addr,
    
    // System Output (Captured from the Master's read channel)
    output wire [31:0] master_dout
);


//The Interconnect Wires (The Bus Channel)
    wire [31:0] bus_haddr;   // Carries the target memory address from Master to Slave
    wire        bus_hwrite;  // Carries the Write/Read command from Master to Slave
    wire [1:0]  bus_htrans;  // Carries the Transfer Type (IDLE/NONSEQ) from Master to Slave
    wire [31:0] bus_hwdata;  // Carries the Write Data payload from Master to Slave
    
    wire        bus_hready;  // Feedback loop: Slave's HREADYOUT goes back into Master
    wire [31:0] bus_hrdata;  // Carries the Read Data payload from Slave back to Master

    ahb_master_input master_inst (
      // Infrastructure Connections
        .hclk        (clk),
        .hresetn     (rst_n),
        
    // Fed by Testbench stimuli
        .enable      (tb_enable),
        .data_in_a   (tb_data_a),
        .data_in_b   (tb_data_b),
        .wr          (tb_wr),
        .target_addr (tb_addr),
        
     // Input Listening Ports (Listens to the response from the Slave)
        .hreadyout   (bus_hready),
        .hrdata      (bus_hrdata),
        
      // Output Driving Ports (Pushes signals OUT onto the internal bus wires)
        .haddr       (bus_haddr),
        .hwrite      (bus_hwrite),
        .htrans      (bus_htrans),
        .hwdata      (bus_hwdata),
    
    // Tied or Unused Ports for this simple loop    
        .hresp       (1'b0),  //tied to o (okay)
        .hready      (),      // left open/unconnected
        .dout        (master_dout) //routed back to the top level output
    );

    ahb_slave_input slave_inst (
    // Infrastructure Connections
        .HCLK      (clk),
        .HRESETn   (rst_n),
        
        // Input Listening Ports (Receiving commands FROM the Master)
        .HADDR     (bus_haddr),  // Connects to the same address wire driven by master
        .HTRANS    (bus_htrans), // Connects to the same transfer type wire
        .HWRITE    (bus_hwrite), // Connects to the same write control wire
        .HWDATA    (bus_hwdata), // Connects to the same write data wire
        .HREADY    (bus_hready), // Tracks the global readiness status
        
        // Output Driving Ports (Pushing data/status BACK to the Master)
        .HRDATA    (bus_hrdata),  // Puts read data onto the return wire
        .HREADYOUT (bus_hready),  // Puts ready status onto the feedback wire
        .HRESP     ()             // Left open/unconnected
    );

endmodule

