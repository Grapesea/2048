/*
 * 2048游戏FPGA顶层模块设计（最终版）
 * 功能：协调各个子模块，实现完整的2048游戏系统
 * 作者：FPGA设计团队
 * 日期：2025年5月
 * 修改：替换为DisplayNumber模块
 */

module top_2048 (
    // 系统时钟和复位
    input  wire        clk_100m,      // 100MHz主时钟
    input  wire        rst_n,         // 低有效复位信号
    
    //PS2接口
    input  wire        ps2_clk,
    input  wire        ps2_data,
    
    // VGA显示接口
    output wire        vga_hsync,     // VGA行同步
    output wire        vga_vsync,     // VGA场同步
    output wire [3:0]  vga_red,       // VGA红色分量
    output wire [3:0]  vga_green,     // VGA绿色分量
    output wire [3:0]  vga_blue,      // VGA蓝色分量
    
    // 7段数码管显示（显示分数）- 更新接口
    output wire [3:0]  AN,            // 数码管位选
    output wire [7:0]  SEGMENT,       // 数码管段选
    
    // LED状态指示
    output wire [7:0]  led_status     // 状态LED
);

    // ========================================
    // 内部信号定义
    // ========================================
    
    // 时钟信号
    wire clk_25m;           // 25MHz VGA像素时钟
    wire clk_1k;            // 1KHz数码管扫描时钟
    wire clk_locked;        // PLL锁定信号
    
    // 复位信号
    wire sys_rst_n;         // 系统复位信号
    wire sys_rst;           // 正逻辑复位信号（DisplayNumber需要）
    
    // 用户输入接口
    wire        key_up;        // 上移键
    wire        key_down;      // 下移键  
    wire        key_left;      // 左移键
    wire        key_right;     // 右移键
    wire        key_restart;   // 重新开始键
    
    // 按键处理信号
    wire key_up_pulse;      // 上键脉冲
    wire key_down_pulse;    // 下键脉冲
    wire key_left_pulse;    // 左键脉冲
    wire key_right_pulse;   // 右键脉冲
    wire key_restart_pulse; // 重启键脉冲
    wire [1:0] move_direction; // 移动方向编码（与game_2048_move模块匹配）
    wire move_start;        // 移动开始信号
    
    // 游戏逻辑信号
    wire [79:0] game_matrix;        // 游戏矩阵 (16*5=80位，每位单元格5位)
    wire [19:0] current_score;      // 当前分数
    wire [19:0] best_score;         // 最高分数（暂未实现存储，可接EEPROM模块）
    reg  [2:0] game_state;          // 游戏状态
    wire game_over;                 // 游戏结束标志
    wire game_win;                  // 游戏胜利标志
    wire move_valid;                // 移动有效标志
    wire move_done;                 // 移动完成标志
    
    // 显示控制信号
    wire [9:0] vga_x;               // VGA X坐标
    wire [9:0] vga_y;               // VGA Y坐标
    wire vga_valid;                 // VGA有效区域
    wire [11:0] pixel_color;        // 像素颜色（RGB444格式）
    
    // 随机数信号
    wire [15:0] random_seed;        // 随机种子
    wire [3:0] new_block_pos;       // 新方块位置(0-15)
    wire [1:0] new_block_val_2bit;  // 随机生成器输出的2位数值（0=2，1=4）
    wire [4:0] new_block_val;       // 扩展为5位的数值（2=00001，4=00010）
    
    // DisplayNumber接口信号
    wire [15:0] display_hexs;       // 4位16进制数显示
    wire [3:0] display_points;      // 小数点控制
    wire [3:0] display_LEs;         // LED使能控制
    
    // 游戏状态定义
    parameter IDLE       = 3'b000,
              PLAYING    = 3'b001,
              MOVING     = 3'b010,
              ADD_BLOCK  = 3'b011,
              GAME_OVER  = 3'b100,
              GAME_WIN   = 3'b101;
    
    // 复位信号转换
    assign sys_rst_n = rst_n & clk_locked;
    assign sys_rst = ~sys_rst_n;  // DisplayNumber需要正逻辑复位
    
    // ========================================
    // 时钟管理模块
    // ========================================
    
    clk_manager u_clk_manager (
        .clk_in(clk_100m),
        .rst_n(rst_n),
        .clk_25m(clk_25m),
        .clk_1k(clk_1k),
        .locked(clk_locked)
    );
    
    // ========================================
    // PS/2键盘模块
    // ========================================
    
    PS2 u_ps2_keyboard (
        .clk(clk_100m),
        .rst(sys_rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .up(ps2_up),
        .down(ps2_down),
        .left(ps2_left),
        .right(ps2_right),
        .space(ps2_space)
    ); 
    // ========================================
    // 按键输入处理模块
    // ========================================
    
    input_controller u_input_ctrl (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        
        // 原始按键输入
        .key_up_raw(ps2_up),
        .key_down_raw(ps2_down),
        .key_left_raw(ps2_left),
        .key_right_raw(ps2_right),
        .key_restart_raw(ps2_restart),
        
        // 处理后的按键脉冲
        .key_up_pulse(key_up_pulse),
        .key_down_pulse(key_down_pulse),
        .key_left_pulse(key_left_pulse),
        .key_right_pulse(key_right_pulse),
        .key_restart_pulse(key_restart_pulse)
    );
    
    // 移动方向编码（与game_2048_move模块定义一致）
    assign move_direction = key_left_pulse  ? 2'b00 :  // 左
                           key_right_pulse ? 2'b01 :  // 右
                           key_up_pulse    ? 2'b10 :  // 上
                           key_down_pulse  ? 2'b11 :  // 下
                           2'b00;                     // 默认
    
    assign move_start = key_up_pulse | key_down_pulse | key_left_pulse | key_right_pulse;
    
    // ========================================
    // 游戏核心移动逻辑模块（需自行实现）
    // ========================================
    
    game_2048_move u_game_move (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .move_direction(move_direction),
        .move_start(move_start && (game_state == PLAYING)),
        .move_valid(move_valid),
        .current_score(current_score),
        .best_score(best_score),
        .move_done(move_done)
    );
    
    // ========================================
    // 随机数生成模块（修正端口连接）
    // ========================================
    
    random_generator u_random_gen (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .seed(random_seed),
        .new_block_trigger(add_new_block),
        
        // 展开为16个独立单元格信号（行优先：row0-col0 ~ row3-col3）
        .cell_00(game_matrix[0*5 +:5]),
        .cell_01(game_matrix[1*5 +:5]),
        .cell_02(game_matrix[2*5 +:5]),
        .cell_03(game_matrix[3*5 +:5]),
        .cell_10(game_matrix[4*5 +:5]),
        .cell_11(game_matrix[5*5 +:5]),
        .cell_12(game_matrix[6*5 +:5]),
        .cell_13(game_matrix[7*5 +:5]),
        .cell_20(game_matrix[8*5 +:5]),
        .cell_21(game_matrix[9*5 +:5]),
        .cell_22(game_matrix[10*5 +:5]),
        .cell_23(game_matrix[11*5 +:5]),
        .cell_30(game_matrix[12*5 +:5]),
        .cell_31(game_matrix[13*5 +:5]),
        .cell_32(game_matrix[14*5 +:5]),
        .cell_33(game_matrix[15*5 +:5]),
        
        .new_pos(new_block_pos),
        .new_val(new_block_val_2bit)
    );
    
    // 将2位数值扩展为5位（2=00001，4=00010）
    assign new_block_val = (new_block_val_2bit == 2'b00) ? 5'b00001 : 5'b00010;
    
    // ========================================
    // 游戏矩阵管理模块（修正组合逻辑错误）
    // ========================================
    
    matrix_manager u_matrix_mgr (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .restart_game(key_restart_pulse),
        .add_new_block(add_new_block),
        .new_block_pos(new_block_pos),
        .new_block_val(new_block_val),
        .game_matrix(game_matrix),
        .game_over(game_over),
        .game_win(game_win)
    );
    
    // ========================================
    // 主状态机控制
    // ========================================
    
    always @(posedge clk_100m or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            game_state <= IDLE;
        end else begin
            case (game_state)
                IDLE: begin
                    if (key_restart_pulse) begin
                        game_state <= PLAYING;
                    end
                end
                
                PLAYING: begin
                    if (game_over) begin
                        game_state <= GAME_OVER;
                    end else if (game_win) begin
                        game_state <= GAME_WIN;
                    end else if (move_start) begin
                        game_state <= MOVING;
                    end
                end
                
                MOVING: begin
                    if (move_done) begin
                        if (move_valid) begin
                            game_state <= ADD_BLOCK;
                        end else begin
                            game_state <= PLAYING;
                        end
                    end
                end
                
                ADD_BLOCK: begin
                    game_state <= PLAYING;
                end
                
                GAME_OVER: begin
                    if (key_restart_pulse) begin
                        game_state <= PLAYING;
                    end
                end
                
                GAME_WIN: begin
                    if (key_restart_pulse) begin
                        game_state <= PLAYING;
                    end else if (move_start) begin
                        game_state <= MOVING; // 允许胜利后继续移动
                    end
                end
                
                default: begin
                    game_state <= IDLE;
                end
            endcase
        end
    end
    
    // 添加新方块信号（状态机控制）
    assign add_new_block = (game_state == ADD_BLOCK);
    
    // ========================================
    // VGA显示控制模块
    // ========================================
    
    vga_controller u_vga_ctrl (
        .clk_pixel(clk_25m),
        .rst_n(sys_rst_n),
        
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .valid(vga_valid),
        .x_pos(vga_x),
        .y_pos(vga_y)
    );
    
    // ========================================
    // 显示渲染模块（修正端口连接）
    // ========================================
    
    display_renderer u_display_render (
        .clk_pixel(clk_25m),
        .rst_n(sys_rst_n),
        
        .x_pos(vga_x),
        .y_pos(vga_y),
        .valid_area(vga_valid),
        
        // 展开为16个独立单元格信号（与random_generator一致）
        .cell_00(game_matrix[0*5 +:5]),
        .cell_01(game_matrix[1*5 +:5]),
        .cell_02(game_matrix[2*5 +:5]),
        .cell_03(game_matrix[3*5 +:5]),
        .cell_10(game_matrix[4*5 +:5]),
        .cell_11(game_matrix[5*5 +:5]),
        .cell_12(game_matrix[6*5 +:5]),
        .cell_13(game_matrix[7*5 +:5]),
        .cell_20(game_matrix[8*5 +:5]),
        .cell_21(game_matrix[9*5 +:5]),
        .cell_22(game_matrix[10*5 +:5]),
        .cell_23(game_matrix[11*5 +:5]),
        .cell_30(game_matrix[12*5 +:5]),
        .cell_31(game_matrix[13*5 +:5]),
        .cell_32(game_matrix[14*5 +:5]),
        .cell_33(game_matrix[15*5 +:5]),
        
        .current_score(current_score),
        .best_score(best_score), // 暂未实现，可接地或设为0
        .game_state(game_state),
        
        .pixel_color(pixel_color)
    );
    
    // VGA RGB信号分配（RGB444格式）
    assign vga_red   = pixel_color[11:8];
    assign vga_green = pixel_color[7:4];
    assign vga_blue  = pixel_color[3:0];
    
    // ========================================
    // 7段数码管显示模块 - 替换为DisplayNumber
    // ========================================
    
    // 分数转换为16进制显示格式（显示当前分数的低16位）
    assign display_hexs = current_score[15:0];
    
    // 小数点控制（可根据需要设置，这里关闭所有小数点）
    assign display_points = 4'b0000;
    
    // LED使能控制（全部使能）
    assign display_LEs = 4'b0000;  // 低有效，0表示使能
    
    DisplayNumber u_display_number (
        .clk(clk_100m),
        .rst(sys_rst),          // 注意：DisplayNumber使用正逻辑复位
        .hexs(display_hexs),
        .points(display_points),
        .LEs(display_LEs),
        .AN(AN),
        .SEGMENT(SEGMENT)
    );
     // ========================================
    // LED状态指示
    // ========================================
    
    assign led_status[0] = game_over;           // 游戏结束
    assign led_status[1] = game_win;            // 游戏胜利
    assign led_status[2] = move_valid;          // 移动有效
    assign led_status[3] = move_start;          // 有移动输入
    assign led_status[4] = (game_state == MOVING);    // 正在移动
    assign led_status[5] = (game_state == ADD_BLOCK); // 正在添加方块
    assign led_status[7:6] = game_state[1:0];   // 游戏状态低2位
    
    // 随机种子生成（使用时钟和按键组合，建议替换为专用PRNG）
    assign random_seed = {clk_100m, key_up, key_down, key_left, key_right, 
                         current_score[10:0]};

endmodule