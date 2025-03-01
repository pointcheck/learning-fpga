module top (						// This module is for testing debouncer.sv
	input logic clk25,
	input logic [1:0] key,
	output logic [2:0] led
);

	logic button_pressed, button_released;
        logic button_reg0, button_reg1;

	debouncer debouncer_test(
		.clk(clk25),
		.button_in(key[0]),
		.button_pressed(button_pressed),
		.button_state(led[1]),
		.button_released(button_released)
	);

	always_ff @(posedge clk25) begin
		if (button_pressed) button_reg0 <= 1'd1;
		if (button_released) button_reg1 <= 1'd1;
		if (key[1]) begin
			button_reg0 <= 1'd0;
			button_reg1 <= 1'd0;
		end
	end

	assign led[0] = button_reg0;
	assign led[2] = button_reg1;

endmodule
