module led(
    input clk,
    output reg led,

//    wire [11: 0] addr_out, // 8-битный адрес, соответствующий данным в ПЗУ
    output [11: 0] sin,
//    output TX,
    
    output clk_o
//    output [11:0] D
);

wire [11: 0] addr_out;
wire pll_out_clk;
wire [11: 0] sin_out;

reg [28:0]cnt = 0;

always @(posedge clk) begin
    cnt <= cnt + 1;
    if(cnt==13500000) begin
        cnt <= 0;
        led<=!led;
    end
end

// --------------Phase-based  module------------------------   
    dds_addr dds_addr_inst (
        .clk(clk),            // input wire clk
        .rst_n(1'b1),        // input wire rst_n
        .addr_out(addr_out),  // output wire [7 : 0] addr_out
        .test(),
        .strobe(strobe_sin)
    );  
    //----------------------------------------------------------

// Waveform Data Module       
    Gowin_pROM rom_inst (
        .dout(sin), //output [11:0] dout
        .clk(clk), //input clk
        .oce(), //input oce
        .ce(1'b1), //input ce
        .reset(1'b0), //input reset
        .ad(addr_out) //input [11:0] ad

//        .clka(clk),        // input wire clka
//        .addra(addr_out),  // input wire [7 : 0] addra
//        .douta(sin)          // output wire [7 : 0] douta
    );

Gowin_PLLVR your_instance_name(
    .clkout(pll_out_clk), //output clkout
    .clkin(clk) //input clkin
);

reg [3:0]cnt_div12;
always @(posedge pll_out_clk)
    if(cnt_div12==11)
        cnt_div12<=0;
    else
        cnt_div12<=cnt_div12+1;

reg [ 3: 0]cnt_div10;
always @(posedge clk)
    if(cnt_div10==9)
        cnt_div10<=0;
    else
        cnt_div10 <= cnt_div10 + 1'b1;

reg [11:0]serial_out_reg;
always @(posedge pll_out_clk)
    if(cnt_div12==0) begin
        serial_out_reg <= { 3'b111, sin_out[11:4], 1'b0 }; //load
    end
    else begin
        serial_out_reg <= { 1'b1, serial_out_reg[11:1] }; //shift out, LSB first
    end

reg [11: 0] sin_out_reg;
reg strob_sin;

always @(posedge clk)
    if(cnt_div10==0) begin
        sin_out_reg <= sin;
        strob_sin <= 1'b1;
    end
    else begin
        strob_sin <= 1'b0;
    end

assign sin_out = sin_out_reg;

//Serial_TX
//assign TX = serial_out_reg[0];

assign clk_o = clk;
//assign D = sin;

endmodule