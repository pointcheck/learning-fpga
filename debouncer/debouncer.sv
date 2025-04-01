module debouncer (
	input logic clk,
	input logic rst,
	input logic button_in,
	output logic button_pressed,
	output logic button_state,
	output logic button_released
);

	logic button_sync_0;							// Declaring 2 regs to sync clk and button_in signals
	logic button_sync_1;
	always_ff @(posedge clk) begin
		button_sync_0 <= button_in;	
		button_sync_1 <= button_sync_0;
	end
	
	logic [17:0] counter;							// Declating 18 bit counter to count to ~250000

	logic button_idle, button_state;
	assign button_idle = (button_state == button_sync_1);			// Checking if the button changes its state on this clock cycle 

	logic button_cnt_max;							// button_cnt_max = 1 only if counter is full
	assign button_cnt_max = &counter;
	
	always_ff @(posedge clk) begin
		if (button_idle) counter <= 18'd0;
		else begin
			counter <= counter + 18'd1;
			if (button_cnt_max) button_state <= ~button_state;	// Updating recent stable state comparing to the last one
		end
	end

	assign button_pressed = ~button_idle & button_cnt_max & ~button_state;
	assign button_released = ~button_idle & button_cnt_max & button_state;

endmodule
