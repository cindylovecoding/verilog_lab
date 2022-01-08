/*`define h_pixel 640;
`define h_front_porch 16;
`define h_sync_pulse 96;
`define h_back_porch 48;
`define v_pixel 480;
`define v_front_porch 10;
`define v_sync_pulse 2;
`define v_back_porch 33;
*/
module clk_divider_25MHz(input clk,input reset,output reg divided_clk);

    always@(posedge clk or negedge reset) 
        begin
	        if(!reset) 
	            begin
		            divided_clk <= 1'b0;
    	            end
	        else   
	            begin
		            divided_clk <= ~divided_clk;
	            end
        end
endmodule
module clk_divider_2Hz(input clk,input reset,output reg divided_clk);

    reg [31:0] counter=31'd0;
    always@(posedge clk or negedge reset) 
        begin
	        if(!reset) 
	            begin
		            counter <= 31'd0;
		            divided_clk <= 1'd0;
	            end
	        else 
	            begin
		            if(counter == 31'd12500000) 
		                begin
			                counter <= 31'd0;
			                divided_clk <= ~divided_clk;
		                end
		            else    
		                begin
			                counter <= counter + 31'd1;
		                end
	            end

        end
endmodule
module clk_divider_100Hz(input clk,input reset,output reg divided_clk);

    reg [31:0] counter=31'd0;
    always@(posedge clk or negedge reset) 
        begin
	        if(!reset) 
	                begin
		            counter <= 31'd0;
		            divided_clk <= 1'd0;
            		end
        	else 
        	    begin
	               	if(counter == 31'd250000) 
    	         	        begin
    			            counter <= 31'd0;
    	        		    divided_clk <= ~divided_clk;
    	            		end
    	        	else 
    	        	        begin
    			            counter <= counter + 31'd1;
    		                end
            	end
        end
endmodule
module h_sync_signal(input [15:0] h_count_value,output h_sync);

    parameter h_pixel = 640,
			 h_front_porch = 16,
			 h_sync_pulse = 96,
			 h_back_porch = 48;

    assign h_sync = (h_count_value < h_sync_pulse);
endmodule

module horizontal_counter(input clk_25MHz,input reset,output reg [15:0] h_count_value = 16'd0,output enable_v_counter);

    assign enable_v_counter = (h_count_value == 16'd799);
    always@(posedge clk_25MHz or negedge reset) 
        begin
	        if(!reset) 
	            begin
		            h_count_value <= 16'd0;
	            end
	        else if(h_count_value == 16'd799) 
	            begin
		            h_count_value <= 16'd0;
            	end
	        else
	            begin
		            h_count_value <= h_count_value + 16'd1;
	            end
        end
endmodule

module v_sync_signal(input [16:0] v_count_value,output v_sync);

    parameter v_pixel = 480,
			 v_front_porch = 10,
			 v_sync_pulse = 2,
			 v_back_porch = 33;
    assign v_sync = (v_count_value<v_sync_pulse);
endmodule

module vertical_counter(input clk_25MHz,input reset,input enable_v_counter,output reg [15:0] v_count_value = 16'd0);
    always@(posedge clk_25MHz or negedge reset)
        begin
	        if(!reset)
	            begin
	            	v_count_value <= 16'd0;
	            end
	        else 
	            begin
		            if(enable_v_counter)
		                begin
			                if(v_count_value == 16'd524) 
			                    begin
				                    v_count_value <= 16'd0;
			                    end
			                else 
			                    begin
				                    v_count_value <= v_count_value + 16'd1;
			                    end
		                end
	            end
        end
endmodule

module check_on_display(input [15:0] h_count_value,input [15:0] v_count_value,output on_display);
    parameter h_pixel = 640,
			 h_front_porch = 16,
			 h_sync_pulse = 96,
			 h_back_porch = 48;

    parameter h_wait_time = h_sync_pulse + h_back_porch,
			 h_display_over_time = h_wait_time + h_pixel - 1;
			 
    parameter v_pixel = 480,
			 v_front_porch = 10,
			 v_sync_pulse = 2,
			 v_back_porch = 33;
    parameter v_wait_time = v_sync_pulse + v_back_porch,
			 v_display_over_time = v_wait_time + v_pixel - 1;
    assign on_display = (h_count_value >= h_wait_time && h_count_value <= h_display_over_time && v_count_value >= v_wait_time && v_count_value <= v_display_over_time);
endmodule

module output_rgb_signal(input on_display,input [3:0] red_input,input [3:0] green_input,input [3:0] blue_input,output [3:0] red_output,output [3:0] green_output,output [3:0] blue_output);

    assign red_output = (on_display) ? red_input:4'h0;
    assign green_output = (on_display) ? green_input:4'h0;
    assign blue_output = (on_display) ? blue_input:4'h0;
endmodule


module KeypadController(clk_100Hz, reset, keypadCol, keypadRow, direction);
    input clk_100Hz, reset;
    input [3:0]keypadCol;
    output reg [3:0]keypadRow;
    
    output reg [1:0]direction;
    parameter UP = 2'd0, DOWN = 2'd1, RIGHT = 2'd2, LEFT = 2'd3;
    
    always@(posedge clk_100Hz or negedge reset)
    begin
        if(!reset)
        begin
            keypadRow = 4'b1110;
            direction = RIGHT;// default direction: right
        end
        else
        begin
            case({keypadRow, keypadCol})
                8'b1011_1101:begin
                    direction <= UP;
                end// press 6
                8'b1110_1101:begin
                    direction <= DOWN;
                end// press 4
                8'b1101_1110:begin
                    direction <= RIGHT;
                end// press 8
                8'b1101_1011:begin
                    direction <= LEFT;
                end// press 2
                default:begin
                    direction <= direction;// maintain previous direction
                end// press invalid buttons
            endcase
            // decide direction
            
            case(keypadRow)
                4'b1110:begin
                    keypadRow <= 4'b1101;
                end
                4'b1101:begin
                    keypadRow <= 4'b1011;
                end
                4'b1011:begin
                    keypadRow <= 4'b0111;
                end
                4'b0111:begin
                    keypadRow <= 4'b1110;
                end
                default:begin
                    keypadRow <= 4'b1110;
                end
            endcase
            // next row
        end
    end
endmodule
module snake(input clk,input reset,input [3:0] keypadCol,output [3:0] keypadRow,output H_sync,output V_sync,output [3:0] red,output [3:0] green,output [3:0] blue,output [6:0] result_ten,output [6:0] result_one);

    wire clk_25MHz;
    wire clk_2Hz;
    wire clk_100Hz;
    wire enable_v_counter;
    wire [15:0] h_count_value;
    wire [15:0] v_count_value;
    wire on_display;
    wire [3:0] red_wire;
    wire [3:0] green_wire;
    wire [3:0] blue_wire;
    wire [1:0] direction;
    clk_divider_2Hz my_clk_divider_2Hz(clk,reset,clk_2Hz);
    clk_divider_25MHz my_clk_divider_25MHz(clk,reset,clk_25MHz);
    clk_divider_100Hz my_clk_divider_100Hz(clk,reset,clk_100Hz);
    horizontal_counter my_horizontal_counter(clk_25MHz,reset,h_count_value,enable_v_counter);
    vertical_counter my_vertical_counter(clk_25MHz,reset,enable_v_counter,v_count_value);
    h_sync_signal my_h_sync_signal(h_count_value,H_sync);
    v_sync_signal my_v_sync_signal(v_count_value,V_sync);
    check_on_display my_check_on_display(h_count_value,v_count_value,on_display);
    output_rgb_signal my_output_rgb_signal(on_display,red_wire,green_wire,blue_wire,red,green,blue);
    KeypadController(clk_100Hz, reset, keypadCol, keypadRow, direction);

    /*葉惟欣 七段顯示器*/
    wire [6:0] result_ten,result_one;
    display_ten my_ten(ten,result_ten); 
    display_one my_one(one,result_one); 
    /*葉惟欣 七段顯示器*/
    parameter h_pixel = 640,
			 h_front_porch = 16,
			 h_sync_pulse = 96,
			 h_back_porch = 48;

    parameter h_wait_time = h_sync_pulse + h_back_porch,
			 h_display_over_time = h_wait_time + h_pixel - 1;
			 
    parameter v_pixel = 480,
			 v_front_porch = 10,
			 v_sync_pulse = 2,
			 v_back_porch = 33;
    parameter v_wait_time = v_sync_pulse + v_back_porch,
			 v_display_over_time = v_wait_time + v_pixel - 1;

    reg [6:0] snake_len=7'd0;
    reg [6:0] array_of_snake_x_position[127:0];
    reg [6:0] array_of_snake_y_position[127:0];
    reg [3:0] green_reg;
    /*七段顯示器***/
    reg [3:0] ten;
    reg [3:0] one; 
    /*葉惟欣 apple*/
    reg [127:0] MAX_x;
    reg [127:0] MAX_y;
    reg [127:0] MIN_x;
    reg [127:0] MIN_y;
    reg [127:0] score;
    reg right,up,appear;     //食物相對蛇的位置是否在上或下 ，右或左
    /*葉惟欣*/
    reg found;
    assign green_wire = green_reg;
    integer len_counter_s;
    initial 
        begin
            array_of_snake_x_position[0]=7'd5;
            array_of_snake_y_position[0]=7'd0;
            array_of_snake_x_position[1]=7'd4;
            array_of_snake_y_position[1]=7'd0;
            array_of_snake_x_position[2]=7'd3;
            array_of_snake_y_position[2]=7'd0;
            array_of_snake_x_position[3]=7'd2;
            array_of_snake_y_position[3]=7'd0;
            array_of_snake_x_position[4]=7'd1;
            array_of_snake_y_position[4]=7'd0;
            array_of_snake_x_position[5]=7'd0;
            array_of_snake_y_position[5]=7'd0;
            /*葉惟欣 蛇目前的位置*/
            MAX_x = array_of_snake_x_position[0]; //蛇目前最右邊的位置
            MAX_y = array_of_snake_y_position[0]; //蛇目前最高的位置
            MIN_x = array_of_snake_x_position[0]; //蛇目前最左的位置
            MIN_y = array_of_snake_y_position[0]; //蛇目前最低的位置
            score = 7'd0;
            appear = 1'd1;
            /*葉惟欣*/
        end
    always@(posedge clk_25MHz or negedge reset) 
        begin
	        if(!reset) 
	            begin
		            green_reg <= 4'h0;
	            end
	       else 
	            begin
		            found = 1'd0;
		            for(len_counter_s = 0;len_counter_s < 128;len_counter_s = len_counter_s + 1) 
		                begin
			                if(!found && len_counter_s <= snake_len)
			                    begin
				                    if((h_count_value > h_wait_time + array_of_snake_x_position[len_counter_s] * 10) && (h_count_value < h_wait_time + (array_of_snake_x_position[len_counter_s] + 1) * 10) && (v_count_value > v_wait_time + array_of_snake_y_position[len_counter_s] * 10) && (v_count_value < v_wait_time + (array_of_snake_y_position[len_counter_s] + 1) * 10)) 
				                        begin
					                        green_reg <= 4'hf;
					                        found = 1'd1;
				                        end
				                    else 
				                        begin
					                        green_reg <= 4'h0;
				                        end
			                    end
		                end
	            end
            end

    integer len_counter_p;
    always@(posedge clk_2Hz or negedge reset) 
        begin
	        if(!reset) 
	            begin
		            //
	            end
	        else 
	            begin
		            for(len_counter_p = 127;len_counter_p > 0;len_counter_p=len_counter_p - 1) 
		                begin
			                if(len_counter_p <= snake_len + 1) 
			                    begin
				                    array_of_snake_x_position[len_counter_p] <= array_of_snake_x_position[len_counter_p-1];
				                    array_of_snake_y_position[len_counter_p] <= array_of_snake_y_position[len_counter_p-1];
			                    end
		                end
		            case(direction)
		                //葉惟欣
			            2'd0: //往上
			                begin 
				                array_of_snake_y_position[0] <= array_of_snake_y_position[0] - 7'd1;
				                MIN_Y = array_of_snake_y_position[0];
			                end
			            2'd1: //往下
			                begin
				                array_of_snake_y_position[0] <= array_of_snake_y_position[0] + 7'd1;
				                MAX_Y = array_of_snake_y_position[0];
			                end
			            2'd2: //往右
			                begin
				                array_of_snake_x_position[0] <= array_of_snake_x_position[0] + 7'd1;
				                MAX_x = array_of_snake_x_position[0];
			                end
			            2'd3: //往左
			                begin
				                array_of_snake_x_position[0] <= array_of_snake_x_position[0] - 7'd1;
				                MIN_x = array_of_snake_x_position[0];
			                end
			            //葉惟欣
		            endcase
		            if(is_collision) 
		                begin
			                snake_len <= snake_len + 7'd1;
		                end
	            end
        end

        reg [3:0] red_reg;
        reg [6:0] apple_x_position=7'd30;
        reg [6:0] apple_y_position=7'd20;
        /*吃到生成  葉惟欣***********************************************************/
        always@(posedge is_collision or negedge appear)
            begin
                right <= {$random}%2;
                up <= {$random}%2;
                appear <= 1'd0; //食物還沒有出現
                if(right == 1'd1 && MAX_X!= 7'd127)
                    begin
                        apple_x_position <= MAX_X + {$random}%(7'd127-MAX_X); //只要食物的位置比蛇目前的位置還更高就不會有衝突
                        if(up == 1'd1 && MAX_Y!= 7'd127)
                            begin
                                apple_y_position <= MAX_Y + {$random}%(7'd127-MAX_Y);
                                appear <= 1'd1; //食物出現
                                score <= score + 7'd1;
                            end
                        else if(up == 1'd0 && MIN_Y!= 7'd0)
                            begin
                                apple_y_position <= MIN_Y - {$random}%(MIN_Y);
                                appear <= 1'd1; //食物出現
                                score <= score + 7'd1;
                            end
                    end
                else if(right == 1'd0 && MIN_X!= 7'd0)
                    begin
                        apple_x_position <= MIN_X - {$random}%(MIN_X); //只要食物的位置比蛇目前的位置還更低就不會有衝突
                        if(up == 1'd1 && MAX_Y!= 7'd127)
                            begin
                                apple_y_position <= MAX_Y + {$random}%(7'd127-MAX_Y);
                                appear <= 1'd1; //食物出現
                                score <= score + 7'd1;
                            end
                        else if(up == 1'd0 && MIN_Y!= 7'd0)
                            begin
                                apple_y_position <= MIN_Y - {$random}%(MIN_Y);
                                appear <= 1'd1; //食物出現
                                score <= score + 7'd1;
                            end
                    end
                one <= score %10;
                ten <= score /10;
            end
        
        /*吃到生成***********************************************************/
        wire is_collision;
        assign is_collision = ((array_of_snake_x_position[0] == apple_x_position) && (array_of_snake_y_position[0] == apple_y_position));
        assign red_wire = red_reg;
        always@(posedge clk_25MHz or negedge reset) 
            begin
	            if(!reset) 
	                begin
		                red_reg <= 4'h0;
	                end
	            else 
	                begin
		                if((h_count_value > h_wait_time + apple_x_position * 10) && (h_count_value < h_wait_time + (apple_x_position + 1) * 10) && (v_count_value > v_wait_time + apple_y_position * 10) && (v_count_value < v_wait_time + (apple_y_position + 1) * 10)) 
		                    begin
			                    red_reg <= 4'hf;
		                    end
		                else 
		                    begin
			                    red_reg <= 4'h0;
		                    end
	                end
            end
endmodule
/********葉惟欣************************/
module display_one(one,result_one); 
    input [3:0] one; 
    output [6:0] result_one; 
    reg [6:0] result_one; 
    always@(one) 
        begin 
            case(one) 
                4'd0 :result_one = 7'b1000000; 
                4'd1 :result_one = 7'b1111001; 
                4'd2 :result_one = 7'b0100100; 
                4'd3 :result_one = 7'b0110000; 
                4'd4 :result_one = 7'b0011001; 
                4'd5 :result_one = 7'b0010010; 
                4'd6 :result_one = 7'b0000010; 
                4'd7 :result_one = 7'b1111000; 
                4'd8 :result_one = 7'b0000000; 
                4'd9 :result_one = 7'b0010000; 
            endcase 
        end 
endmodule 
module display_ten(ten,result_ten); 
    input [3:0] ten; 
    output [6:0] result_one; 
    reg [6:0] result_one; 
    always@(ten) 
        begin 
            case(ten) 
                4'd0 :result_ten = 7'b1000000; 
                4'd1 :result_ten = 7'b1111001; 
                4'd2 :result_ten = 7'b0100100; 
                4'd3 :result_ten = 7'b0110000; 
                4'd4 :result_ten = 7'b0011001; 
                4'd5 :result_ten = 7'b0010010; 
                4'd6 :result_ten = 7'b0000010; 
                4'd7 :result_ten = 7'b1111000; 
                4'd8 :result_ten = 7'b0000000; 
                4'd9 :result_ten = 7'b0010000; 
            endcase 
        end 
endmodule 
/********葉惟欣************************/
