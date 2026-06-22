`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 21:31:20
// Design Name: 
// Module Name: ahb_master_input
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


module ahb_master_input (
//global infrastyructure signals
    input  wire        hclk,
    input  wire        hresetn,

//core interface( inputs driving the master)    
    input  wire        enable,
    input  wire [31:0] data_in_a,
    input  wire [31:0] data_in_b,
    input  wire        wr,
    input  wire [31:0] target_addr, //The memory address we want to target

//AHB bus retun inputs( feedback from slaves)  
    input  wire        hreadyout, // 1 = Slave is done with the previous cycle; 0 = Slave is freezing the bus
    input  wire        hresp,
    input  wire [31:0] hrdata, // Data bus driven by the slave during a Read

//AHB bus output ports ( what master drives onto the bus)    
    output reg  [31:0] haddr,
    output reg         hwrite,
    output reg  [1:0]  htrans,
    output reg         hready, // Master ready signal (tied high)
    output reg  [31:0] hwdata,
    output reg  [31:0] dout   // Output where we store read data for the system
);

    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;

    reg [1:0] current_state, next_state;
    localparam STATE_IDLE = 2'b00,
               STATE_ADDR = 2'b01,
               STATE_DATA = 2'b10;

    reg [31:0] hwdata_buffer;
    reg        write_phase_reg;

    // FSM State Transition (sequential block)
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn)
            current_state <= STATE_IDLE;
        else if (hreadyout)  //CRITICAL - if (hreadyout) matters: If a slave is slow and pulls hreadyout low, the master
            current_state <= next_state;
    end

    // FSM Next State Evaluation (combinational block)
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (enable) next_state = STATE_ADDR;
            end
            STATE_ADDR: begin
                next_state = STATE_DATA;  //ove to data phase immediately
            end
            STATE_DATA: begin
                if (enable) next_state = STATE_ADDR;  //back to streaming ----. If enable is still high, it jumps straight back to STATE_ADDR. This allows the master to stream transactions back-to-back every single clock cycle without dropping into an idle state.
                else        next_state = STATE_IDLE;  // go abck to rest
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Address Phase Generation Module (bus commands)
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            haddr           <= 32'b0;
            hwrite          <= 1'b0;
            htrans          <= IDLE;
            hready          <= 1'b1;
            write_phase_reg <= 1'b0;
            hwdata_buffer   <= 32'b0;
        end 
        else if (hreadyout) begin
            if (next_state == STATE_ADDR) begin
                haddr           <= target_addr;
                hwrite          <= wr;
                htrans          <= NONSEQ;
                //internal pipleline saves
                write_phase_reg <= wr; 
                hwdata_buffer   <= data_in_a + data_in_b; // Pipelined math logic
            end else begin
                htrans          <= IDLE;
                write_phase_reg <= 1'b0;
            end
        end
    end

    // Data Phase Execution Module (bus payload)   
                         //This block runs in parallel and manages the Data Phase. It uses the pipeline registers we stashed during the Address Phase block.
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            hwdata <= 32'b0;
            dout   <= 32'b0;
        end
        else if (hreadyout) begin
        // CASE A: It's a Write Data Phase
            if (write_phase_reg) begin
                hwdata <= hwdata_buffer;
            end
        // CASE B: It's a Read Data Phase
            else if (current_state == STATE_DATA && !write_phase_reg) begin
                dout   <= hrdata; 
            end
        end
    end

endmodule
