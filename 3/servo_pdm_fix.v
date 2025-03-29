module servo_pdm_fix
# (
        parameter  clk_hz   = 25000000,							// Global clock
) ( 
        input  wire       rst,								// Global RESET signal
        input  wire       clk,  							// Global Clock
        input  wire       en,   							// Enable signal
        input  wire [7:0]  duty, 							// input Duty cycle value
        output wire       pdm_done								// produced PDM signal
);

	wire [15:0] pdm_width;								// Calculating clocks number to count to needed PDM width (+ 1,1ms at the start)
	reg [15:0] pdmw_counter;							// PDM width counter

	localparam zero_dur = clk_hz / 1000 * 20;						// Calculating clocks number to count to 20ms @ 25MHz
	localparam div_counter_w = $clog2(zero_dur);

	reg [div_counter_w-1:0] div_counter;						// Calculating bit depth for clocks number

	reg pdm_done_reg;
	assign pdm_done = pdm_done_reg;
	
	assign pdm_width = (duty << 6) + 'd27500;						// Calculating clocks number to count to needed PDM width (+ 1,1ms at the start)
	// assign pdm_width = (duty << 6) + (duty << 4) + 'd27500;	// To test	
	
	always @(posedge rst or posedge clk) begin					// Second counter makes 20ms pause after PDM signal
		if (rst) begin
			div_counter <= 'd0;
			pdmw_counter <= 'd0;
			pdm_done_reg <= 'b0;
		end else if (en) begin
			if(pdm_done_reg == 'b1) begin
				if (pdmw_counter != pdm_width) begin // Counter to make PDM signal (only when pdm_done = 0)
					pdmw_counter <= pdmw_counter + 'd1;
				end else begin			
					pdm_done_reg <= 'b0;						// Setting pdm_done to 1 when PDM signal is done
					div_counter <= 'd0;					// Starting over when 20ms is over
				end
			end else begin
				div_counter <= div_counter + 'd1;			// Counting 20ms after PDM signal

				if (div_counter == zero_dur) begin		
					pdm_done_reg <= 'b1;
					pdmw_counter <= 'd0;
				end
			end
		end
	end
	
endmodule
