module ir_decoder (
	input  wire clk,
	input  wire rst,
	input  wire enable,
	input  wire ir_input,
	output wire ready,
	output wire [31:0] command, 
	output wire [3:0] test
);

	localparam T0_MIN = 12800 - 128;
	localparam T0_MAX = 12800 + 128;
	localparam T1_MIN = 40925 - 128;
	localparam T1_MAX = 40925 + 128;
	localparam START_MIN = 122500 - 128;
	localparam START_MAX = 122500 + 128;
	localparam T1_TOP = 1750000;

	reg ir_input_last;
	wire strobe_front;
	wire strobe_back;
	reg [23:0] t1; 
	reg [5:0] bit_count;
	reg [31:0] cmd;

	reg test_start;

	//assign test[3:0] = 4'b0;
	assign ready = t1 == T1_TOP;
	assign strobe_front = (ir_input_last != ir_input) & ir_input;
	assign strobe_back = (ir_input_last != ir_input) & ~ir_input;

	assign command[31:0] = cmd[31:0];

	assign test[0] = strobe_front;
	assign test[1] = strobe_back;
	assign test[2] = test_start;
	assign test[3] = 0;//1'b1;

	always_ff @(posedge clk or posedge rst)
	begin
		if(rst) begin
			ir_input_last <= '0;
			t1 <= '0;
			bit_count <= '0;

			test_start <= '0;

		end else begin
			if(enable)
			begin
				ir_input_last <= ir_input;

				if(t1 != T1_TOP)
					t1 <= t1 + '1;

				if(strobe_front)
					t1 <= '0;

				if(strobe_back)
				begin
					if(t1 > START_MIN && t1 < START_MAX)
					begin
						// Start of packet
						bit_count <= '0;
						test_start <= '1;
					end

					if(t1 > T0_MIN && t1 < T0_MAX)
					begin
						// ZERO received
						cmd[bit_count] <= '0;
						bit_count <= bit_count + '1;
					end

					if(t1 > T1_MIN && t1 < T1_MAX)
					begin
						// ONE received
						cmd[bit_count] <= '1;
						bit_count <= bit_count + '1;
					end

				end


			end
		end

	end
endmodule
