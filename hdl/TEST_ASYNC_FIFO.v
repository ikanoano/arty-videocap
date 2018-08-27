`default_nettype none
`timescale 1ps/1ps

module TEST_ASYNC_FIFO ();
reg wclk, rclk, rst;

localparam[32-1:0]
  WINT      = 514,// 20,// 97,
  RINT      = 500,//100,//101,
  RSTWIDTH  = (WINT>RINT ? WINT : RINT) * 2 * 10;

initial begin
  $display("WINT:%d, RINT:%d, RSTWIDTH:%d", WINT, RINT, RSTWIDTH);
end

initial begin
  wclk = 1'b1;
  forever #WINT wclk = ~wclk;
end
initial begin
  rclk = 1'b1;
  forever #RINT rclk = ~rclk;
end
//initial begin
//  forever #10000 $display("tick");
//end

initial begin
  $display("assert rst");
  rst = 1'b1;
  #RSTWIDTH
  $display("deassert rst");
  rst = 1'b0;
  #1000000
  $display("finish");
  $finish();
end

initial begin
  wdata   = 0;
end
wire  enqueue = !full;
always @(posedge wclk) begin
  //enqueue <= !full;
  if(!rst) begin
    if(!full) begin
      wdata <= wdata+1;
    end else begin
      $display("full! (normal behavior)");
    end
  end
  //$display("%b", enqueue);
end

wire              dequeue = !empty;
reg               dequeue_reg;
reg [8-1:0]       rdata_prev = 0;
localparam        diff = 1;
wire[8-1:0]       expected = rdata_prev+diff;
always @(posedge rclk) begin
  if(dequeue_reg) begin
    if(rdata !== expected) begin
    //if(rdata[0+:10] != 10'h00 && rdata != rdata_prev+10'h01) begin
      $display("\ninvalid rdata? expected:%h, actual:%h", expected, rdata);
      //$display("x invalid rdata! expected:%h, actual:%h", rdata_prev+10'h01, rdata);
    end else begin
      //$write("o");
      $display("o %h", rdata);
    end

    rdata_prev  <= rdata;
  end
  dequeue_reg   <= dequeue;
end

wire          full, empty, filled;
reg [ 8-1:0]  wdata;
wire[ 8-1:0]  rdata;
ASYNC_FIFO #(8,8,128) af (
  rst,  // Hold 8 cycle for slower clock
  // Write clock region
  wclk, full, enqueue, wdata,
  // Read clock region
  rclk, empty, filled, dequeue, rdata
);

endmodule
