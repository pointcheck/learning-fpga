module top (
	input  logic clk25,
	input  logic [3:0] key,
	inout  logic [3:0] gpio,		// gpio[0] - pwm_outA, gpio[1] - pwm_outB, gpio[2] - pdm_done, gpio[3] - ir_input
	output logic [3:0] led,
	
	input  logic adc_spi_miso,
	output logic adc_spi_mosi,
	output logic adc_spi_sclk,
	output logic adc_spi_csn
);

	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;
	logic ack;

	logic [2:0] address;
	logic dout_bit;
	logic sclk;
	logic cs;
	logic adc_ready;
	logic din_bit;
	logic [11:0] d_signal;

	logic state;

	logic ir_ready;
	logic ctl_valid;
	logic [31:0] command;

	logic can_move_fwd;

	logic rst;

        assign address = 3'b001;

        assign adc_spi_sclk = sclk;
        assign adc_spi_mosi = din_bit;
        assign adc_spi_csn = cs;
        assign dout_bit = adc_spi_miso;

	assign led[0] = state;
	assign led[1] = direction;
	assign led[2] = motor_dc[7];
	assign led[3] = ~can_move_fwd;

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
		.enable(state),
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
		.en(state),
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
		
		.x_High(12'd3800),
		.x_Low(12'd2000)
	) hysteresis_inst (
		.rst(rst),
		.clk(clk25),
		.d_signal(d_signal),
		.can_move_fwd(can_move_fwd)
	);

        adc_capture # (
                .clk_hz(25000000),
                .sclk_hz(5000000),
                .cycle_pause(30)
        ) adc_capture_inst (
                .clk(clk25),
                .rst(rst),
                .ctl_valid(ctl_valid),
                .address(address),
                .dout_bit(dout_bit),
                .sclk(sclk),
                .cs(cs),
                .adc_ready(adc_ready),
                .din_bit(din_bit),
                .d_signal(d_signal)
        );

endmodule
