`default_nettype none
`timescale 1 ps / 1 ps

// insert stuff zero byte after 8'hff except when bsdata_nostuff is asserted
module INSERT_STUFF (
  input   wire          clk,
  input   wire          rst,

  input   wire          enqueue,
  input   wire[32-1:0]  wdata,
  input   wire[32-1:0]  wdata_nostuff,

  output  wire          valid,
  output  wire[ 8-1:0]  rdata
);
localparam[8-1:0] zero = 0;

reg [4-1:0] ready4;

reg         stuff;
reg [2-1:0] roffset;
reg [9-1:0] tmp[0:4-1];

assign      valid = rst ? 0 : (ready4[roffset] || stuff);

// insert stuff zero byte if data is 8'hff and no nostuff flag
assign  rdata = stuff ? zero : tmp[roffset][0+:8];
always @(posedge clk) begin
  if(rst) begin
    stuff   <=  0;
    roffset <= ~0;
  end else if(valid) begin
    stuff   <= !stuff && tmp[roffset]==9'h0ff;
    roffset <= roffset - (stuff ? 0 : 1); // roffset -1
  end
end

integer i;
generate genvar gi;
for (gi = 0; gi < 4; gi = gi + 1) begin
  (* ram_style = "distributed" *)
  reg [9-1:0] buffer[0:32-1];  //ring buffer
  reg [5-1:0] waddr;
  reg [5-1:0] raddr;

  always @(posedge clk) begin
    if(rst) begin
      {raddr, waddr, ready4[gi]} <= 0;
    end else begin
      ready4[gi] <= raddr!=waddr;
      if(enqueue) begin
        waddr         <= waddr+1;
        buffer[waddr] <= {wdata_nostuff[8*gi+7], wdata[8*gi +: 8]};
        if(waddr+1 == raddr) begin
          $display("buffer overflow");
          for (i = 0; i < 32; i = i + 1) $display("buffer[%d]=0x%x", i, buffer[i]);
          $finish();
        end
      end
      if(valid && roffset==gi && !stuff) begin
        raddr         <= raddr+1;
      end
      tmp[gi]       <= buffer[raddr];
    end
  end
end
endgenerate

endmodule

`default_nettype wire

