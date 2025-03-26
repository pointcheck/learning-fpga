module servo_pdm2
# (
        parameter  clk_hz   = 25000000, // Global clock
        parameter  cyc_hz   = 50        // Frequency of produced PDM signal
) ( 
        input  wire       rst,  // Global RESET signal
        input  wire       clk,  // Global Clock
        input  wire       en,   // Enable signal
        input  wire [7:0] duty, // Input Duty cycle value
        output wire       pdm   // Produced PDM signal
);

	wire [15:0] pdm_width; // Calculating clocks number to count to needed PDM width
	reg [15:0] pdmw_counter; // PDM width counter

	localparam zero_dur = clk_hz / 1000 * 20; // Calculating clocks number to count to 20ms @ 25MHz
	localparam div_counter_w = $clog2(zero_dur);

	reg [div_counter_w-1:0] div_counter; // Calculating bit depth for clocks number
	
	reg pdm_done;
	
	assign pdm = pdm_done;
	assign pdm_width = (duty << 6) + 27500; // Calculating clocks number to count to needed PDM width
	
	always @(posedge rst or posedge clk) begin // Second counter makes 20ms pause after PDM signal
		if (rst) begin
			div_counter <= '0;
			pdmw_counter <= '0;
			pdm_done <= '0;
		end else if (en) begin
			if (pdm_done) begin
				if (pdmw_counter != pdm_width) // Counter to make PDM signal
					pdmw_counter <= pdmw_counter + 1;
				else begin			
					pdm_done <= 0; // Setting pdm_done to 1 when PDM signal is done
					div_counter <= 0; // Starting over when 20ms is over
				end
			end else begin
				div_counter <= div_counter + 1; // Counting 20ms after PDM signal

				if (div_counter == zero_dur) begin		
					pdm_done <= 1;
					pdmw_counter <= 0;
				end
			end
		end
	end
	
endmodule
