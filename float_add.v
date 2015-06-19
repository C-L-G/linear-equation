/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	latency 3 clock
--Version:VERA.1.0.0
--Data modified:
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module float_add (
	input			clock		,
	input [15:0]	adata		,
	input [15:0]	bdata		,
	output[15:0]	cdata		
);

/*   1    5        10
     X  XXXXX  XXXXXXXXXX
	 S    E         B
*/

//--->>store bigger one to ay<<--- 
// ay is always bigger than by
reg [15:0]		ay,by;
reg [4:0]		deltaE;
wire			exp_comp;
wire			base_comp;
assign	exp_comp	= bdata[14:10] > adata[14:10];
assign	base_comp	= bdata[9:0]   > adata[9:0];
always@(posedge clock)begin
	if(exp_comp || base_comp)begin
		ay		<= bdata;
		by		<= adata;
		deltaE	<= bdata[14:10]-adata[14:10];
	end else begin
		ay		<= adata;
		by		<= bdata; 
		deltaE	<= adata[14:10]-bdata[14:10];
end end


wire		asign,bsign;
wire[4:0]	aexp,bexp;
wire[9:0]	abase,bbase;

assign	{asign,aexp,abase} = ay;
assign	{bsign,bexp,bbase} = by;

reg[19:0]	ashift;
reg[9:0]	bbase_need_add;
reg			exp_need_shift;
reg[4:0]	exp_shift;
always@(posedge clock)
	if(deltaE < 11)begin
		ashift			<= {10'd0,abase}<<deltaE;
		bbase_need_add	<= by;
		exp_need_shift	<= 1'b1;
		exp_shift		<= deltaE;
	end else begin
		ashift			<= {10'd0,abase};
		bbase_need_add	<= 10'd0;
		exp_need_shift	<= 1'b0;
		exp_shift		<= aexp;
	end

wire		mix_sign;
cross_clk_sync #(                     
	.DSIZE    	(1),                 
	.LAT		(1)                   
)latency_sign_inst0(                              
	clock,                              
	1'b1,                            
	(asign^bsign),           
	mix_sign 
);           

reg[19:0]	comb_base;
reg[4:0]	comb_exp;
reg			comb_exp_need;
always@(posedge clock)begin
	comb_base		<= mix_sign? ashift - bbase_need_add : ashift + bbase_need_add;
	comb_exp		<= exp_shift;
	comb_exp_need	<= exp_need_shift;
end

reg[10:0]	arigen_base;
reg[4:0]	arigen_exp;
always@(posedge clock)begin
	if(!comb_exp_need)begin
		arigen_base	<= comb_base[9:0];
		arigen_exp	<= comb_exp;
	end else begin
		arigen_base	<= comb_base >> comb_exp;
		arigen_exp	<= comb_exp + 5'd16;
end end

reg [3:0]	normal_base_shift;
always@(posedge clock)begin
	normal_base_shift[3]  <= |arigen_base[10:8];
	normal_base_shift[2]  <= |arigen_base[7:4]; 
	normal_base_shift[1]  <= |arigen_base[3:2] || arigen_base[4+3:4+2] || arigen_base[10]; 
	normal_base_shift[0]  <= |arigen_base[1] | arigen_base[3] | arigen_base[5] | arigen_base[7] |
							  arigen_base[9];
end	 

reg [10:0]	normal_base_prp;
reg [4:0]	normal_exp_prp;

always@(posedge clock)begin
	normal_base_prp		<= arigen_base;
	normal_exp_prp		<= arigen_exp;
end
	
reg [9:0]	final_base;
reg	[4:0]	final_exp;
always@(posedge clock)begin   
	case(normal_base_shift)
	4'd0:begin		final_base	<= normal_base_prp << 9;  final_exp <= normal_exp_prp - 9; end
	4'd1:begin		final_base	<= normal_base_prp << 8;  final_exp <= normal_exp_prp - 8; end
	4'd2:begin		final_base	<= normal_base_prp << 7;  final_exp <= normal_exp_prp - 7; end
	4'd3:begin		final_base	<= normal_base_prp << 6;  final_exp <= normal_exp_prp - 6; end
	4'd4:begin		final_base	<= normal_base_prp << 5;  final_exp <= normal_exp_prp - 5; end
	4'd5:begin		final_base	<= normal_base_prp << 4;  final_exp <= normal_exp_prp - 4; end
	4'd6:begin		final_base	<= normal_base_prp << 3;  final_exp <= normal_exp_prp - 3; end
	4'd7:begin		final_base	<= normal_base_prp << 2;  final_exp <= normal_exp_prp - 2; end
	4'd8:begin		final_base	<= normal_base_prp << 1;  final_exp <= normal_exp_prp - 1; end
	4'd9:begin		final_base	<= normal_base_prp << 0;  final_exp <= normal_exp_prp - 0; end
	4'd10:begin		final_base	<= normal_base_prp >> 1;  final_exp <= normal_exp_prp + 1; end
	default:;
	endcase
end

wire		arigen_sign;

cross_clk_sync #(                     
	.DSIZE    	(1),                 
	.LAT		(6)                   
)latency_sign(                              
	clock,                              
	1'b1,                            
	(asign^bsign),           
	arigen_sign
);      

assign	cdata	= {arigen_sign,final_exp,final_base};

endmodule
	 




