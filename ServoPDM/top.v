module top (				// Declaring inputs and outputs according to the configuration file (karnix_cabga256.lpf)
	input wire clk25,
	input wire [1:0] key,
	output wire [3:0] led
);
	
	servo_pdm # (			// Creating an instance of servo_pdm module (servo_pdm.v)
		.clk_hz(25000000),	 
		.cyc_hz(50),
	) servo_inst (
		.clk(clk25),
		.en(key[0]),
		.rst(key[1]),
		.duty(8'd0),		// Duty cycle is manually set here for test purposes
		.pdm(led [0])		// LED lights up showing pulse width
	);

endmodule
