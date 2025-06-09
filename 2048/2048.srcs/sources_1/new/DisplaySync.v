/******************************************************************************
 ** Logisim-evolution goes FPGA automatic generated Verilog code             **
 ** https://github.com/logisim-evolution/                                    **
 **                                                                          **
 ** Component : DisplaySync                                                  **
 **                                                                          **
 *****************************************************************************/

module DisplaySync( AN,
                    HEX,
                    LE,
                    LEs,
                    hexs,
                    point,
                    points,
                    scan );

   /*******************************************************************************
   ** The inputs are defined here                                                **
   *******************************************************************************/
   input [3:0]  LEs;
   input [15:0] hexs;
   input [3:0]  points;
   input [1:0]  scan;

   /*******************************************************************************
   ** The outputs are defined here                                               **
   *******************************************************************************/
   output [3:0] AN;
   output [3:0] HEX;
   output       LE;
   output       point;

   /*******************************************************************************
   ** The wires are defined here                                                 **
   *******************************************************************************/
   wire [3:0]  s_logisimBus10;
   wire [3:0]  s_logisimBus16;
   wire [3:0]  s_logisimBus17;
   wire [15:0] s_logisimBus22;
   wire [3:0]  s_logisimBus23;
   wire [3:0]  s_logisimBus5;
   wire [3:0]  s_logisimBus6;
   wire [3:0]  s_logisimBus7;
   wire [3:0]  s_logisimBus8;
   wire [1:0]  s_logisimBus9;
   wire        s_logisimNet0;
   wire        s_logisimNet1;
   wire        s_logisimNet11;
   wire        s_logisimNet18;
   wire        s_logisimNet19;
   wire        s_logisimNet2;
   wire        s_logisimNet20;
   wire        s_logisimNet21;
   wire        s_logisimNet3;
   wire        s_logisimNet4;

   /*******************************************************************************
   ** The module functionality is described here                                 **
   *******************************************************************************/

   /*******************************************************************************
   ** Here all input connections are defined                                     **
   *******************************************************************************/
   assign s_logisimBus16[3:0]  = LEs;
   assign s_logisimBus22[15:0] = hexs;
   assign s_logisimBus23[3:0]  = points;
   assign s_logisimBus9[1:0]   = scan;

   /*******************************************************************************
   ** Here all output connections are defined                                    **
   *******************************************************************************/
   assign AN    = s_logisimBus10[3:0];
   assign HEX   = s_logisimBus17[3:0];
   assign LE    = s_logisimNet0;
   assign point = s_logisimNet11;

   /*******************************************************************************
   ** Here all in-lined components are defined                                   **
   *******************************************************************************/

   //     
   assign  s_logisimBus6[3:0]  =  4'hD;


   //     
   assign  s_logisimBus8[3:0]  =  4'h7;


   //     
   assign  s_logisimBus5[3:0]  =  4'hE;


   //     
   assign  s_logisimBus7[3:0]  =  4'hB;


   /*******************************************************************************
   ** Here all sub-circuits are defined                                          **
   *******************************************************************************/

   Mux4to1b4   mux_hexs (.D0(s_logisimBus22[3:0]),
                         .D1(s_logisimBus22[7:4]),
                         .D2(s_logisimBus22[11:8]),
                         .D3(s_logisimBus22[15:12]),
                         .S(s_logisimBus9[1:0]),
                         .Y(s_logisimBus17[3:0]));

   Mux4to1   mux_LE (.D0(s_logisimBus16[0]),
                     .D1(s_logisimBus16[1]),
                     .D2(s_logisimBus16[2]),
                     .D3(s_logisimBus16[3]),
                     .S(s_logisimBus9[1:0]),
                     .Y(s_logisimNet0));

   Mux4to1b4   mux_AN (.D0(s_logisimBus5[3:0]),
                       .D1(s_logisimBus6[3:0]),
                       .D2(s_logisimBus7[3:0]),
                       .D3(s_logisimBus8[3:0]),
                       .S(s_logisimBus9[1:0]),
                       .Y(s_logisimBus10[3:0]));

   Mux4to1   mux_points (.D0(s_logisimBus23[0]),
                         .D1(s_logisimBus23[1]),
                         .D2(s_logisimBus23[2]),
                         .D3(s_logisimBus23[3]),
                         .S(s_logisimBus9[1:0]),
                         .Y(s_logisimNet11));

endmodule
