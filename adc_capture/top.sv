module top (
	input  logic clk25,
	input  logic [3:0] key,
	input  logic adc_spi_miso,
	output logic [3:0] led,
	output logic adc_spi_mosi,
	output logic adc_spi_sclk,
	output logic adc_spi_csn,

	output logic [3:0] gpio
);

	logic rst;
	logic en;
	logic ctl_valid;
	logic adc_ack;
	logic [2:0] address;
	logic dout_bit;
	logic sclk;
	logic cs;
	logic adc_ready;
	logic din_bit;
	logic [11:0] d_signal;

	adc_capture # (
		.clk_hz(25000000),
		.sclk_hz(500000),
		.cycle_pause(30)
	) adc_capture_inst (
		.clk(clk25),
		.rst(rst),
		.en(en),
		.adc_ack(adc_ack),
		.address(address),
		.dout_bit(dout_bit),
		.sclk(sclk),
		.cs(cs),
		.adc_ready(adc_ready),
		.din_bit(din_bit),
		.d_signal(d_signal)
	);

	always_ff @(posedge clk25 or posedge rst) begin

		if (rst) begin
			en <= 1'd1;
			adc_ack <= 1'd0;
			address <= 3'b000;			
			
		end else begin
			if (key[2:0] == 3'b101) begin
				en <= 1'd0;
			end
		end

	end

	assign adc_spi_sclk = sclk;
	assign adc_spi_mosi = din_bit;
	assign adc_spi_csn = cs;
	assign dout_bit = adc_spi_miso;

	assign gpio[0] = sclk;
	assign gpio[1] = cs;
	assign gpio[2] = din_bit;
	assign gpio[3] = dout_bit;

	assign rst = key[3];

	always_comb begin

		case (key[2:0])

			3'b011: led = d_signal[3:0];
			3'b010: led = d_signal[7:4];
			3'b001: led = d_signal[11:8];
			3'b100: led = {1'b0, address};

			default: led = {rst, cs, adc_ack, adc_ready};

		endcase

	end

endmodule
