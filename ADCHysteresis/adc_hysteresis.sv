module adc_hysteresis 
# (
	x_High = 12'd3000,		
	x_Low = 12'd1000
) (
	input  clk,
	input  logic [11:0] signal,		// Digital signal from ADC
	output logic can_move_fwd
);

	always_ff @(posedge clk) begin
		if (signal < x_Low)
			can_move_fwd <= 1;
		else if (signal > x_High)
			can_move_fwd <= 0;
	end

endmodule
