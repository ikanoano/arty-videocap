`default_nettype none
`timescale 1 ps / 1 ps

module TEST_MJPG_ENCODER #(
  parameter PERIOD=1000
) (
);

reg clk = 0;
initial begin
  clk = #PERIOD 1;
  forever clk = #(PERIOD/2) ~clk;
end

reg rst = 1;
initial begin
  repeat(10) @(posedge clk);
  rst <= 0;
  repeat(2) @(posedge clk);
  if(1) begin
    // oshietyau
    me.width  = 640;
    me.height = 360;
    me.footer_header[143] = 360 >> 8;
    me.footer_header[144] = 360 & 8'hff;
    me.footer_header[145] = 640 >> 8;
    me.footer_header[146] = 640 & 8'hff;
  end
end

integer rfd, wfd;
initial begin
  $display("reading frame.hex");
  rfd = $fopen("/tmp/frame.hex", "r");
  if(!rfd) begin
    $display("failed to open frame.hex");
    $finish();
  end
  wfd = $fopen("/tmp/frame.jpg", "wb");
  if(!wfd) begin
    $display("failed to open frame.jpg");
    $finish();
  end
  @(negedge rst);
  $display("start");
end

reg [27-1:0]  rdata;
wire          pvalid, hsync, vsync;
wire[24-1:0]  ycbcr;
assign {vsync, hsync, pvalid, ycbcr} = rdata;

wire          jvalid;
wire[ 8-1:0]  jpeg;
reg [32-1:0]  jpeg_big;
integer       offset = 0;
always @(posedge clk) if(jvalid) begin
  jpeg_big  <= (jpeg_big>>8) | (jpeg<<24);
  offset    <= offset+1;
end

integer cnt = 0;
integer rtn;
integer last_offset = 0;
always @(posedge clk) begin
  if(rst) begin
    rdata <= 0;
  end else begin
    if(last_offset!=offset && offset[0+:2]==0) begin
      last_offset <= offset;
      // write data in big endian
      $fwrite(wfd, "%u", jpeg_big);
    end

    if($feof(rfd)) begin
      cnt = cnt+1;
      case (cnt)
        1: begin
          $display("width  = %d", me.width);
          $display("height = %d", me.height);
        end
        2: begin $display("end"); $fclose(wfd); $finish(); end
        default : begin $display("???"); $finish(); end
      endcase
      rtn = $rewind(rfd);
    end
    rtn = $fscanf(rfd,"%h\n", rdata);
  end
end

always @(negedge me.cenc[1].bsvalid[4]) begin
  if(0 && !rst) begin
    $display("negedge bsvalid4");
    $finish();
  end
end

generate if(0) begin
always @(posedge clk) begin
  if(0 && !rst && me.yenc.gen_dsp[0].storeP) begin
    $write("sum_acc[0][%x]<=%d (y=%d) ",
        me.yenc.gen_dsp[0].raddrA,
        $signed(me.yenc.gen_dsp[0].P),
        me.yenc.y_in_mcu);
    $write("sum_acc[1][%x]<=%d (y=%d) ",
        me.yenc.gen_dsp[1].raddrA,
        $signed(me.yenc.gen_dsp[1].P),
        me.yenc.y_in_mcu);
    $write("sum_acc[2][%x]<=%d (y=%d) ",
        me.yenc.gen_dsp[2].raddrA,
        $signed(me.yenc.gen_dsp[2].P),
        me.yenc.y_in_mcu);
    $display("");
  end
end
end endgenerate

integer yyy = 0;
always @(posedge clk) begin
  if(me.yenc.vsync) begin
    yyy = 0;
  end else begin
    if(me.yenc.valid && me.yenc.y_in_mcu==0 && me.x_from_valid==0) $write("\n");
    if(me.yenc.valid && me.yenc.x_in_mcu==0 && me.yenc.x_mcu==0) begin
      $write("\n%x %d ", me.yenc.pix, yyy);
      $fflush(32'h8000_0001);
      yyy = yyy+1;
    end
    if(me.yenc.valid && me.yenc.x_in_mcu==0) $write(".");
  end
end

always @(posedge me.yenc.ereq) if(0) $display("yereq _/");
always @(posedge clk) if(0 && me.yenc.eob) $display("yereq eob");
always @(negedge me.yenc.ereq) if(0) $display("yereq \\_");
always @(posedge clk) if(0 && me.yenc.elen>0) begin
  $display("elen=%d, edata=%x, bitlen=%d, runlen=%d, val=%b, bsvalid=%b, is_dc=%b",
    me.yenc.elen,
    me.yenc.edata,
    me.yenc.bitlen[5],
    me.yenc.runlen[5],
    me.yenc.val[5],
    me.yenc.bsvalid[5],
    me.yenc.is_dc[5]
  );
end

always @(posedge clk) if(0 && me.yenc.bsvalid[4] && !me.yenc.is_dc[4])
  $display("achufflen[%d]=%d, achuffcode[{%d,%d}]=0b%b",
    me.yenc.bitlen[4],
    me.yenc.ac_huff_len,
    me.yenc.runlen[4][0+:4],
    me.yenc.bitlen[4],
    me.yenc.ac_huff_code);
always @(posedge clk) if(0 && me.yenc.bsvalid[4] &&  me.yenc.is_dc[4])
  $display("dchufflen[%d]=%d, dchuffcode[%d]=0b%b",
    me.yenc.bitlen[4],
    me.yenc.dc_huff_len,
    me.yenc.bitlen[4],
    me.yenc.dc_huff_code);

always @(posedge clk) if(!rst) begin
  if(0 && me.is.enqueue) $display("in : 0x%x (nostuff:0x%x)",
    me.is.wdata,
    me.is.wdata_nostuff);
  if(0 && me.is.valid) $display("out: 0x%x (roffset=%d)",
    me.is.rdata,
    me.is.roffset);
  if(1 && me.is.valid&&me.is.stuff)  $write("s");
end


MJPG_ENCODER me (
  clk,
  rst,

  pvalid,
  hsync,
  vsync,
  ycbcr,

  jvalid,
  jpeg
);

endmodule
