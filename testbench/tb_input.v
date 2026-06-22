`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 21:33:48
// Design Name: 
// Module Name: tb_input
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


module tb_input;

   //  Virtual Stimulus Registers
    reg         clk;
    reg         rst_n;
    reg         tb_enable;
    reg  [31:0] tb_data_a;
    reg  [31:0] tb_data_b;
    reg         tb_wr;
    reg  [31:0] tb_addr;
    
  //  Output Wires
    wire [31:0] master_dout;

    ahb_top_input uut (
        .clk(clk),
        .rst_n(rst_n),
        .tb_enable(tb_enable),
        .tb_data_a(tb_data_a),
        .tb_data_b(tb_data_b),
        .tb_wr(tb_wr),
        .tb_addr(tb_addr),
        .master_dout(master_dout)
    );

    always #10 clk = ~clk;

    // Driver tasks
    task ahb_write(input [31:0] address, input [31:0] data_part1, input [31:0] data_part2);
        begin
           
            tb_enable = 1'b1;
            tb_wr     = 1'b1;   //write mode
            tb_addr   = address;
            tb_data_a = data_part1;
            tb_data_b = data_part2; 
             @(posedge clk);  //hold everything stable until exact clock edge hits
            #1;    //hold skew delay
        end
    endtask

    task ahb_read(input [31:0] address);
        begin
            
            tb_enable = 1'b1;
            tb_wr     = 1'b0;  //read mode
            tb_addr   = address;
            @(posedge clk);  //hold stable until clock edge hits
            #1;
        end
    endtask

    initial begin
        clk       = 0;
        rst_n     = 0;
        tb_enable = 0;
        tb_data_a = 0;
        tb_data_b = 0;
        tb_wr     = 0;
        tb_addr   = 0;

        repeat(2) @(posedge clk);
        #1; rst_n = 1;
        repeat(1) @(posedge clk);

        // --- WRITE PHASE -------------------------------------------------
        // Address 0x04 gets: 0x40000000 + 0x08454C4C = 0x48454C4C ("HELL")
        ahb_write(32'h0000_0004, 32'h4000_0000, 32'h0845_4C4C);
      
        
        // Address 0x08 gets: 0x40000000 + 0x0F5F5341 = 0x4F5F5341 ("O_SA")
        ahb_write(32'h0000_0008, 32'h4000_0000, 32'h0F5F5341);
        
        
        // Address 0x0C gets: 0x40000000 + 0x0B534849 = 0x4B534849 ("KSHI")
        ahb_write(32'h0000_000C, 32'h4000_0000, 32'h0B534849);


        // --- THE CRITICAL FIX ---
        // Wait 1 extra clock cycle HERE while tb_enable is still HIGH.
        // This gives the master FSM time to sample 0x0C and drive it onto bus_haddr!
        @(posedge clk); 
        #1;

        // Now it is safe to turn off streaming
        tb_enable = 1'b0;
        tb_wr     = 1'b0;
        repeat(5) @(posedge clk); // Let the bus settle in IDLE
        

        // --- READ PHASE ------------------------------------------------
        ahb_read(32'h0000_0004); // Expect "HELL" back on bus
        ahb_read(32'h0000_0008); // Expect "O_SA" back on bus
        ahb_read(32'h0000_000C); // Expect "KSHI" back on bus

        // --- THE CRITICAL FIX ---
        // Wait 1 extra clock cycle here so the master can sample the 0x0C read address
        @(posedge clk);
        #1;
        
        tb_enable = 1'b0;
        
        // Give the pipeline 3-4 cycles to let the data return from the slave
        repeat(5) @(posedge clk); 
        $finish;
    end

endmodule

