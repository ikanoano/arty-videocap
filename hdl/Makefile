OBJS = \
			TEST_MJPG_ENCODER.v \
			MJPG_ENCODER.v \
			COMPONENT_ENCODER.v \
			DSP.v \
			BITSTREAM.v \
			INSERT_STUFF.v

isim: $(OBJS)
	iverilog -g2005 $(OBJS) -o $@

clean:
	rm -f isim
