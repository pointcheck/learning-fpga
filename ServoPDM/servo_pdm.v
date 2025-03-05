module servo_pdm
# (
        parameter  clk_hz       = 25000000,				// Global clock
        parameter  cyc_hz 	= 50,					// Frequency of produced PDM signal
        parameter  pdm_hz	= 312500				// PDM clock
) ( 
        input  wire       rst,						// Global RESET signal
        input  wire       clk,  					// Global Clock
        input  wire       en,   					// Enable signal
        input  reg [7:0]  duty, 					// input Duty cycle value
        output reg        pdm   					// produced PDM signal
);

	integer divider = clk_hz/pdm_hz;				// Calculating clock divider to get 312,5 KHz from 25 MHz
	reg [$clog2(pdm_div)-1:0] div_counter;				// Calculating bit depth for clock divider
	
	integer cycle_clocks = pdm_hz/cyc_hz;				// Calculating clock divider to get 50 Hz from 312,5 KHz
	reg [$clog2(cycle_clocks)-1:0] pdm_counter;			// Calculating bit depth for clock divider
	
	always @(posedge rst or posedge clk) begin
		if (rst) begin
			pdm_counter <= 0;
			div_counter <= 0;				// Resetting everything on global RESET
		end else if (en) begin
			div_counter <= div_counter + 1;			// Counting @ 25 MHz
			if (div_counter == divider - 1) begin	
				div_counter <= 0;			// Counter is reset after getting to max number (80 - 1 = 79)
				pdm_counter <= pdm_counter + 1;		// Counting @ 312,5 KHz
				if (pdm_counter > cycle_clocks) begin
					pdm_counter <= 0;		// Resetting pdm_counter every 6250 clocks to get 50 Hz 
				end
			end
		end
	end
			
	wire pdm;
	assign pdm = 1;
	if (pdm_counter > 344) begin
		assign pdm = (duty > pdm_counter - 344);		// Roughly 344 clocks @ 312,5 KHz (343,75 clocks) needed to reach 1,1 ms, then comparison can start
	end

endmodule
