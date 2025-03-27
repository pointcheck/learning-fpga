module control
# (
	parameter clk_hz = 25000000,
	parameter sclk_hz = 256					// slow clock signal for making acceleration more smooth
) (
	input  logic clk,
	input  logic rst,
	input  logic ir_ready,					// READY signal from ir_decoder module
	input  logic [31:0] command,				// Command from ir_decoder module
	input  logic can_move_fwd,				// From adc_hysteresis module
	output logic ctl_valid,
	output logic ack,
	output logic [7:0] motor_dc,				// Duty cycle for PWM in motor_drv module
	output logic direction,
	output logic [7:0] servo_dc				// Duty cycle for PDM in servo_drv module
);

	logic enable;
	logic ack_int;
	
	assign ack = ack_int;

	// Dividing frequency from clk_hz to sclk_hz
	localparam MAX_DIV = clk_hz / (2 * sclk_hz);
	logic [$clog2(MAX_DIV)-1:0] frdiv;

	logic sclk;
	always_ff @(posedge clk or posedge rst) begin
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
		if (rst) begin
                        enable <= 1'd0;
                        ack_int <= 1'd0;
		end else begin		

			ctl_valid <= 1'd1;

        	        // Stopping if photodiode detects obstruction ahead
        	        if (~can_move_fwd) begin
        	                motor_dc <= 8'd0;
        	        end
			
			// Getting signal from ir_decoder through VALID-READY
			if (ir_ready) begin

				// Turning on/off
				case (command)
					32'hD12FFE01: enable <= 1'd1;			// SOURCE SIGNAL
					32'hEF11FE01: enable <= 1'd0;			// ON/OFF
				endcase
				
				if (enable) begin
		
					case (command)

					32'hD52BFE01: direction <= 1'd1;
					32'hCB35FE01: direction <= 1'd0;

					
					32'hC937FE01:	if (servo_dc > 8'd8) begin				// LEFT ARROW
								servo_dc <= servo_dc - 8'd8;
							end

					32'hCD33FE01:	if (servo_dc < 8'd247) begin				// RIGHT ARROW
								servo_dc <= servo_dc + 8'd8;
							end				

					32'hF907FE01:	if (can_move_fwd && motor_dc < 8'd247) begin		// CHANNEL +
								motor_dc <= motor_dc + 8'd8;
							end

					32'hDF21FE01:	if (motor_dc > 8'd8) begin				// CHANNEL -
								motor_dc <= motor_dc - 8'd9;
							end

					32'hC33DFE01: motor_dc <= 8'd0;						// ENTER
					32'hDB25FE01: servo_dc <= 8'd127;					// HOME				

					endcase
				end
				ack_int <= 1'd1;

			end else 
				ack_int <= 1'd0;
		end
	end

endmodule
