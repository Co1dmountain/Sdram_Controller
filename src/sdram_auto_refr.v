module sdram_auto_refr(
		// input
		input					sys_clk				,
		input					sys_rst_n			,
		input					refr_en				,	// arbit给出的刷新使能信号
		
		// output
		output	reg				refr_req			,   // 给arbit的刷新请求信号
		output	reg				refr_end			,	// 给arbit的刷新结束信号？
		output		[11:0]		refr_addr			,	
		output	reg [ 3:0]		refr_cmd				// 给top模块的刷新指令
);

	//// define ////
	localparam 	CNT_15US	= 	'd750;
	localparam  NOP         =   4'b0111         ;
	localparam  PRE         =   4'b0010         ;
	localparam  AREF        =   4'b0001         ;
	localparam  REFR_ADDR	=	12'b0100_0000_0000;
	
	reg [ 2:0] cmd_cnt;  // cmd_cnt，根据计数值不同发不同指令实现刷新功能
	reg [ 9:0] cnt_15us;  // 计数15us，刷新一次，发出一次刷新请求信号
	
	
	//// main code ////
	
	// refr_addr
	assign refr_addr = REFR_ADDR;
	
	// cnt_15us
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cnt_15us <= 'd0;
		end
		else if(cnt_15us == CNT_15US - 1'b1) begin
			cnt_15us <= 'd0;
		end
		else begin  // 有无判断条件？
			cnt_15us <= cnt_15us + 1'b1;
		end
	end
	
	// refr_req
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			refr_req <= 1'b0;
		end
		else if(cnt_15us == CNT_15US - 1'b1) begin
			refr_req <= 1'b1;
		end
		else if(refr_end == 1'b1) begin
			refr_req <= 1'b0;
		end
		else begin
			refr_req <= refr_req;
		end
	end
	// refr_end
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			refr_end <= 1'b0;
		end
		else if(refr_en && cmd_cnt >= 'd4) begin
			refr_end <= 1'b1;
		end
		else if(!refr_en) begin
			refr_end <= 1'b0;
		end
	end
	
	// cmd_cnt
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cmd_cnt <= 'd0;
		end
		else if(refr_en) begin
			if(cmd_cnt == 3'd4) begin
				cmd_cnt <= 'd0;
			end
			else begin
				cmd_cnt <= cmd_cnt + 1'b1;
			end
		end
		else begin
			cmd_cnt <= 'd0;
		end
	end
	
	// refr_cmd
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			refr_cmd <= NOP;
		end
		else if(refr_en) begin
			case(cmd_cnt) 
				1 : refr_cmd <= PRE;
				4 : refr_cmd <= AREF;     // 在这里发送的刷新指令
				default : refr_cmd <= NOP;
			endcase
		end
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	



endmodule