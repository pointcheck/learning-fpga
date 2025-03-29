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

	logic enable;

	logic ir_ready;
	logic ctl_valid;
	logic [31:0] command;

	assign led[0] = enable;
	assign led[1] = direction;
	assign led[2] = motor_dc[7];
	assign led[3] = servo_dc[7];

	logic rst;
	assign rst = key[3];

/*	always_comb begin
	
	if (key[2:0] == 3'b000) led[3:0] = command[3:0];

	else if (key[2:0] == 3'b001) led[3:0] = command[7:4];

	else if (key[2:0] == 3'b010) led[3:0] = command[11:8];

	else if (key[2:0] == 3'b011) led[3:0] = command[15:12];

	else if (key[2:0] == 3'b100) led[3:0] = command[19:16];

	else if (key[2:0] == 3'b101) led[3:0] = command[23:20];

	else if (key[2:0] == 3'b110) led[3:0] = command[27:24];

	else led[3:0] = command[31:28];
	end
*/

        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256),
		.servo_step(16)
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



	servo_pdm_fix
	# (
		.clk_hz(25000000)
	) servo_inst (
		.rst(rst),
		.clk(clk25),
		.en(ctl_valid),
		.duty(servo_dc),
		.pdm_done(gpio[2])
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

endmodule
