module DisplayNumber(
    input        clk,
    input        rst,
    input [15:0] hexs,
    input [3:0] points,
    input [3:0] LEs,
    output[3:0] AN,
    output[7:0] SEGMENT
);
    wire [31:0] div_ress;
    wire [1:0] scan;
    wire [3:0] HEX;
    wire [3:0] mux_AN;
    wire point;
    wire LE;

    clkdiv clkdiv_inst(
       .clk(clk),
       .rst(rst),
       .div_res(div_ress)
    );

    assign scan = div_ress[18:17];

    DisplaySync DisplaySync_inst(
       .scan(scan),
       .hexs(hexs),
       .points(points),
       .LEs(LEs),
       .HEX(HEX),
       .AN(mux_AN),
       .point(point),
       .LE(LE)
    );

    MyMC14495 MyMC14495_inst(
       .D0(HEX[0]),
       .D1(HEX[1]),
       .D2(HEX[2]),
       .D3(HEX[3]),
       .LE(LE),
       .point(point),
       .a(SEGMENT[0]),
       .b(SEGMENT[1]),
       .c(SEGMENT[2]),
       .d(SEGMENT[3]),
       .e(SEGMENT[4]),
       .f(SEGMENT[5]),
       .g(SEGMENT[6]),
       .p(SEGMENT[7])
    );

    assign AN = mux_AN;

endmodule