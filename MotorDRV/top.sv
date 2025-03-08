module top (
	input logic clk25,					// This module is for testing motor_drv.sv
	input logic [2:0] key,
	output logic [1:0] led
);

	logic [7:0] duty_cycle = 8'd128;

	motor_drv # (						// Creating an instance of motor_drv module (motor_drv.sv)
		.clk_hz(25000000),
		.pwm_hz(250) 
	) motor_inst (
		.clk(clk25),
		.enable(key[0]),
		.rst(key[1]),
		.direction(key[2]),
		.duty_cycle(duty_cycle),
		.pwm_outA(led[0]),
		.pwm_outB(led[1])
	);

endmodule
