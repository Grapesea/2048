/*
 * 2048游戏输入控制模块
 * 功能：按键消抖、脉冲生成、移动命令编码
 * 特点：支持20ms消抖时间，生成单次脉冲信号
 */

module input_controller (
    input  wire       clk,              // 100MHz系统时钟
    input  wire       rst_n,            // 复位信号
    
    // 原始按键输入（低有效）
    input  wire       key_up_raw,       // 上移键
    input  wire       key_down_raw,     // 下移键
    input  wire       key_left_raw,     // 左移键
    input  wire       key_right_raw,    // 右移键
    input  wire       key_restart_raw,  // 重新开始键
    
    // 处理后的按键脉冲输出（高有效单脉冲）
    output wire       key_up_pulse,     // 上移脉冲
    output wire       key_down_pulse,   // 下移脉冲
    output wire       key_left_pulse,   // 左移脉冲
    output wire       key_right_pulse,  // 右移脉冲
    output wire       key_restart_pulse,// 重启脉冲
    
    // 移动命令编码输出
    output reg [2:0]  move_cmd          // 000:无, 001:上, 010:下, 011:左, 100:右
);

    // ========================================
    // 参数定义
    // ========================================
    
    // 消抖时间参数 (20ms @ 100MHz = 2,000,000 cycles)
    parameter DEBOUNCE_TIME = 20'd2_000_000;
    
    // 移动命令编码
    parameter CMD_NONE  = 3'b000;
    parameter CMD_UP    = 3'b001;
    parameter CMD_DOWN  = 3'b010;
    parameter CMD_LEFT  = 3'b011;
    parameter CMD_RIGHT = 3'b100;
    
    // ========================================
    // 内部信号定义
    // ========================================
    
    // 消抖计数器
    reg [19:0] debounce_cnt_up;
    reg [19:0] debounce_cnt_down;
    reg [19:0] debounce_cnt_left;
    reg [19:0] debounce_cnt_right;
    reg [19:0] debounce_cnt_restart;
    
    // 按键同步寄存器（用于跨时钟域同步）
    reg [2:0] key_up_sync;
    reg [2:0] key_down_sync;
    reg [2:0] key_left_sync;
    reg [2:0] key_right_sync;
    reg [2:0] key_restart_sync;
    
    // 消抖后的按键状态
    reg key_up_debounced;
    reg key_down_debounced;
    reg key_left_debounced;
    reg key_right_debounced;
    reg key_restart_debounced;
    
    // 按键边沿检测寄存器
    reg key_up_reg;
    reg key_down_reg;
    reg key_left_reg;
    reg key_right_reg;
    reg key_restart_reg;
    
    // 内部脉冲信号
    wire key_up_pulse_int;
    wire key_down_pulse_int;
    wire key_left_pulse_int;
    wire key_right_pulse_int;
    wire key_restart_pulse_int;
    
    // ========================================
    // 按键输入同步处理
    // ========================================
    
    // 上移键同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_up_sync <= 3'b111;  // 默认高电平（按键未按下）
        end else begin
            key_up_sync <= {key_up_sync[1:0], key_up_raw};
        end
    end
    
    // 下移键同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_down_sync <= 3'b111;
        end else begin
            key_down_sync <= {key_down_sync[1:0], key_down_raw};
        end
    end
    
    // 左移键同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_left_sync <= 3'b111;
        end else begin
            key_left_sync <= {key_left_sync[1:0], key_left_raw};
        end
    end
    
    // 右移键同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_right_sync <= 3'b111;
        end else begin
            key_right_sync <= {key_right_sync[1:0], key_right_raw};
        end
    end
    
    // 重启键同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_restart_sync <= 3'b111;
        end else begin
            key_restart_sync <= {key_restart_sync[1:0], key_restart_raw};
        end
    end
    
    // ========================================
    // 按键消抖处理
    // ========================================
    
    // 上移键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt_up <= 20'd0;
            key_up_debounced <= 1'b1;
        end else begin
            if (key_up_sync[2] == key_up_debounced) begin
                debounce_cnt_up <= 20'd0;
            end else begin
                if (debounce_cnt_up >= DEBOUNCE_TIME) begin
                    key_up_debounced <= key_up_sync[2];
                    debounce_cnt_up <= 20'd0;
                end else begin
                    debounce_cnt_up <= debounce_cnt_up + 1'b1;
                end
            end
        end
    end
    
    // 下移键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt_down <= 20'd0;
            key_down_debounced <= 1'b1;
        end else begin
            if (key_down_sync[2] == key_down_debounced) begin
                debounce_cnt_down <= 20'd0;
            end else begin
                if (debounce_cnt_down >= DEBOUNCE_TIME) begin
                    key_down_debounced <= key_down_sync[2];
                    debounce_cnt_down <= 20'd0;
                end else begin
                    debounce_cnt_down <= debounce_cnt_down + 1'b1;
                end
            end
        end
    end
    
    // 左移键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt_left <= 20'd0;
            key_left_debounced <= 1'b1;
        end else begin
            if (key_left_sync[2] == key_left_debounced) begin
                debounce_cnt_left <= 20'd0;
            end else begin
                if (debounce_cnt_left >= DEBOUNCE_TIME) begin
                    key_left_debounced <= key_left_sync[2];
                    debounce_cnt_left <= 20'd0;
                end else begin
                    debounce_cnt_left <= debounce_cnt_left + 1'b1;
                end
            end
        end
    end
    
    // 右移键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt_right <= 20'd0;
            key_right_debounced <= 1'b1;
        end else begin
            if (key_right_sync[2] == key_right_debounced) begin
                debounce_cnt_right <= 20'd0;
            end else begin
                if (debounce_cnt_right >= DEBOUNCE_TIME) begin
                    key_right_debounced <= key_right_sync[2];
                    debounce_cnt_right <= 20'd0;
                end else begin
                    debounce_cnt_right <= debounce_cnt_right + 1'b1;
                end
            end
        end
    end
    
    // 重启键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt_restart <= 20'd0;
            key_restart_debounced <= 1'b1;
        end else begin
            if (key_restart_sync[2] == key_restart_debounced) begin
                debounce_cnt_restart <= 20'd0;
            end else begin
                if (debounce_cnt_restart >= DEBOUNCE_TIME) begin
                    key_restart_debounced <= key_restart_sync[2];
                    debounce_cnt_restart <= 20'd0;
                end else begin
                    debounce_cnt_restart <= debounce_cnt_restart + 1'b1;
                end
            end
        end
    end
    
    // ========================================
    // 边沿检测生成单脉冲
    // ========================================
    
    // 边沿检测寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_up_reg <= 1'b1;
            key_down_reg <= 1'b1;
            key_left_reg <= 1'b1;
            key_right_reg <= 1'b1;
            key_restart_reg <= 1'b1;
        end else begin
            key_up_reg <= key_up_debounced;
            key_down_reg <= key_down_debounced;
            key_left_reg <= key_left_debounced;
            key_right_reg <= key_right_debounced;
            key_restart_reg <= key_restart_debounced;
        end
    end
    
    // 下降沿检测生成脉冲（按键按下瞬间）
    assign key_up_pulse_int = key_up_reg & (~key_up_debounced);
    assign key_down_pulse_int = key_down_reg & (~key_down_debounced);
    assign key_left_pulse_int = key_left_reg & (~key_left_debounced);
    assign key_right_pulse_int = key_right_reg & (~key_right_debounced);
    assign key_restart_pulse_int = key_restart_reg & (~key_restart_debounced);
    
    // ========================================
    // 按键优先级处理
    // ========================================
    
    // 防止多键同时按下，按优先级处理：上 > 下 > 左 > 右
    assign key_up_pulse = key_up_pulse_int;
    assign key_down_pulse = key_down_pulse_int & (~key_up_pulse_int);
    assign key_left_pulse = key_left_pulse_int & (~key_up_pulse_int) & (~key_down_pulse_int);
    assign key_right_pulse = key_right_pulse_int & (~key_up_pulse_int) & (~key_down_pulse_int) & (~key_left_pulse_int);
    assign key_restart_pulse = key_restart_pulse_int;
    
    // ========================================
    // 移动命令编码
    // ========================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            move_cmd <= CMD_NONE;
        end else begin
            if (key_up_pulse) begin
                move_cmd <= CMD_UP;
            end else if (key_down_pulse) begin
                move_cmd <= CMD_DOWN;
            end else if (key_left_pulse) begin
                move_cmd <= CMD_LEFT;
            end else if (key_right_pulse) begin
                move_cmd <= CMD_RIGHT;
            end else begin
                move_cmd <= CMD_NONE;
            end
        end
    end

endmodule