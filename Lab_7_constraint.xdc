# Basys3 Lab 7 - Discrete ADC
# Authors: Yassin Shehata, Abdelrahman Salem, Ahmed Attiya
# Board:   Digilent Basys3 (Artix-7)

# Clock (100 MHz)
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Switches
# SW0-SW1: number format (HEX/DEC)
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {bin_bcd_select[0]}] ; # SW0
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {bin_bcd_select[1]}] ; # SW1

# SW2-SW3: ADC source select (00=XADC, 01=PWM, others unused)
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {adc_select[0]}]     ; # SW2
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {adc_select[1]}]     ; # SW3

# SW4-SW5: display_mode (00=RAW, 01=AVG, 10=VOLT)
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports {display_mode[0]}]   ; # SW4
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {display_mode[1]}]   ; # SW5

# LEDs (led[15:0])
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports {led[15]}]

# 7-segment display
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports CA]
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports CB]
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports CC]
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports CD]
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports CE]
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports CF]
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports CG]
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports DP]

set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports AN1]
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports AN2]
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports AN3]
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports AN4]

# Reset (center push button)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

# Pmod JA - comparator input
# JA1: comparator output used as comp_pwm
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports comp_pwm] ; 

# JXADC - PWM output and analog input
# XA1_P: PWM feeding RC/comparator
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports pwm_out]
# XA4_P/N: analog channel for XADC (VAUX15)
set_property -dict { PACKAGE_PIN N2 IOSTANDARD LVCMOS33 } [get_ports vauxp15]
set_property -dict { PACKAGE_PIN N1 IOSTANDARD LVCMOS33 } [get_ports vauxn15]

# Global configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS        VCCO [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33   [current_design]
set_property CONFIG_MODE                    SPIx4 [current_design]

# R-2R ladder digital outputs (example pins - change to match your wiring)

# JA2, JA3, JA4, JA7, JA8, JA9, JA10, and one extra pin (e.g. JB1)
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[0]}] ; # JA2
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[1]}] ; # JA3
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[2]}] ; # JA4
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[3]}] ; # JA7
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[4]}] ; # JA8
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[5]}] ; # JA9
set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[6]}] ; # JA10
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports {r2r_out[7]}] ; 

set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports comp_r2r]

# SW6: 0 = Ramp, 1 = SAR
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {sar_mode}] ; # SW6