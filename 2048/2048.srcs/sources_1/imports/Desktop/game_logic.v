// 2048游戏移动逻辑完整实现
module game_2048_move (
    input wire clk,
    input wire rst_n,
    input wire [1:0] move_direction,  // DIR_LEFT=0, DIR_RIGHT=1, DIR_UP=2, DIR_DOWN=3
    input wire move_start,
    output reg move_valid,
    output reg [19:0] current_score,
    output reg [19:0] best_score,
    output reg move_done
);

    // 方向定义
    parameter DIR_LEFT  = 2'b00;
    parameter DIR_RIGHT = 2'b01;
    parameter DIR_UP    = 2'b10;
    parameter DIR_DOWN  = 2'b11;
    
    // 空值定义
    parameter VAL_EMPTY = 5'b00000;
    
    // 游戏矩阵 4x4，每个元素5位
    reg [79:0] game_matrix;  // 4*4*5 = 80位
    reg [79:0] matrix_backup;
    
    // 临时处理变量
    reg [4:0] temp_line_0, temp_line_1, temp_line_2, temp_line_3;
    reg [4:0] compressed[3:0];
    reg [4:0] new_line[3:0];
    reg [1:0] compress_count;
    reg [19:0] line_score;
    reg [19:0] move_score;
    reg move_changed;
    
    // 状态机相关
    reg [3:0] process_counter;
    reg [1:0] current_col;
    reg [1:0] current_row;
    
    // 矩阵元素访问函数
    function [4:0] get_matrix_element;
        input [1:0] row;
        input [1:0] col;
        begin
            get_matrix_element = game_matrix[((row)*4+col)*5 +:5];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            game_matrix <= 80'h0;
            current_score <= 20'h0;
            best_score <= 20'h0;
            move_valid <= 1'b0;
            move_done <= 1'b0;
            process_counter <= 4'h0;
        end else if (move_start) begin
            matrix_backup <= game_matrix;
            move_score <= 20'h0;
            move_changed <= 1'b0;
            move_done <= 1'b0;
            process_counter <= 4'h1;
        end else if (process_counter != 4'h0) begin
            process_counter <= process_counter + 1;
            
            case (process_counter)
                // 处理第0行/列（补全向上/向下方向的列数据提取）
                4'd1: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            temp_line_0 <= get_matrix_element(0,0);
                            temp_line_1 <= get_matrix_element(0,1);
                            temp_line_2 <= get_matrix_element(0,2);
                            temp_line_3 <= get_matrix_element(0,3);
                        end
                        DIR_RIGHT: begin
                            temp_line_0 <= get_matrix_element(0,3);
                            temp_line_1 <= get_matrix_element(0,2);
                            temp_line_2 <= get_matrix_element(0,1);
                            temp_line_3 <= get_matrix_element(0,0);
                        end
                        DIR_UP: begin  // 向上移动：按列提取数据（当前列=0）
                            temp_line_0 <= get_matrix_element(0, 0);  // 行0，列0
                            temp_line_1 <= get_matrix_element(1, 0);  // 行1，列0
                            temp_line_2 <= get_matrix_element(2, 0);  // 行2，列0
                            temp_line_3 <= get_matrix_element(3, 0);  // 行3，列0
                        end
                        DIR_DOWN: begin  // 向下移动：按列逆序提取数据（当前列=0）
                            temp_line_0 <= get_matrix_element(3, 0);  // 行3，列0
                            temp_line_1 <= get_matrix_element(2, 0);  // 行2，列0
                            temp_line_2 <= get_matrix_element(1, 0);  // 行1，列0
                            temp_line_3 <= get_matrix_element(0, 0);  // 行0，列0
                        end
                    endcase
                end

                // 压缩合并逻辑（以列为单位处理上下方向）
                4'd2: begin
                    // 压缩空值（移除VAL_EMPTY）
                    compressed[0] = VAL_EMPTY;
                    compressed[1] = VAL_EMPTY;
                    compressed[2] = VAL_EMPTY;
                    compressed[3] = VAL_EMPTY;
                    compress_count = 2'd0;
                    
                    if (temp_line_0 != VAL_EMPTY) begin
                        compressed[0] = temp_line_0;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_1 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_1;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_2 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_2;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_3 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_3;
                        compress_count = compress_count + 1;
                    end

                    // 合并相邻相同值
                    line_score = 20'd0;
                    if (compressed[0] == compressed[1] && compressed[0] != VAL_EMPTY) begin
                        compressed[0] = compressed[0] + 1;  // 数值以2的幂次存储，+1表示乘以2
                        line_score = line_score + (2 << (compressed[0]-1));  // 计算得分
                        compressed[1] = VAL_EMPTY;
                        // 向前移动后续元素
                        compressed[1] = compressed[2];
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[1] == compressed[2] && compressed[1] != VAL_EMPTY) begin
                        compressed[1] = compressed[1] + 1;
                        line_score = line_score + (2 << (compressed[1]-1));
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[2] == compressed[3] && compressed[2] != VAL_EMPTY) begin
                        compressed[2] = compressed[2] + 1;
                        line_score = line_score + (2 << (compressed[2]-1));
                        compressed[3] = VAL_EMPTY;
                    end

                    // 最终压缩
                    new_line[0] = compressed[0];
                    new_line[1] = compressed[1];
                    new_line[2] = compressed[2];
                    new_line[3] = compressed[3];
                end

                // 写回矩阵（根据方向调整顺序）
                4'd3: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            game_matrix[((0)*4+0)*5 +:5] <= new_line[0];
                            game_matrix[((0)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((0)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((0)*4+3)*5 +:5] <= new_line[3];
                        end
                        DIR_RIGHT: begin
                            game_matrix[((0)*4+0)*5 +:5] <= new_line[3];
                            game_matrix[((0)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((0)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((0)*4+3)*5 +:5] <= new_line[0];
                        end
                        DIR_UP: begin  // 向上移动：按列写回（当前列=0）
                            game_matrix[((0)*4+0)*5 +:5] <= new_line[0];  // 行0，列0
                            game_matrix[((1)*4+0)*5 +:5] <= new_line[1];  // 行1，列0
                            game_matrix[((2)*4+0)*5 +:5] <= new_line[2];  // 行2，列0
                            game_matrix[((3)*4+0)*5 +:5] <= new_line[3];  // 行3，列0
                        end
                        DIR_DOWN: begin  // 向下移动：按列逆序写回（当前列=0）
                            game_matrix[((0)*4+0)*5 +:5] <= new_line[3];  // 行0，列0（逆序后最低位）
                            game_matrix[((1)*4+0)*5 +:5] <= new_line[2];  // 行1，列0
                            game_matrix[((2)*4+0)*5 +:5] <= new_line[1];  // 行2，列0
                            game_matrix[((3)*4+0)*5 +:5] <= new_line[0];  // 行3，列0（逆序后最高位）
                        end
                    endcase
                    move_score <= move_score + line_score;
                end

                // 处理第1行/列
                4'd4: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            temp_line_0 <= get_matrix_element(1,0);
                            temp_line_1 <= get_matrix_element(1,1);
                            temp_line_2 <= get_matrix_element(1,2);
                            temp_line_3 <= get_matrix_element(1,3);
                        end
                        DIR_RIGHT: begin
                            temp_line_0 <= get_matrix_element(1,3);
                            temp_line_1 <= get_matrix_element(1,2);
                            temp_line_2 <= get_matrix_element(1,1);
                            temp_line_3 <= get_matrix_element(1,0);
                        end
                        DIR_UP: begin
                            temp_line_0 <= get_matrix_element(0, 1);
                            temp_line_1 <= get_matrix_element(1, 1);
                            temp_line_2 <= get_matrix_element(2, 1);
                            temp_line_3 <= get_matrix_element(3, 1);
                        end
                        DIR_DOWN: begin
                            temp_line_0 <= get_matrix_element(3, 1);
                            temp_line_1 <= get_matrix_element(2, 1);
                            temp_line_2 <= get_matrix_element(1, 1);
                            temp_line_3 <= get_matrix_element(0, 1);
                        end
                    endcase
                end

                4'd5: begin
                    // 重复压缩合并逻辑
                    compressed[0] = VAL_EMPTY;
                    compressed[1] = VAL_EMPTY;
                    compressed[2] = VAL_EMPTY;
                    compressed[3] = VAL_EMPTY;
                    compress_count = 2'd0;
                    
                    if (temp_line_0 != VAL_EMPTY) begin
                        compressed[0] = temp_line_0;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_1 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_1;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_2 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_2;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_3 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_3;
                        compress_count = compress_count + 1;
                    end

                    line_score = 20'd0;
                    if (compressed[0] == compressed[1] && compressed[0] != VAL_EMPTY) begin
                        compressed[0] = compressed[0] + 1;
                        line_score = line_score + (2 << (compressed[0]-1));
                        compressed[1] = compressed[2];
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[1] == compressed[2] && compressed[1] != VAL_EMPTY) begin
                        compressed[1] = compressed[1] + 1;
                        line_score = line_score + (2 << (compressed[1]-1));
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[2] == compressed[3] && compressed[2] != VAL_EMPTY) begin
                        compressed[2] = compressed[2] + 1;
                        line_score = line_score + (2 << (compressed[2]-1));
                        compressed[3] = VAL_EMPTY;
                    end

                    new_line[0] = compressed[0];
                    new_line[1] = compressed[1];
                    new_line[2] = compressed[2];
                    new_line[3] = compressed[3];
                end

                4'd6: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            game_matrix[((1)*4+0)*5 +:5] <= new_line[0];
                            game_matrix[((1)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((1)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((1)*4+3)*5 +:5] <= new_line[3];
                        end
                        DIR_RIGHT: begin
                            game_matrix[((1)*4+0)*5 +:5] <= new_line[3];
                            game_matrix[((1)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((1)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((1)*4+3)*5 +:5] <= new_line[0];
                        end
                        DIR_UP: begin
                            game_matrix[((0)*4+1)*5 +:5] <= new_line[0];
                            game_matrix[((1)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((2)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((3)*4+1)*5 +:5] <= new_line[3];
                        end
                        DIR_DOWN: begin
                            game_matrix[((0)*4+1)*5 +:5] <= new_line[3];
                            game_matrix[((1)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((2)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((3)*4+1)*5 +:5] <= new_line[0];
                        end
                    endcase
                    move_score <= move_score + line_score;
                end

                // 处理第2行/列
                4'd7: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            temp_line_0 <= get_matrix_element(2,0);
                            temp_line_1 <= get_matrix_element(2,1);
                            temp_line_2 <= get_matrix_element(2,2);
                            temp_line_3 <= get_matrix_element(2,3);
                        end
                        DIR_RIGHT: begin
                            temp_line_0 <= get_matrix_element(2,3);
                            temp_line_1 <= get_matrix_element(2,2);
                            temp_line_2 <= get_matrix_element(2,1);
                            temp_line_3 <= get_matrix_element(2,0);
                        end
                        DIR_UP: begin
                            temp_line_0 <= get_matrix_element(0, 2);
                            temp_line_1 <= get_matrix_element(1, 2);
                            temp_line_2 <= get_matrix_element(2, 2);
                            temp_line_3 <= get_matrix_element(3, 2);
                        end
                        DIR_DOWN: begin
                            temp_line_0 <= get_matrix_element(3, 2);
                            temp_line_1 <= get_matrix_element(2, 2);
                            temp_line_2 <= get_matrix_element(1, 2);
                            temp_line_3 <= get_matrix_element(0, 2);
                        end
                    endcase
                end

                4'd8: begin
                    // 重复压缩合并逻辑
                    compressed[0] = VAL_EMPTY;
                    compressed[1] = VAL_EMPTY;
                    compressed[2] = VAL_EMPTY;
                    compressed[3] = VAL_EMPTY;
                    compress_count = 2'd0;
                    
                    if (temp_line_0 != VAL_EMPTY) begin
                        compressed[0] = temp_line_0;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_1 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_1;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_2 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_2;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_3 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_3;
                        compress_count = compress_count + 1;
                    end

                    line_score = 20'd0;
                    if (compressed[0] == compressed[1] && compressed[0] != VAL_EMPTY) begin
                        compressed[0] = compressed[0] + 1;
                        line_score = line_score + (2 << (compressed[0]-1));
                        compressed[1] = compressed[2];
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[1] == compressed[2] && compressed[1] != VAL_EMPTY) begin
                        compressed[1] = compressed[1] + 1;
                        line_score = line_score + (2 << (compressed[1]-1));
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[2] == compressed[3] && compressed[2] != VAL_EMPTY) begin
                        compressed[2] = compressed[2] + 1;
                        line_score = line_score + (2 << (compressed[2]-1));
                        compressed[3] = VAL_EMPTY;
                    end

                    new_line[0] = compressed[0];
                    new_line[1] = compressed[1];
                    new_line[2] = compressed[2];
                    new_line[3] = compressed[3];
                end

                4'd9: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            game_matrix[((2)*4+0)*5 +:5] <= new_line[0];
                            game_matrix[((2)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((2)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((2)*4+3)*5 +:5] <= new_line[3];
                        end
                        DIR_RIGHT: begin
                            game_matrix[((2)*4+0)*5 +:5] <= new_line[3];
                            game_matrix[((2)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((2)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((2)*4+3)*5 +:5] <= new_line[0];
                        end
                        DIR_UP: begin
                            game_matrix[((0)*4+2)*5 +:5] <= new_line[0];
                            game_matrix[((1)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((2)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((3)*4+2)*5 +:5] <= new_line[3];
                        end
                        DIR_DOWN: begin
                            game_matrix[((0)*4+2)*5 +:5] <= new_line[3];
                            game_matrix[((1)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((2)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((3)*4+2)*5 +:5] <= new_line[0];
                        end
                    endcase
                    move_score <= move_score + line_score;
                end

                // 处理第3行/列
                4'd10: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            temp_line_0 <= get_matrix_element(3,0);
                            temp_line_1 <= get_matrix_element(3,1);
                            temp_line_2 <= get_matrix_element(3,2);
                            temp_line_3 <= get_matrix_element(3,3);
                        end
                        DIR_RIGHT: begin
                            temp_line_0 <= get_matrix_element(3,3);
                            temp_line_1 <= get_matrix_element(3,2);
                            temp_line_2 <= get_matrix_element(3,1);
                            temp_line_3 <= get_matrix_element(3,0);
                        end
                        DIR_UP: begin
                            temp_line_0 <= get_matrix_element(0, 3);
                            temp_line_1 <= get_matrix_element(1, 3);
                            temp_line_2 <= get_matrix_element(2, 3);
                            temp_line_3 <= get_matrix_element(3, 3);
                        end
                        DIR_DOWN: begin
                            temp_line_0 <= get_matrix_element(3, 3);
                            temp_line_1 <= get_matrix_element(2, 3);
                            temp_line_2 <= get_matrix_element(1, 3);
                            temp_line_3 <= get_matrix_element(0, 3);
                        end
                    endcase
                end

                4'd11: begin
                    // 重复压缩合并逻辑
                    compressed[0] = VAL_EMPTY;
                    compressed[1] = VAL_EMPTY;
                    compressed[2] = VAL_EMPTY;
                    compressed[3] = VAL_EMPTY;
                    compress_count = 2'd0;
                    
                    if (temp_line_0 != VAL_EMPTY) begin
                        compressed[0] = temp_line_0;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_1 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_1;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_2 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_2;
                        compress_count = compress_count + 1;
                    end
                    if (temp_line_3 != VAL_EMPTY) begin
                        compressed[compress_count] = temp_line_3;
                        compress_count = compress_count + 1;
                    end

                    line_score = 20'd0;
                    if (compressed[0] == compressed[1] && compressed[0] != VAL_EMPTY) begin
                        compressed[0] = compressed[0] + 1;
                        line_score = line_score + (2 << (compressed[0]-1));
                        compressed[1] = compressed[2];
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[1] == compressed[2] && compressed[1] != VAL_EMPTY) begin
                        compressed[1] = compressed[1] + 1;
                        line_score = line_score + (2 << (compressed[1]-1));
                        compressed[2] = compressed[3];
                        compressed[3] = VAL_EMPTY;
                    end
                    if (compressed[2] == compressed[3] && compressed[2] != VAL_EMPTY) begin
                        compressed[2] = compressed[2] + 1;
                        line_score = line_score + (2 << (compressed[2]-1));
                        compressed[3] = VAL_EMPTY;
                    end

                    new_line[0] = compressed[0];
                    new_line[1] = compressed[1];
                    new_line[2] = compressed[2];
                    new_line[3] = compressed[3];
                end

                4'd12: begin
                    case (move_direction)
                        DIR_LEFT: begin
                            game_matrix[((3)*4+0)*5 +:5] <= new_line[0];
                            game_matrix[((3)*4+1)*5 +:5] <= new_line[1];
                            game_matrix[((3)*4+2)*5 +:5] <= new_line[2];
                            game_matrix[((3)*4+3)*5 +:5] <= new_line[3];
                        end
                        DIR_RIGHT: begin
                            game_matrix[((3)*4+0)*5 +:5] <= new_line[3];
                            game_matrix[((3)*4+1)*5 +:5] <= new_line[2];
                            game_matrix[((3)*4+2)*5 +:5] <= new_line[1];
                            game_matrix[((3)*4+3)*5 +:5] <= new_line[0];
                        end
                        DIR_UP: begin
                            game_matrix[((0)*4+3)*5 +:5] <= new_line[0];
                            game_matrix[((1)*4+3)*5 +:5] <= new_line[1];
                            game_matrix[((2)*4+3)*5 +:5] <= new_line[2];
                            game_matrix[((3)*4+3)*5 +:5] <= new_line[3];
                        end
                        DIR_DOWN: begin
                            game_matrix[((0)*4+3)*5 +:5] <= new_line[3];
                            game_matrix[((1)*4+3)*5 +:5] <= new_line[2];
                            game_matrix[((2)*4+3)*5 +:5] <= new_line[1];
                            game_matrix[((3)*4+3)*5 +:5] <= new_line[0];
                        end
                    endcase
                    move_score <= move_score + line_score;
                end

                // 移动完成后更新状态
                4'd13: begin
                    current_score <= current_score + move_score;
                    move_changed <= (game_matrix != matrix_backup);
                    move_valid <= move_changed;
                    // 更新最高分
                    if ((current_score + move_score) > best_score) begin
                        best_score <= current_score + move_score;
                    end
                    move_done <= 1'b1;
                    process_counter <= 4'h0;  // 重置状态机
                end

                default: begin
                    process_counter <= 4'h0;
                end
            endcase
        end
    end

endmodule