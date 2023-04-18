module sdram_top(
		// input 
		input sys_clk,
		input sys_rst_n,
		
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
	localparam  NOP         =   4'b0111         ;
	localparam  PRE         =   4'b0010         ;
	localparam  AREF        =   4'b0001         ;
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
	assign sdram_bank = 2'b00;
	assign sdram_clk  = ~sys_clk;
	
	/// ARBITER ///
	// 1st -> initial
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
					if(refr_en) begin
						c_state <= AREFRE;
					end
					else if(write_en) begin  //进入写状态
						c_state <= WRITE;
					end
					else if(read_en) begin   //进入读状态
						c_state <= READ;
					end
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
				WRITE : begin
					if()
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
			//
			//
			default : begin
				sdram_addr      =      12'd0;
				{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = NOP;
			end

		endcase
	end
	
	// refr_en 仿真验证这里的判据是否有问题
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			refr_en <= 1'b0;
		end
		else if(c_state == ARBIT && refr_req) begin
			refr_en <= 1'b1;
		end
		else if(c_state == AREFRE && refr_end == 1'b1) begin
			refr_en <= 1'b0;
		end
		else begin
			refr_en <= refr_en;
		end
	end

	
	
	sdram_init U_sdram_init(
		.sys_clk			(sys_clk),
		.sys_rst_n			(sys_rst_n),          
		.cmd_reg			(init_cmd),
		.sdram_addr			(init_addr),
		.flag_init_end      (flag_init_end)
	);
	
	sdram_auto_refr U_sdram_auto_refr(
		.sys_clk			(sys_clk),
		.sys_rst_n			(sys_rst_n),
		.refr_en			(refr_en),	
		.refr_req			(refr_req),   
		.refr_end			(refr_end),	
		.refr_addr			(refr_addr),	
	    .refr_cmd			(refr_cmd)	
	);
	
	
	
	
	
	
	
	
	
	
	
	
	

endmodule