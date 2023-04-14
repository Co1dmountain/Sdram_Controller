module uart_tx(
		//system signals
		input					sclk				,
		input					s_rst_n				,
		//tx_flag
		input					tx_flag				,
		//UART Interface
		output	reg				rs232_tx			,
		//others
		input			[7:0]	tx_data				

);

	//define parameter and internal signals
	localparam		BAUD_END		= 5208;
	localparam		BAUD_MID		= BAUD_END / 2 - 1;
	localparam		BIT_END			= 10;
	reg 			work_en		;
	reg 			bit_flag	;
	reg	[12:0] 		baud_cnt	;
	reg [3:0]  		bit_cnt		;
	
	
	//// main code ////
	
	// work_en
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
	
	// baud_cnt
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

	// bit_flag
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
	
	// bit_cnt
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			bit_cnt <= 4'd0;
		end
		else if(work_en) begin
			if(bit_cnt == BIT_END - 1'b1 && bit_flag == 1'b1) begin
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
	
	// send data 
	always @(posedge sclk or negedge s_rst_n) begin
		if(!s_rst_n) begin
			rs232_tx <= 1'b0;
		end
		else if (bit_flag == 1'b1)begin  //须在bit_flag为1时发送，不然会一直赋值
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


//module uart_tx
//#(
//parameter UART_BPS = 'd9600, //串口波特率
//parameter CLK_FREQ = 'd50_000_000 //时钟频率
//)
//(
//input wire sys_clk , //系统时钟 50MHz
//input wire sys_rst_n , //全局复位
//input wire [7:0] pi_data , //模块输入的 8bit 数据
// input wire pi_flag , //并行数据有效标志信号
// 
// output reg tx //串转并后的 1bit 数据
// );
// 
// //********************************************************************//
// //****************** Parameter and Internal Signal *******************//
// //********************************************************************//
// 
// //localparam define
// localparam BAUD_CNT_MAX = CLK_FREQ/UART_BPS ;
// 
// //reg define
// reg [12:0] baud_cnt;
// reg bit_flag;
// reg [3:0] bit_cnt ;
// reg work_en ;
// 
// //********************************************************************//
// //***************************** Main Code ****************************//
// //********************************************************************//
// 
// //work_en:接收数据工作使能信号
// always@(posedge sys_clk or negedge sys_rst_n)
// if(sys_rst_n == 1'b0)
// work_en <= 1'b0;
// else if(pi_flag == 1'b1)
//
//work_en <= 1'b1;
// else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
// work_en <= 1'b0;
// 
// //baud_cnt:波特率计数器计数，从 0 计数到 5207
// always@(posedge sys_clk or negedge sys_rst_n)
// if(sys_rst_n == 1'b0)
// baud_cnt <= 13'b0;
// else if((baud_cnt == BAUD_CNT_MAX - 1) || (work_en == 1'b0))
// baud_cnt <= 13'b0;
// else if(work_en == 1'b1)
// baud_cnt <= baud_cnt + 1'b1;
// 
// //bit_flag:当 baud_cnt 计数器计数到 1 时让 bit_flag 拉高一个时钟的高电平
// always@(posedge sys_clk or negedge sys_rst_n)
// if(sys_rst_n == 1'b0)
// bit_flag <= 1'b0;
// else if(baud_cnt == 13'd1)
// bit_flag <= 1'b1;
// else
// bit_flag <= 1'b0;
// 
// //bit_cnt:数据位数个数计数，10 个有效数据（含起始位和停止位）到来后计数器清零
// always@(posedge sys_clk or negedge sys_rst_n)
// if(sys_rst_n == 1'b0)
// bit_cnt <= 4'b0;
// else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
// bit_cnt <= 4'b0;
// else if((bit_flag == 1'b1) && (work_en == 1'b1))
// bit_cnt <= bit_cnt + 1'b1;
// 
// //tx:输出数据在满足 rs232 协议（起始位为 0，停止位为 1）的情况下一位一位输出
// always@(posedge sys_clk or negedge sys_rst_n)
// if(sys_rst_n == 1'b0)
// tx <= 1'b1; //空闲状态时为高电平
// else if(bit_flag == 1'b1)
// case(bit_cnt)
// 0 : tx <= 1'b0;
// 1 : tx <= pi_data[0];
// 2 : tx <= pi_data[1];
// 3 : tx <= pi_data[2];
// 4 : tx <= pi_data[3];
// 5 : tx <= pi_data[4];
// 6 : tx <= pi_data[5];
// 7 : tx <= pi_data[6];
// 8 : tx <= pi_data[7];
// 9 : tx <= 1'b1;
// default : tx <= 1'b1;
// endcase
// 
// endmodule