`default_nettype none
`timescale 1 ps / 1 ps

module TEST_BITSTREAM #(
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

reg [5-1:0]   ilength = 0;
reg [16-1:0]  idata   = 0;
initial begin
  $display("start");
  @(negedge rst);
  repeat(20) @(posedge clk);
  @(posedge clk); ilength <= 16;  idata <= 16'h1010;
  @(posedge clk); ilength <= 0;
  @(posedge clk);
  @(posedge clk); ilength <= 16;  idata <= 16'h2020;
  @(posedge clk); ilength <= 16;  idata <= 16'h3030;
  @(posedge clk); ilength <= 0;
  @(posedge clk);
  @(posedge clk); ilength <= 8;   idata <= 16'hff40;
  @(posedge clk); ilength <= 8;   idata <= 16'hff50;
  @(posedge clk); ilength <= 8;   idata <= 16'hff60;
  @(posedge clk); ilength <= 8;   idata <= 16'hff70;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 1;   idata <= 16'h0000;
  @(posedge clk); ilength <= 7;   idata <= 16'hffff;
  @(posedge clk); ilength <= 2;   idata <= 16'h0000;
  @(posedge clk); ilength <= 6;   idata <= 16'hffff;
  @(posedge clk); ilength <= 3;   idata <= 16'h0000;
  @(posedge clk); ilength <= 5;   idata <= 16'hffff;
  @(posedge clk); ilength <= 4;   idata <= 16'h0000;
  @(posedge clk); ilength <= 4;   idata <= 16'hffff;
  @(posedge clk); ilength <= 5;   idata <= 16'h0000;
  @(posedge clk); ilength <= 3;   idata <= 16'hffff;
  @(posedge clk); ilength <= 6;   idata <= 16'h0000;
  @(posedge clk); ilength <= 2;   idata <= 16'hffff;
  @(posedge clk); ilength <= 7;   idata <= 16'h0000;
  @(posedge clk); ilength <= 1;   idata <= 16'hffff;
  @(posedge clk); ilength <= 8;   idata <= 16'h0000;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 16'h8080;
  @(posedge clk); ilength <= 8;   idata <= 16'h0090;
  @(posedge clk); ilength <= 16;  idata <= 16'ha0a0;
  @(posedge clk); ilength <= 16;  idata <= 16'hb0b0;
  @(posedge clk); ilength <= 8;   idata <= 16'h00c0;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 3;   idata <= 16'hfff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 16'hfff2;  // 8bit
  @(posedge clk); ilength <= 2;   idata <= 16'hfff2;  // 10101010
  @(posedge clk); ilength <= 3;   idata <= 16'hfff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 16'hfff2;  // 9bit
  @(posedge clk); ilength <= 3;   idata <= 16'hfff5;  // 10101010 1
  @(posedge clk); ilength <= 2;   idata <= 16'hfff1;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 16'hfff2;  // 7bit
  @(posedge clk); ilength <= 2;   idata <= 16'hfff2;  // 0101010
  @(posedge clk); ilength <= 3;   idata <= 16'hfff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 16'hfff2;  // 8bit
  @(posedge clk); ilength <= 2;   idata <= 16'hfff2;  // 10101010
  @(posedge clk); ilength <= 8;   idata <= 16'h00d0;
  @(posedge clk); ilength <= 8;   idata <= 16'h00e0;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 3;   idata <= 16'hfff0;  // 3bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 16'hffff;  // byte alignment
  @(posedge clk); ilength <= 3;   idata <= 16'hfff0;  // 3bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 16'hffff;  // byte alignment
  @(posedge clk); ilength <= 16;  idata <= 16'hff00;  // 16bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 16'hf0f0;  // no byte alignment
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 16'h0505;
  @(posedge clk); ilength <= 0;
  repeat(10) @(posedge clk);
  $display("end");
  $finish();
end

wire          ovalid;
wire[16-1:0]  odata;
wire[5-1:0]   acclen;
wire[3-1:0]   rest;
BITSTREAM bs (
  .clk(clk),
  .rst(rst),
  .ilength(ilength),  // 0 <= ilength <= 16
  .idata(idata),
  .rest(rest),
  .ovalid(ovalid),
  .odata(odata)
);

always @(posedge clk) begin
  if(ovalid) $display("out: %x", odata);
end

endmodule
