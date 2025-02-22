module top (
	input logic clk,
	input logic enable,
	input logic rst,
	input logic direction,
	//input logic [7:0] duty_cycle,
	output logic pwm_outA,
	output logic pwm_outB
);

	parameter [7:0] duty_cycle = 8'd128;
	logic [7:0] counter;
	
	always_ff @(posedge clk or posedge rst) begin
		duty_cycle[7:0] <= 8'b01000000;
		if (rst) begin						// сброс при сигнале reset
			counter <= 8'b0;
			pwm_outA <= 1'b0;
			pwm_outB <= 1'b0;
			

		end else if (enable) begin				// +1 к счетчику при сигнале enable
			counter <= counter + 8'b1;

			if (direction) begin				// в зависимости от направления выводит ШИМ на выход А или выход B 
				pwm_outA <= (counter < duty_cycle);
				pwm_outB <= 1'b0;		
		
			end else begin
				pwm_outB <= (counter < duty_cycle);
				pwm_outA <= 1'b0;

			end			

		end
	end

endmodule
