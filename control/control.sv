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
	logic [7:0] timer;
	logic stall;
	logic stk;
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

		if (rst) begin					// Resetting cart if rst button is pressed
                        state <= 1'd0;
			ctl_valid <= 1'd1;
                        ack <= 1'd0;

			motor_dc <= 8'd0;
			direction <= 1'd1;
			servo_dc <= 8'(servo_center);
			
			timer[7:0]<=8'd0;
			stall <= 'd0;
			stk <= 'd0;
		end else begin		

			ctl_valid <= 1'd1;			// Valid signal is always 1 to work with adc_capture, ir_decoder modules

		        if (~can_move_fwd) begin		// Stopping if photodiode detects obstruction ahead
				direction <= 1'd0;
				stall <= 1'd1;
				motor_dc <= 8'(motor_max);
				stk <= 'd1;
			end
			
			if(stall) begin				// Stall state makes cart move back and turn right
				servo_dc <= 8'd50;
				if (timer <= 8'd250)
					timer <=timer + 1'd1;
                                else begin
                                        direction <=1'd1;
                                        timer <= 8'd0;
                                        motor_dc <= 8'd0;
					servo_dc <= 8'(servo_center);	
					stk <= 'd0;
					stall <= 'd0;	
                                end
			end 

			if (ir_ready) begin					// Processing signal if ir_decoder is ready

				case (command)					// Turning cart ON/OFF
					32'hFE010707:	state <= 1'd1;		// "Signal Source"
					32'hFD020707:	begin			// "Power OFF/ON (2)"
								state <= 1'd0;
								motor_dc <= 8'd0;
								servo_dc <= 8'(servo_center);
							end
				endcase

				if (state) begin				// Processing speed change or wheel turn commands only if cart is on
		
					case (command)				// Check README.md file for command list

					32'hED120707:	direction <= 1'd1;	// "ch+"
					32'hEF100707:	direction <= 1'd0;	// "ch-"

					
					32'h9A650707:	if (servo_dc <= 8'(servo_max - servo_step)) begin	// "Arrow left"
								servo_dc <= servo_dc + 8'(servo_step);
							end

					32'h9D620707:	if (servo_dc >= 8'(servo_min + servo_step)) begin	// "Arrow right"
								servo_dc <= servo_dc - 8'(servo_step);
							end				

					32'h9F600707:	if (can_move_fwd && motor_dc <= 8'(motor_max - motor_step)) begin	// "Arrow up"
								motor_dc <= motor_dc + 8'(motor_step);
							end

					32'h9E610707:	if (motor_dc >= 8'(motor_min + motor_step)) begin	// "Arrow down"
								motor_dc <= motor_dc - 8'(motor_step);
							end

					32'h86790707:	motor_dc <= 8'd0;					// "Home"
					32'h97680707:	servo_dc <= 8'(servo_center);				// "Enter"
					
					endcase
				end

				ack <= 1'd1;				// Setting acknowledge signal after processing every command to clear ir_ready

			end else begin
				ack <= 1'd0;				// Clearing acknowledge signal if ir_decoder didn't send a command during last clock cycle
			end
		end
	end

endmodule
