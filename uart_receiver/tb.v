`timescale 1ns / 1ps

module uart_rx_tb;

// Parameters
parameter CLK_PERIOD = 40;       // 25 MHz = 40 ns period
parameter BAUD_RATE = 115200;
parameter BIT_PERIOD = 1000000000/BAUD_RATE; // ~8680 ns for 115200 baud

// Inputs
reg clk;
reg rst;
reg rx;
reg valid;
reg [1:0] stop_bits;
reg parity_en;
reg parity_type;

// Outputs
wire parity_valid;
wire ready;
wire [7:0] rx_data;

// Instantiate the UART receiver
uart_rx uut (
    .rst(rst),
    .clk(clk),
    .rx(rx),
    .baudrate(BAUD_RATE),
    .valid(valid),
    .stop_bits(stop_bits),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .parity_valid(parity_valid),
    .ready(ready),
    .output_rx_data(rx_data)
);

// Clock generation
always begin
    clk = 1'b0;
    #(CLK_PERIOD/2);
    clk = 1'b1;
    #(CLK_PERIOD/2);
end

// Task for sending one byte
task send_byte;
    input [7:0] data;
    integer i;
    begin
        // Start bit
        rx = 1'b0;
        #BIT_PERIOD;
        
        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #BIT_PERIOD;
        end
        
        // Parity bit (Even)
        rx = ^data; // XOR всех битов для Even parity
        #BIT_PERIOD;
        
        // Stop bit
        rx = 1'b1;
        #BIT_PERIOD;
    end
endtask

// Test stimulus
initial begin
    // Initialize inputs
    rst = 1'b1;
    rx = 1'b1; // Idle state
    valid = 1'b1;
    stop_bits = 2'b00; // 1 stop bit
    parity_en = 1'b1;  // Enable parity
    parity_type = 1'b0; // Even parity
    
    // Reset the system
    #100;
    rst = 1'b0;
    #100;
    
    // Test case 1: Send 'A' (0x41)
    $display("Sending 'A' (0x41)");
    send_byte(8'h41);
    
    // Verify first byte
    #(BIT_PERIOD*2); // Small delay
    if (rx_data === 8'h41 && parity_valid === 1'b1) begin
        $display("Test 1 PASSED: Received 0x41 with valid parity");
    end else begin
        $display("Test 1 FAILED");
    end
    
    // Wait until ready is asserted
    wait(ready == 1'b1);
    #(BIT_PERIOD*4);
    
    // Test case 2: Send 'B' (0x42)
    $display("Sending 'B' (0x42)");
    send_byte(8'h42);
    
    // Verify second byte
    #(BIT_PERIOD*2);
    if (rx_data === 8'h42 && parity_valid === 1'b1) begin
        $display("Test 2 PASSED: Received 0x42 with valid parity");
    end else begin
        $display("Test 2 FAILED");
    end
    
    // Additional delay for observation
    #(BIT_PERIOD*10);
    $finish;
end

// Monitor
initial begin
    $monitor("Time = %t ns: state = %d, rx_data = %h, parity_valid = %b, ready = %b", 
             $time, uut.state, rx_data, parity_valid, ready);
end

initial begin
    $dumpfile("uart_rx_tb.vcd");  // Создаем файл для сохранения波形
    $dumpvars(0, uart_rx_tb);     // Записываем все сигналы тестбенча
end

endmodule
