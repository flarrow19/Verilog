//TB
`include "syn_FIFO.v"
module syn_fifo_tb();
parameter DEPTH = 16, WIDTH = 8, PTR_WIDTH = 4;

reg clk_i, rst_i, wr_en_i, rd_en_i;
reg [WIDTH-1:0]wdata_i;
wire  [WIDTH-1:0]rdata_o;
wire  empty_o, full_o, wr_error_o, rd_error_o;
integer i;

fifo dut(
    clk_i, rst_i, wdata_i, full_o, wr_en_i, wr_error_o,
    rdata_o, empty_o, rd_en_i, rd_error_o
);
// clock generation
initial begin
    clk_i = 0;
    forever #10 clk_i = ~clk_i;
end
//reset apply, release

initial begin
    rst_i = 1; // Apply reset
    wdata_i = 0;
    wr_en_i = 0;
    rd_en_i = 0;
    #20;       // Hold reset for a certain time period
    rst_i = 0; // Release reset

    for (i = 0; i<DEPTH; i=i+1)begin
        @(posedge clk_i);
        wr_en_i = 1;
        wdata_i = $random;
        $display("Time: %t, wr_ptr: %d, rd_ptr: %d, wdata_i: %h, rdata_o: %h", $time, dut.wr_ptr, dut.rd_ptr, wdata_i, rdata_o);
    end
    @(posedge clk_i);
    wr_en_i = 0;
    wdata_i = 0;
    //Read

    for (i = 0; i<DEPTH; i=i+1)begin
        @(posedge clk_i);
        rd_en_i = 1;
        $display("Time: %t, wr_ptr: %d, rd_ptr: %d, wdata_i: %h, rdata_o: %h,", $time, dut.wr_ptr, dut.rd_ptr, wdata_i, rdata_o);
    end
    @(posedge clk_i);
    rd_en_i = 0;
    $finish;
end

initial begin
    $dumpfile ("syn_fifo_wave.vcd");
    $dumpvars (0, syn_fifo_tb);
end
endmodule
