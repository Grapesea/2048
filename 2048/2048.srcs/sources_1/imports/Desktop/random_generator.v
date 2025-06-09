/*
 * 随机数生成器模块
 * 功能：为2048游戏生成随机方块（数值和位置）
 * 算法：使用线性反馈移位寄存器(LFSR)生成伪随机数
 * 生成规则：90%概率生成2，10%概率生成4
 */

module random_generator (
    input  wire        clk,                    // 系统时钟
    input  wire        rst_n,                  // 复位信号（低有效）
    input  wire [15:0] seed,                   // 随机种子
    input  wire        new_block_trigger,      // 新方块生成触发信号
    // 修改：将数组端口改为单独的信号端口
    input  wire [4:0]  cell_00, cell_01, cell_02, cell_03,
    input  wire [4:0]  cell_10, cell_11, cell_12, cell_13,
    input  wire [4:0]  cell_20, cell_21, cell_22, cell_23,
    input  wire [4:0]  cell_30, cell_31, cell_32, cell_33,
    output reg  [3:0]  new_pos,                // 新方块位置(0-15)
    output reg  [1:0]  new_val                 // 新方块数值(0->2, 1->4)
);

    // ========================================
    // 参数定义
    // ========================================
    
    parameter LFSR_WIDTH = 16;              // LFSR宽度
    parameter PROB_4_THRESHOLD = 51;        // 生成4的概率阈值(51/512 ≈ 10%)
    
    // ========================================
    // 内部信号定义
    // ========================================
    
    reg [LFSR_WIDTH-1:0] lfsr_reg;          // LFSR寄存器
    reg [LFSR_WIDTH-1:0] lfsr_next;         // LFSR下一状态
    reg new_block_trigger_d1;               // 触发信号延迟一拍
    reg new_block_trigger_d2;               // 触发信号延迟两拍
    wire trigger_posedge;                   // 触发信号上升沿
    
    // 空白位置相关信号
    reg [3:0] empty_positions [0:15];       // 空白位置数组
    reg [4:0] empty_count;                  // 空白位置计数
    reg [3:0] selected_empty_idx;           // 选中的空白位置索引
    
    // 随机数提取
    wire [8:0] rand_val;                    // 9位随机数用于概率判断
    wire [3:0] rand_pos;                    // 4位随机数用于位置选择
    
    // 内部游戏矩阵数组
    reg [4:0] game_matrix [0:15];
    
    // ========================================
    // 将输入信号赋值到内部数组
    // ========================================
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
    
    // ========================================
    // LFSR随机数生成器
    // ========================================
    
    // LFSR反馈多项式：x^16 + x^14 + x^13 + x^11 + 1
    // 对应抽头位置：[15, 13, 12, 10]
    always @(*) begin
        lfsr_next = {lfsr_reg[14:0], 
                    lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10]};
    end
    
    // LFSR寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 16'hACE1;  // 非零初始值
        end else begin
            // 持续运行LFSR以增加随机性
            if (seed != 16'h0000) begin
                lfsr_reg <= seed;   // 种子更新
            end else begin
                lfsr_reg <= lfsr_next;
            end
        end
    end
    
    // 随机数提取
    assign rand_val = lfsr_reg[8:0];        // 用于数值概率判断
    assign rand_pos = lfsr_reg[15:12];      // 用于位置选择
    
    // ========================================
    // 触发信号边沿检测
    // ========================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            new_block_trigger_d1 <= 1'b0;
            new_block_trigger_d2 <= 1'b0;
        end else begin
            new_block_trigger_d1 <= new_block_trigger;
            new_block_trigger_d2 <= new_block_trigger_d1;
        end
    end
    
    assign trigger_posedge = new_block_trigger_d1 & ~new_block_trigger_d2;
    
    // ========================================
    // 空白位置检测与统计
    // ========================================
    
    integer i;
    always @(*) begin
        empty_count = 0;
        
        // 扫描所有位置，记录空白位置
        for (i = 0; i < 16; i = i + 1) begin
            if (game_matrix[i] == 5'b00000) begin
                empty_positions[empty_count] = i;
                empty_count = empty_count + 1;
            end
        end
        
        // 确保至少有一个有效的空白位置记录
        if (empty_count == 0) begin
            empty_positions[0] = 4'd0;
            empty_count = 1;
        end
    end
    
    // ========================================
    // 位置选择逻辑
    // ========================================
    
    always @(*) begin
        if (empty_count > 0) begin
            // 使用随机数选择空白位置
            selected_empty_idx = rand_pos % empty_count;
        end else begin
            selected_empty_idx = 4'd0;
        end
    end
    
    // ========================================
    // 随机方块生成主逻辑
    // ========================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            new_pos <= 4'd0;
            new_val <= 2'd0;  // 默认生成2
        end else if (trigger_posedge && empty_count > 0) begin
            // 位置选择：从空白位置中随机选择
            new_pos <= empty_positions[selected_empty_idx];
            
            // 数值选择：90%概率生成2(值0)，10%概率生成4(值1)
            if (rand_val < PROB_4_THRESHOLD) begin
                new_val <= 2'd1;  // 生成4
            end else begin
                new_val <= 2'd0;  // 生成2
            end
        end
        // 如果没有触发或没有空白位置，保持当前值
    end
    
    `ifdef DEBUG_RANDOM
    always @(posedge trigger_posedge) begin
        $display("[DEBUG] Random Generator:");
        $display("  Empty count: %d", empty_count);
        $display("  Selected position: %d", new_pos);
        $display("  Generated value: %s", (new_val == 0) ? "2" : "4");
        $display("  LFSR state: %h", lfsr_reg);
    end
    `endif

endmodule