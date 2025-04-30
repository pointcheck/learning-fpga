module uart_tx (
	input wire rst,        	  // Reset
    input wire clk,        	  // 25 MHz clock
    input wire [7:0] data, 	  // byte to transmit (need to use param)
    input wire [31:0] baudrate,   // baudrate selector
    input wire valid,      	  // Valid signal
    input wire parity_en,	  // Enable pariry_type (1-Enable)
    input wire parity_type,	  // 0 - Even parity, 1 - Odd parity
    output reg ready,      	  // Ready signal
    output reg tx	   	  // uart output signal
);

//===============================================
// State parameters
//===============================================

localparam [2:0]
    IDLE        = 3'd0,    // Waiting for command
    START_BIT   = 3'd1,    // Start bit
    DATA_BITS   = 3'd2,    // Start bit transfer
    PARITY_BIT  = 3'd3,	   // Parity
    STOP_BIT    = 3'd4;	   // Stop bit

//===============================================
// Transmitter state machine
//===============================================
reg [7:0] shift_reg;
reg [2:0] bit_count;
reg [2:0]  state;

reg parity_bit;
wire final_parity;
assign final_parity = parity_type ? ~(^data) : ^data;

reg [31:0] baud_counter;
wire [31:0] baud_limit;
assign baud_limit = (25000000/baudrate) - 1;
reg baud_tick;

reg valid_prev;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        tx <= 1'b1;
        ready <= 1'b1;
        shift_reg <= 0;
        bit_count <= 0;
	baud_tick <= 0; // for test
	baud_counter <= 0;
    end else begin
	    valid_prev <= valid;

	    // Generation clk with baudrate
	if (state != IDLE) begin
		if (baud_counter == baud_limit) begin
			baud_counter <= 0;
			baud_tick <= 1'b1; 
		end else begin
			baud_counter <= baud_counter + 1;
			baud_tick    <= 1'b0;
		end
	end else begin
		baud_counter <= 0;
		baud_tick    <= 1'b1; // for test
	end


        case (state)
            IDLE: begin
                tx <= 1'b1;
		//ready <= 1'b1;
                if (ready && valid && !valid_prev) begin
                    state <= START_BIT;
                    shift_reg <= data;
		    baud_counter <= 0;
                    ready <= 1'b0;
		    parity_bit <= final_parity;
                end
            end

	    //valid_prev <= valid;

            START_BIT: begin
                tx <= 1'b0;  
                if (baud_counter == baud_limit) begin
                    state <= DATA_BITS;
		    baud_counter <= 0;
		    bit_count <= 0;
                end
            end

            DATA_BITS: begin
                tx <= shift_reg[0]; 
                if (baud_counter == baud_limit) begin
                    shift_reg <= {1'b0, shift_reg[7:1]};  
		    baud_counter <= 0;
		    bit_count <= bit_count + 1;
                    if (bit_count == 7) begin // 8 bit
                        state <= parity_en ? PARITY_BIT : STOP_BIT;
                    end
                end else begin
                    baud_counter <= baud_counter + 1;
                end
            end

	    PARITY_BIT: begin
		    tx <= parity_bit;
		    if (baud_counter == baud_limit) begin
			    state <= STOP_BIT;
		    end
	    end

            STOP_BIT: begin
                tx <= 1'b1; 
                if (baud_counter == baud_limit) begin
                    baud_counter <= 0;
                    state <= IDLE;
		    ready <= 1'b1;
                end
            end
        endcase

    end
end


endmodule
