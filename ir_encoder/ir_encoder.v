module ir_encoder (
    input wire rst,        // Reset
    input wire clk,        // 25 MHz clock
    input wire [31:0] cmd, // Command to transmit
    input wire valid,      // Valid signal
    output reg ready,      // Ready signal
    output reg ir_output   // IR output signal
);

//===============================================
// State parameters
//===============================================
localparam [2:0]
    IDLE        = 3'd0,    // Waiting for command
    START_MOD   = 3'd1,    // Start modulation
    START_SPACE = 3'd2,    // Start pause
    ACTIVE      = 3'd3,    // Active bit transfer
    PAUSE       = 3'd4,    // Pause between bits
    GAP		= 3'd5;    // Pause between commands
//===============================================
// Time interval parameters
//===============================================
localparam
    //CLK_FREQ     = 25_000_000, Clock frequency
    //CARRIER_FREQ = 36_000, Carrier frequency
    //DATA_RATE    = 900, Envelope frequency

    CARRIER_DIV = 347, // 25000000/(36000*2)
    DATA_DIV    = 13888, // 25000000/(900*2)
    START_TICKS = 112500, // (4,5ms) 25000000/1000000*4500
    STOP_TICKS  = 5000000; //  (200 ms) 25000000/1000000*200000

//===============================================
// Generation clock signal
//===============================================
reg [15:0] carrier_cnt;
reg carrier_36k;

// Generation 36 kHz
always @(posedge clk or posedge rst) begin
    if(rst) begin
        carrier_cnt <= 0;
        carrier_36k <= 0;
    end else begin
        if(carrier_cnt >= CARRIER_DIV-1) begin
            carrier_cnt <= 0;
            carrier_36k <= ~carrier_36k;
        end else begin
            carrier_cnt <= carrier_cnt + 1;
        end
    end
end
 
//===============================================
// Transfer state machine
//===============================================
reg [31:0] shift_reg;
reg [5:0]  bit_cnt;
reg [23:0] main_cnt;
reg [27:0] gap_cnt;
reg [2:0]  state;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        ready     <= 1'b1;
        ir_output <= 1'b0;
        shift_reg <= 0;
        bit_cnt   <= 0;
        main_cnt  <= 0;
	gap_cnt   <= 0;
        state     <= IDLE;
    end else begin
        case(state)
            IDLE: begin
                ir_output <= 1'b0;
                if(valid && ready) begin
                    shift_reg <= cmd;
                    ready     <= 1'b0;
                    main_cnt  <= 0;
                    state     <= START_MOD;
                end
            end

            START_MOD: begin
                ir_output <= carrier_36k;
                if(main_cnt == START_TICKS) begin
                    main_cnt <= 0;
                    state    <= START_SPACE;
                end else begin
                    main_cnt <= main_cnt + 1;
                end
            end

            START_SPACE: begin
                ir_output <= 1'b0;
                if(main_cnt == START_TICKS) begin
                    main_cnt   <= 0;
                    bit_cnt    <= 0;
                    state      <= ACTIVE;
                end else begin
                    main_cnt <= main_cnt + 1;
                end
            end

            ACTIVE: begin
                ir_output <= carrier_36k;
                if(main_cnt == DATA_DIV-1) begin
                    main_cnt <= 0;
                    state    <= PAUSE;
                end else begin
                    main_cnt <= main_cnt + 1;
                end
            end

            PAUSE: begin
                ir_output <= 1'b0;
                if(main_cnt == (shift_reg[0] ? (DATA_DIV*3)-1 : DATA_DIV-1)) begin 
                    main_cnt <= 0;
                    shift_reg <= {1'b0, shift_reg[31:1]}; // shift right with 0
                    bit_cnt   <= bit_cnt + 1;
                    if(bit_cnt == 32) begin
                        state <= GAP; 
			gap_cnt <= 1'b0;
                    end else begin
                        state <= ACTIVE;
                    end
                end else begin
                    main_cnt <= main_cnt + 1;
                end
            end

	    GAP: begin
                ir_output <= 1'b0;
                if(gap_cnt == STOP_TICKS-1) begin
                    ready <= 1'b1;
                    state <= IDLE;
                end else begin
                    gap_cnt <= gap_cnt + 1;
                end
            end
        endcase
    end
end

endmodule                                  
