// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input  wire       clk_p,
    input   wire      clk_n,
    input  wire       reset_n,


    /*
     * Ethernet: 1000BASE-T RGMII
     */
   input  wire       phy_rx_clk_0,
    input  wire [3:0] phy_rxd_0,
    input  wire       phy_rx_ctl_0,
    output wire       phy_tx_clk_0,
    output wire [3:0] phy_txd_0,
    output wire       phy_tx_ctl_0,
    output wire       phy_reset_n_0,
    
    input  wire       phy_rx_clk_1,
    input  wire [3:0] phy_rxd_1,
    input  wire       phy_rx_ctl_1,
    output wire       phy_tx_clk_1,
    output wire [3:0] phy_txd_1,
    output wire       phy_tx_ctl_1,
    output wire       phy_reset_n_1
);

wire clk_ibufg;
// Clock and reset
IBUFGDS
clk_200mhz_ibufgds_inst(
    .I(clk_p),
    .IB(clk_n),
    .O(clk_ibufg)
);

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire rst_int;   

wire mmcm_rst = ~reset_n;
wire mmcm_locked;
wire mmcm_clkfb;
wire clk90_mmcm_out;
wire clk90_int;

wire clk_200_mmcm_out;
wire clk_200_int;

// MMCM instance
// 200 MHz in, 125 MHz out
// PFD range: 10 MHz to 500 MHz
// VCO range: 600 MHz to 1440 MHz
// M = 5, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
// Need two 125 MHz outputs with 90 degree offset
// Also need 200 MHz out for IODELAY
// 1000 / 5 = 200 MHz
MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(8),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(90),
    .CLKOUT2_DIVIDE(5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(5),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(5.0),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(clk_ibufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(clk90_mmcm_out),
    .CLKOUT1B(),
    .CLKOUT2(clk_200_mmcm_out),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);
BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(clk_int)
);

BUFG
clk90_bufg_inst (
    .I(clk90_mmcm_out),
    .O(clk90_int)
);

BUFG
clk_200_bufg_inst (
    .I(clk_200_mmcm_out),
    .O(clk_200_int)
);
sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);

// IODELAY elements for RGMII interface to PHY 0
wire [3:0] phy_rxd_delay_0;
wire       phy_rx_ctl_delay_0;

// IODELAY elements for RGMII interface to PHY 1
wire [3:0] phy_rxd_delay_1;
wire       phy_rx_ctl_delay_1;
IDELAYCTRL
idelayctrl_inst_0
(
    .REFCLK(clk_200_int),
    .RST(rst_int),
    .RDY()
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_0_idelay_0
(
    .IDATAIN(phy_rxd_0[0]),
    .DATAOUT(phy_rxd_delay_0[0]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_0_idelay_1
(
    .IDATAIN(phy_rxd_0[1]),
    .DATAOUT(phy_rxd_delay_0[1]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_0_idelay_2
(
    .IDATAIN(phy_rxd_0[2]),
    .DATAOUT(phy_rxd_delay_0[2]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_0_idelay_3
(
    .IDATAIN(phy_rxd_0[3]),
    .DATAOUT(phy_rxd_delay_0[3]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rx_ctl_0_idelay
(
    .IDATAIN(phy_rx_ctl_0),
    .DATAOUT(phy_rx_ctl_delay_0),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

// IODElay instance1  --------------------------------------------------------------------------

IDELAYCTRL
idelayctrl_inst_1
(
    .REFCLK(clk_200_int),
    .RST(rst_int),
    .RDY()
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_1_idelay_0
(
    .IDATAIN(phy_rxd_1[0]),
    .DATAOUT(phy_rxd_delay_1[0]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_1_idelay_1
(
    .IDATAIN(phy_rxd_1[1]),
    .DATAOUT(phy_rxd_delay_1[1]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_1_idelay_2
(
    .IDATAIN(phy_rxd_1[2]),
    .DATAOUT(phy_rxd_delay_1[2]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_1_idelay_3
(
    .IDATAIN(phy_rxd_1[3]),
    .DATAOUT(phy_rxd_delay_1[3]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rx_ctl_1_idelay
(
    .IDATAIN(phy_rx_ctl_1),
    .DATAOUT(phy_rx_ctl_delay_1),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);




fpga_core #(
    .TARGET("XILINX")
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .clk90(clk90_int),
    .rst(rst_int),

    /*
     * Ethernet: 1000BASE-T RGMII -> 0
     */
    .phy_rx_clk_0(phy_rx_clk_0),
    .phy_rxd_0(phy_rxd_delay_0),
    .phy_rx_ctl_0(phy_rx_ctl_delay_0),
    .phy_tx_clk_0(phy_tx_clk_0),
    .phy_txd_0(phy_txd_0),
    .phy_tx_ctl_0(phy_tx_ctl_0),
    .phy_reset_n_0(phy_reset_n_0),  
    
    /*
     * Ethernet: 1000BASE-T RGMII -> 1
     */
    .phy_rx_clk_1(phy_rx_clk_1),
    .phy_rxd_1(phy_rxd_delay_1),
    .phy_rx_ctl_1(phy_rx_ctl_delay_1),
    .phy_tx_clk_1(phy_tx_clk_1),
    .phy_txd_1(phy_txd_1),
    .phy_tx_ctl_1(phy_tx_ctl_1),
    .phy_reset_n_1(phy_reset_n_1) 

);

endmodule

`resetall
