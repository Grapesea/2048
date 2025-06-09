// ========================================
// 时钟管理模块定义
// ========================================

module clk_manager (
    input  wire clk_in,     // 输入时钟100MHz
    input  wire rst_n,      // 复位信号
    output wire clk_25m,    // 25MHz输出
    output wire clk_1k,     // 1KHz输出
    output wire locked      // PLL锁定状态
);

    // PLL IP核实例化（需要根据具体FPGA平台调整）
    // 这里给出通用的分频器实现示例
    
    reg [1:0] div4_cnt;     // 4分频计数器
    reg [16:0] div1k_cnt;   // 1KHz分频计数器
    
    reg clk_25m_reg;
    reg clk_1k_reg;
    
    // 4分频生成25MHz
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            div4_cnt <= 2'b0;
            clk_25m_reg <= 1'b0;
        end else begin
            if (div4_cnt == 2'd1) begin  // 100MHz/4 = 25MHz
                div4_cnt <= 2'b0;
                clk_25m_reg <= ~clk_25m_reg;
            end else begin
                div4_cnt <= div4_cnt + 1'b1;
            end
        end
    end
    
    // 100KHz分频生成1KHz
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            div1k_cnt <= 17'b0;
            clk_1k_reg <= 1'b0;
        end else begin
            if (div1k_cnt == 17'd49999) begin  // 100MHz/100K = 1KHz
                div1k_cnt <= 17'b0;
                clk_1k_reg <= ~clk_1k_reg;
            end else begin
                div1k_cnt <= div1k_cnt + 1'b1;
            end
        end
    end
    
    assign clk_25m = clk_25m_reg;
    assign clk_1k = clk_1k_reg;
    assign locked = rst_n;  // 简化实现，实际使用PLL时需要连接PLL的locked信号

endmodule