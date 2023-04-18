
module uart_rx(
		// input 
		input				sclk		,
		input				s_rst_n		,
		input				rs232_rx	,
		// output
		output	reg			po_flag		,
		output	reg [7:0]	po_data	
);

	//// define ////
	localparam			BAUD_END		= 5208			;
	localparam			BAUD_M			= BAUD_END/2-1	;
	localparam			BIT_END			= 9				;

	reg					rx_r1							;
	reg					rx_r2							;
	reg					rx_r3							;
	reg					work_en							;
	reg					rx_flag							;	// 1rx process done flag
	reg					bit_flag						;	// 1bit done flag
	reg		[12:0]		baud_cnt						;
	reg		[ 3:0]		bit_cnt							;
	reg		[ 7:0]		rx_data							;
	
	wire				rx_neg							;

	//// main code ////
	
	assign rx_neg = ~rx_r2 & rx_r3;
	
	// reg
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rx_r1			<= 1'b0		;
			rx_r2			<= 1'b0		;
			rx_r3			<= 1'b0		;
		end
		else begin
			rx_r1			<= rs232_rx	;
			rx_r2			<= rx_r1	;
			rx_r3			<= rx_r2	;			
		end
	end

	// work_en
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			work_en			<= 1'b0		;
		end
		else if(rx_neg) begin
			work_en			<= 1'b1		;	
		end
		else if(rx_flag == 1'b1) begin  // when pull work_en down
			work_en			<= 1'b0		;
		end
	end
	
	// baud_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			baud_cnt		<= 13'd0		;
		end
		else if(work_en) begin
			if(baud_cnt == BAUD_END - 1) begin
				baud_cnt	<= 13'd0		;
			end
			else begin
				baud_cnt	<= baud_cnt + 1'b1;
			end
		end
		else begin  
			baud_cnt		<= 13'd0		;
		end
	end
	
	// bit_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_cnt			<= 4'd0		;
		end
		else if(work_en) begin
			if(bit_cnt == BIT_END - 1 && bit_flag == 1'b1) begin
				bit_cnt		<= 4'd0		;
			end
			else if(bit_flag == 1'b1)begin
				bit_cnt		<= bit_cnt + 1'b1;
			end
		end
		else begin  
			bit_cnt			<= 4'd0		;
		end
	end
	
	// bit_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_flag		<= 1'b0		;
		end
		else if(baud_cnt == BAUD_END/2-1) begin
			bit_flag		<= 1'b1		;	
		end
		else begin
			bit_flag		<= 1'b0		;
		end
	end
	
	// rx_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rx_flag			<= 1'b0		;
		end
		else if(bit_cnt == BIT_END-1 && bit_flag == 1'b1) begin
			rx_flag			<= 1'b1		;	
		end
		else begin
			rx_flag			<= 1'b0		;
		end
	end
	
	// rx_data
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rx_data			<= 8'd0			;
		end
		else if((bit_cnt >= 4'd1) && (bit_flag == 1'b1)) begin  //
			rx_data			<= {rx_r3, rx_data[7:1]}		;	
		end
		else begin
			rx_data			<= rx_data		;
		end
	end
	
	// po_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			po_flag			<= 1'b0			;
		end
		else begin
			po_flag			<= rx_flag		;
		end
	end
	
	// po_data
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			po_data			<= 7'd0			;
		end
		else if(rx_flag) begin
			po_data			<= rx_data		;
		end
	end
	
endmodule






























































/* module uart_rx(
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
	

	
endmodule */