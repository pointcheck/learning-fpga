module ir_decoder (
	input wire clk,
        input wire rst,
	input wire ack,
        input wire enable,
        input wire ir_input,
        output reg ready,
        output wire [31:0] command,
);
	localparam T0_MIN = (28256-2816)/64;				//количество тактового сигнвла соотвествует сигнал 0 (время*чачтота = 1,13мс*25000000)
	localparam T0_MAX = (28256+2816)/64;
	localparam T1_MIN = (57008-5648)/64;				 //количество тактового сигнвла соотвествует сигнал 1(время*чачтота = 2.28мс*25000000)
	localparam T1_MAX = (57008+5648)/64;
	localparam START_MIN = (128176-6400)/64;			 //количество тактового сигнвла соотвествует сигнал старта
	localparam START_MAX = (128176+6400)/64;
	
	reg [15:0] slow_clk_div;
	wire slow_clk;

        wire strobe_front;

	reg  ir_input_last;						//предыдущий бит 
	reg [20:0] t1;							// счетчик для определения длинн бит-0 и бит-1
	reg [7:0] bit_count;						//считать число быитов до 31
	reg [31:0] cmd;							//32-битовый от пульта


	always @(posedge clk or posedge rst)
	begin
		if(rst) begin
			slow_clk_div <= '0;
		end else begin
			slow_clk_div <= slow_clk_div + 'd1;
		end

	end
	
	assign slow_clk = slow_clk_div[5];				//уменьшение частоты на 64 раз

	assign command[31:0] = cmd[31:0];

	assign strobe_front = (ir_input_last != ir_input) * ir_input; //условие для фронта тактового сигнала

	always @(posedge slow_clk or posedge rst)
        begin
		if(rst) begin					//Сброс
			ir_input_last <= 1'b1;
		        t1 <= 'b0;
			bit_count <= '0;
			cmd<= '0;
			ready <= 1'd0;

                end else begin
                        if(enable)
                        begin	
				
				ir_input_last <= ir_input;
				
				if(strobe_front == 'b0)	 //проверить фронт тактового сингнал
					t1<=t1+ 'b1;
				else begin
						
					if(t1 == 21'h1fffff) begin //ограничения время
						t1 <= '0;
						bit_count <= '0;
						cmd <= '0;
					end

				        if(t1>START_MIN  && t1<START_MAX) begin		// Стартовый сигнал
						bit_count <= '0;
						cmd <= '0;
					end
					
					if(!ready) begin	//когда полная команда запишется то ready = 1
					
						if(t1<T0_MAX && t1>T0_MIN) begin	//Сигнал "0"
							cmd = {1'b0, cmd[31:1]};
							bit_count<=bit_count+'b1;	
						end

						if(t1>T1_MIN && t1<T1_MAX) begin	//Сигнал "1"
							cmd = {1'b1, cmd[31:1]};
							bit_count <= bit_count + 'b1;
						end
					end
					t1<='b0;
					if (bit_count == 31) begin
						ready <= 1;
					end
				end
				//if (ack == 1) ready <= 1'd0;	//Вспомогательный сигнал чтобы команнды не повториться

                        end
                end

        end
endmodule
