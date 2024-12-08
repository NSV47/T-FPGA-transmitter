module led(
    input clk,
    input				rst,
    output              led,

//    wire [11: 0] addr_out, // 8-битный адрес, соответствующий данным в ПЗУ
    output [11: 0] sin,
//    output TX,
    
    output clk_o,
//    inout [7:0]gpio,
//-----------------------------------------
    input				cs,
    input				sck,
    input				MOSI,
    output				MISO,
//    output	[7:0]		rxd_out,
    output				rxd_flag
    //output  reg         led_state
);

reg [31:0] fword;
reg [31:0] fword_valid;
reg ready_fword = 0;

wire	[7:0]		rxd_out;

//--------------------------------------------
reg [7:0] txd_dat;
wire clk_30M;
//--------------------------------------------
wire [11: 0] addr_out;
wire pll_out_clk;
wire [11: 0] sin_out;

reg [28:0]cnt = 0;

//-------------------------------------------

//wire [7:0]gpio;

//--------Copy here to design--------

Gowin_EMPU_Top cortexM3_inst(
    .sys_clk(clk), //input sys_clk
    .gpio(led), //inout [15:0] gpio
    .uart0_rxd(), //input uart0_rxd
    .uart0_txd(), //output uart0_txd
    .reset_n(1'b1) //input reset_n
);

//--------Copy end-------------------

//assign led = gpio[7];

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)
        txd_dat <= 8'b11000011;
	else
    begin
        txd_dat <= rxd_out + 1'b1; //отправить данные +1 отправителю
    end
end

//always@(posedge rxd_flag or negedge rst)begin
//    if(!rst)
//        led<=1'b0;
//    else if(rxd_out<8'h80)
//        begin
//            led<=1'b1;
//            fword = 3316685096; // 3316669189
//        end
//    else
//        begin
//            led<=1'b0;
//            fword = 3316669189; // 3316669189
//        end
//end

Gowin_OSC osc(//выход внутреннего кварцевого генератора 25MHz
    .oscout(oscout_o), //output oscout
    .oscen(1) //input oscen
);

Gowin_PLLVR pll(//октава до 30Mhz
    .clkout(clk_30M), //output clkout
    .clkin(oscout_o) //input clkin
);

spi_slaver spi_slaver1(
    .clk(clk_30M),
    .rst(rst),
    .cs(cs),
    .sck(sck),
    .MOSI(MOSI),
    .MISO(MISO),
    .rxd_out(rxd_out),
    .txd_data(txd_dat),
    .rxd_flag(rxd_flag)
);

//-------------------------------------------
//always @(posedge clk) begin
//    cnt <= cnt + 1;
//    if(cnt==27000000) begin
//        cnt <= 0;
//        led<=!led;
//    end
//end

// --------------Phase-based  module------------------------   
dds_addr dds_addr_inst (
    .clk(clk),            // input wire clk
    .rst_n(1'b0),        // input wire rst_n // 1 enable
    .addr_out(addr_out),  // output wire [7 : 0] addr_out
    .test(),
    .strobe(strobe_sin),
    .FWORD(fword_valid)
);  
//----------------------------------------------------------

// Waveform Data Module       
Gowin_pROM rom_inst (
    .dout(sin), //output [11:0] dout
    .clk(clk), //input clk
    .oce(), //input oce
    .ce(1'b1), //input ce
    .reset(1'b1), //input reset // 0 enable
    .ad(addr_out) //input [11:0] ad
);

assign clk_o = clk;

endmodule