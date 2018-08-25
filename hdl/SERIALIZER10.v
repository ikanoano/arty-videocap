`default_nettype none
`timescale 1ps/1ps

// Serialize 10bit to 1bit using OSERDESE2
module SERIALIZER10 (
  input   wire          clk_parallel_sdr,
  input   wire          clk_serial_ddr,
  input   wire          rst,  // Deassert should be synced to clk_parallel_sdr
  input   wire[10-1:0]  parallel_in,
  output  wire          serial_out  // LSB first
);

wire  shift[0:1];

OSERDESE2 #(
  .DATA_RATE_OQ("DDR"),
  .DATA_RATE_TQ("SDR"),
  .DATA_WIDTH(10),
  .TRISTATE_WIDTH(1),
  .SERDES_MODE("MASTER")
) masterdese (
  .OQ(serial_out),
  .SHIFTIN1(shift[0]),
  .SHIFTIN2(shift[1]),
  .CLK(clk_serial_ddr),
  .CLKDIV(clk_parallel_sdr),
  .TCE(1'b0),
  .OCE(1'b1),
  .RST(rst),
  .D1(parallel_in[0]),  // D1 send first
  .D2(parallel_in[1]),
  .D3(parallel_in[2]),
  .D4(parallel_in[3]),
  .D5(parallel_in[4]),
  .D6(parallel_in[5]),
  .D7(parallel_in[6]),
  .D8(parallel_in[7])
);

OSERDESE2 #(
  .DATA_RATE_OQ("DDR"),
  .DATA_RATE_TQ("SDR"),
  .DATA_WIDTH(10),
  .TRISTATE_WIDTH(1),
  .SERDES_MODE("SLAVE")
) slavedese (
  .SHIFTOUT1(shift[0]),
  .SHIFTOUT2(shift[1]),
  .CLK(clk_serial_ddr),
  .CLKDIV(clk_parallel_sdr),
  .TCE(1'b0),
  .OCE(1'b1),
  .RST(rst),
  .D3(parallel_in[8]),
  .D4(parallel_in[9])
);

endmodule
