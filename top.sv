module top (
	input  logic clk25,
	input  logic [3:0] key,
	inout  logic [3:0] gpio,
	output logic [3:0] led
);

	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;
	logic ack;

	logic state;

	logic ir_ready;
	logic ctl_valid;
	logic [31:0] command;

	logic [11:0] d_signal;
	logic can_move_fwd;

	assign led[0] = state;
	assign led[1] = direction;
	assign led[2] = motor_dc[7];
	assign led[3] = servo_dc[7];

	logic rst;
	assign rst = key[3];

        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256),
		.servo_step(16)
        ) control_inst (
		.state(state),
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.command(command),
		.can_move_fwd(can_move_fwd),
		.ctl_valid(ctl_valid),
		.ack(ack),
		.motor_dc(motor_dc),
		.direction(direction),
		.servo_dc(servo_dc)
        );

	motor_drv 
	# (
		.clk_hz(25000000),
		.pwm_hz(250)
	) motor_inst (
		.clk(clk25),
		.enable(1'd1),
		.rst(rst),
		.direction(direction),
		.duty_cycle(motor_dc),
		.pwm_outA(gpio[0]),
		.pwm_outB(gpio[1])
	);

	servo_pdm
	# (
		.clk_hz(25000000)
	) servo_inst (
		.rst(rst),
		.clk(clk25),
		.en(ctl_valid),
		.duty(servo_dc),
		.pdm_done(gpio[2])
	);

	ir_decoder decoder_inst (
		.clk(clk25),
		.rst(rst),
		.ack(ack),
		.enable(ctl_valid),
		.ir_input(gpio[3]),
		.ready(ir_ready),
		.command(command)
	);

	adc_hysteresis
	# (
		
		.x_High(12'd3000),
		.x_Low(12'd1000)
	) hysteresis_inst (
		.rst(rst),
		.clk(clk25),
		.d_signal(d_signal),
		.can_move_fwd(can_move_fwd)
	);
	
	adc_capture 
	# (
		.clk_hz(25000000),
		.sclk_hz(500000),
		.cycle_pause(30)
	) adc_capture_inst (
		.clk(clk25),
		.rst(rst),
		.ctl_valid(ctl_valid),
		.adc_ack(adc_ack),
		.address(address),
		.dout_bit(dout_bit),
		.sclk(sclk),
		.cs(cs),
		.adc_ready(adc_ready),
		.din_bit(din_bit),
		.d_signal(d_signal)
	);


endmodule
