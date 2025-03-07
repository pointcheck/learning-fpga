module adc_polling # (
	parameter clk_hz = 25000000,
	parameter adc_hz = 5000000,
) (		
	input  logic clk,
	input  logic cs,
	input  [2:0] add,					// address of the ADCs input (IN0-IN7) 
	input  logic dout_bit,					// one bit from DOUT
	output logic sclk,					// SCLK for ADC
	output logic din_bit,					// one bit for DIN
	output logic [11:0] d_signal				// digital signal as a result
);

	// Turning clk_hz to adc_hz
	localparam SCLK_DIV = clk_hz / adc_hz;
	logic [$clog2(SCLK_DIV)-1:0] sclk_counter;

	always @(posedge clk) begin
		if (sclk_counter == SCLK_DIV - 1) begin
			sclk <= ~sclk;
			sclk_counter <= 0;
		end else begin
			sclk_counter <= sclk_counter + 1;
		end
	end    

	logic [3:0] c_counter;					// Declaring cycle counter for counting to 15
	logic [7:0] din;					// DIN
	logic [15:0] dout;					// DOUT

	assign din = {2'b00, add, 3'b000};			// Forming DIN signal  
	assign d_signal = dout[11:0];				// Removing first 4 zeros from DOUT
	
	// Transferring the address to DIN on the rising edge of SCLK
	always @(posedge sclk) begin
		if (~cs && c_counter < 16) begin
			din_bit <= din[c_counter];		// Choosing particular bit to transfer to DIN (MSB first)
			c_counter <= c_counter + 1;
		end else begin
			c_counter <= 0;
		end
	end

	// Reading the result on the falling edge 
	always @(negedge sclk) begin
		if (~cs && c_counter < 16) begin
			dout <= {dout[14:0], dout_bit};		// Shifting register to the left to implement MSB first
			c_counter <= c_counter + 1;
		end else begin
			c_counter <= 0;
		end
	end

endmodule
