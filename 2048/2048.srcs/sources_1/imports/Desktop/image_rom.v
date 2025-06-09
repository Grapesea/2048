// 图片ROM模块，输入文件为 VGA444（12位）格式
module image_rom #(
    parameter IMAGE_WIDTH  = 80,
    parameter IMAGE_HEIGHT = 80,
    parameter DATA_FILE    = "undefined.hex" // 每行为12位数据（hex）
)(
    input wire clk,
    input wire [8:0] x,  // 横坐标，0 ~ IMAGE_WIDTH - 1
    input wire [8:0] y,  // 纵坐标，0 ~ IMAGE_HEIGHT - 1
    output reg [11:0] pixel_color // VGA444: {R[3:0], G[3:0], B[3:0]}
);

    localparam DATA_DEPTH = IMAGE_WIDTH * IMAGE_HEIGHT;
    reg [11:0] rom_data [0:DATA_DEPTH-1]; // 直接读取12位 VGA444 数据

    // 初始化读取 hex 文件，格式为每行一个 12-bit 十六进制数
    initial begin
        $readmemh(DATA_FILE, rom_data);
    end

    // 按坐标查找像素颜色
    always @(posedge clk) begin
        if (x < IMAGE_WIDTH && y < IMAGE_HEIGHT)
            pixel_color <= rom_data[y * IMAGE_WIDTH + x];
        else
            pixel_color <= 12'h000; // 越界区域透明（黑色）
    end

endmodule
