module debouncer (
    input wire clk,
    input wire rst,
    input wire button_in,
    output reg button_pressed,
    output reg button_state,
    output reg button_released
);

    reg button_sync_0;  // First synchronization register
    reg button_sync_1;  // Second synchronization register
    
    // Synchronization flip-flops
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            button_sync_0 <= 1'b0;
            button_sync_1 <= 1'b0;
        end else begin
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0;
        end
    end

    reg [17:0] counter;  // 18-bit counter (counts up to 262143)
    
    wire button_idle;
    assign button_idle = (button_state == button_sync_1);  // Check if button state is stable
    
    wire button_cnt_max;
    assign button_cnt_max = &counter;  // AND reduction - true when all bits are 1
    
    // Debouncing logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 18'd0;
            button_state <= 1'b0;
            button_pressed <= 1'b0;
            button_released <= 1'b0;
        end else begin
            // Default outputs
            button_pressed <= 1'b0;
            button_released <= 1'b0;
            
            if (button_idle) begin
                counter <= 18'd0;
            end else begin
                counter <= counter + 18'd1;
                if (button_cnt_max) begin
                    button_state <= ~button_state;
                    // Generate single-cycle pulses
                    if (~button_state) button_pressed <= 1'b1;
                    else button_released <= 1'b1;
                end
            end
        end
    end

endmodule
