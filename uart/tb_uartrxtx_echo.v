`timescale 1ns / 1ps
`define CLK_PERIOD 10 //10ns
`define BAUD_MULT 10416 //10416 clks = 1 bit
module tb_uartrxtx_echo;

	// Inputs
	reg clk;
	reg nrst;
	reg rx;
  wire tx;

	// Outputs
	wire [7:0] dout;

	// Instantiate the Unit Under Test (UUT)
	uartrxtx_echo uut (
		.clk(clk), 
		.nrst(nrst), 
		.rx(rx),
    .tx(tx)
	);
  
  always begin
    #(`CLK_PERIOD/2) clk = ~clk;
  end

	initial begin
		// Initialize Inputs
		clk = 0;
		nrst = 0;
		rx = 1'b1;

		// Wait 100 ns for global reset to finish
		#(`CLK_PERIOD*10);
    nrst = 1'b1;
    #(`CLK_PERIOD*10);
        
		// Add stimulus here
    #(`CLK_PERIOD * (`BAUD_MULT/2));
    #(`CLK_PERIOD * 5 * `BAUD_MULT);
    // Start bit
    rx = 0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 0
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 1
    rx = 0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 2
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 3
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 4
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 5
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 6
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 7
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // Stop bit
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    
    // delay between test cases
    #(`CLK_PERIOD * `BAUD_MULT * 20);
    
    // Start bit
    rx = 0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 0
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 1
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 2
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 3
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 4
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 5
    rx = 1'b0;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 6
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // bit 7
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);
    // Stop bit
    rx = 1'b1;
    #(`CLK_PERIOD * `BAUD_MULT);

    #(`CLK_PERIOD * 10);
	end
      
endmodule

