`timescale 1ns/1ns

module uart_top_tb();
	
	reg		sys_clk			;
	reg		sys_rst_n		;
	reg		rs232_rx		;
	
	wire	rs232_tx		;
	
	//// main code ////
	
	// initial clk, rst, input signals
	initial begin
		sys_clk			= 1'b1;
		sys_rst_n		= 1'b0;
		rs232_rx		= 1'b1;
		#20 
		sys_rst_n		= 1'b1;
	end
	
	always #10 sys_clk			<= ~sys_clk;
	
	// use task
	initial begin
		#200
		rx_byte();
	end
	
	// task rx_byte
	task rx_byte();
		integer		j		;
		for(j = 0; j < 8; j = j + 1) begin
			rx_bit(j);
		end
	endtask
	
	// task rx_bit
	task rx_bit(
		input	[7:0]	data
	);
		integer		i		;
		for(i = 0; i < 10; i = i + 1) begin
			case(i)
				0: rs232_rx <= 1'b0;
				1: rs232_rx <= data[0];
				2: rs232_rx <= data[1];
				3: rs232_rx <= data[2];
				4: rs232_rx <= data[3];
				5: rs232_rx <= data[4];
				6: rs232_rx <= data[5];
				7: rs232_rx <= data[6];
				8: rs232_rx <= data[7];
				9: rs232_rx <= 1'b1;
				default : ;
			endcase
			#(5208 * 20);
		end
	endtask
	
	//// inst ////
	uart_top		U_uart_top(
			.sys_clk		(sys_clk)		,
			.sys_rst_n		(sys_rst_n)		,
			.rs232_rx		(rs232_rx)		,
			.rs232_tx		(rs232_tx)		
	);


endmodule

