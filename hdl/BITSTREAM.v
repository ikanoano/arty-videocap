`default_nettype none
`timescale 1 ps / 1 ps

module BITSTREAM (
  input   wire          clk,
  input   wire          rst,

  input   wire[5-1:0]   ilength,  // 0 <= ilength <= 16
  input   wire[16-1:0]  idata,
  output  wire[3-1:0]   rest,

  output  reg           ovalid,
  output  reg [16-1:0]  odata
);

reg [16-1:0]  mask[0:16-1];
initial begin
  mask[ 0] = 16'b11111111_11111111; // for ilength==16
  mask[ 1] = 16'b00000000_00000001; // for ilength==1
  mask[ 2] = 16'b00000000_00000011;
  mask[ 3] = 16'b00000000_00000111;
  mask[ 4] = 16'b00000000_00001111;
  mask[ 5] = 16'b00000000_00011111;
  mask[ 6] = 16'b00000000_00111111;
  mask[ 7] = 16'b00000000_01111111;
  mask[ 8] = 16'b00000000_11111111;
  mask[ 9] = 16'b00000001_11111111;
  mask[10] = 16'b00000011_11111111;
  mask[11] = 16'b00000111_11111111;
  mask[12] = 16'b00001111_11111111;
  mask[13] = 16'b00011111_11111111;
  mask[14] = 16'b00111111_11111111;
  mask[15] = 16'b01111111_11111111;
end

reg [5-1:0] acclen;
wire[5-1:0] n_acclen = acclen + ilength;
always @(posedge clk) begin
  if(rst) acclen <= 0;
  else    acclen <= n_acclen;
end
assign  rest = -acclen[0+:3];

reg [ 5-1:0]  shiftlen [0:5-1];
reg [32-1:0]  shiftdata[0:3-1];
reg [32-1:0]  acc;
wire          w_valid = shiftlen[4][4] ^ shiftlen[3][4];
wire[32-1:0]  accmask =
  !w_valid        ? ~0 :
  shiftlen[3][4]  ? 32'h0000ffff :
                    32'hffff0000;
integer i;
always @(posedge clk) begin
  for (i = 0; i < 5; i = i + 1) shiftlen[i] <= i>0 ? shiftlen[i-1]  : n_acclen;

  shiftdata[0]<= ilength==0 ? 32'd0 : {16'd0, idata & mask[ilength[0+:4]]};
  shiftdata[1]<= ROTATE2(ROTATE1(shiftdata[0], shiftlen[0][0]), shiftlen[0][1]);
  shiftdata[2]<= ROTATE8(ROTATE4(shiftdata[1], shiftlen[1][2]), shiftlen[1][3]);
  acc         <= rst ? 0 : acc & accmask | ROTATE16(shiftdata[2], shiftlen[2][4]);

  ovalid      <= w_valid;
  odata       <= shiftlen[3][4] ? acc[16+:16] : acc[0+:16];
end

function[32-1:0] ROTATE1 (input [32-1:0] v, input r); ROTATE1 = r ? {v[0+: 1], v[ 1+:32- 1]} : v; endfunction
function[32-1:0] ROTATE2 (input [32-1:0] v, input r); ROTATE2 = r ? {v[0+: 2], v[ 2+:32- 2]} : v; endfunction
function[32-1:0] ROTATE4 (input [32-1:0] v, input r); ROTATE4 = r ? {v[0+: 4], v[ 4+:32- 4]} : v; endfunction
function[32-1:0] ROTATE8 (input [32-1:0] v, input r); ROTATE8 = r ? {v[0+: 8], v[ 8+:32- 8]} : v; endfunction
function[32-1:0] ROTATE16(input [32-1:0] v, input r); ROTATE16= r ? {v[0+:16], v[16+:32-16]} : v; endfunction

endmodule

`default_nettype wire

