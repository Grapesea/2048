module display_renderer (
    input  wire        clk_pixel,    // 25MHz 像素时钟
    input  wire        rst_n,        // 低有效复位
    // VGA 坐标
    input  wire [9:0]  x_pos,
    input  wire [9:0]  y_pos,
    input  wire        valid_area,
    // 游戏数据 - 修改为单独的信号
    input  wire [4:0]  cell_00, cell_01, cell_02, cell_03,
    input  wire [4:0]  cell_10, cell_11, cell_12, cell_13,
    input  wire [4:0]  cell_20, cell_21, cell_22, cell_23,
    input  wire [4:0]  cell_30, cell_31, cell_32, cell_33,
    input  wire [19:0] current_score,
    input  wire [19:0] best_score,
    input  wire [2:0]  game_state,
    // 输出像素颜色（RGB565格式）
    output reg [15:0]  pixel_color
);
    // 屏幕区域划分参数（以 640x480 分辨率为基础）
    localparam GRID_ORIGIN_X = 100;     // 左上角X
    localparam GRID_ORIGIN_Y = 60;      // 左上角Y
    localparam CELL_SIZE     = 80;      // 单元格大小（正方形）
    
    // 当前是否在游戏矩阵区域
    wire in_grid;
    wire [3:0] cell_row, cell_col;
    wire [4:0] cell_value;
    wire [6:0] rel_x, rel_y;
    
    assign in_grid = (x_pos >= GRID_ORIGIN_X && x_pos < GRID_ORIGIN_X + 4 * CELL_SIZE &&
                      y_pos >= GRID_ORIGIN_Y && y_pos < GRID_ORIGIN_Y + 4 * CELL_SIZE);
    assign rel_x = x_pos - GRID_ORIGIN_X;
    assign rel_y = y_pos - GRID_ORIGIN_Y;
    assign cell_col = rel_x / CELL_SIZE;
    assign cell_row = rel_y / CELL_SIZE;
    
    // 根据行列位置选择对应的单元格值
    reg [4:0] game_matrix [0:15];
    
    always @(*) begin
        game_matrix[0]  = cell_00;
        game_matrix[1]  = cell_01;
        game_matrix[2]  = cell_02;
        game_matrix[3]  = cell_03;
        game_matrix[4]  = cell_10;
        game_matrix[5]  = cell_11;
        game_matrix[6]  = cell_12;
        game_matrix[7]  = cell_13;
        game_matrix[8]  = cell_20;
        game_matrix[9]  = cell_21;
        game_matrix[10] = cell_22;
        game_matrix[11] = cell_23;
        game_matrix[12] = cell_30;
        game_matrix[13] = cell_31;
        game_matrix[14] = cell_32;
        game_matrix[15] = cell_33;
    end
    
    assign cell_value = game_matrix[cell_row * 4 + cell_col];
    
    // 简单颜色映射函数
    function [15:0] get_color;
        input [4:0] val;
        begin
            case (val)
                0:  get_color = 16'hFFFF; // 白色
                1:  get_color = 16'hFFE0; // 黄色
                2:  get_color = 16'hF800; // 红色
                3:  get_color = 16'h07E0; // 绿色
                4:  get_color = 16'h001F; // 蓝色
                5:  get_color = 16'hF81F; // 紫色
                6:  get_color = 16'h07FF; // 青色
                7:  get_color = 16'hFD20; // 橙色
                default: get_color = 16'h0000; // 黑色
            endcase
        end
    endfunction
    
    // 像素绘制逻辑
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            pixel_color <= 16'h0000;
        else if (!valid_area)
            pixel_color <= 16'h0000;
        else if (in_grid) begin
            // 渲染方格
            if ((rel_x % CELL_SIZE < 2) || (rel_y % CELL_SIZE < 2))
                pixel_color <= 16'h0000; // 黑色边框
            else
                pixel_color <= get_color(cell_value);
        end else begin
            pixel_color <= 16'hC618; // 背景灰色
        end
    end
endmodule