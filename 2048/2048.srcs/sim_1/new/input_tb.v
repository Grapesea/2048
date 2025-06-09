// ========================================
// 输入控制模块测试平台
// ========================================

`ifdef SIM_INPUT_CONTROLLER

module tb_input_controller;
    
    // 测试信号定义
    reg         clk;
    reg         rst_n;
    reg         key_up_raw;
    reg         key_down_raw;
    reg         key_left_raw;
    reg         key_right_raw;
    reg         key_restart_raw;
    
    wire        key_up_pulse;
    wire        key_down_pulse;
    wire        key_left_pulse;
    wire        key_right_pulse;
    wire        key_restart_pulse;
    wire [2:0]  move_cmd;
    
    // 实例化被测试模块
    input_controller u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_up_raw(key_up_raw),
        .key_down_raw(key_down_raw),
        .key_left_raw(key_left_raw),
        .key_right_raw(key_right_raw),
        .key_restart_raw(key_restart_raw),
        .key_up_pulse(key_up_pulse),
        .key_down_pulse(key_down_pulse),
        .key_left_pulse(key_left_pulse),
        .key_right_pulse(key_right_pulse),
        .key_restart_pulse(key_restart_pulse),
        .move_cmd(move_cmd)
    );
    
    // 时钟生成 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns周期
    end
    
    // 测试序列
    initial begin
        // 初始化
        rst_n = 0;
        key_up_raw = 1;
        key_down_raw = 1;
        key_left_raw = 1;
        key_right_raw = 1;
        key_restart_raw = 1;
        
        // 复位释放
        #100;
        rst_n = 1;
        
        // 等待稳定
        #1000;
        
        // 测试上键
        $display("Testing UP key...");
        key_up_raw = 0;
        #25_000_000;  // 25ms按键保持
        key_up_raw = 1;
        #10_000_000;  // 10ms间隔
        
        // 测试下键
        $display("Testing DOWN key...");
        key_down_raw = 0;
        #25_000_000;
        key_down_raw = 1;
        #10_000_000;
        
        // 测试左键
        $display("Testing LEFT key...");
        key_left_raw = 0;
        #25_000_000;
        key_left_raw = 1;
        #10_000_000;
        
        // 测试右键
        $display("Testing RIGHT key...");
        key_right_raw = 0;
        #25_000_000;
        key_right_raw = 1;
        #10_000_000;
        
        // 测试重启键
        $display("Testing RESTART key...");
        key_restart_raw = 0;
        #25_000_000;
        key_restart_raw = 1;
        #10_000_000;
        
        // 测试按键抖动
        $display("Testing key bounce...");
        repeat(10) begin
            key_up_raw = 0;
            #1000;  // 1us
            key_up_raw = 1;
            #1000;
        end
        key_up_raw = 0;
        #25_000_000;
        key_up_raw = 1;
        
        #100_000_000;
        $finish;
    end
    
    // 监控输出
    always @(posedge clk) begin
        if (key_up_pulse) $display("Time: %t - UP pulse detected, move_cmd = %b", $time, move_cmd);
        if (key_down_pulse) $display("Time: %t - DOWN pulse detected, move_cmd = %b", $time, move_cmd);
        if (key_left_pulse) $display("Time: %t - LEFT pulse detected, move_cmd = %b", $time, move_cmd);
        if (key_right_pulse) $display("Time: %t - RIGHT pulse detected, move_cmd = %b", $time, move_cmd);
        if (key_restart_pulse) $display("Time: %t - RESTART pulse detected", $time);
    end

endmodule

`endif