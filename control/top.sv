module top (
	input  logic clk25,
	input  logic [3:0] key,
	output logic [3:0] led
);

	logic rst;
	
	logic ir_ready;					// Input signals
	logic [31:0] command;
	
	logic state;					// Output signals
	logic direction;
	logic [7:0] motor_dc;
	logic [7:0] servo_dc;
	logic ctl_valid;
	
	control # (
		.clk_hz(25000000),
		.sclk_hz(256),
		.servo_center(155)
	) control_inst (
		.clk(clk25),
		.rst(rst),
		.ir_ready(ir_ready),
		.can_move_fwd(1'd1),
		.command(command),
		.state(state),
		.ctl_valid(ctl_valid),
		.ack(),
		.direction(direction),
		.motor_dc(motor_dc),
		.servo_dc(servo_dc)
	);

	always_ff @(posedge clk25 or posedge rst) begin

		if (rst) begin

			ir_ready <= 1'd0;
			command <= 32'h6897FF00;		// Turning ON module automatically

		end else if (key[2:0]) begin

			ir_ready <= 1'd1;

			case (key[2:0])

				3'b001:	command <= 32'h7C83FF00;

				3'b010:	command <= 32'h6F90FF00;

				3'b011: command <= 32'h6A95FF00;

				3'b100: command <= 32'h659AFF00;

				3'b101: command <= 32'h649BFF00;

				3'b110: command <= 32'h6699FF00;			

			endcase

		end else

			ir_ready <= 1'd0;
	end
	
	always_comb begin
		key[3] = rst;

		led[0] = state;
		led[1] = direction;
		led[2] = motor_dc > 8'd127;
		led[3] = servo_dc > 8'd155;
	end

endmodule
