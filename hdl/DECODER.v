`default_nettype none
`timescale 1ps/1ps

//Transition-minimized and DC-balanced 8bit to 10bit video data decoder
module DECODER (
  input   wire          clk,
  input   wire          rst,
  input   wire[10-1:0]  D,
  output  reg [ 8-1:0]  Q
);

wire[8-1:0] d_m = D[9] ? ~D[7:0] : D[7:0];

always @(posedge clk) begin
  if(rst) begin
    Q <= 0;
  end else begin
    Q <= D[8] ?
      {{d_m[7:1]  ^ d_m[6:0]}, d_m[0]} :
      {{d_m[7:1] ~^ d_m[6:0]}, d_m[0]};
  end
end

endmodule

