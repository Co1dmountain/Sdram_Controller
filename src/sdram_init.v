module sdram_init(
		// input
		input				sys_clk				,
		input				sys_rst_n			,
		
		// 
		output	reg [ 3:0]	cmd_reg				,
		output		[11:0]	sdram_addr			,
		output 				flag_init_end
);

	//// define ////
	
	localparam				DELAY_200US = 10000		;
	
	// sram command
	localparam				NOP			= 4'b0111	;
	localparam				PRECHARGE	= 4'b0010	;
	localparam				AUTO_REFRESH= 4'b0001	;
	localparam				MODE_SET	= 4'b0000	;
	
	reg		[13:0]			cnt_200us				;
	wire					flag_200us				;
	reg		[ 3:0]			cnt_cmd					;

	
	//// main code ////
	// cnt_200us
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cnt_200us <= 'd0;
		end
		else if(flag_200us == 1'b0) begin
			cnt_200us <= cnt_200us + 1'b1;
		end
	end
	
	assign flag_200us = (cnt_200us >= DELAY_200US) ? 1'b1 : 1'b0;
	
	// cnt_cmd 
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cnt_cmd	<= 'd0;
		end
		else if(flag_200us == 1'b1 && flag_init_end == 1'b0) begin
			cnt_cmd	<= cnt_cmd + 1'b1;
		end
	end

	// cmd_reg, refer to the value of cnt_cmd, give different cmd
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cmd_reg <= NOP;
		end
		else if(flag_200us == 1'b1) begin
			case(cnt_cmd) // 根据初始化时序得来 refer to initialation 
				0 : cmd_reg <= PRECHARGE;
				1 : cmd_reg <= AUTO_REFRESH;
				5 : cmd_reg <= AUTO_REFRESH;
				9 : cmd_reg <= MODE_SET;
				default : cmd_reg <= NOP;
			endcase
		end
	end

	// sdram_addr
	assign sdram_addr = cmd_reg == MODE_SET ? 12'b00_0_00_011_0010 : 12'b0100_0000_0000;

	//flag_init_end
	assign flag_init_end = cnt_cmd >= 'd10 ? 1'b1 : 1'b0;























endmodule















