module led(
    input clk,
    input				rst,
    output reg          led,

    output UART_TX,
    
    output				rxd_flag
);

wire				cs;
wire				sck;
wire				MOSI;
wire				MISO;

wire	[7:0]		rxd_out;

//--------------------------------------------
reg [7:0] txd_dat;
wire clk_60M;
//--------------------------------------------

wire pll_out_clk;

//-------------------------------------------

wire [7:0]gpio;

//--------Copy here to design--------

Gowin_EMPU_Top cortexM3_inst(
    .sys_clk(clk_60M), //input sys_clk
    .gpio(gpio[7:0]), //inout [15:0] gpio
    .uart0_rxd(1'b1), //input uart0_rxd
    .uart0_txd(UART_TX), //output uart0_txd
    .mosi(MOSI), //output mosi
    .miso(MISO), //input miso
    .sclk(sck), //output sclk
    .nss(cs), //output nss
    .reset_n(1'b1) //input reset_n
);

//--------Copy end-------------------

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)
        txd_dat <= 8'b11000011;
	else
    begin
        txd_dat <= rxd_out + 1'b1; //отправить данные +1 отправителю
    end
end

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)
        led<=1'b0;
    else if(rxd_out<8'h80)
        begin
            led<=1'b1;
        end
    else
        begin
            led<=1'b0;
        end
end

//--------Copy here to design--------

Gowin_PLLVR1 your_instance_name(
    .clkout(clk_60M), //output clkout
    .clkin(clk) //input clkin
);

//--------Copy end-------------------

spi_slaver spi_slaver1(
    .clk(clk_60M), // clk_30M
    .rst(rst),
    .cs(cs),
    .sck(sck),
    .MOSI(MOSI),
    .MISO(MISO),
    .rxd_out(rxd_out),
    .txd_data(txd_dat),
    .rxd_flag(rxd_flag)
);

endmodule