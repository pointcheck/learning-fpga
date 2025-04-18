module adc_hysteresis 
# (
	x_High = 12'd3000,		
	x_Low = 12'd1000
) (
	input rst,
	input  clk,
	input  logic [11:0] d_signal,			// Digital signal from ADC
	output logic can_move_fwd
);
	logic [11:0] not_d_signal;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin 				// Global RESET
			can_move_fwd <= '1;
			not_d_signal <= '1;
		end else begin
			not_d_signal <= 12'd4075-d_signal-12'd561;
			if (not_d_signal < x_Low)
				can_move_fwd <= 1;
			else if (not_d_signal > x_High)
				can_move_fwd <= 0;
		end
	end

endmodule
