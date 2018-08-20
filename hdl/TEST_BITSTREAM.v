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

reg [6-1:0]   ilength = 0;
reg [32-1:0]  idata   = 0;
initial begin
  $display("start");
  @(negedge rst);
  repeat(20) @(posedge clk);
  @(posedge clk); ilength <= 32;  idata <= 32'h10101010;
  @(posedge clk); ilength <= 0;
  @(posedge clk);
  @(posedge clk); ilength <= 32;  idata <= 32'h20202020;
  @(posedge clk); ilength <= 32;  idata <= 32'h30303030;
  @(posedge clk); ilength <= 0;
  @(posedge clk);
  @(posedge clk); ilength <= 16;  idata <= 32'hffff4040;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff5050;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff6060;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff7070;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 1;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 7;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 2;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 6;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 3;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 5;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 4;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 4;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 5;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 3;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 6;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 2;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 7;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 1;   idata <= 32'hffffffff;
  @(posedge clk); ilength <= 8;   idata <= 32'hffff0000;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff8080;
  @(posedge clk); ilength <= 8;   idata <= 32'hffff0090;
  @(posedge clk); ilength <= 16;  idata <= 32'hffffa0a0;
  @(posedge clk); ilength <= 16;  idata <= 32'hffffb0b0;
  @(posedge clk); ilength <= 8;   idata <= 32'hffff00c0;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 32'hffffa0a0;  // 16bit
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 8bit
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff2;  // 10101010
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 9bit
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 10101010 1
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff1;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 7bit
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff2;  // 0101010

  @(posedge clk); ilength <= 8;   idata <= 32'hffffffa0;  // 8bit
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 8bit
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff2;  // 10101010
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 9bit
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff5;  // 10101010 1
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff1;  // 0xAA
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff2;  // 7bit
  @(posedge clk); ilength <= 2;   idata <= 32'hfffffff2;  // 0101010
  @(posedge clk); ilength <= 16;  idata <= 32'hffffd0d0;
  @(posedge clk); ilength <= 8;   idata <= 32'hffff00e0;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff0;  // 3bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 32'hffffffff;  // byte alignment
  @(posedge clk); ilength <= 3;   idata <= 32'hfffffff0;  // 3bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 32'hffffffff;  // byte alignment
  @(posedge clk); ilength <= 16;  idata <= 32'hffff1111;  // 16bit
  @(posedge clk); ilength <= 0;   // wait 1 cycle to use rest
  @(posedge clk); ilength <= rest;idata <= 32'hffffffff;  // no byte alignment
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff0505;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff0505;
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 32;  idata <= 32'haaaaaaaa;
  repeat(32) begin
    @(posedge clk); ilength <= 1;   idata <= 32'hfffffffe;
    @(posedge clk); ilength <= 32;  idata <= 32'haaaaaaaa;
  end
  @(posedge clk); ilength <= 0;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff0505;
  @(posedge clk); ilength <= 16;  idata <= 32'hffff0505;
  @(posedge clk); ilength <= 0;
  repeat(10) @(posedge clk);
  $display("end");
  $finish();
end

wire          ovalid;
wire[32-1:0]  odata;
wire[6-1:0]   acclen;
wire[3-1:0]   rest;
BITSTREAM bs (
  .clk(clk),
  .rst(rst),
  .ilength(ilength),  // 0 <= ilength <= 32
  .idata(idata),
  .rest(rest),
  .ovalid(ovalid),
  .odata(odata)
);

always @(posedge clk) begin
  if(ovalid) $display("out: %x", odata);
end

endmodule
