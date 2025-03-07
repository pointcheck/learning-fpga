module top (
	input  logic clk25,
	input  logic key[0],
	input  logic spi0_miso,
	output logic spi0_sclk,
	output logic spi0_mosi,
	output logic [3:0] led
);

	logic cs;
	logic [11:0] d_signal;

	adc_polling
	# (
		.clk_hz(25000000),
		.adc_hz(5000000)
	) adc_polling_inst(
		.clk(clk25),
		.cs(~cs),
		.add(3'b000),
		.dout_bit(spi0_miso),
		.sclk(spi0_sclk),
		.din_bit(spi0_mosi),
		.d_signal(d_signal)
	);

	assign cs = key[0];
	assign led[3:0] = d_signal[11:8];

endmodule
