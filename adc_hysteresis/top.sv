module top (
	input  logic clk25,
	input  logic [3:0] key,
	output logic [3:0] led
);

	logic rst;
	logic adc_ready;
	logic [11:0] d_signal;
	logic [11:0] not_d_signal;
	logic can_move_fwd;
	logic adc_ack;

	assign rst	  = key[0];
	assign adc_ready  = key[1];

	always_ff @(posedge clk25 or posedge rst) begin
		if (rst) begin
			d_signal <= 12'd0;
		end else begin

			case (key[3:2])
			
				2'b01: d_signal <= 12'd3200;	// high level
				2'b10: d_signal <= 12'd2500;	// middle level 1
				2'b11: d_signal <= 12'd1500;	// middle level 2
			
				default: d_signal <= 12'd800;	// low level
        		endcase
		end
	end

	adc_hysteresis #(
		.x_High(12'd3000),
		.x_Low (12'd1000)
	) hysteresis_inst (
		.rst(rst),
		.clk(clk25),
		.adc_ready(adc_ready),
		.d_signal(d_signal),
		.not_d_signal(not_d_signal),
		.can_move_fwd(can_move_fwd),
		.adc_ack(adc_ack)
	);

	assign led[0] = not_d_signal[10];
	assign led[1] = not_d_signal[11];
	assign led[2] = can_move_fwd;
	assign led[3] = adc_ack;

endmodule

