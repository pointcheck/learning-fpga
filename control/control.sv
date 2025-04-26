module control
# (
	parameter clk_hz = 25000000,
	parameter sclk_hz = 256,
	parameter servo_min = 0,
	parameter servo_max = 255,
	parameter servo_step = 32,
	parameter servo_center = 155,
	parameter motor_min = 0,
	parameter motor_max = 255,
	parameter motor_step = 32
) (
	input  logic clk,
	input  logic rst,
	input  logic ir_ready,
	input  logic adc_ready,
	input  logic can_move_fwd,
	input  logic [31:0] command,
	output logic state,					
	output logic ctl_valid,
	output logic ack,
	output logic direction,
	output logic [7:0] motor_dc,
	output logic [7:0] servo_dc
);

	localparam MAX_DIV = clk_hz / (2 * sclk_hz);				// Declaring parameter of max number for clock divider to count to
	logic [$clog2(MAX_DIV)-1:0] frdiv;					// frdiv - clock dividing counter (frequency divider)

	logic sclk;
	always_ff @(posedge clk or posedge rst) begin				// Dividing frequency from clk_hz to sclk_hz

		if (rst) begin
			frdiv <= 1'd0;
			sclk <= 1'd0;

		end else begin

			if (frdiv == MAX_DIV - 'd1) begin
				sclk <= ~sclk;
				frdiv <= 0;
			end else
				frdiv <= frdiv + 'd1;
		end
	end

	always_ff @(posedge sclk or posedge rst) begin

		if (rst) begin							// Resetting cart if rst button is pressed
                        state <= 1'd0;
			ctl_valid <= 1'd1;
                        ack <= 1'd0;
			motor_dc <= 8'd0;
			direction <= 1'd1;
			servo_dc <= 8'(servo_center);

		end else begin		

			if (adc_ready) ctl_valid <= 1'd0;					// VALID signal is always 1 to work with ADCPolling, IRDecoder modules

		        if (~can_move_fwd && adc_ready) begin				// Stopping if photodiode detects obstruction ahead
		                motor_dc <= 8'd0;
				ctl_valid <= 1'd1;
		        end
			
			if (ir_ready && adc_ready) begin					// Processing signal if IRDecoder is ready

				case (command)					// Turning cart ON/OFF
					32'h6897FF00:	state <= 1'd1;
					32'h7788FF00:	begin
								state <= 1'd0;
								motor_dc <= 8'd0;
								servo_dc <= 8'(servo_center);
							end
				endcase

				if (state) begin				// Processing speed change or wheel turn commands only if cart is on
		
					case (command)				// Check README.md file for command list

					32'h6A95FF00:	direction <= 1'd1;
					32'h659AFF00:	direction <= 1'd0;

					
					32'h649BFF00:	if (servo_dc <= 8'(servo_max - servo_step)) begin
								servo_dc <= servo_dc + 8'(servo_step);
							end

					32'h6699FF00:	if (servo_dc >= 8'(servo_min + servo_step)) begin
								servo_dc <= servo_dc - 8'(servo_step);
							end				

					32'h7C83FF00:	if (can_move_fwd && motor_dc <= 8'(motor_max - motor_step)) begin
								motor_dc <= motor_dc + 8'(motor_step);
							end

					32'h6F90FF00:	if (motor_dc >= 8'(motor_min + motor_step)) begin
								motor_dc <= motor_dc - 8'(motor_step);
							end

					32'h619EFF00:	motor_dc <= 8'd0;
					32'h6D92FF00:	servo_dc <= 8'(servo_center);			
					
					endcase
				end

				ack <= 1'd1;				// Setting acknowledge signal after processing every command to clear ir_ready

				ctl_valid <= 1'd1;

			end else
				ack <= 1'd0;				// Clearing acknowledge signal if IRDecoder didn't send a command during last clock cycle
		end
	end

endmodule
