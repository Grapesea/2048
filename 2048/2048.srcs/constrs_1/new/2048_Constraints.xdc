set_property PACKAGE_PIN AC18 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS18 [get_ports clk_100m]
create_clock -period 10.000 -name clk_100m [get_ports clk_100m]

set_property PACKAGE_PIN W13 [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]

set_property PACKAGE_PIN V17 [get_ports key_up]
set_property PACKAGE_PIN W18 [get_ports key_down]
set_property PACKAGE_PIN W19 [get_ports key_left]
set_property PACKAGE_PIN W15 [get_ports key_right]
set_property PACKAGE_PIN W16 [get_ports key_restart]
set_property IOSTANDARD LVCMOS18 [get_ports {key_up key_down key_left key_right key_restart}]

set_property PACKAGE_PIN M22 [get_ports vga_hsync]
set_property PACKAGE_PIN M21 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_hsync vga_vsync}]

set_property PACKAGE_PIN P21 [get_ports vga_red[3]]
set_property PACKAGE_PIN R21 [get_ports vga_red[2]]
set_property PACKAGE_PIN N22 [get_ports vga_red[1]]
set_property PACKAGE_PIN N21 [get_ports vga_red[0]]

set_property PACKAGE_PIN T25 [get_ports vga_green[3]]
set_property PACKAGE_PIN T24 [get_ports vga_green[2]]
set_property PACKAGE_PIN R23 [get_ports vga_green[1]]
set_property PACKAGE_PIN R22 [get_ports vga_green[0]]

set_property PACKAGE_PIN T23 [get_ports vga_blue[3]]
set_property PACKAGE_PIN T22 [get_ports vga_blue[2]]
set_property PACKAGE_PIN R20 [get_ports vga_blue[1]]
set_property PACKAGE_PIN T20 [get_ports vga_blue[0]]

set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[*] vga_green[*] vga_blue[*]}]

set_property PACKAGE_PIN AD21 [get_ports AN[0]]
set_property PACKAGE_PIN AC21 [get_ports AN[1]]
set_property PACKAGE_PIN AB21 [get_ports AN[2]]
set_property PACKAGE_PIN AC22 [get_ports AN[3]]

set_property PACKAGE_PIN AB22 [get_ports SEGMENT[0]]
set_property PACKAGE_PIN AD24 [get_ports SEGMENT[1]]
set_property PACKAGE_PIN AD23 [get_ports SEGMENT[2]]
set_property PACKAGE_PIN Y21 [get_ports SEGMENT[3]]
set_property PACKAGE_PIN W20 [get_ports SEGMENT[4]]
set_property PACKAGE_PIN AC24 [get_ports SEGMENT[5]]
set_property PACKAGE_PIN AC23 [get_ports SEGMENT[6]]
set_property PACKAGE_PIN AA22 [get_ports SEGMENT[7]]

set_property IOSTANDARD LVCMOS33 [get_ports {AN[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEGMENT[*]}]
      
set_property PACKAGE_PIN W23 [get_ports led_status[0]]
set_property PACKAGE_PIN AB26 [get_ports led_status[1]]
set_property PACKAGE_PIN Y25 [get_ports led_status[2]]
set_property PACKAGE_PIN AA23 [get_ports led_status[3]]
set_property PACKAGE_PIN Y23 [get_ports led_status[4]]
set_property PACKAGE_PIN Y22 [get_ports led_status[5]]
set_property PACKAGE_PIN AE21 [get_ports led_status[6]]
set_property PACKAGE_PIN AF24 [get_ports led_status[7]]

set_property IOSTANDARD LVCMOS33 [get_ports {led_status[*]}]

set_input_delay -clock [get_clocks clk_100m] -min 1.000 [get_ports {key_up key_down key_left key_right key_restart}]
set_input_delay -clock [get_clocks clk_100m] -max 3.000 [get_ports {key_up key_down key_left key_right key_restart}]

set_output_delay -clock [get_clocks clk_100m] -min 1.000 [get_ports {vga_hsync vga_vsync vga_red[*] vga_green[*] vga_blue[*]}]
set_output_delay -clock [get_clocks clk_100m] -max 3.000 [get_ports {vga_hsync vga_vsync vga_red[*] vga_green[*] vga_blue[*]}]

set_output_delay -clock [get_clocks clk_100m] -min 1.000 [get_ports {AN[*] SEGMENT[*]}]
set_output_delay -clock [get_clocks clk_100m] -max 3.000 [get_ports {AN[*] SEGMENT[*]}]

set_output_delay -clock [get_clocks clk_100m] -min 1.000 [get_ports {led_status[*]}]
set_output_delay -clock [get_clocks clk_100m] -max 3.000 [get_ports {led_status[*]}]