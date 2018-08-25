set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_tx_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_tx_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_tx_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_tx_p[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_rx_p[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_rx_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_rx_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_rx_p[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports rst_raw_n]
set_property IOSTANDARD LVCMOS33 [get_ports scl_tx]
set_property IOSTANDARD LVCMOS33 [get_ports sda_tx]
set_property IOSTANDARD LVCMOS33 [get_ports hpd_tx]
set_property IOSTANDARD LVCMOS33 [get_ports scl_rx]
set_property IOSTANDARD LVCMOS33 [get_ports sda_rx]
set_property IOSTANDARD LVCMOS33 [get_ports hpd_rx]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports clk_src_raw]


set_property PACKAGE_PIN H5  [get_ports {led[4]}]
set_property PACKAGE_PIN J5  [get_ports {led[5]}]
set_property PACKAGE_PIN T9  [get_ports {led[6]}]
set_property PACKAGE_PIN T10 [get_ports {led[7]}]
set_property PACKAGE_PIN V10 [get_ports {tmds_tx_p[0]}]
set_property PACKAGE_PIN U12 [get_ports {tmds_tx_p[1]}]
# inv
set_property PACKAGE_PIN U14 [get_ports {tmds_tx_p[2]}]
# inv
set_property PACKAGE_PIN T13 [get_ports {tmds_tx_p[3]}]
set_property PACKAGE_PIN D15 [get_ports {tmds_rx_p[3]}]
set_property PACKAGE_PIN E15 [get_ports {tmds_rx_p[0]}]
# inv
set_property PACKAGE_PIN J17 [get_ports {tmds_rx_p[1]}]
# inv
set_property PACKAGE_PIN K15 [get_ports {tmds_rx_p[2]}]
set_property PACKAGE_PIN C2  [get_ports rst_raw_n]
set_property PACKAGE_PIN G13 [get_ports hpd_rx]
set_property PACKAGE_PIN B11 [get_ports sda_rx]
set_property PACKAGE_PIN A11 [get_ports scl_rx]
set_property PACKAGE_PIN D13 [get_ports hpd_tx]
set_property PACKAGE_PIN B18 [get_ports sda_tx]
set_property PACKAGE_PIN A18 [get_ports scl_tx]
set_property PACKAGE_PIN B8  [get_ports {btn[3]}]
set_property PACKAGE_PIN B9  [get_ports {btn[2]}]
set_property PACKAGE_PIN C9  [get_ports {btn[1]}]
set_property PACKAGE_PIN D9  [get_ports {btn[0]}]
set_property PACKAGE_PIN A10 [get_ports {sw[3]}]
set_property PACKAGE_PIN C10 [get_ports {sw[2]}]
set_property PACKAGE_PIN C11 [get_ports {sw[1]}]
set_property PACKAGE_PIN A8  [get_ports {sw[0]}]
set_property PACKAGE_PIN E3  [get_ports clk_src_raw]

set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports { led0[2] }];
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { led0[1] }];
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { led0[0] }];
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { led1[2] }];
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { led1[1] }];
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { led1[0] }];
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { led2[2] }];
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { led2[1] }];
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { led2[0] }];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { led3[2] }];
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { led3[1] }];
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { led3[0] }];
