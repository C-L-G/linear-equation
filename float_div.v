/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created: 2015/7/1 11:35:35
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module float_div (
	input				clock		,
	input [15:0]		adata       ,
	input [15:0]		bdata       ,
	output[15:0]		cdata
);

//---->> STEP 1 :get 1/x <<----

wire[9:0]		step1_reciprocal_bbase;

div_rom div_rom_inst(		//latency 2 clock
	.address	(bdata[8:0]),
	.clock		(clock),
	.q			(step1_reciprocal_bbase)
);

reg	[4:0]		step1_bexp;
reg 			step1_bsign;
reg				step1_zero_b;

always@(posedge clock)begin:BDATA_BLOCK
reg	[4:0]		Q_step1_bexp;
reg 			Q_step1_bsign;
reg				Q_step1_zero_b;
	Q_step1_bexp	<= bdata[14:10];
	Q_step1_bsign	<= bdata[15];
	Q_step1_zero_b	<= bdata[9] == 1'b0;
	step1_bexp      <= Q_step1_bexp	 	;   
	step1_bsign     <= Q_step1_bsign	;
	step1_zero_b	<= Q_step1_zero_b	;
end

reg [9:0]		step1_abase;
reg [4:0]		step1_aexp;
reg				step1_asign;

always@(posedge clock)begin:ADATA_BLOCK
reg [9:0]		Q_step1_abase;
reg [4:0]		Q_step1_aexp;
reg				Q_step1_asign;
	{Q_step1_asign,Q_step1_aexp,Q_step1_abase}	<= adata;
	{step1_asign,step1_aexp,step1_abase}		<= {Q_step1_asign,Q_step1_aexp,Q_step1_abase};
end

//----<< STEP 1 >>---------
//---->> STEP 2 <<---------

reg 		step2_shif_need;
always@(posedge clock)
	step2_shif_need	<= step1_reciprocal_bbase[9] == 1'b0;

reg [9:0]	step2_bbase_r;
always@(posedge clock)
	if(step1_reciprocal_bbase[9])
			step2_bbase_r	<= step1_reciprocal_bbase[9:0];
	else	step2_bbase_r	<= step1_reciprocal_bbase[8:0]<<1;

reg [4:0]	step2_bexp_r;
always@(posedge clock)
	if(step1_reciprocal_bbase[9])
			step2_bexp_r	<= 6'd31 - step1_bexp;
	else	step2_bexp_r	<= 6'd32 - step1_bexp;

reg 		step2_bsign;
always@(posedge clock)
	step2_bsign	<= step1_bsign;

reg			step2_zero_b;
always@(posedge clock)
	step2_zero_b	<= step1_zero_b;

reg [9:0]		step2_abase;
reg [4:0]		step2_aexp;
reg				step2_asign;

always@(posedge clock)
	{step2_asign,step2_aexp,step2_abase}	<= {step1_asign,step1_aexp,step1_abase};
//----<< STEP 2 >>------------
//---->> STEP 3 <<------------

wire		step3_csign;
wire[4:0]	step3_cexp;
wire[9:0]	step3_cbase;

float_multiply float_multiply_inst(
	.clock			(clock		),
	.adata			({step2_asign,step2_aexp,step2_abase}),
	.bdata			({step2_bsign,step2_bexp_r,step2_bbase_r}),
	.cdata			({step3_csign,step3_cexp,step3_cbase})
);

wire		step3_zero_b;
cross_clk_sync #(                     
	.DSIZE    	(1),                 
	.LAT		(3)                   
)latency_zero_inst0(                              
	clock,                              
	1'b1,                            
	step2_zero_b,           
	step3_zero_b 
); 

//----<< STEP 3 >>-----------
//---->> STEP 4 <<-----------

reg [15:0]	 float_c;
always@(*)
	if(!step3_zero_b)
			float_c	= {step3_csign,step3_cexp,step3_cbase};
	else	float_c	= 16'b0_00000_00000_00000;	

//-----<< STEP 4 >>-----------

assign	cdata	= float_c;

endmodule

