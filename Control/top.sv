module top (
	input logic clk25,
	input logic key[0],
	inout logic [3:0] gpio
);

	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;

        logic ir_ready;
	logic ctl_valid;
        logic [31:0] command;


        control
        # (
                .clk_hz = 25000000,
		.sclk_hz = 256
        ) control_inst (
		.clk(clk25),
		.ir_ready(ir_ready),
		.adc_ready(1'd0),
		.command(command),
		.can_move_fwd(1'd1),
		.ctl_valid(ctl_valid),
		.motor_dc(motor_dc),
		.direction(direction),
		.servo_dc(servo_dc)
        );



	motor_drv 
	# (
		.clk_hz = 25000000,
		.pwm_hz = 250
	) motor_inst (
		.clk(clk25),
		.enable(1'd1),
		.rst(key[0]),
		.direction(direction),
		.duty_cycle(motor_dc),
		.pwm_outA(gpio[1]),
		.pwm_outB(gpio[2])
	);



	servo_pdm
	# (
		.clk_hz = 25000000,
		.cyc_hz = 50
	) servo_inst (
		.rst(key[0]),
		.clk(clk25),
		.en(1'd1),
		.duty(servo_dc),
		.pdm(gpio[3])
	);

	

	ir_decoder decoder_inst (
		.clk(clk25),
		.rst(key[0]),
		.enable(ctl_valid),
		.ir_input(gpio[0]),
		.ready(ir_ready),
		.command(command),
		.test(1'd0)
	);	

endmodule
