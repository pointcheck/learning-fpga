module top (
	input  logic clk25,			// 25 MHz clock signal (clk25)
	input  logic [0:0] key,
	inout  logic [9:0] gpio,
	output logic [3:0] led,
	input  logic adc_spi_miso,		// adc dout output
	output logic adc_spi_mosi,		// adc din input
	output logic adc_spi_sclk,		// adc sclk input
	output logic adc_spi_csn		// adc ~cs input
);

	// control related outputs
	logic state;
	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;
	logic ctl_valid;
	logic ack;

	// adc_hysteresis related outputs
	logic adc_ack;
	logic can_move_fwd;

	// adc_capture related outputs
	logic dout_bit;
	logic sclk;
	logic cs;
	logic adc_ready;
	logic din_bit;
	logic [11:0] d_signal;

	assign adc_spi_sclk = sclk;
	assign adc_spi_mosi = din_bit;
	assign adc_spi_csn = cs;
	assign dout_bit = adc_spi_miso;

	// ir_decoder related outputs
	logic ir_ready;
	logic [31:0] command;

	// adc wires
	assign gpio[9:4] = {adc_ready, ctl_valid, sclk, cs, din_bit, dout_bit};
	
	// debugging tools
	assign led[0] = state;
	assign led[1] = can_move_fwd;
	assign led[2] = direction;
	assign led[3] = motor_dc[7];	

	logic rst;
	assign rst = key[0];

	// modules 
        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256),
		.servo_step(16)
        ) control_inst (
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.command(command),
		.can_move_fwd(can_move_fwd),
		.state(state),
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
		.enable(ctl_valid),
		.rst(rst),
		.direction(direction),
		.duty_cycle(motor_dc),
		.pwm_outA(gpio[0]),		// motor wires
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
		.enable(ctl_valid),
		.ir_input(gpio[3]),		// decoder wires
		.ack(ack),
		.ready(ir_ready),
		.command(command)
	);

	adc_hysteresis
	# (
		
		.x_High(12'd1246),
		.x_Low(12'd1059),		// Voltage range for photodiode ~0.4-2.7 V
	) hysteresis_inst (
		.rst(rst),
		.clk(clk25),
		.adc_ready(adc_ready),
		.d_signal(d_signal),
		.can_move_fwd(can_move_fwd),
		.adc_ack(adc_ack)
	);
	
	adc_capture 
	# (
		.clk_hz(25000000),
		.sclk_hz(5000000),
		.cycle_pause(30)
	) adc_capture_inst (
		.clk(clk25),
		.rst(rst),
		.en(ctl_valid),
		.adc_ack(adc_ack),
		.address(3'b000),		// IN0 adc input
		.dout_bit(dout_bit),
		.sclk(sclk),
		.cs(cs),
		.adc_ready(adc_ready),
		.din_bit(din_bit),
		.d_signal(d_signal)
	);

endmodule
