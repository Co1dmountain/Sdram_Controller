module sdram_write(
		// input
		input 				sys_clk					,
		input				sys_rst_n				,
		// write_en?
		input               write_trig			    ,
		input				write_en				,
		input				refresh_req				,  //刷新请求信号
		// output
		output	reg			byte_end				,
		output				write_req				,
		output				write_end				,
		output	reg	[ 3:0]	write_cmd				,
		output	reg	[11:0]	write_addr				,
		output	wire[ 1:0]	bank_addr				,
		output	reg	[15:0]	write_data				
		
);

	//// define ////
	// 定义指令、计数器、寄存器、状态机状态（写数据过程的状态机，
	// 在顶层文件中应该还有写状态这一状态，当顶层状态机进入写数据状态，
	// 就进入该模块进行写数据操作）
	
	// Define State
	localparam  S_IDLE      =   5'b0_0001       ;
	localparam  S_REQ       =   5'b0_0010       ;
	localparam  S_ACT       =   5'b0_0100       ;
	localparam  S_WR        =   5'b0_1000       ;
	localparam  S_PRE       =   5'b1_0000       ;
	// SDRAM Command
	localparam  CMD_NOP     =   4'b0111         ;
	localparam  CMD_PRE     =   4'b0010         ;
	localparam  CMD_AREF    =   4'b0001         ;
	localparam  CMD_ACT     =   4'b0011         ;
	localparam  CMD_WR      =   4'b0100         ;
	
	reg  flag_write;
	reg  [4:0] state;//状态机状态
	reg	 flag_act_end;//ACT结束标志
	reg  flag_pre_end;//PRE结束标志
	reg  flag_row_end;//换行标志
	reg  flag_data_end;//写操作结束标志，表示所有数据都写完
	reg  [1:0] burst_cnt;//突发计数器
	     
	reg  [8:0] col_addr_cnt;//列地址计数器，寄到511就说明该换行了
	wire [8:0] col_addr;
    reg  [11:0] row_addr_cnt;
	wire [11:0] row_addr;
	
	reg  [1:0] act_cnt;
	reg  [1:0] pre_cnt;
	
	
	
	//// main code ////
	// state machine
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			state <= S_IDLE;
			byte_end <= 1'b0;
		end
		else begin
			case(state) 
				S_IDLE : begin  //只进入该状态一次？
					if(write_trig) begin
						state <= S_REQ;
					end
					else begin
						state <= S_IDLE;
					end
				end
				S_REQ : begin
					if(write_en) begin
						state <= S_ACT;
					end
					else begin
						state <= S_REQ;
					end
				end
				S_ACT : begin
					if(flag_act_end) begin
						state <= S_WR;
					end
					else begin
						state <= S_ACT;
					end
				end
				S_WR : begin  // 三种情况须跳出写数据状态
					// 1.收到sdram刷新请求，需要进行刷新,但必须保证当前突发结束
					if(refresh_req && burst_cnt == 2'd3 && flag_write) begin
						state <= S_PRE;//回到PRECHARGE状态
						byte_end <= 1'b1;
					end
					// 2.写完一行数据，但写操作未结束(数据未写完)，此时需要进行换行
					else if(flag_row_end && !flag_data_end && flag_write) begin
						state <= S_PRE;//回到PRECHARGE状态
					end
					// 3.写操作结束(数据写完)
					else if(flag_data_end) begin
						state <= S_PRE;//回到IDLE状态
					end
				end
				S_PRE : begin
					byte_end <= 1'b0;
					if(flag_row_end && !flag_data_end) begin  // 换行
						state <= S_ACT;
					end
					else if(refresh_req) begin  // 刷新
						state <= S_REQ;
					end
					else if(flag_data_end) begin  // 写结束
						state <= S_IDLE;
					end
					else begin
						state <= S_PRE;
					end
				end
				default : state <= S_IDLE;
			endcase
		end
	end
	
	// flag_write
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			flag_write <= 1'b0;
		end
		else if(write_trig) begin
			flag_write <= 1'b1;
		end
		else if(flag_data_end) begin  // 写操作结束才拉低
			flag_write <= 1'b0;
		end
	end
	
	// act_cnt
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			act_cnt <= 2'd0;
		end
		else if(state == S_ACT) begin
			act_cnt <= act_cnt + 1'b1;
		end
		else begin
			act_cnt <= 2'd0;
		end
	end
	
	// flag_act_end
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			flag_act_end <= 1'b0;
		end
		else if(state == S_ACT && act_cnt == 2'd3) begin  ///
			flag_act_end <= 1'b1;
		end
		else begin
			flag_act_end <= 1'b0;
		end
	end
	
	// pre_cnt
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			pre_cnt <= 2'd0;
		end
		else if(state == S_ACT) begin
			pre_cnt <= pre_cnt + 1'b1;
		end
		else begin
			pre_cnt <= 2'd0;
		end
	end
	
	// flag_pre_end
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			flag_pre_end <= 1'b0;
		end
		else if(state == S_ACT && act_cnt == 2'd3) begin  ///
			flag_pre_end <= 1'b1;
		end
		else begin
			flag_pre_end <= 1'b0;
		end
	end
	
	// col_addr_cnt 每次加4  直接赋给col_addr寄存器是否可行，具体多久加1根据仿真结果改进
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			col_addr_cnt <= 'd0;
		end
		else if(col_addr_cnt == 'd511) begin
			col_addr_cnt <= 'd0;
		end
		else if(state == S_WR && burst_cnt == 2'd3 && flag_write) begin  ///
			col_addr_cnt <= col_addr_cnt + 'd4;
		end
		else begin
			col_addr_cnt <= col_addr_cnt;
		end
	end
	
	// burst_cnt
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			burst_cnt <= 'd0;
		end	
		else if(state == S_WR) begin
			if(burst_cnt == 2'd3) begin  ///
				burst_cnt <= 2'd0;
			end
			else begin
				burst_cnt <= burst_cnt + 1'b1;
			end
		end
		else begin
			burst_cnt <= 'd0;
		end
	end
	
	// row_addr_cnt
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			row_addr_cnt <= 'd0;
		end	
		else if(col_addr_cnt == 'd511 && !flag_data_end) begin  ///
			row_addr_cnt <= row_addr_cnt + 1'b1;
		end
		else begin
			row_addr_cnt <= row_addr_cnt;
		end
	end
	
	// flag_row_end
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			flag_row_end <= 1'b0;
		end
		else if(state == S_WR && col_addr_cnt == 'd510) begin  ///
			flag_row_end <= 1'b1;
		end
		else begin
			flag_pre_end <= 1'b0;
		end
	end
	
	// flag_data_end
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			flag_data_end <= 1'b0;
		end
		else if(row_addr_cnt == 'd1 && col_addr_cnt == 'd510) begin  ///
			flag_data_end <= 1'b1;
		end
		else begin
			flag_data_end <= 1'b0;
		end
	end
	assign write_end = flag_data_end;
	
	// state machine output
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			write_cmd <= CMD_NOP;
		end
		else case(state)
			S_IDLE : begin
				write_cmd <= CMD_NOP;
			end
			S_REQ : begin
				write_cmd <= CMD_NOP;
			end
			S_ACT : begin
				if(act_cnt == 'd0) begin
					write_cmd <= CMD_ACT;
				end
				else begin
					write_cmd <= CMD_NOP;
				end
			end
			S_WR : begin
				if(burst_cnt == 'd0) begin
					write_cmd <= CMD_WR;
				end
				else begin
					write_cmd <= CMD_NOP;
				end
			end
			S_PRE : begin
				if(pre_cnt == 'd0) begin
					write_cmd <= CMD_PRE;
				end
				else begin
					write_cmd <= CMD_NOP;
				end
			end
			default : write_cmd <= CMD_NOP;
		endcase
	end
	
	// generate data for test
	always @(*) begin
		case(burst_cnt)
			0:		write_data	<=		'd3;
			1:		write_data	<=		'd5;
			2:		write_data	<=		'd7;
			3:		write_data	<=		'd9;
		endcase
	end
	
	assign col_addr = col_addr_cnt;
	assign row_addr = row_addr_cnt;
	assign write_req			=		state[1];
	assign bank_addr = 2'b00;
	
	always @(*) begin // wr_addr
		case(state)
			S_ACT:
					if(act_cnt == 'd0)
						write_addr	<=	row_addr;
			S_WR:	write_addr	<=	{3'b000,col_addr};
			S_PRE:	
					if(pre_cnt == 'd0)
						write_addr	<=	{12'b0100_0000_0000};
						
		endcase

	end
	
	

	
	
	

endmodule
