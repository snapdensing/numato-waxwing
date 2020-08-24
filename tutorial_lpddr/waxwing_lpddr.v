`timescale 1ns/1ps
module waxwing_lpddr(
   input         clk_in,
   input         reset,
   inout  [15:0] mcb3_dram_dq,
   output [12:0] mcb3_dram_a,
   output [1:0]  mcb3_dram_ba,
   output        mcb3_dram_ras_n,
   output        mcb3_dram_cas_n,
   output        mcb3_dram_we_n,
   output        mcb3_dram_cke,
   output        mcb3_dram_dm,
   inout         mcb3_dram_udqs,
   inout         mcb3_rzq,
   output        mcb3_dram_udm,
   inout         mcb3_dram_dqs,
   output        mcb3_dram_ck,
   output        mcb3_dram_ck_n,
   output        led_calib,
   output  reg   led_pass,
   output  reg   led_fail
   );
 
 wire                c3_clk0;
 wire                c3_rst0;
 // Command Signals
 wire                c3_p0_cmd_clk;
 reg                 c3_p0_cmd_en;
 reg    [2:0]        c3_p0_cmd_instr;
 reg    [5:0]        c3_p0_cmd_bl;
 reg    [29:0]       c3_p0_cmd_byte_addr;
 wire                c3_p0_cmd_empty;
 wire                c3_p0_cmd_full;
 // Write Signals
 wire                c3_p0_wr_clk;
 reg                 c3_p0_wr_en;
 wire   [15:0]       c3_p0_wr_mask;
 reg    [127:0]      c3_p0_wr_data;
 wire                c3_p0_wr_full;
 wire                c3_p0_wr_empty;
 wire   [6:0]        c3_p0_wr_count;
 wire                c3_p0_wr_underrun;
 wire                c3_p0_wr_error;
 // Read Signals
 wire                c3_p0_rd_clk;
 reg                 c3_p0_rd_en;
 wire   [127:0]      c3_p0_rd_data;
 wire                c3_p0_rd_full;
 wire                c3_p0_rd_empty;
 wire   [6:0]        c3_p0_rd_count;
 wire                c3_p0_rd_overflow;
 wire                c3_p0_rd_error;
 
 reg  [2:0]  state;
 reg  [127:0]data_read_from_memory = 128'd0;
 wire [127:0]data_to_write = {32'hcafebabe, 32'h12345678,
                              32'hAA55AA55, 32'h55AA55AA};
 
assign c3_p0_cmd_clk = c3_clk0;
assign c3_p0_wr_clk  = c3_clk0; 
assign c3_p0_rd_clk  = c3_clk0; 
 
// Instantiation of memory
 mem u_mem (
   .c3_sys_clk         (clk_in),
   .c3_sys_rst_n       (reset),

   .mcb3_dram_dq       (mcb3_dram_dq), 
   .mcb3_dram_a        (mcb3_dram_a), 
   .mcb3_dram_ba       (mcb3_dram_ba),
   .mcb3_dram_ras_n    (mcb3_dram_ras_n), 
   .mcb3_dram_cas_n    (mcb3_dram_cas_n), 
   .mcb3_dram_we_n     (mcb3_dram_we_n), 
   .mcb3_dram_cke      (mcb3_dram_cke), 
   .mcb3_dram_ck       (mcb3_dram_ck), 
   .mcb3_dram_ck_n     (mcb3_dram_ck_n), 
   .mcb3_dram_dqs      (mcb3_dram_dqs), 
   .mcb3_dram_udqs     (mcb3_dram_udqs), // for X16 parts 
   .mcb3_dram_udm      (mcb3_dram_udm), // for X16 parts
   .mcb3_dram_dm       (mcb3_dram_dm),
   .c3_clk0            (c3_clk0),
   .c3_rst0            (c3_rst0),
   .c3_calib_done      (led_calib),
   .mcb3_rzq           (mcb3_rzq), 
   .c3_p0_cmd_clk      (c3_p0_cmd_clk),
   .c3_p0_cmd_en       (c3_p0_cmd_en),
   .c3_p0_cmd_instr    (c3_p0_cmd_instr),
   .c3_p0_cmd_bl       (c3_p0_cmd_bl),
   .c3_p0_cmd_byte_addr(c3_p0_cmd_byte_addr),
   .c3_p0_cmd_empty    (c3_p0_cmd_empty),
   .c3_p0_cmd_full     (c3_p0_cmd_full),
   .c3_p0_wr_clk       (c3_p0_wr_clk),
   .c3_p0_wr_en        (c3_p0_wr_en),
   .c3_p0_wr_mask      (c3_p0_wr_mask),
   .c3_p0_wr_data      (c3_p0_wr_data),
   .c3_p0_wr_full      (c3_p0_wr_full),
   .c3_p0_wr_empty     (c3_p0_wr_empty),
   .c3_p0_wr_count     (c3_p0_wr_count), 
   .c3_p0_wr_underrun  (c3_p0_wr_underrun),
   .c3_p0_wr_error     (c3_p0_wr_error),
   .c3_p0_rd_clk       (c3_p0_rd_clk),
   .c3_p0_rd_en        (c3_p0_rd_en),
   .c3_p0_rd_data      (c3_p0_rd_data),
   .c3_p0_rd_full      (c3_p0_rd_full),
   .c3_p0_rd_empty     (c3_p0_rd_empty),
   .c3_p0_rd_count     (c3_p0_rd_count), 
   .c3_p0_rd_overflow  (c3_p0_rd_overflow),
   .c3_p0_rd_error     (c3_p0_rd_error)
   );

localparam IDLE    = 3'h0,
           WR_CMD  = 3'h1,
           WRITE   = 3'h2,
           RD_CMD  = 3'h3,
           READ    = 3'h4,
           PARK    = 3'h5; 
assign c3_p0_wr_mask = 16'h0000;
//****************** State Machine start here ****************************//
always@(posedge c3_clk0)
begin
   if(c3_rst0) begin
      c3_p0_cmd_byte_addr <= 0;
      c3_p0_cmd_bl    <= 1; 
      state           <= IDLE;
      c3_p0_cmd_instr <= 3'b000;
      c3_p0_cmd_en    <= 1'b0;
      c3_p0_wr_en     <= 1'b0;
      c3_p0_rd_en     <= 1'b0;
      led_pass        <= 1'b0;
      led_fail        <= 1'b0;
   end
   else begin
      case(state)
         IDLE : begin
           if(led_calib) begin
              state <= WR_CMD;
           end
         end
 
         WR_CMD : begin
            if(~c3_p0_cmd_full) begin
               c3_p0_cmd_byte_addr <= 0;
               c3_p0_cmd_bl    <= 1;
               c3_p0_cmd_instr <= 3'b000;
               c3_p0_cmd_en    <= 1'b1;
               state           <= WRITE;
            end
         end
 
         WRITE : begin
            c3_p0_cmd_en     <= 1'b0; 
            if(~c3_p0_wr_full) begin
               c3_p0_wr_en   <= 1'b1;
               c3_p0_wr_data <= data_to_write;
               state         <= RD_CMD;
            end
         end


         RD_CMD : begin
            if(~c3_p0_cmd_full) begin
               c3_p0_wr_en         <= 1'b0;
               c3_p0_cmd_byte_addr <= 0;
               c3_p0_cmd_bl        <= 1;
               c3_p0_cmd_instr     <= 3'b001;
               c3_p0_cmd_en        <= 1'b1; 
               state               <= READ;
            end
         end
 
         READ : begin
            c3_p0_cmd_en   <= 1'b0;
            if(~c3_p0_rd_empty) begin
               c3_p0_rd_en <= 1'b1;
               data_read_from_memory <= c3_p0_rd_data;
               state       <= PARK;
            end
         end
 
         PARK : begin
            c3_p0_rd_en <= 1'b0;
            if (data_to_write == data_read_from_memory) begin
               led_pass <= 1;
           end else if (data_to_write != data_read_from_memory) begin
               led_fail <= 1;
           end
        end
 
        default: state <= IDLE;
      endcase
   end
end
 
endmodule