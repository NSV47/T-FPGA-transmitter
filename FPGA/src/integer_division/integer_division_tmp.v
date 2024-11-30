//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.09
//Part Number: GW1NSR-LV4CQN48PC6/I5
//Device: GW1NSR-4C
//Created Time: Sat Nov 30 19:21:06 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Integer_Division_Top your_instance_name(
		.clk(clk_i), //input clk
		.rstn(rstn_i), //input rstn
		.dividend(dividend_i), //input [63:0] dividend
		.divisor(divisor_i), //input [24:0] divisor
		.in_valid(in_valid_i), //input in_valid
		.quotient(quotient_o), //output [63:0] quotient
		.out_valid(out_valid_o) //output out_valid
	);

//--------Copy end-------------------
