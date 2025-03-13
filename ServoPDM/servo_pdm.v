module servo_pdm
# (
        parameter  clk_hz   = 25000000,						// Global clock
        parameter  cyc_hz 	= 50,							// Frequency of produced PDM signal
) ( 
        input  wire       rst,								// Global RESET signal
        input  wire       clk,  							// Global Clock
        input  wire       en,   							// Enable signal
        input  reg [7:0]  duty, 							// input Duty cycle value
        output wire        pdm								// produced PDM signal
);

	localparam pdmw = (clk_hz*duty)/255;					// Calculating clocks number to count to needed PDM width
	reg [$clog2(pdmw)-1:0] pdmw_counter;					// Calculating bit depth for PDM width counter

	localparam divider = clk_hz/cyc_hz;						// Calculating clocks number to count to 20ms @ 25MHz
	reg [$clog2(divider)-1:0] div_counter;					// Calculating bit depth for clocks number
	
	wire pdm_done = 0;
	
	always @(posedge rst or posedge clk) begin				// Second counter makes 20ms pause after PDM signal
		if (rst) begin
			div_counter <= 0;
			pdmw_counter <= 0;
		end else if (en) begin
			if (pdmw_counter <= pdmw and pdm_done == 0)		// Counter to make PDM signal (only when pdm_done = 0)
				pdmw_counter <= pdmw_counter + 1;
			end else if (pdmw_counter > pdmw) begin			
				pdm_done <= 1;								// Setting pdm_done to 1 when PDM signal is done
			end
			if (pdm_done == 1) begin
				div_counter <= div_counter + 1;				// Counting 20ms after PDM signal
			end else if (div_counter == divider - 1)		
				div_counter <= 0;							// Starting over when 20ms is over
				pdm_done <= 0;
		end
	end
	
	if (pdmw < pdmw_counter) begin							// Creating output signal
		pdm <= 1;
	end else begin
		pdm <= 0;
	end
	
endmodule
