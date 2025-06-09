module PS2(
    input clk,rst,          
    input ps2_clk, ps2_data,     
    output reg up,down,reg left,right,space    
);

// 状态机状态定义
localparam [1:0] 
    IDLE = 2'b00,         // 空闲状态
    GET_E0 = 2'b01,       // 收到扩展码E0
    GET_F0 = 2'b10,       // 收到断码F0
    GET_E0_F0 = 2'b11;    // 收到扩展码E0后收到F0

// 内部信号声明
reg [1:0] state, next_state;
reg [3:0] count;        // 位计数器（0-10）
reg [7:0] temp_data;    // 数据暂存寄存器
reg [7:0] data_byte;    // 完整数据字节
reg data_ready;         // 数据就绪标志
reg ps2_clk_reg0;       // PS/2时钟同步寄存器0
reg ps2_clk_reg1;       // PS/2时钟同步寄存器1
reg ps2_clk_reg2;       // PS/2时钟同步寄存器2
wire negedge_ps2_clk;   // PS/2时钟下降沿检测

// PS/2时钟同步和边沿检测
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ps2_clk_reg0 <= 1'b0;
        ps2_clk_reg1 <= 1'b0;
        ps2_clk_reg2 <= 1'b0;
    end 
    else begin
        ps2_clk_reg0 <= ps2_clk;
        ps2_clk_reg1 <= ps2_clk_reg0;
        ps2_clk_reg2 <= ps2_clk_reg1;
    end
end

assign negedge_ps2_clk = ps2_clk_reg2 & ~ps2_clk_reg1;

// 位计数器和数据采集
always @(posedge clk or posedge rst) begin
    if (rst) begin
        count <= 0;
        temp_data <= 0;
    end 
    else if (negedge_ps2_clk) begin
        if (count == 4'd10) begin
            count <= 0;
        end 
        else begin
            count <= count + 1;
            // 在数据位（2-9）采集数据
            if (count >= 2 && count <= 9) begin
                temp_data[count-2] <= ps2_data;
            end
        end
    end
end

// 数据就绪标志生成
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_ready <= 0;
        data_byte <= 0;
    end else if (negedge_ps2_clk && count == 4'd10) begin
        data_ready <= 1;
        data_byte <= temp_data;
    end else begin
        data_ready <= 0;
    end
end

// 状态机状态转移
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 状态机逻辑和按键处理
always @(*) begin
    // 默认状态转移
    next_state = state;
    
    // 默认按键状态保持不变
    up    = up;
    down  = down;
    left  = left;
    right = right;
    space = space;
    
    if (data_ready) begin
        case (state)
            IDLE: begin
                case (data_byte)
                    8'hE0: next_state = GET_E0;   // 检测到扩展码
                    8'hF0: next_state = GET_F0;   // 检测到断码
                    default: begin
                        // 处理普通按键（空格）
                        if (data_byte == 8'h29) space = 1'b1;
                    end
                endcase
            end
            
            GET_F0: 
            begin
                // 处理普通按键的断码
                if (data_byte == 8'h29) space = 1'b0;
                next_state = IDLE;
            end
            
            GET_E0: 
            begin
                if (data_byte == 8'hF0) begin
                    next_state = GET_E0_F0;  // 扩展按键的断码
                end else begin
                    // 处理扩展按键的通码
                    case (data_byte)
                        8'h75: up    = 1'b1;  // 上
                        8'h72: down  = 1'b1;  // 下
                        8'h6B: left  = 1'b1;  // 左
                        8'h74: right = 1'b1;  // 右
                    endcase
                    next_state = IDLE;
                end
            end
            
            GET_E0_F0: 
            begin
                // 处理扩展按键的断码
                case (data_byte)
                    8'h75: up    = 1'b0;  // 上
                    8'h72: down  = 1'b0;  // 下
                    8'h6B: left  = 1'b0;  // 左
                    8'h74: right = 1'b0;  // 右
                endcase
                next_state = IDLE;
            end
        endcase
    end
end

// 按键状态寄存器（时序逻辑部分）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        up    <= 0;
        down  <= 0;
        left  <= 0;
        right <= 0;
        space <= 0;
    end else begin
        // 状态机输出直接驱动寄存器
        up    <= up;
        down  <= down;
        left  <= left;
        right <= right;
        space <= space;
    end
end

endmodule