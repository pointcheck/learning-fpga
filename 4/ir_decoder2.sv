module ir_decoder2 # (
	parameter clk_hz = 25000000,
	parameter sclk_hz = 25000
) (     
	input logic clk,
        input logic rst,
        input logic enable,
        input logic ir_input,
        output logic ready,
        output logic [31:0] command,
        //output logic [3:0] test
);
	localparam T0_MIN = (28256-2816)/64;
	localparam T0_MAX = (28256+2816)/64;
	localparam T1_MIN = (57008-5648)/64;
	localparam T1_MAX = (57008+5648)/64;
	localparam START_MIN = (128176-6400)/64;
	localparam START_MAX = (128176+6400)/64;
	//localparam T1_TOP = 1750000;


        logic strobe_front;

	logic  ir_input_last;
	logic [20:0] t1;
	logic [7:0] bit_count;
//	logic [7:0] dem;
	logic [31:0] cmd;
//	logic [1250:0] a;

        localparam MAX_DIV = clk_hz / (2 * sclk_hz) - 1;
        logic [$clog2(MAX_DIV)-1:0] frdiv;
        logic sclk;

	assign ready = bit_count == 31;

	assign command[31:0] = cmd[31:0];

	assign strobe_front = (ir_input_last != ir_input) * ir_input;
	//assign test[0]= ~ready;
	//assign test[3:0] = '0;     
	always @(posedge sclk or posedge rst)
        begin
		if (frdiv == MAX_DIV) begin
			sclk <= ~sclk;
			frdiv <= 0;
                end else begin
                        frdiv <= frdiv + 'd1;
                end
		

		if(rst) begin
			ir_input_last <= 1'b1;
		        t1 <= 'b0;
			bit_count <= '0;
//			dem[5:0] <= '0;
			cmd<= '0;
			sclk <= 1'd0;

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
