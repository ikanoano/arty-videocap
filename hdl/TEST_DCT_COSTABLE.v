`default_nettype none
`timescale 1 ps / 1 ps

module TEST_DCT_COSTABLE #(
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

reg [4-1:0] r;
reg [4-1:0] c;
wire[8-1:0] o;

DCT_COSTABLE #(26, 7) dc (
  r[0+:3],
  c[0+:3],
  o
);

initial begin
  $display("start");
  for (r = 0; r < 8; r = r + 1)
  for (c = 0; c < 8; c = c + 1) begin
    @(posedge clk)
    $display("r=%d, c=%d, o=%d", r, c, o);
  end
  repeat(10) @(posedge clk);
  $display("end");
  $finish();
end

endmodule
`default_nettype wire

