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
--author:Young-吴明
--E-mail: wmy367@Gmail.com
--Data created: 2015/7/1 9:08:01
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module float_multiply (
	input				clock		,
	input [15:0]		adata       ,
	input [15:0]		bdata       ,
	output[15:0]		cdata
);

//----->> STEP 1 <<----
reg [19:0]		step1_mul_data;
always@(posedge clock)
	step1_mul_data	<= adata[9:0] * bdata[9:0];

reg [5:0]		step1_exp_sum;
always@(posedge clock)
	step1_exp_sum	<= adata[14:10] + bdata[14:10];

//-----<< STEP 1 >>----
//----->> STEP 2 <<----
reg [1:0]		step2_shift_mul;
always@(posedge clock)
	if(step1_mul_data[19])
			step2_shift_mul	<= 2'b01;
	else if(step1_mul_data[18])
			step2_shift_mul	<= 2'b10;
	else 	step2_shift_mul	<= 2'b00;

reg [19:0]		step2_mul;
reg [5:0]		step2_exp;
always@(posedge clock)begin
	step2_mul	<= step1_mul_data;
	step2_exp	<= step1_exp_sum;
end

reg step2_exp_bigger_15;
reg step2_exp_eq_15;
always@(posedge clock)begin
	step2_exp_bigger_15	<= step1_exp_sum >  16'd15;
	step2_exp_eq_15		<= step1_exp_sum == 16'd15;
end

reg				step2_rel_zero;
always@(posedge clock)
	step2_rel_zero	<= ~(|step1_mul_data);

//-----<< STEP 2 >>---- 
//----->> STEP 3 <<----
reg [9:0]		step3_align_mul;
always@(posedge clock)
	if(step2_exp_bigger_15)
		case(step2_shift_mul)
		2'b01:	step3_align_mul	<= step2_mul[19:10];
		2'b10:	step3_align_mul	<= step2_mul[18:9];
		default:step3_align_mul	<= 10'd0;
		endcase
	else if(step2_exp_eq_15)
		case(step2_shift_mul)
		2'b01:	step3_align_mul	<=  step2_mul[19:10];
		2'b10:	step3_align_mul	<= (step2_mul[18:17]==2'b11)? 1'b1<<9 : 10'd0;
		default:step3_align_mul	<= 10'd0;
		endcase
	else	step3_align_mul	<= 10'd0;
			
reg [4:0]		step3_align_exp;
always@(posedge clock)
	if(step2_rel_zero)
			step3_align_exp	<= 5'd1;		//如果基数是0 指数不能是0 ，否则表示 NaN
	else if(step2_exp_bigger_15)
		case(step2_shift_mul)
		2'b01:	step3_align_exp	<= step2_exp - 5'd15;
		2'b10:	step3_align_exp	<= step2_exp - 5'd16;
		default:step3_align_exp	<= step2_exp - 5'd16;
		endcase
	else	step3_align_exp	<= 5'd0;
//-----<< STEP 3 >>-----

wire		mix_sign;
cross_clk_sync #(                     
	.DSIZE    	(1),                 
	.LAT		(3)                   
)latency_sign_inst0(                              
	clock,                              
	1'b1,                            
	(adata[15]~^bdata[15]),           
	mix_sign 
);  


assign	cdata	= {mix_sign,step3_align_exp,step3_align_mul};

endmodule
         

