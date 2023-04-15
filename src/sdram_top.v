module sdram_top(
		// input 
		input sys_clk,
		input sys_rst_n,
		
		// SDRAM interface
		output sdram_clk,
		output sdram_cke,
		output sdram_cs_n,
		output sdram_cas_n,
		output sdram_ras_n,
		output sdram_we_n,
		output [ 1:0] sdram_bank,
		output [11:0] sdram_addr,
		output [ 1:0] sdram_dqm,
		
		inout  [15:0] sdram_dq
		
		
		 
);
	
	//// define ////
	wire 		flag_init_end;
	wire [3:0]  init_cmd;
	wire [11:0] init_addr;
	
	
	//// main code ////
	
	assign sdram_clk  = ~sys_clk;
	assign sdram_addr = init_addr;
	assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = init_cmd;
	assign sdram_dqm  = 2'b00;
	assign sdram_cke  = 1'b1;
	
	sdram_init U_sdram_init(
		.sys_clk			(sys_clk),
		.sys_rst_n			(sys_rst_n),          
		.cmd_reg			(init_cmd),
		.sdram_addr			(init_addr),
		.flag_init_end      (flag_init_end)
	);
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

endmodule