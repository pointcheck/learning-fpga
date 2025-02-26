module motor_drv
# (
	parameter clk_hz = 25000000,					// Setting frequency parameters to change them through top.sv file
	parameter pwm_hz = 250
) (
	input logic clk,
	input logic enable,
	input logic rst,
	input logic direction,
	input logic [7:0] duty_cycle,
	output logic pwm_outA,
	output logic pwm_outB
);

	localparam integer CLK_DIV = clk_hz / pwm_hz;			// Calculating max number for clock divider (pwm_counter)
	logic [$clog2(CLK_DIV)-1:0] pwm_counter = 0;			// Calculating bit width for clock divider (pwm_counter) to get 250 Hz frequency after dividing
	logic [7:0] main_counter = 0;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			pwm_counter  <= 0;
			main_counter <= 0;
		end else if (enable) begin
			pwm_counter <= pwm_counter + 1;
			if (pwm_counter == CLK_DIV - 1) begin		// Resetting pwm_counter after it gets to the max number (CLK_DIV - 1)
				pwm_counter <= 0;
				main_counter <= main_counter + 1;	// Adding +1 to the main_counter to reach 250 Hz frequency for PWM signal
			end
		end
	end

	logic pwm;							
	assign pwm = (main_counter < duty_cycle);			// Getting PWM signal
	assign pwm_outA = direction ? pwm : 0;				// Setting the PWM signal to one of the outputs based on the direction variable
	assign pwm_outB = direction ? 0 : pwm;

endmodule
