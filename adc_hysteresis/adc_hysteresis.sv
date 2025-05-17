module adc_hysteresis 
# (
	x_High = 12'd3000,					// High activation threshold (can_move_fwd <= 0)
	x_Low = 12'd1000					// Low  activation threshold (can_move_fwd <= 1)
) (
	input  logic rst,
	input  logic clk,
	input  logic adc_ready,
	input  logic [11:0] d_signal,				// Digital signal from ADC
	output logic [11:0] not_d_signal,
	output logic can_move_fwd,
	output logic adc_ack
);
	logic [12:0] old_d_signal0;				// Keeping 1 previous d_signal value to filter signal spikes  

	always_ff @(posedge clk or posedge rst) begin
		
		if (rst) begin 					// Global reset

			can_move_fwd	<= 1'd1;

			not_d_signal	<= 12'd0;
			old_d_signal0	<= 12'd0;

			adc_ack		<= 1'd0;

		end else if (adc_ready) begin

			old_d_signal0 <= d_signal;
			not_d_signal  <= (d_signal + old_d_signal0) >> 1;	// Dividing the sum of current and previous d_signal values by 2
			
			if (not_d_signal < x_Low)
				can_move_fwd <= 1'd1;

			else if (not_d_signal > x_High)
				can_move_fwd <= 1'd0;
			
			adc_ack	<= 1'd1;			// Setting up acknowledge signal after processing d_signal
		end else
			adc_ack <= 1'd0;			// Resetting acknowledge signal if adc is not finished its work cycle
	end

endmodule
