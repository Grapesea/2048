module tb_input_controller();

    // 定义参数
    parameter CLK_PERIOD = 10; // 10ns = 100MHz
    parameter DEBOUNCE_TIME_NS = 20_000_000; // 20ms
    
    // 信号声明
    reg clk;
    reg rst_n;
    
    // 原始按键输入
    reg key_up_raw;
    reg key_down_raw;
    reg key_left_raw;
    reg key_right_raw;
    reg key_restart_raw;
    
    // 输出信号
    wire key_up_pulse;
    wire key_down_pulse;
    wire key_left_pulse;
    wire key_right_pulse;
    wire key_restart_pulse;
    wire [2:0] move_cmd;
    
    // 实例化被测模块
    input_controller uut (
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
    
    // 生成时钟
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 测试序列
    initial begin
        // 初始化信号
        rst_n = 0;
        key_up_raw = 1;
        key_down_raw = 1;
        key_left_raw = 1;
        key_right_raw = 1;
        key_restart_raw = 1;
        
        // 复位
        $display("[%0t] Applying reset...", $time);
        #100;
        rst_n = 1;
        $display("[%0t] Reset released", $time);
        #100;
        
        // 测试上键消抖和脉冲生成
        $display("[%0t] Testing UP key debounce and pulse generation...", $time);
        @(posedge clk);
        key_up_raw = 0;  // 直接操作信号而非通过任务
        #(DEBOUNCE_TIME_NS + 100);
        @(posedge clk);
        key_up_raw = 1;
        #100;
        
        // 测试下键消抖和脉冲生成
        $display("[%0t] Testing DOWN key debounce and pulse generation...", $time);
        @(posedge clk);
        key_down_raw = 0;
        #(DEBOUNCE_TIME_NS + 100);
        @(posedge clk);
        key_down_raw = 1;
        #100;
        
        // 测试左键消抖和脉冲生成
        $display("[%0t] Testing LEFT key debounce and pulse generation...", $time);
        @(posedge clk);
        key_left_raw = 0;
        #(DEBOUNCE_TIME_NS + 100);
        @(posedge clk);
        key_left_raw = 1;
        #100;
        
        // 测试右键消抖和脉冲生成
        $display("[%0t] Testing RIGHT key debounce and pulse generation...", $time);
        @(posedge clk);
        key_right_raw = 0;
        #(DEBOUNCE_TIME_NS + 100);
        @(posedge clk);
        key_right_raw = 1;
        #100;
        
        // 测试重启键消抖和脉冲生成
        $display("[%0t] Testing RESTART key debounce and pulse generation...", $time);
        @(posedge clk);
        key_restart_raw = 0;
        #(DEBOUNCE_TIME_NS + 100);
        @(posedge clk);
        key_restart_raw = 1;
        #100;
        
        // 测试多键同时按下的优先级
        $display("[%0t] Testing key priority when multiple keys are pressed...", $time);
        key_up_raw = 1; key_down_raw = 1; key_left_raw = 1; key_right_raw = 1; key_restart_raw = 1;
        #100;
        
        // 同时按下上和下
        @(posedge clk);
        key_up_raw = 0; key_down_raw = 0;
        $display("[%0t] Pressing UP and DOWN simultaneously", $time);
        #(DEBOUNCE_TIME_NS + 200);
        @(posedge clk);
        key_up_raw = 1; key_down_raw = 1;
        #100;
        
        // 同时按下下和左
        @(posedge clk);
        key_down_raw = 0; key_left_raw = 0;
        $display("[%0t] Pressing DOWN and LEFT simultaneously", $time);
        #(DEBOUNCE_TIME_NS + 200);
        @(posedge clk);
        key_down_raw = 1; key_left_raw = 1;
        #100;
        
        // 结束仿真
        $display("[%0t] Simulation completed successfully!", $time);
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("[%0t] rst_n=%b | key_up_raw=%b key_down_raw=%b key_left_raw=%b key_right_raw=%b key_restart_raw=%b | key_up_pulse=%b key_down_pulse=%b key_left_pulse=%b key_right_pulse=%b key_restart_pulse=%b | move_cmd=%b",
                 $time, rst_n, 
                 key_up_raw, key_down_raw, key_left_raw, key_right_raw, key_restart_raw,
                 key_up_pulse, key_down_pulse, key_left_pulse, key_right_pulse, key_restart_pulse,
                 move_cmd);
    end

endmodule    