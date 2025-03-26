module ir_decoder2
(       input wire clk,
        input wire rst,
        input wire enable,
        input wire ir_input,
        output wire ready,
        output wire [31:0] command,
        output wire [3:0] test
);
	localparam T0_MIN = (28256-2816)/64;
	localparam T0_MAX = (28256+2816)/64;
	localparam T1_MIN = (57008-5648)/64;
	localparam T1_MAX = (57008+5648)/64;
	localparam START_MIN = (128176-6400)/64;
	localparam START_MAX = (128176+6400)/64;
	//localparam T1_TOP = 1750000;


        wire strobe_front;

	reg  ir_input_last;
	reg [20:0] t1;
	reg [7:0] bit_count;
	reg [7:0] dem;
	reg [31:0] cmd;
	reg [1250:0] a;


	assign ready = bit_count == 31;

	assign command[31:0] = cmd[31:0];

	assign strobe_front = (ir_input_last != ir_input) * ir_input;
	//assign test[0]= ~ready;
	assign test[3:0] = '0;     
	always @(posedge clk or posedge rst)
        begin
		if(rst) begin
			ir_input_last <= 1'b1;
		        t1 <= 'b0;
			bit_count <= '0;
			dem[5:0] <= '0;
			cmd<= '0;

                end else begin
                        if(enable)
                        begin	
				
				ir_input_last <= ir_input;
				
				if(strobe_front == 'b0)
					t1<=t1+ 'b1;
				else begin
						
					if(t1 == 21'h1fffff) begin
						t1 <= '0;
						bit_count <= '0;
						cmd <= '0;
					end

				        if(t1>START_MIN  && t1<START_MAX) begin
						bit_count <= '0;
						cmd <= '0;
					end
					
					if(!ready) begin
					
						if(t1<T0_MAX && t1>T0_MIN) begin
							cmd = {1'b0, cmd[31:1]};
							bit_count<=bit_count+'b1;	
						end

						if(t1>T1_MIN && t1<T1_MAX) begin
							cmd = {1'b1, cmd[31:1]};
							bit_count <= bit_count + 'b1;
						end
					end
					t1<='b0;	
				end
                        end
                end

        end
endmodule
