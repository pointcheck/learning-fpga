module control
# (
	parameter clk_hz = 25000000,
	parameter sclk_hz = 256					// slow clock signal for making acceleration more smooth
) (
	input  clk,
	input  logic ir_ready,					// READY signal from ir_decoder module
	input  logic [31:0] command,				// Command from ir_decoder module
	input  logic can_move_fwd,				// From adc_hysteresis module
	output logic ctl_valid,
	output logic [7:0] motor_dc,				// Duty cycle for PWM in motor_drv module
	output logic direction,
	output logic [7:0] servo_dc				// Duty cycle for PDM in servo_drv module
);

	// Dividing frequency from clk_hz to sclk_hz
	localparam MAX_DIV = clk_hz / (2 * sclk_hz);
	logic [$clog2(MAX_DIV)-1:0] frdiv;

	logic sclk = 1'd0;
	always_ff @(posedge clk) begin
		if (frdiv == MAX_DIV - 'd1) begin
			sclk <= ~sclk;
			frdiv <= 0;
		end else begin
			frdiv <= frdiv + 'd1;
		end
	end

	logic enable = 1'd0;
	
	always_ff @(posedge sclk) begin
		
		ctl_valid <= 1'd1;

                // Stopping if photodiode detects obstruction ahead
                if (~can_move_fwd) begin
                        motor_dc <= 8'd0;
                end
		
		// Getting signal from ir_decoder through VALID-READY
		if (ir_ready) begin

			// Turning on/off
			case (command)
				32'hFE010707: enable <= 1'd1;			// SOURCE SIGNAL
				32'hFD020707: enable <= 1'd0;			// ON/OFF
			endcase
			
			if (enable) begin
	
				case (command)
				
				32'h9F600707: direction <= 1'd1;					// UP ARROW
				32'h9E610707: direction <= 1'd0;					// DOWN ARROW

				32'h9A650707:	if (servo_dc > 8'd8) begin				// LEFT ARROW
							servo_dc <= servo_dc - 8'd8;
						end

				32'h9D620707:	if (servo_dc < 8'd247) begin				// RIGHT ARROW
							servo_dc <= servo_dc + 8'd8;
						end				

				32'hED120707:	if (can_move_fwd && motor_dc < 8'd247) begin		// CHANNEL +
							motor_dc <= motor_dc + 8'd8;
						end

				32'hEF100707:	if (motor_dc > 8'd8) begin				// CHANNEL -
							motor_dc <= motor_dc - 8'd9;
						end

				32'h97680707: motor_dc <= 8'd0;						// ENTER
				32'h86790707: servo_dc <= 8'd127;					// HOME

				endcase
			end
		end
	end

endmodule
