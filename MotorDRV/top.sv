module top (
	input logic clk25,		// Declaring inputs and outputs according to the configuration file (karnix_cabga256.lpf)
	input logic [3:0] key,
	output logic [1:0] led
);
	
	motor_drv # (			// Creating an instance of motor_drv module (motor_drv.sv)
		.clk_hz(25000000),
		.pwm_hz(250) 
	) motor_inst (
		.clk(clk25),
		.enable(key[0]),
		.rst(key[1]),
		.direction(key[2]),
		.duty_cycle(8'd128),	// Setting duty_cycle to a fixed value (50%) for testing purposes
		.pwm_outA(led[0]),
		.pwm_outB(led[1])
	);

endmodule
