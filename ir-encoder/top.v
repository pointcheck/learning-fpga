module top (
        input wire clk25,
        input wire  [3:0] key,
        output wire [0:0] led,
        output wire [0:0] gpio
);

reg [31:0] cmd_reg;

reg rst = 1'b1;
  always @(posedge clk25)
    if (rst == 1'b1) rst <= 1'b0;

wire ready;
wire ir_out;

wire valid;
reg valid_reg;

wire [3:0] button_pressed;

assign led[0] = ready;
assign gpio[0] = ir_out;

assign valid = valid_reg;

always @(posedge clk25) begin
        if (button_pressed[0]) begin
                cmd_reg      <= 32'b10011101011000100000011100000111; // Right
        end
        else if (button_pressed[1]) begin
                cmd_reg      <= 32'b10011111011000000000011100000111; // Up
        end
        else if (button_pressed[2]) begin
                cmd_reg      <= 32'b10011110011000010000011100000111; // Down
        end
        else if (button_pressed[3]) begin
                cmd_reg      <= 32'b10011010011001010000011100000111; // Left
        end

        valid_reg <= |button_pressed;
end

genvar i;
generate
        for (i=0; i<4; i=i+1) begin: debouncers
                debouncer debounce_inst (
                   .clk(clk25),
                   .rst(rst),
                   .button_in(key[i]),
                   .button_pressed(button_pressed[i]),
                   .button_state(),
                   .button_released()
                );
        end
endgenerate


ir_encoder encoder (
        .clk(clk25),
        .rst(rst),
        .cmd(cmd_reg),
        .valid(valid),
        .ready(ready),
        .ir_output(ir_out)
);

endmodule



