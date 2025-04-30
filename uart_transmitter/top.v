module top (
        input wire clk25,
        input wire  [1:0] key,
        output wire [0:0] led,
        output wire uart_debug_txd
);

wire [31:0] baudrate  = 31'd115200;

wire rst;
assign rst = key[0];

wire ready;
reg [7:0] data = 8'h41; //"A"

wire valid;
assign valid = key[1];


wire tx;


assign led[0] = ready;
assign uart_debug_txd = tx;


uart_tx uart (
        .clk(clk25),
        .rst(rst),
        .data(data),
        .baudrate(baudrate),
        .ready(ready),
	.valid(valid),
	.parity_en(1'b1), // Enable bit parity
	.parity_type(1'b1), // Odd parity
	.tx(tx)
);

endmodule
