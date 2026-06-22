`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 21:32:14
// Design Name: 
// Module Name: ahb_slave_input
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


module ahb_slave_input (
// Global Infrastructure Signals
    input  wire        HCLK,
    input  wire        HRESETn,
    
 // AHB Bus Inputs (Driven by the Master) 
   input  wire [31:0] HADDR,             // Address lines from the master
    input  wire [1:0]  HTRANS,            // Transfer type (IDLE, NONSEQ, etc.)
    input  wire        HWRITE,            // 1 = Master wants to write, 0 = Master wants to read
    input  wire        HREADY,            // Global bus ready status (feedback loop input)
    input  wire [31:0] HWDATA,            // The actual write data payload from the master

    // AHB Bus Outputs (What our slave drives back to the master)
    output reg  [31:0] HRDATA,            // Read data bus driven back to master during a Read
    output wire        HREADYOUT,         // 1 = Slave is done; 0 = Slave needs more time (Wait State)
    output wire        HRESP              // 0 = OKAY response, 1 = ERROR response
);

    localparam NONSEQ = 2'b10;

    reg [31:0] memory [0:63];  //memory array

  // THE SHADOW REGISTERS (The Memory Buffer)
    reg [5:0]  addr_reg;          // Stores the captured address for the data phase
    reg        write_reg;         // Stores whether it's a write or read for the data phase
    reg        data_phase_active; // Flag: 1 means "we are currently in a valid data phase cycle"


// address phase capture block
               //This block acts like a camera shutter. On the rising edge of the clock, if the bus is active, it takes a snapshot of what the master is requesting and saves it into the shadow registers.
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg          <= 6'b0;
            write_reg         <= 1'b0;
            data_phase_active <= 1'b0;
        end
        else if (HREADY) begin   //ONLLY samples if bus is ready
          //check if master is initiating a real transaction
            if (HTRANS == NONSEQ) begin
                addr_reg          <= HADDR[7:2];
                write_reg         <= HWRITE;
                data_phase_active <= 1'b1;   // Arm the data phase for the next cycle
            end else begin
                data_phase_active <= 1'b0;  // Master is IDLE, turn off data phase
            end
        end
    end

    
    // data phase execution block (write path)
    always @(posedge HCLK) begin
        if (data_phase_active && write_reg) begin
            memory[addr_reg] <= HWDATA;
        end
    end

  //The Read Path & Constant Outputs (Combinational)
    always @(*) begin
        // If we are in a valid data phase and it's a READ transaction
        if (data_phase_active && !write_reg)  
            HRDATA = memory[addr_reg];  // Instantly drive the data back onto the read bus
        else
            HRDATA = 32'b0;  // Keep the read bus clean when not reading
    end


// Bus Status Drivers
    assign HREADYOUT = 1'b1;  //  a zero-wait-state slave, always ready!
    assign HRESP     = 1'b0;  // Send back an OKAY response status code to the master

endmodule
