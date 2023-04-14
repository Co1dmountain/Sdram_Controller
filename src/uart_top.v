module uart_top(
	//input 
	input		sys_clk			,
	//input		sys_rst_n		,
	input		rs232_rx		,
	
	//output
	//output		led				,
	//output		reg led2			,
	//output		reg clk_reg			,
	output		rs232_tx		
);
	//// define ////
	wire		[7:0]		po_data		;
	wire					tx_flag		;
	
	reg			[15:0]		rst_cnt = 0	;
	reg						sys_rst_n_reg	;
	wire					sys_rst_n	;
	
	//assign led = 1'b1;
	
	//// main code ////
	always @(posedge sys_clk) begin
		if(rst_cnt == 16'd1000) begin
			rst_cnt <= 16'd2000		;
		end
		else if(rst_cnt < 16'd1000) begin
			rst_cnt <= rst_cnt + 1		;
		end
		else begin
			rst_cnt <= rst_cnt			;
		end
	end
	  
	always @(posedge sys_clk) begin
		if(rst_cnt == 16'd2000) begin
			sys_rst_n_reg 	<= 1'b1;
			//led2		<= 1'b1;
		end
		else begin
			sys_rst_n_reg 	<= 1'b0;
			//led2		<= 1'b0;
		end
	end
	
	
/* 	always @(posedge sys_clk or negedge sys_rst_n_reg) begin
		if(!sys_rst_n_reg) begin
			clk_reg <= 0;
		end
		else begin
			clk_reg <= ~clk_reg;
		end
		
	end */
	
	assign sys_rst_n = sys_rst_n_reg;
	
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
	
//	uart_tx uart_tx_inst(
//		.sys_clk (sys_clk ), //input sys_clk
//		.sys_rst_n (sys_rst_n ), //input sys_rst_n
//		.pi_data (po_data ), //output [7:0] pi_data
//		.pi_flag (tx_flag ), //output pi_flag
//		
//		.tx (rs232_tx ) //input tx
//	
//	);
	
	
	


endmodule