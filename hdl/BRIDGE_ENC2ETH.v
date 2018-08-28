`default_nettype none
`timescale 1 ps / 1 ps

module BRIDGE_ENC2ETH (
  input   wire                enc_clk,
  input   wire                rst,
  input   wire                enqueue,
  input   wire[8-1:0]         jpeg,

  input   wire                eth_clk,
  output  reg                 start_send,
  input   wire[3:0]           nibble,
  input   wire                nibble_user_data,
  input   wire                nibble_valid,
  output  reg [3:0]           with_usr,
  output  reg                 with_usr_valid
);


reg           enqueue = 0;
reg [8-1:0]   wdata   = 0;

reg           dequeue = 0;
wire[8-1:0]   rdata;
wire          empty, filled;
ASYNC_FIFO #(
  .SIZE_SCALE(15),
  .WIDTH(8),
  .FILLED_THRESH(1024*4)
) af (
  .rst(rst),// Hold 8 cycle in slower clock
  // Write clock region
  .wclk(enc_clk),
  .full(),
  .filled_w(),
  .enqueue(enqueue),
  .wdata(jpeg),
  // Read clock region
  .rclk(eth_clk),
  .empty(empty),
  .filled_r(filled),
  .dequeue(dequeue),
  .rdata(rdata)
);

integer i;
reg           next_dequeue;
reg [4-1:0]   rnibble[0:8-1];
reg           rnibble_user_data[0:8-1];
reg           rnibble_valid[0:8-1];
reg [8-1:0]   rrdata;
always @(posedge eth_clk) begin
  for (i = 0; i < 8; i = i + 1) begin
    rnibble[i]          <= i>0 ? rnibble[i-1]           : nibble;
    rnibble_user_data[i]<= i>0 ? rnibble_user_data[i-1] : nibble_user_data;
    rnibble_valid[i]    <= i>0 ? rnibble_valid[i-1]     : nibble_valid;
  end

  // cycle 1
  dequeue       <= rnibble_user_data[1] ?  next_dequeue : 0;
  next_dequeue  <= rnibble_user_data[1] ? ~next_dequeue : 1;
  if(next_dequeue) rrdata <= rdata;

  // cycle 2
  with_usr      <=
    !rnibble_user_data[2] ? rnibble[2] :
    dequeue               ? rrdata[0+:4] :
                            rrdata[4+:4];
  with_usr_valid<= rnibble_valid[2];

  // assert start
  start_send    <= !rnibble_valid[2] & filled;
end

endmodule

`default_nettype wire

