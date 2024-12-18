module led(
    input clk,
    input				rst,
    output reg          led,

    output [11: 0] sin,
    output UART_TX,
    
    output clk_o,

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
wire [11: 0] addr_out;
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

//assign led = gpio[7];

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)
        txd_dat <= 8'b11000011;
	else
    begin
        txd_dat <= rxd_out + 1'b1; //отправить данные +1 отправителю
    end
end

reg [31:0] fword;
reg [31:0] oneBytes_f;
reg [31:0] twoBytes_f;
reg [31:0] thrBytes_f;
reg [ 3:0] state_reg_f;

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)begin
        fword <= 1'b0;
    end
    else if(rxd_out==8'h01)
        begin
            state_reg_f <= 0;
            oneBytes_f <= 0;
        end
    else
        begin
            case(state_reg_f)
                4'd0: begin
                    oneBytes_f <= oneBytes_f + rxd_out;
                    state_reg_f <= 1;
                end

                4'd1: begin
                    twoBytes_f <= oneBytes_f + (rxd_out << 8); // +tmp
                    state_reg_f <= 2;
                end

                4'd2: begin
                    thrBytes_f <= twoBytes_f + (rxd_out << 16); // +tmp
                    state_reg_f <= 3;
                end

                4'd3: begin
                    fword <= thrBytes_f + (rxd_out << 24); // +tmp
                    state_reg_f <= 4;
//                    led <= !led;
                end
                
                default: begin
                    state_reg_f <= 4;
                end
            endcase
        end
end

reg [15:0] oneBytes_p;
reg [15:0] pword_reg;
reg [ 3:0] state_reg_p = 4;

always@(posedge rxd_flag or negedge rst)begin
    if(!rst)begin
        pword_reg <= 0;
    end    
    else if(rxd_out==8'h02)
        begin
            state_reg_p <= 0;
        end
    else
        begin
            case(state_reg_p)
      
                4'd0: begin
                    oneBytes_p <= rxd_out;
                    state_reg_p <= 1;
                end

                4'd1: begin
                    pword_reg <= oneBytes_p + (rxd_out << 8);
                    state_reg_p <= 4; // "другое" состояние, чтобы частота не мешалась
                    led <= !led;
                end

                default: begin
                    state_reg_p <= 4; // "другое" состояние, чтобы частота не мешалась
                end
            endcase
        end
end

//--------Copy here to design--------

Gowin_PLLVR1 your_instance_name(
    .clkout(clk_60M), //output clkout
    .clkin(clk) //input clkin
);

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

//-------------------------------------------

// --------------Phase-based  module------------------------   
dds_addr dds_addr_inst (
    .clk(clk),            // input wire clk
    .rst_n(1'b1),        // input wire rst_n // 1 enable
    .addr_out(addr_out),  // output wire [7 : 0] addr_out
    .strobe(strobe_sin),
    .FWORD(fword), // fword // fword_valid
    .PWORD(pword_reg) // tmp5 // 16'd2048
);  
//----------------------------------------------------------

// Waveform Data Module       
Gowin_pROM rom_inst (
    .dout(sin), //output [11:0] dout
    .clk(clk), //input clk
    .oce(), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset // 0 enable
    .ad(addr_out) //input [11:0] ad
);

assign clk_o = clk;

endmodule