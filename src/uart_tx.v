module uart_tx(
		//system signals
		input					sclk				,
		input					s_rst_n				,
		//tx_flag
		input					tx_flag				,
		//UART Interface
		output					rs232_tx			,
		//others
		output	reg		[7:0]	tx_data				,

);

	//define parameter and internal signals
	localparam BAUD_END = 5208;
	localparam BAUD_MID = BAUD_END / 2 - 1;
	localparam BIT_END  = 10;
	reg work_en;
	reg bit_flag;
	reg [12:0] baud_cnt;
	reg [3:0]  bit_cnt;
	reg 
	
	//main code
	
	//work_en
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			work_en <= 1'b0;
		end
		else if(tx_flag == 1'b1) begin
			work_en <= 1'b1;
		end
		else if(bit_cnt == 4'd9 && bit_flag == 1'b1) begin  //发送结束后将work_en拉低
			work_en <= 1'b0;
		end
	end
	
	//baud_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			baud_cnt <= 13'd0;
		end
		else if(work_en) begin
			if(baud_cnt == BAUD_END - 1'b1) begin
				baud_cnt <= 13'd0;
			end
			else begin
				baud_cnt <= baud_cnt + 1'b1;
			end
		end
		else begin
			baud_cnt <= 13'd0;
		end
		
	end

	//bit_flag
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_flag <= 1'b0;
		end
		else if(baud_cnt == 13'd1 && work_en == 1'b1) begin  //在baud_cnt中间取一个值即可
			bit_flag <= 1'b1;
		end
		else begin
			bit_flag <= 1'b0;
		end
	end
	
	//bit_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_cnt <= 13'd0;
		end
		else if(work_en) begin
			if(bit_cnt == BIT_END - 1'b1) begin
				bit_cnt <= 4'd0;
			end
			else if(bit_flag == 1'b1) begin  
				bit_cnt <= bit_cnt + 1'b1;
			end
		end
		else begin
			bit_cnt <= 4'd0;
		end
	end
	
	//send_data state machine
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rs232_tx <= 1'b0;
		end
		else begin  //须在bit_flag为1时发送，不然会一直赋值
			case(bit_cnt)
				'd0 : rs232_tx <= 1'b0;  //起始位
				'd1 : rs232_tx <= tx_data[0];
				'd2 : rs232_tx <= tx_data[1];
				'd3 : rs232_tx <= tx_data[2];
				'd4 : rs232_tx <= tx_data[3];
				'd5 : rs232_tx <= tx_data[4];
				'd6 : rs232_tx <= tx_data[5];
				'd7 : rs232_tx <= tx_data[6];
				'd8 : rs232_tx <= tx_data[7];
				'd9 : rs232_tx <= 1'b1;
				default : rs232_tx <= 1'b1;
			endcase
		end
	end
	
	
	
	
	
	
	
	
endmodule