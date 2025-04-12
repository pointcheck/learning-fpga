module adc_capture
# (
	parameter clk_hz = 25000000,						
	parameter sclk_hz = 5000000,						// ADC128S052 polling frequency (3.2-8 MHz)
	parameter cycle_pause = 10						// amount of slowed clocks (sclk) between ADC cycles  
) (
	input  logic clk,
	input  logic rst,
	input  logic ctl_valid,							// == 1 if control is ready to process d_signal
	input  logic adc_ack,							// == 1 if control processed d_signal
	input  logic [2:0] address,						// Address of ADC's analog input (IN0 - IN7)
	input  logic dout_bit,							// DOUT port that sends converted digital signal
	output logic sclk,							// Slowed clocks sended to ADC SCLK port
	output logic cs,							// ADC's CS signal that begins the work cycle
	output logic adc_ready,							// == 1 if ADC finished converting analog -> digital
	output logic din_bit,							// DIN port to that adc_capture sends input address
	output logic [11:0] d_signal						// Converted digital signal (12-bit)
);

	localparam MAX_DIV = clk_hz / (2 * sclk_hz) - 1;			// Dividing clk_hz to sclk_hz
	logic [$clog2(MAX_DIV) - 1:0] frdiv;

	logic clk2;
	always_ff @(posedge clk or posedge rst) begin

		if (rst) begin
			sclk <= 1'd0;
			clk2 <= 1'd0;
			frdiv <= 'd0;
		end else begin
			if (frdiv >= MAX_DIV) begin
				clk2 <= ~clk2;

				if (~cs) sclk <= ~sclk;

				frdiv <= 'd0;
			end else begin
				frdiv <= frdiv + 'd1;
			end
		end

	end

	logic [7:0] din;						// Declaring what to send to the DIN port: 000 + address(3-bit) + 00
	logic [15:0] dout;						// Declaring what to get from the DOUT port: 0000 + d_signal(12-bit)
	assign d_signal = dout[11:0];

	logic [4:0] cs_reg;						// cs_reg(4-bit) is used to count length of ADC's work cycle (16 slowed clocks sclk)
	logic [$clog2(cycle_pause) - 1:0] cs_pause;			// cs_pause is used to count length of ADC's pause between work cycles (cycle_pause slowed clocks)

	always_ff @(negedge clk2 or posedge rst) begin
		if(rst) begin
			din_bit <= 1'd0;
                        din <= 8'd0;
		end else begin
			// 00 address[2:0] 000
			din[7:0] <= {2'b00, address, 3'b00};
			if (cs == 1'd0) begin                                   // Performing single work cycle (cs = 1)

				if (cs_reg < 8) begin
					din_bit <= din[5'd7 - cs_reg];  // Sending MSB to ADC DIN (000 + address + 00)
				end
			end
		end	
	end

	always_ff @(posedge clk2 or posedge rst) begin

		if (rst) begin						// Resetting all regs (not inputs except dout_bit)

			adc_ready <= 1'd0;

			cs_reg <= 5'd0;
			cs_pause <= 'd0;
			cs <= 1'd0;

			//din_bit <= 1'd0;
			//din <= 8'd0;

			dout <= 16'd0;
						
		end else begin
			
			// 00 address[2:0] 000
		//	din[7:0] <= {1'b0, address, 4'b0};

			if (cs == 1'd0) begin					// Performing single work cycle (cs = 1)

//				if (cs_reg < 8) begin
//					din_bit <= din[5'd7 - cs_reg];	// Sending MSB to ADC DIN (000 + address + 00)
//				end

				dout[15:0] <= {dout[14:0], dout_bit};		// Recieving MSB from ADC DOUT and shifting it to the left (0000 + d_signal) 

				if (cs_reg == 5'd16) begin			// Clearing cs after 16 slowed clocks (end of work cycle)
					cs <= 1'd1;
					cs_reg <= 5'd0;
					adc_ready <= 1'd1;		// Setting adc_ready after finishing work cycle

				end else begin
					cs_reg <= cs_reg + 5'd1;
				end

			end else begin					// Performing pause before another work cycle

				if (cs_pause >= cycle_pause) begin	// Setting cs after cycle_pause slowed clocks
					cs <= 1'd0;
					cs_pause <= 'd0;

				end else begin
					cs_pause <= cs_pause + 'd1;
				end

				if (adc_ack) begin
					adc_ready <= 1'd0;		// Clearing adc_ready after control processed d_signal
				end

			end

		end
	
	end

endmodule

// При частоте 5 Мгц период одного цикла = 3.2 мкс,
// что соответствует 312.5 кГц

// Мерим 9.6 мкс через 16 МГц = 
// 000 address(3-bit) 00
