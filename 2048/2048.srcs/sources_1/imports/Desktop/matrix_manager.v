// ========================================
// 矩阵管理模块（完整修正版）
// ========================================
module matrix_manager (
    input wire clk,
    input wire rst_n,
    input wire restart_game,
    input wire add_new_block,
    input wire [3:0] new_block_pos,
    input wire [4:0] new_block_val,
    output reg [79:0] game_matrix, // 16*5=80位，每位单元格5位
    output wire game_over,
    output wire game_win
);

    parameter VAL_EMPTY = 5'b00000;
    parameter VAL_2048  = 5'b11111; // 5位最大值31（测试用，实际需扩展位宽）
    
    integer i;
    reg [3:0] empty_count; // 0-16，4位足够
    reg has_2048;

    // 单元格访问函数（阻塞赋值）
    function [4:0] get_cell;
        input [3:0] idx; // 单元格索引0-15
        begin
            get_cell = game_matrix[idx*5 +:5];
        end
    endfunction

    reg init_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            game_matrix <= 80'h0;
            init_state <= 1'b1;
        end else if (init_state) begin
            // 延迟一个时钟周期初始化方块
            game_matrix[0*5 +:5] <= 5'b00001;
            game_matrix[3*5 +:5] <= 5'b00001;
            init_state <= 1'b0;
        end else if (restart_game) begin
            game_matrix <= 80'h0;
            init_state <= 1'b1;
        end else if (add_new_block && new_block_pos < 16) begin
            game_matrix[new_block_pos*5 +:5] <= new_block_val;
        end
    end

    // 组合逻辑：计算空白格和胜利条件
    always @(*) begin
        empty_count = 0;
        has_2048 = 0;
        
        for (i = 0; i < 16; i = i + 1) begin
            if (get_cell(i) == VAL_EMPTY) begin
                empty_count = empty_count + 1;
            end
            if (get_cell(i) >= VAL_2048) begin
                has_2048 = 1;
            end
        end
    end

    // 简化的游戏结束条件：无空白格且无法移动（需结合move_valid信号）
    assign game_over = (empty_count == 0); // 实际应判断所有相邻单元格是否可合并
    assign game_win = has_2048;

endmodule
