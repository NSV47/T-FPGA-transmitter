module dds_addr (clk, rst_n, addr_out, strobe, FWORD, PWORD);
    input clk, rst_n;          // Resetting the system clock
    input [31:0] FWORD;
    input [15:0] PWORD;

    output [11: 0] addr_out;    // The output address corresponding to the data in the ROM

    output strobe;
    parameter N = 32;

//    parameter PWORD = 2048;     // Phase control word (x/360) * 256
//    parameter FWORD = 3316669189;  // слово управления частотой F_out = B * (F_clk / 2 ** 32), fword = B 5KHZ // 858994

    reg [N-1: 0] addr;         // 32-bit battery

//    reg [11:0] addr;

    reg [15:0] pword;
    always @ (posedge clk)begin
        pword <= PWORD;
    end

    reg [31:0] fword;
    always @ (posedge clk)begin
        fword <= FWORD;
    end
    reg strobe_r;
    always @ (posedge clk or negedge rst_n)
    begin
       if (!rst_n)
           begin
              addr <= 0;  
           end
      else
          begin
              //Each word size outputs an address, if the word control frequency is 2, then the output of the address counter is 0, 2, 4...
              addr <= addr + fword;
              if (addr[N-1:N-12] + PWORD == 12'hc00) begin
                  strobe_r <= 1'b1;
              end
              else begin
                  strobe_r <= 1'b0;
              end
//              addr <= addr + 1;
          end     
    end 
    //Assign the top eight bits of the battery address to the output address (ROM address
    assign addr_out = addr[N-1:N-12] + PWORD;

    assign strobe = strobe_r;
endmodule