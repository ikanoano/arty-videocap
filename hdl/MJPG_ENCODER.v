`default_nettype none
`timescale 1 ps / 1 ps

module MJPG_ENCODER (
  input   wire          clk,
  input   wire          rst,

  input   wire          cvalid,
  input   wire          hsync,
  input   wire          vsync,
  input   wire[24-1:0]  ycbcr,

  output  wire          bsvalid,
  output  wire[16-1:0]  bsdata
);

localparam [2:0]
  S_WAIT4HSYNC  = 3'd0,
  S_COUNTWIDTH  = 3'd1,
  S_WAIT4VSYNC  = 3'd2,
  S_COUNTHEIGHT = 3'd3,
  S_OUTPUTJPEG  = 3'd4;
reg [2:0] state;
always @(posedge clk) begin
  if(rst) state <= S_WAIT4HSYNC;
  else case(state)
    S_WAIT4HSYNC  : if(hsync) state <= S_COUNTWIDTH;
    S_COUNTWIDTH  : if(hsync) state <= S_WAIT4VSYNC;
    S_WAIT4VSYNC  : if(vsync) state <= S_COUNTHEIGHT;
    S_COUNTHEIGHT : if(vsync) state <= S_OUTPUTJPEG;
    default       : state <= state;
  endcase
end

reg [11-1:0]  width, height, y, x;  // 0 <= . < 2047
reg           hvalid;
wire          hvalidsync = hvalid & hsync;
always @(posedge clk) begin
  if(rst) {width, height} <= 0;
  else case(state)
    S_COUNTWIDTH:   if(cvalid)      width <= width+1;
    S_COUNTHEIGHT:  if(hvalidsync)  height<= height+1;
  endcase

  x <= (rst || hsync) ? 11'd0 : x + cvalid;
  y <= (rst || vsync) ? 11'd0 : y + hvalidsync;

  hvalid <=
    rst   ? 1'b0 :
    hsync ? 1'b0 :
    cvalid? 1'b1 : hvalid;
end


// FIXME: width from 16 to 32
reg [6-1:0]   elen;
reg [32-1:0]  edata;
wire[4-1:0]   bsrest;
BITSTREAM bs (
  .clk(clk),
  .rst(rst),
  .ilength(elen),  // 0 <= ilength <= 32
  .idata(edata),
  .rest(bsrest),
  .ovalid(bsvalid),
  .odata(bsdata)
);

// generate bitstream
localparam LEN_FH = 171;
reg [8-1:0]   idx_fh;
reg [8-1:0]   footer_header[0:LEN_FH-1];
reg [6-1:0]   elen_fh;
reg [32-1:0]  edata_fh;
initial $readmemh("fh.hex", footer_header, 0, LEN_FH-1);
always @(posedge clk) begin
  if(rst) {elen_fh, edata_fh, idx_fh} <= 0;
  else begin
    if(vsync) begin // byte alignment
      elen_fh <= bsrest;
      edata_fh<= 32'hffff;
      idx_fh  <= 0;
    end else if(idx_fh<LEN_FH) begin // output footer and header
      elen_fh <= 8;
      edata_fh<= footer_header[idx_fh];
      idx_fh  <= idx_fh + 1;
      case (idx_fh)
        8'd143: footer_header[idx_fh] <= {5'd0, height[8+:3]};
        8'd144: footer_header[idx_fh] <= height[0+:8];
        8'd145: footer_header[idx_fh] <= {5'd0, width[8+:3]};
        8'd146: footer_header[idx_fh] <= width[0+:8];
      endcase
    end else begin  // output entropy-coded image data
      elen_fh <= 0;

      //FIXME: this is dummy!!!
      e_x_mcu[0] <= x[3+:8];
      e_x_mcu[1] <= x[3+:8];
      e_x_mcu[2] <= x[3+:8];
      ereq_ce[0]  <= x[4];
      ereq_ce[1]  <= x[5];
      ereq_ce[2]  <= x[6];
    end
  end
end


reg [8-1:0] pix_y, pix_b, pix_r;
reg         rcvalid, rvsync;
always @(posedge clk) {pix_y, pix_b, pix_r} <= ycbcr;
always @(posedge clk) rcvalid <= cvalid;
always @(posedge clk) rvsync  <= vsync;

reg [8-1:0]   e_x_mcu[0:2];
reg           ereq_ce[0:2];
wire[6-1:0]   elen_ce[0:2];
wire[32-1:0]  edata_ce[0:2];
COMPONENT_ENCODER #(.IS_Y(1), .DCT_TH(28)) yenc (
  .clk(clk),
  .rst(rst),
  .page(y[3]),

  .valid(rcvalid),
  .pix(pix_y),
  .x_mcu(x[3+:8]),      // assign from -1 to h_mcu + 1
  .y_in_mcu(y[0+:3]),
  .x_in_mcu(x[0+:3]),
  .vsync(rvsync),

  .e_x_mcu(e_x_mcu[0]),   // must be valid before bsreq is asserted
  .ereq(ereq_ce[0]),
  .elen(elen_ce[0]),
  .edata(edata_ce[0])
);

COMPONENT_ENCODER #(.IS_Y(1), .DCT_TH(6)) cenc[1:0] (
  .clk(clk),
  .rst(rst),
  .page(x[3]),

  .valid(rcvalid),
  .pix({pix_r, pix_b}),
  .x_mcu(x[3+:8]),      // assign from -1 to h_mcu + 1
  .y_in_mcu(y[0+:3]),
  .x_in_mcu(x[0+:3]),
  .vsync(rvsync),

  .e_x_mcu({e_x_mcu[2], e_x_mcu[1]}),   // must be valid before bsreq is asserted
  .ereq   ({ereq_ce[2], ereq_ce[1]}),
  .elen   ({elen_ce[2], elen_ce[1]}),
  .edata  ({edata_ce[2],edata_ce[1]})
);

wire[4-1:0]   evalid = {|elen_fh, |elen_ce[2], |elen_ce[1], |elen_ce[0]};
reg [6-1:0]   pre_elen;
reg [32-1:0]  pre_edata[0:3];
always @(posedge clk) begin
  pre_elen      <= elen_fh | elen_ce[2] | elen_ce[1] | elen_ce[0];
  pre_edata[0]  <= evalid[0] ? edata_ce[0] : 0;
  pre_edata[1]  <= evalid[1] ? edata_ce[1] : 0;
  pre_edata[2]  <= evalid[2] ? edata_ce[2] : 0;
  pre_edata[3]  <= evalid[3] ? edata_fh    : 0;

  elen  <= pre_elen;
  edata <= pre_edata[3] | pre_edata[2] | pre_edata[1] | pre_edata[0];

  if(!rst) case (evalid)
    4'b0000, 4'b1000, 4'b0100,4'b0010,4'b0001: begin end
    default : begin
      $display("bitstream collision detected: %b", evalid);
      $finish();
    end
  endcase
end

endmodule

`default_nettype wire

