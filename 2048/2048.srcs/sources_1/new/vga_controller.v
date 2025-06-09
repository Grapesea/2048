module vga_controller (
    input  wire        clk_pixel,     // 25MHz 像素时钟
    input  wire        rst_n,         // 低有效复位
    output reg         hsync,         // VGA 行同步
    output reg         vsync,         // VGA 场同步
    output reg         valid,         // 是否在可显示区域
    output reg  [9:0]  x_pos,         // 当前像素X坐标
    output reg  [9:0]  y_pos          // 当前像素Y坐标
);

    // VGA时序参数（640x480 @ 60Hz）
    localparam H_ACTIVE = 640;        // 可视区宽度
    localparam H_FRONT  = 16;         // 行前肩
    localparam H_SYNC   = 96;         // 行同步脉冲
    localparam H_BACK   = 48;         // 行后肩
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    localparam V_ACTIVE = 480;        // 可视区高度
    localparam V_FRONT  = 10;         // 场前肩
    localparam V_SYNC   = 2;          // 场同步脉冲
    localparam V_BACK   = 33;         // 场后肩
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    // 行列计数器
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // 水平扫描计数器
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            h_cnt <= 0;
        else if (h_cnt == H_TOTAL - 1)
            h_cnt <= 0;
        else
            h_cnt <= h_cnt + 1;
    end

    // 垂直扫描计数器
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            v_cnt <= 0;
        else if (h_cnt == H_TOTAL - 1) begin
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 0;
            else
                v_cnt <= v_cnt + 1;
        end
    end

    // 行同步信号（负极性）
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            hsync <= 1'b1;
        else
            hsync <= ~((h_cnt >= H_ACTIVE + H_FRONT) &&
                       (h_cnt <  H_ACTIVE + H_FRONT + H_SYNC));
    end

    // 场同步信号（负极性）
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            vsync <= 1'b1;
        else
            vsync <= ~((v_cnt >= V_ACTIVE + V_FRONT) &&
                       (v_cnt <  V_ACTIVE + V_FRONT + V_SYNC));
    end

    // 可视区域判断
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
        end else begin
            valid <= (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
        end
    end

    // 输出像素坐标（在有效区输出真实坐标，否则输出0）
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            x_pos <= 10'd0;
            y_pos <= 10'd0;
        end else if (valid) begin
            x_pos <= h_cnt;
            y_pos <= v_cnt;
        end else begin
            x_pos <= 10'd0;
            y_pos <= 10'd0;
        end
    end

endmodule
