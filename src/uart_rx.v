module uart_rx(
		//system signals
		input					sclk				,
		input					s_rst_n				,
		//UART Interface
		input					rs232_rx			,
		//others
		output	reg		[7:0]	rx_data				,
		output	reg				po_flag

);

	//define parameter and internal signals
	localparam		BAUD_END		= 5207;
	localparam		BAUD_M			= BAUD_END/2-1;
	localparam		BIT_END			= 8;
	
	reg				rx_r1				;
	reg				rx_r2				;
	reg				rx_r3				;
	reg				rx_flag				;
	reg	[12:0]		baud_cnt			;
	reg				bit_flag			;
	reg	[ 3:0]		bit_cnt				;
	
	wire			rx_neg;
	//main code
	
	assign rx_neg = ~rx_r2 & rx_r3;  //下降沿捕获
	
	//打3拍
	always @(posedge sclk) begin
		rx_r1 <= rs232_rx;
		rx_r2 <= rx_r1;
		rx_r3 <= rx_r2;
	end
	
	//rx_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rx_flag <= 0;
		end
		else if(rx_neg) begin
			rx_flag <= 1;
		end
		else if(bit_cnt == 'd0 && baud_cnt == BAUD_END) begin
			rx_flag <= 0;
		end
	end
	
	//bit_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_flag <= 0;
		end
		else if(baud_cnt == BAUD_M) begin
			bit_flag <= 1;
		end
		else begin
			bit_flag <= 0;
		end
	end
	
	
	//bit_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_cnt <= 0;
		end
		else if(bit_flag == 1 && bit_cnt == BIT_END) begin
			bit_cnt <= 0;
		end
		else if(bit_flag == 1) begin
			bit_cnt <= bit_cnt + 1;
		end
	end
	
	//baud_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			baud_cnt <= 0;
		end
		else if(rx_flag == 1 && baud_cnt == BAUD_END) begin
			baud_cnt <= 0;
		end
		else if(rx_flag == 1) begin
			baud_cnt <= baud_cnt + 1;
		end
		else begin
			baud_cnt <= 0;
		end
	end
	
	//rx_data
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rx_data <= 'd0;
		end
		else if(bit_flag == 1 && bit_cnt >= 'd1) begin
			rx_data <= {rx_r2, rx_data[7:1]};
		end
		else begin
			rx_data <= rx_data;
		end
	end
	
	//po_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			po_flag <= 'd0;
		end
		else if(bit_flag == 1 && bit_cnt == BIT_END) begin
			po_flag <= 'd1;
		end
		else begin
			po_flag <= 'd0;
		end
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
endmodule