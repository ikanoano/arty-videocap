`default_nettype none
`timescale 1 ps / 1 ps

module TEST_RGB2YCBCR #(
  parameter PERIOD=1000
) (
);

reg clk = 0;
initial begin
  clk = #PERIOD 1;
  forever clk = #(PERIOD/2) ~clk;
end

reg rst = 0;
initial begin
  @(posedge clk);
  rst <= 1;
  repeat(5) @(posedge clk);
  rst <= 0;
end

reg [8-1:0] R, G, B;
wire[8-1:0] Y, Cb, Cr;

initial begin
  $display("start");
  repeat(10) @(posedge clk);
  {R, G, B} <= {8'd000, 8'd000, 8'd000};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd000, 8'd000};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd000, 8'd255, 8'd000};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd000, 8'd000, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd255, 8'd000};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd000, 8'd255, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd000, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd255, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd000, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  {R, G, B} <= {8'd255, 8'd000, 8'd255};
  repeat(10) @(posedge clk);
  $display("{R,G,B}={%d,%d,%d} -> {Y,Cb,Cr}={%d,%d,%d}",R,G,B,Y,Cb,Cr);

  $display("end");
  $finish();
end

RGB2YCBCR cnv_color (
  clk,

  {1'b0, R},
  {1'b0, G},
  {1'b0, B},

  Y,
  Cb,
  Cr
);

endmodule
`default_nettype wire

