`default_nettype none
`timescale 1 ps / 1 ps

// insert stuff zero byte after 8'hff except when bsdata_nostuff is asserted
module INSERT_STUFF (
  input   wire          clk,
  input   wire          rst,

  input   wire          enqueue,
  input   wire[32-1:0]  wdata,
  input   wire[32-1:0]  wdata_nostuff,

  output  wire          ready,
  input   wire          dequeue,
  output  wire[ 8-1:0]  rdata
);
localparam[8-1:0] zero = 0;

wire[4-1:0] ready4;
reg         last_fold_ready4;
assign      ready = last_fold_ready4 & |ready4;
always @(posedge clk) last_fold_ready4 <= rst ? 0 : |ready4;

reg         stuff;
reg [2-1:0] roffset;
reg [9-1:0] tmp[0:4-1];

// insert stuff zero byte
assign  rdata = stuff ? zero : tmp[roffset][0+:8];
always @(posedge clk) begin
  if(rst) begin
    stuff   <=  0;
    roffset <= ~0;
  end else if(dequeue) begin
    stuff   <= !stuff && tmp[roffset]==9'h0ff;
    roffset <= roffset - (stuff ? 0 : 1); // roffset -1
  end
end

generate genvar gi;
for (gi = 0; gi < 4; gi = gi + 1) begin
  // TODO: buffer should be SRL
  reg [9-1:0] buffer[0:32-1];  //ring buffer
  reg [5-1:0] waddr;
  reg [5-1:0] raddr;
  assign  ready4[gi] = raddr!=waddr;

  always @(posedge clk) begin
    if(rst) begin
      {raddr, waddr} <= 0;
    end else begin
      if(enqueue) begin
        waddr         <= waddr+1;
        buffer[waddr] <= {wdata_nostuff[8*gi+7], wdata[8*gi +: 8]};
      end
      if(dequeue && roffset==gi && !stuff) begin
        raddr         <= raddr+1;
      end
      tmp[gi]       <= buffer[raddr];
    end
  end
end
endgenerate

always @(posedge clk) if(!ready && dequeue) begin
  $display("invalid dequeue");
  $finish();
end
endmodule

`default_nettype wire

