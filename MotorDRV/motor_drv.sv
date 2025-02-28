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

	localparam integer CLK_DIV = clk_hz / (256 *  pwm_hz);		// Calculating max number for clock divider (clock_counter)
	logic [$clog2(CLK_DIV)-1:0] clock_counter = 0;			// Calculating bit width for clock divider (clock_counter) to get 64 kHz frequency after dividing
	logic [7:0] pwm_counter = 0;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			clock_counter  <= 0;
			pwm_counter <= 0;
		end else if (enable) begin
			clock_counter <= clock_counter + 1;
			if (clock_counter == CLK_DIV - 1) begin		// Resetting clock_counter after it gets to the max number (CLK_DIV - 1)
				clock_counter <= 0;
				pwm_counter <= pwm_counter + 1;		// Adding +1 to the pwm_counter to reach 250 Hz frequency for PWM signal (64 kHz for pwm_counter)
			end
		end
	end

	logic pwm;							
	assign pwm = (pwm_counter < duty_cycle);			// Getting PWM signal (250 Hz)
	assign pwm_outA = direction ? pwm : 0;				// Setting the PWM signal to one of the outputs based on the direction variable
	assign pwm_outB = direction ? 0 : pwm;

endmodule
