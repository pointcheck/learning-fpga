module uart_rx (
    input wire rst,        	  // Reset
    input wire clk,        	  // 25 MHz clocki
    input wire rx,	   	  // uart input signal
    input wire [31:0] baudrate,   // baudrate selector
    input wire valid,      	  // Valid signal
    input wire [1:0] stop_bits,   // 0 - 1 stop bit, 1 - 2 stop bits, 2 - 1,5 stop bits 
    input wire parity_en,	  // Enable pariry_type (1-Enable)
    input wire parity_type,	  // 0 - Even parity, 1 - Odd parity
    output wire parity_valid,	  // Parity valid flag
    output reg ready,      	  // Ready signal
    output reg [7:0] rx_data
);

//===============================================
// Internal signals
//===============================================

reg [31:0] baud_counter;
reg [3:0] bit_counter;
reg [2:0] state;
reg parity_bit;
reg parity_calc;
reg rx_prev;


//===============================================
// State parameters
//===============================================

localparam [2:0]
    IDLE        = 3'd0,    // Waiting for command
    START_BIT   = 3'd1,    // Start bit receive
    DATA_BITS   = 3'd2,       
    PARITY_BIT  = 3'd3,	   // Parity
    STOP_BIT    = 3'd4;	   // Stop bit

//===============================================
// Baudrate calculation
//===============================================

wire [31:0] baud_limit;
wire [31:0] half_baud_limit;
assign baud_limit = (25000000/baudrate) - 1;
assign half_baud_limit = baud_limit / 2;

//===============================================
// Main state machine
//===============================================

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state        <= IDLE;
        bit_counter  <= 0;
	baud_counter <= 0;
	rx_data      <= 0;
	ready        <= 1'b1;
	parity_bit   <= 1'b0;
	parity_calc  <= 1'b0;
	rx_prev      <= 1'b1;
    end else begin

	    rx_prev  <= rx;

	    case (state)
		    IDLE: begin
			    ready   <= 1'b1;
			    rx_data <= 0;
			    if (valid && rx_prev && !rx) begin  // Falling edge detected
				    state <= START_BIT;
				    baud_counter <= 0;
				    parity_calc  <= 1'b0;
				    ready        <= 1'b0;
			    end
		    end
		    
		    START_BIT: begin
			    if (baud_counter == half_baud_limit) begin
				    if (valid && !rx) begin
					    state <= DATA_BITS;
			                    baud_counter <= 0;
					    bit_counter  <= 0;
				    end else begin
					    state <= IDLE;
				    end
			    end else begin
				    baud_counter <= baud_counter +1;
			    end
		    end

		    DATA_BITS: begin
			    if (baud_counter == baud_limit) begin
				    baud_counter <= 0;
				    if (valid) begin
					    rx_data[bit_counter] <= rx;
					    parity_calc <= parity_calc ^ rx;
				    end

				    if (bit_counter == 7) begin
					    if (parity_en) begin
						    state <= PARITY_BIT;
					    end else begin
						    state <= STOP_BIT;
					    end
				    end else begin
					    bit_counter <= bit_counter + 1;
				    end
			    end else begin
				    baud_counter <= baud_counter + 1;
			    end
		    end

		    PARITY_BIT: begin
			    if (baud_counter == baud_limit) begin
				    baud_counter <= 0;
				    if (valid) parity_bit <= rx;
				    state <= STOP_BIT;
		            end else begin
				    baud_counter <= baud_counter + 1;
			    end
		    end
		    
		    STOP_BIT: begin
			    if (stop_bits == 2'd0) begin
				    if (baud_counter == baud_limit) begin
					    baud_counter <= 0;
					    state <= IDLE;
					    ready <= 1'b1;
				    end else begin
					    baud_counter <= baud_counter +1;
				    end

			    end else if (stop_bits == 2'd1) begin
				    if (baud_counter == (baud_limit*2)) begin
					    baud_counter <= 0;
					    state <= IDLE;
					    ready <= 1'b1;
				    end else begin
					    baud_counter <= baud_counter +1;
				    end

			    end else if (stop_bits == 2'd2) begin
				    if (baud_counter == (baud_limit + half_baud_limit)) begin
					    baud_counter <= 0;
					    state <= IDLE;
					    ready <= 1'b1;
				    end else begin
					    baud_counter <= baud_counter +1;
				    end
			    end
		    end
	    endcase
    end
end

assign parity_valid = parity_en ? ((parity_type == 0) ? (parity_calc == parity_bit) : (parity_calc != parity_bit)) : 1'b1;

endmodule
