module top (
	input logic clk25,					// Declaring inputs and outputs according to the configuration file (karnix_cabga256.lpf)
	input logic [3:0] key,
	output logic [1:0] led
);

	logic [7:0] duty_cycle = 8'd128;

	motor_drv # (						// Creating an instance of motor_drv module (motor_drv.sv)
		.clk_hz(25000000),
		.pwm_hz(1) 
	) motor_inst (
		.clk(clk25),
		.enable(1'd1),
		.rst(1'd0),
		.direction(key[2]),
		.duty_cycle(duty_cycle),
		.pwm_outA(led[0]),
		.pwm_outB(led[1])
	);

	logic button_pressed_inc, button_released_inc;
        logic button_pressed_dec, button_released_dec;

	debouncer debouncer_inc(				// Creating an instance of debouncer for increment button
		.clk(clk25),
		.button_in(key[0]),
		.button_pressed(button_pressed_inc),
		.button_state(),
		.button_released(button_released_inc)
	);

	debouncer debouncer_dec(				// The same for decrement button
		.clk(clk25),
		.button_in(key[1]),
		.button_pressed(button_pressed_dec),
		.button_state(),
		.button_released(button_released_dec)
	);

	always_ff @(posedge clk25) begin
		if (button_pressed_inc & duty_cycle < 8'd247) duty_cycle <= duty_cycle + 8'd8;
		if (button_pressed_dec & duty_cycle > 8'd8) duty_cycle <= duty_cycle - 8'd8;
		if (key[3]) duty_cycle <= 8'd128;							// key[3] resets duty_cycle to 50%
	end

endmodule
