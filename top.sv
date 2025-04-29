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

	logic [2:0] address;		// top
	logic rst;
	logic pwm_outA;
	logic pwm_outB;
	logic pdm_done;
	logic ir_input;
	logic test_flag;

	logic [7:0] motor_dc;		// control
	logic [7:0] servo_dc;
	logic direction;
	logic state;
	logic ctl_valid;
	logic ack;

	logic dout_bit;			// adc_capture
	logic sclk;
	logic cs;
	logic adc_ready;
	logic din_bit;
	logic [11:0] d_signal;

	logic can_move_fwd;		// adc_hysteresis

	logic ir_ready;			// ir_decoder
	logic [31:0] command;

	// Cart inputs and outputs
	assign gpio[0]  = pwm_outA;
	assign gpio[1]  = pwm_outB;
	assign gpio[2]  = pdm_done;
	assign ir_input = gpio[3];

        assign adc_spi_sclk = sclk;
        assign adc_spi_mosi = din_bit;
        assign adc_spi_csn  = cs;
        assign dout_bit     = adc_spi_miso;

	// Cart control & debugging tools
	assign rst = key[3];

	always_ff @(posedge sclk or posedge rst) begin

		if (rst) begin
			address <= 3'b001;
			test_flag <= 1'b1;
		end

		else if (key[2:0] == 3'b101) test_flag <= 1'b0;

	end

	always_comb begin
		case (key[2:0])

			3'b001: led = d_signal[3:0];
			3'b010: led = d_signal[7:4];
			3'b011: led = d_signal[11:8];
			3'b100: led = {1'b0, address};

			default: led = {state, direction, motor_dc[7], ~can_move_fwd};

		endcase
	end

	// Modules
        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256),
		.servo_step(16)
        ) control_inst (
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.adc_ready(adc_ready),
		.can_move_fwd(can_move_fwd),
		.command(command),
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
		.enable(state),
		.rst(rst),
		.direction(direction),
		.duty_cycle(motor_dc),
		.pwm_outA(pwm_outA),
		.pwm_outB(pwm_outB)
	);

	servo_pdm
	# (
		.clk_hz(25000000)
	) servo_inst (
		.rst(rst),
		.clk(clk25),
		.en(state),
		.duty(servo_dc),
		.pdm_done(pdm_done)
	);

	ir_decoder decoder_inst (
		.clk(clk25),
		.rst(rst),
		.ack(ack),
		.enable(1'd1),
		.ir_input(ir_input),
		.ready(ir_ready),
		.command(command)
	);

	adc_hysteresis
	# (
		.x_High(12'd3800),
		.x_Low(12'd1400)
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
                .ctl_valid(ctl_valid && test_flag),
                .address(address),
                .dout_bit(dout_bit),
                .sclk(sclk),
                .cs(cs),
                .adc_ready(adc_ready),
                .din_bit(din_bit),
                .d_signal(d_signal)
        );

endmodule
