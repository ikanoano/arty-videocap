`default_nettype none
`timescale 1 ps / 1 ps

module BITSTREAM (
  input   wire          clk,
  input   wire          rst,

  input   wire[6-1:0]   ilength,  // 0 <= ilength <= 16
  input   wire[32-1:0]  idata,
  output  wire[3-1:0]   rest,

  output  reg           ovalid,
  output  reg [32-1:0]  odata
);

reg [32-1:0]  mask[0:32-1];

integer i;
initial begin
  mask[ 0] = ~0; // for ilength==32
  for (i = 1; i < 32; i = i + 1) mask[i] = ~(~0 << i);
  //mask[ 1] = 64'b...0001; // for ilength==1
  //mask[ 2] = 64'b...0011;
end

reg [6-1:0] acclen;
wire[6-1:0] n_acclen = acclen + ilength;
always @(posedge clk) begin
  if(rst) acclen <= 0;
  else    acclen <= n_acclen;
end
assign  rest = -acclen[0+:3];

reg [ 6-1:0]  shiftlen [0:6-1];
reg [64-1:0]  shiftdata[0:4-1];
reg [64-1:0]  acc;
wire          w_valid = shiftlen[5][5] ^ shiftlen[4][5];
wire[64-1:0]  accmask =
  !w_valid        ? ~0 :
  shiftlen[4][5]  ? 64'h00000000ffffffff :
                    64'hffffffff00000000;
integer j;
always @(posedge clk) begin
  for (j = 0; j < 6; j = j + 1) shiftlen[j] <=
    j>0 ? shiftlen[j-1] :
    rst ? 0 :
          n_acclen;

  shiftdata[0]<= ilength==0 ? 64'd0 : {32'd0, idata & mask[ilength[0+:5]]};
  shiftdata[1]<= ROTATE2 (ROTATE1 (shiftdata[0], shiftlen[0][0]), shiftlen[0][1]);
  shiftdata[2]<= ROTATE8 (ROTATE4 (shiftdata[1], shiftlen[1][2]), shiftlen[1][3]);
  shiftdata[3]<= ROTATE32(ROTATE16(shiftdata[2], shiftlen[2][4]), shiftlen[2][5]);
  acc         <= rst ? 0 : acc & accmask | shiftdata[3];

  ovalid      <= rst ? 0 : w_valid;
  odata       <= rst ? 0 : (shiftlen[4][5] ? acc[32+:32] : acc[0+:32]);
end

function[64-1:0] ROTATE1 (input [64-1:0] v, input r); ROTATE1 = r ? {v[0+: 1], v[ 1+:64- 1]} : v; endfunction
function[64-1:0] ROTATE2 (input [64-1:0] v, input r); ROTATE2 = r ? {v[0+: 2], v[ 2+:64- 2]} : v; endfunction
function[64-1:0] ROTATE4 (input [64-1:0] v, input r); ROTATE4 = r ? {v[0+: 4], v[ 4+:64- 4]} : v; endfunction
function[64-1:0] ROTATE8 (input [64-1:0] v, input r); ROTATE8 = r ? {v[0+: 8], v[ 8+:64- 8]} : v; endfunction
function[64-1:0] ROTATE16(input [64-1:0] v, input r); ROTATE16= r ? {v[0+:16], v[16+:64-16]} : v; endfunction
function[64-1:0] ROTATE32(input [64-1:0] v, input r); ROTATE32= r ? {v[0+:32], v[32+:64-32]} : v; endfunction

endmodule

`default_nettype wire

