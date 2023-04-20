module sdram_top(
		// input 
		input sys_clk,
		input sys_rst_n,
		input write_trig,
		
		// SDRAM interface
		output		  sdram_clk,
		output 		  sdram_cke,
		output reg    sdram_cs_n,
		output reg    sdram_cas_n,
		output reg    sdram_ras_n,
		output reg    sdram_we_n,
		output [ 1:0] sdram_bank,
		output reg [11:0] sdram_addr,
		output [ 1:0] sdram_dqm,
		
		inout  [15:0] sdram_dq
		
		
		 
);
	
	//// define ////
	localparam  CMD_NOP         =   4'b0111         ;
	localparam  CMD_PRE         =   4'b0010         ;
	localparam  CMD_AREF        =   4'b0001         ;
	// initial module
	wire 		flag_init_end;
	wire [ 3:0] init_cmd;
	wire [11:0] init_addr;
	// refresh module
	reg			refr_en;
	wire		refr_req;	
	wire		refr_end;	
	wire [11:0]	refr_addr;	
	wire [ 3:0]	refr_cmd;	
	// write module
	reg			write_en;
	wire		byte_end;
	wire		write_req;
	wire		write_end;
	wire [ 3:0] write_cmd;
	wire [11:0]	write_addr;	
	wire [ 1:0] write_bank_addr;
	wire [15:0] write_data;
	// read module
	wire read_en;
	// ARBITER define
	localparam  IDLE			= 5'b00001;
	localparam  ARBIT			= 5'b00010;
	localparam  AREFRE			= 5'b00100;
	localparam  WRITE			= 5'b01000;
	localparam  READ			= 5'b10000;
	reg  [4:0]	c_state;
	
	//// main code ////
	assign sdram_dqm  = 2'b00;
	assign sdram_cke  = 1'b1;
	assign sdram_bank = (c_state == WRITE) ? write_bank_addr : 2'b00;
	assign sdram_clk  = ~sys_clk;
	assign sdram_dq   = (c_state == WRITE) ? write_data : {16{1'bz}};
	
	/// ARBITER state machine ///
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			c_state <= IDLE;
		end
		else begin
			case(c_state)
				IDLE : begin
					if(flag_init_end) begin
						c_state <= ARBIT;
					end
					else begin
						c_state <= IDLE;
					end
				end
				ARBIT : begin
					//if(refr_en && !write_en) begin
					if(refr_en) begin  // 应该优先满足refresh，只要收到刷新信号并一次burst(byte_end == 1)完成退出写状态,就应该进入刷新状态
						c_state <= AREFRE;
					end
					else if(!refr_en && write_en) begin  //进入写状态，write_en如何产生？
						c_state <= WRITE;
					end
					/* else if(read_en) begin   //进入读状态
						c_state <= READ;
					end */
					else begin
						c_state <= ARBIT;
					end
				end
				AREFRE : begin
					if(refr_end) begin
						c_state <= ARBIT;
					end
					else begin
						c_state <= AREFRE;
					end
				end
				//write
				WRITE : begin  /// 先自己尝试写
					if(write_en) begin
						c_state <= WRITE;
					end
					else if(refr_req && byte_end) begin  //需要刷新，需要回到ARBIT状态? 判据是否有问题？
						c_state <= ARBIT;
					end
					else if(!refr_en && !write_en) begin
						c_state <= ARBIT;
					end
					else begin
						c_state <= ARBIT;
					end
				end
				//read
			endcase
		end
	end
	// 3rd -> output
	always @(*) begin
		case(c_state)
			IDLE : begin
				sdram_addr = init_addr;
				{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = init_cmd;
			end
			AREFRE : begin
				sdram_addr = refr_addr;
				{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = refr_cmd;
			end
			// write
			WRITE : begin
				sdram_addr = write_addr;
				{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = write_cmd;
			end
			//
			default : begin
				sdram_addr      =      12'd0;
				{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = CMD_NOP;
			end

		endcase
	end
	
	// refr_en 
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			refr_en <= 1'b0;
		end
		else if(c_state == ARBIT && refr_req) begin  // 当没有写操作时此判据可行，加上写操作后续添加新判据
			refr_en <= 1'b1;
		end
		//else if(c_state == AREFRE && refr_end == 1'b1) begin
		else if(refr_end == 1'b1) begin
			refr_en <= 1'b0;
		end
		else begin
			refr_en <= refr_en;
		end
	end
	
	// write_en
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			write_en <= 1'b0;
		end
		else if(c_state == ARBIT && write_req) begin
			write_en <= 1'b1;
		end
		else if(write_end || byte_end) begin //写结束和需要刷新时将write_en拉低
			write_en <= 1'b0;
		end	
		else begin
			write_en <= write_en;
		end
	end
	
	// initial module inst
	sdram_init U_sdram_init(
		.sys_clk			(sys_clk			),
		.sys_rst_n			(sys_rst_n			),          
		.cmd_reg			(init_cmd			),
		.sdram_addr			(init_addr			),
		.flag_init_end      (flag_init_end		)
	);
	
	// refresh module inst
	sdram_auto_refr U_sdram_auto_refr(
		.sys_clk			(sys_clk			),
		.sys_rst_n			(sys_rst_n			),
		.refr_en			(refr_en			),	
		.refr_req			(refr_req			),   
		.refr_end			(refr_end			),	
		.refr_addr			(refr_addr			),	
	    .refr_cmd			(refr_cmd			)	
	);
	
	// write module inst
	sdram_write U_sdram_write(
		.sys_clk			(sys_clk			),
		.sys_rst_n			(sys_rst_n			),
		.write_trig			(write_trig			),
		.byte_end			(byte_end			),
		.write_en			(write_en			),
		.refresh_req		(refr_req			),
		.write_req			(write_req			),
		.write_end			(write_end			),
		.write_cmd			(write_cmd			),
		.write_addr			(write_addr			),
		.bank_addr			(write_bank_addr	),
		.write_data			(write_data			)	
	);
	
	
	
	
	
	
	
	
	
	

endmodule