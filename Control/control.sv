module control 
# (
	clk_hz = 25000000,
	sclk_hz = 256			// slow clock signal for making acceleration more smooth
) (
	input  clk,
	input  logic ir_ready,		// READY signal from ir_decoder module
	input  logic adc_ready,		// READY signal from adc_polling module
	input  logic [2:0] command,	// Command from ir_decoder module
	input  logic can_move_fwd,	// From adc_hysteresis module
	output logic ctl_valid,
	output logic [7:0] motor_dc,	// Duty cycle for PWM in motor_drv module
	output logic direction,
	output logic [7:0] servo_dc	// Duty cycle for PDM in servo_drv module
);

	// Dividing frequency from clk_hz to sclk_hz
	localparam MAX_DIV = clk_hz / (2 * sclk_hz);
	logic [$clog2(MAX_DIV)-1:0] frdiv;

	logic sclk;
	always_ff @(posedge clk) begin
		if (frdiv == MAX_DIV - 'd1 begin
			sclk <= ~sclk;
			frdiv <= 0;
		end else begin
			frdiv <= frdiv + 'd1;
		end
	end

	logic enable = 0;
	
	always_ff @(posedge sclk) begin
		
		// Getting signal from ir_decoder through VALID-READY
		if (ir_ready) begin

			// Turning on/off
			case (command)
				3'b000: enable <= 1'd1;
				3'b001: enable <= 1'd0;
			endcase
			
			if (enable) begin
	
				case (command)
				
				3'b010: if (can_move_fwd) begin
					direction <= 1'd1;
					motor_dc <= motor_dc + 8'd1;
				end

				3'b011: begin
					direction <= 1'd0;
					motor_dc <= motor_dc - 8'd1;
				end

				3'b100: servo_dc <= servo_dc - 8'd1;
				3'b101: servo_dc <= servo_dc + 8'd1;
				3'b110: motor_dc <= 8'd0;
				
				endcase
			end
		end

		ctl_valid <= 1'd1;

		// Stopping if photodiode detects obstruction ahead
		if (adc_ready && ~can_move_fwd) begin
			motor_dc <= 8'd0;
		end
	end

endmodule;

/*
Command list:
000	- turning on
001	- turning off
010	- moving forward
011	- moving backward
100	- turning left
101	- turning right
110	- stop
*/



