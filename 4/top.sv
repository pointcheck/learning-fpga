module top (
	input  logic clk25,
	input  logic [2:0] key,
	inout  logic [4:0] gpio,
	output logic [3:0] led
);

	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;
	logic ack;

	logic enable;

	logic ir_ready;
	logic ctl_valid;
	logic [31:0] command;

//	logic ir_check_reg;
	assign led[3:0] = motor_dc[7:4];
//	assign led[3:0] = 4'b1001;
//	assign led[0] = direction;
//	assign led[3:1] = servo_dc[7:5];

//	assign led[1:0] = command[17:16];
//	assign led[0] = ir_ready;
//	assign led[1] = ack;
//	assign led[2] = enable;
//	assign led[3] = direction;

	
/*	logic en1;
	logic en0;
	assign key[1] = en1;
	assign key[2] = en0;
	always_ff @(posedge clk25) begin
		if (en1) command <= 32'hD12FFE01;
		if (en0) command <= 32'hEF11FE01;
	end
*/

	logic rst;
	assign rst = key[0];

        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256)
        ) control_inst (
		.enable(enable),
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.command(command),
		.can_move_fwd(1'd1),
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
		.clk_hz(25000000),
		.cyc_hz(50)
	) servo_inst (
		.rst(rst),
		.clk(clk25),
		.en(1'd1),
		.duty(servo_dc),
		.pdm(gpio[2])
	);

	

	ir_decoder_fix decoder_inst (
		.clk(clk25),
		.rst(rst),
		.ack(ack),
		.enable(ctl_valid),
		.ir_input(gpio[3]),
		.ready(ir_ready),
		.command(command)
						// Removed .test from ir_decoder
	);	


	logic uart_tx;
	uart_sender uart_debug (
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.command(command),
		.tx(uart_tx)
	);

	// Выводим TX через GPIO
	assign gpio[4] = uart_tx;

endmodule
