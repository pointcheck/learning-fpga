module top (
        input wire clk25,
	input wire uart_debug_rxd,
	input wire [0:0] key,
        output reg [3:0] led
);

wire [31:0] baudrate  = 32'd115200;
wire parity_valid;
wire ready;

wire rst;
assign rst = key[0];
reg [7:0] rx_data;

always @(posedge clk25) begin
	
		if (rx_data == 8'h36) led[3:0] = 4'b0001;

		else if (rx_data == 8'h32) led[3:0] = 4'b0010;

	        else if (rx_data == 8'h38) led[3:0] = 4'b0100;

	        else if (rx_data == 8'h34) led[3:0] = 4'b1000;

		else led[3:0] = 4'b0000;

end

uart_rx uart_main (
    .rst(rst),
    .clk(clk25),
    .rx(uart_debug_rxd),
    .baudrate(baudrate),
    .valid(1'b1),
    .stop_bits(2'd0),
    .parity_en(1'b1),
    .parity_type(1'b0),
    .parity_valid(parity_valid),
    .ready(ready),
    .rx_data(rx_data)
);


endmodule

endmodule
