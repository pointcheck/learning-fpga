module debouncer (
	input clk,
	input button_in,
	output button_pressed,
	output button_state,
	output button_released
);

	// Синхронизируем сигналы clk и button_in
	logic button_sync_0;
	logic button_sync_1;
	always_ff @(posedge clk) begin
		button_sync_0 <= button_in;					// Инвертируем входной сигнал кнопки, т.к. у многих механических кнопок (вроде бы) активное состояние - лог. 0
		button_sync_1 <= button_sync_0;
	end
	
	// Задаем счетчик чтобы отсчитать 262143 (~10 мс при частоте 25 Мгц)
	logic [17:0] counter;

	logic button_idle, button_state;
	assign button_idle = (button_state == button_sync_1);			// Проверка совпадения нынешнего и предыдущего стабильного состояния кнопки (кнопка не изменилась в этом такте?) 

	logic button_cnt_max;							// button_cnt_max = 1 только при заполненом counter
	assign button_cnt_max = &counter;
	
	// Считаем до 250000 каждый раз, когда состояние кнопки меняется
	always_ff @(posedge clk) begin
		if (button_idle) counter <= 18'd0;
		else begin
			counter <= counter + 18'd1;
			if (button_cnt_max) button_state <= ~button_state;
		end
	end

	assign button_pressed = ~button_idle & button_cnt_max & ~button_state;
	assign button_released = ~button_idle & button_cnt_max & button_state;

endmodule

/*
Значения сигналов:
button_in - входной сигнал от кнопки (до обработки от дребезга)
button_state - выходной сигнал от кнопки (ее полностью стабильное состояние после обработки от дребезга)
button_pressed - выходной сигнал, сигнализирующий о том, что кнопка была нажата
button_released - выходной сигнал, сигнализирующий о том, что кнопка была отпущена
button_sync_0 - значение кнопки в текущем такте (ну совсем нестабильное состояние)
button_sync_1 - значение кнопки в предыдущем такте ("полустабильное" состояние)
counter - 18 битный счетчик
18 бит выбраны потому что с частотой 25 МГц максимальное число (262143) будет отсчитано как раз за ~10 мс

button_idle - сигнал, показывающий, изменилась ли кнопка с момента прошлого полустабильного состояния
button_cnt_max - сигнал, сигнализирующий о заполненности счетчика counter (прошло ~10 мс)
*/
