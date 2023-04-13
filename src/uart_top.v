module uart_top(
	//input 
	input		sys_clk			,
	input		sys_rst_n		,
	input		rs232_rx		,
	
	//output
	output		rs232_tx		
);
	//// define ////
	wire		[7:0]		po_data		;
	wire					tx_flag		;


	//// main code ////
	//inst
	uart_rx		U_uart_rx(
			.sclk			(sys_clk)		,
			.s_rst_n		(sys_rst_n)		,
			
			.rs232_rx		(rs232_rx)		,
			
			.po_data		(po_data)		,
			
			.po_flag		(tx_flag)
	);
	
	uart_tx		U_uart_tx(
			.sclk			(sys_clk)		,
			.s_rst_n		(sys_rst_n)		,
			
			.tx_flag		(tx_flag)		,
			
			.tx_data		(po_data)		,
			
			.rs232_tx		(rs232_tx)		
	);
	
	
	
	
	
	
	


endmodule