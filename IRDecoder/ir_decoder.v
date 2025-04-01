module ir_decoder (
	input wire clk,
        input wire rst,
	input wire ack,
        input wire enable,
        input wire ir_input,
        output reg ready,
        output wire [31:0] command,
);
	localparam T0_MIN = (28256-2816)/64;				//the amount of clock signal corresponds to signal 0 (time*frequency = 1.13 m s*25000000)
	localparam T0_MAX = (28256+2816)/64;
	localparam T1_MIN = (57008-5648)/64;				 //the number of clock signal corresponds to signal 1 (time * frequency = 2.28ms * 25000000)
	localparam T1_MAX = (57008+5648)/64;
	localparam START_MIN = (128176-6400)/64;			 //the amount of clock signal corresponds to the start signal
	localparam START_MAX = (128176+6400)/64;
	
	reg [15:0] slow_clk_div;
	wire slow_clk;

        wire strobe_front;

	reg  ir_input_last;						//last bit
	reg [20:0] t1;							// counter for determining the length of bit-0 and bit-1
	reg [7:0] bit_count;						//count the number of bits to 31
	reg [31:0] cmd;							//32-bit from the remote


	always @(posedge clk or posedge rst)
	begin
		if(rst) begin
			slow_clk_div <= '0;
		end else begin
			slow_clk_div <= slow_clk_div + 'd1;
		end

	end
	
	assign slow_clk = slow_clk_div[5];				//frequency reduction by 64 times

	assign command[31:0] = cmd[31:0];

	assign strobe_front = (ir_input_last != ir_input) * ir_input; //clock front condition

	always @(posedge slow_clk or posedge rst)
        begin
		if(rst) begin					//reset
			ir_input_last <= 1'b1;
		        t1 <= 'b0;
			bit_count <= '0;
			cmd<= '0;
			ready <= 1'd0;

                end else begin
                        if(enable)
                        begin	
				
				ir_input_last <= ir_input;
				
				if(strobe_front == 'b0)	 //check clock front
					t1<=t1+ 'b1;
				else begin
						
					if(t1 == 21'h1fffff) begin //time restrictions
						t1 <= '0;
						bit_count <= '0;
						cmd <= '0;
					end

				        if(t1>START_MIN  && t1<START_MAX) begin		// Start signal
						bit_count <= '0;
						cmd <= '0;
					end
					
					if(!ready) begin	//when the full command is written then ready = 1
					
						if(t1<T0_MAX && t1>T0_MIN) begin	//Signal "0"
							cmd = {1'b0, cmd[31:1]};
							bit_count<=bit_count+'b1;	
						end

						if(t1>T1_MIN && t1<T1_MAX) begin	//Signal "1"
							cmd = {1'b1, cmd[31:1]};
							bit_count <= bit_count + 'b1;
						end
					end
					t1<='b0;
					if (bit_count == 31) begin
						ready <= 1;
					end
				end
				//if (ack == 1) ready <= 1'd0;	//An auxiliary signal to prevent commands from being repeated

                        end
                end

        end
endmodule
