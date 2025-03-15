module top (
	input clk25,
	inout logic [3:0] gpio,
	input logic [3:0] led
);

	// Объявим мотор
	motor_drv 
	# (

	) motor_inst (

	);



	// Объявим серву
	servo_pdm
	# (

	) servo_inst (

	);



	// Объявим декодер
	ir_decoder
	# (

	) decoder_inst (

	);	



	// Объявим контрол
	control
	# (
		
	) control_inst (

	);

endmodule
