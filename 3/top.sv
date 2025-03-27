module top (
	input  logic clk25,
	input  logic [1:0] key,
	inout  logic [3:0] gpio,
	output logic [3:0] led
);

	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic direction;
	logic ack;

	logic ir_ready;
	logic ctl_valid;
	logic [31:0] command;

	//logic ir_check_reg;
	//assign led[3:0] = command[19:16];
	//assign led[3:0] = 4'b1001;
//	assign led[0] = direction;
//	assign led[3:1] = servo_dc[7:5];

	assign led[0] = ack;
	assign led[1] = ir_ready;
	assign led[3:2] = 2'b00;

	logic rst;
	assign rst = key[1];
	logic [15:0] slow_clk_div;
	logic slow_clk;
	
	assign slow_clk = slow_clk_div[5];

        control
        # (
                .clk_hz(25000000),
		.sclk_hz(256)
        ) control_inst (
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

	

	ir_decoder decoder_inst (
		.clk(slow_clk),
		.rst(rst),
		.ack(ack),
		.enable(ctl_valid),
		.ir_input(gpio[3]),
		.ready(ir_ready),
		.command(command)
						// Removed .test from ir_decoder
	);

	always_ff @(posedge clk25 or posedge rst) begin
		if (rst) slow_clk_div <= '0;
		else slow_clk_div <= slow_clk_div + 'd1;
	end	

endmodule
