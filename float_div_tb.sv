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
--Data created:2015/7/1 9:51:23
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module float_div_tb;

bit		clock;

clock_rst clk_c0(
	.clock		(clock),
	.rst		(rst_n)
);

defparam clk_c0.ACTIVE = 0;
initial begin:INITIAL_CLOCK
	clk_c0.run(1 , 1000/100 ,0);		//100	
end

real		adata = 1;
real		bdata = 1; 
real		cdata;

logic[15:0]		float_a,float_b,float_c;

always@(posedge clock) begin
	float_a	= random_float();
	float_b	= random_float();

//	float_a	= {1'b1,5'd16,10'd766};
//	float_b	= {1'b1,5'd17,10'd512};
end

function logic[15:0] random_float;
	random_float[15]	= $urandom_range(0,1);
	random_float[14:10]	= $urandom_range(10,24);
	random_float[9:0]	= $urandom_range(512,1023);
endfunction:random_float

function real float_to_real (logic[15:0] fdata,bit dis = 0);
	real	base;
	real	exp;
	int		E;
	base	= fdata[9:0];
	E		= fdata[14:10]-16;
	if(E>=0)	
		exp		= 2**E;
	else 
		exp		= real'(1)/2**(-E);
//	float_to_real	<= fdata[9:0]*(2**fdata[14:0])/(2**9)*(1*fdata[15] - 1*(~fdata[15]));
	float_to_real	= fdata[15]? (base/512)*exp : (base/512)*exp*(-1);
	if( dis == 1)begin
		$display("====> %b  %d   %b ",fdata[15],E,fdata[9:0]);
		$display("----> %f ,%f ,%f",base/512,exp,float_to_real);
	end
endfunction:float_to_real

always_comb adata	= float_to_real(float_a);
always_comb bdata	= float_to_real(float_b);
always_comb cdata	= float_to_real(float_c,1);


float_div float_div_inst(
	.clock			(clock		),
	.adata			(float_a    ),
	.bdata			(float_b    ),
	.cdata			(float_c    )
);

int exp_a,exp_b,exp_c;
int base_a,base_b,base_c;

always_comb exp_a	= float_a[14:10];
always_comb exp_b	= float_b[14:10];
always_comb exp_c	= float_c[14:10];

always_comb base_a	= float_a[9:0];
always_comb base_b	= float_b[9:0];
always_comb base_c	= float_c[9:0];

real	pre_m_a,pre_m_b,m_c;
always_comb pre_m_a	= float_to_real(float_div_inst.float_multiply_inst.adata);
always_comb pre_m_b	= float_to_real(float_div_inst.float_multiply_inst.bdata);
always_comb m_c		= float_to_real(float_div_inst.float_multiply_inst.cdata);

endmodule


	


	
