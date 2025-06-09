module display_renderer (
    input  wire        clk_pixel,
    input  wire        rst_n,
    // VGA 坐标
    input  wire [9:0]  x_pos,
    input  wire [9:0]  y_pos,
    input  wire        valid_area,
    // 游戏数据
    input  wire [4:0]  cell_00, cell_01, cell_02, cell_03,
    input  wire [4:0]  cell_10, cell_11, cell_12, cell_13,
    input  wire [4:0]  cell_20, cell_21, cell_22, cell_23,
    input  wire [4:0]  cell_30, cell_31, cell_32, cell_33,
    input  wire [19:0] current_score,
    input  wire [19:0] best_score,
    input  wire [2:0]  game_state,
    // 输出像素颜色（VGA444格式，12位）
    output reg [11:0]  pixel_color
);

    // 屏幕区域参数
    localparam GRID_ORIGIN_X = 100;
    localparam GRID_ORIGIN_Y = 60;
    localparam CELL_SIZE     = 80; // 与图片尺寸一致
    
    // 位置计算
    wire [8:0] rel_x, rel_y;
    wire in_grid;
    reg [1:0] cell_col, cell_row;
    reg [4:0] cell_value;
    
    assign in_grid = (x_pos >= GRID_ORIGIN_X && x_pos < GRID_ORIGIN_X + 320 &&
                      y_pos >= GRID_ORIGIN_Y && y_pos < GRID_ORIGIN_Y + 320);
    assign rel_x = x_pos - GRID_ORIGIN_X;
    assign rel_y = y_pos - GRID_ORIGIN_Y;
    
    // 行列计算 - 避免除法
    always @(*) begin
        if (rel_x < 80)      cell_col = 0;
        else if (rel_x < 160) cell_col = 1;
        else if (rel_x < 240) cell_col = 2;
        else                 cell_col = 3;
        
        if (rel_y < 80)      cell_row = 0;
        else if (rel_y < 160) cell_row = 1;
        else if (rel_y < 240) cell_row = 2;
        else                 cell_row = 3;
    end
    
    // 单元格值选择
    always @(*) begin
        case ({cell_row, cell_col})
            4'b0000: cell_value = cell_00;
            4'b0001: cell_value = cell_01;
            4'b0010: cell_value = cell_02;
            4'b0011: cell_value = cell_03;
            4'b0100: cell_value = cell_10;
            4'b0101: cell_value = cell_11;
            4'b0110: cell_value = cell_12;
            4'b0111: cell_value = cell_13;
            4'b1000: cell_value = cell_20;
            4'b1001: cell_value = cell_21;
            4'b1010: cell_value = cell_22;
            4'b1011: cell_value = cell_23;
            4'b1100: cell_value = cell_30;
            4'b1101: cell_value = cell_31;
            4'b1110: cell_value = cell_32;
            4'b1111: cell_value = cell_33;
            default: cell_value = 5'b0;
        endcase
    end

    // 图片ROM实例化（0-11共12个数值，对应12张图片）
    wire [11:0] img_color_0, img_color_1, img_color_2, img_color_3,
                img_color_4, img_color_5, img_color_6, img_color_7,
                img_color_8, img_color_9, img_color_10, img_color_11;

    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/0.hex")  
    ) u_rom_0 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_0)
    );

    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/2.hex")  
    ) u_rom_1 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_1)
    );

    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/4.hex")   
    ) u_rom_2 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_2)
    );

    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/8.hex")  
    ) u_rom_3 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_3)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/16.hex")  
    ) u_rom_4 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_4)
    );

    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/32.hex")  
    ) u_rom_5 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_5)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/64.hex")  
    ) u_rom_6 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_6)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/128.hex")  
    ) u_rom_7 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_7)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/256.hex")  
    ) u_rom_8 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_8)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/512.hex")  
    ) u_rom_9 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_9)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/1024.hex")  
    ) u_rom_10 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_10)
    );
    
    image_rom #(
        .IMAGE_WIDTH(CELL_SIZE),
        .IMAGE_HEIGHT(CELL_SIZE),
        .DATA_FILE("G:/2048/2048/new/2048.hex")  
    ) u_rom_11 (
        .clk(clk_pixel),
        .x(rel_x),
        .y(rel_y),
        .pixel_color(img_color_11)
    );
    
    // 图片颜色选择
    reg [11:0] current_img_color;
    always @(*) begin
        case(cell_value)
            0:  current_img_color = img_color_0;
            1:  current_img_color = img_color_1;
            2:  current_img_color = img_color_2;
            3:  current_img_color = img_color_3;
            4:  current_img_color = img_color_4;
            5:  current_img_color = img_color_5;
            6:  current_img_color = img_color_6;
            7:  current_img_color = img_color_7;
            8:  current_img_color = img_color_8;
            9:  current_img_color = img_color_9;
            10: current_img_color = img_color_10;
            11: current_img_color = img_color_11;
            default: current_img_color = img_color_0; // 透明背景
        endcase
    end

    // 边框检测（保留原有逻辑）
    wire [6:0] cell_rel_x = rel_x - (cell_col << 6) - (cell_col << 4); // 0-79
    wire [6:0] cell_rel_y = rel_y - (cell_row << 6) - (cell_row << 4); // 0-79
    wire is_outer_border = (cell_rel_x < 3) || (cell_rel_y < 3) || 
                          (cell_rel_x >= 77) || (cell_rel_y >= 77);
    wire is_inner_border = (cell_rel_x == 3) || (cell_rel_y == 3) || 
                          (cell_rel_x == 76) || (cell_rel_y == 76);
    wire is_border = is_outer_border || is_inner_border;

    // 主渲染逻辑（图片优先于背景，边框覆盖图片）
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n)
            pixel_color <= 12'h000;  // VGA444黑色
        else if (!valid_area)
            pixel_color <= 12'h000;  // VGA444黑色
        else if (in_grid) begin
            if (is_border) begin // 显示边框
                if (is_outer_border)
                    pixel_color <= 12'h210; // 深色外边框 (VGA444)
                else
                    pixel_color <= 12'h420; // 浅色内边框 (VGA444)
            end else begin // 显示图片或背景
                if (current_img_color != 12'h000) // 非透明像素
                    pixel_color <= current_img_color;
                else // 透明区域显示原有背景（可自定义）
                    pixel_color <= 12'h840; // 浅灰色背景 (VGA444)
            end
        end else begin
            pixel_color <= 12'hFF8; // 整体背景色 (VGA444)
        end
    end

endmodule