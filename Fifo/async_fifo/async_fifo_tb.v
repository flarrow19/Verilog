`include "async_fifo.v"
module asyn_fifo_tb();
parameter DEPTH = 16, WIDTH = 8, PTR_WIDTH = 4;
parameter WR_CLK_TP =10, RD_CLK_TP =14;
reg wr_clk_i, rd_clk_i, rst_i, wr_en_i, rd_en_i;
reg [WIDTH-1:0]wdata_i;
wire  [WIDTH-1:0]rdata_o;
wire  empty_o, full_o, wr_error_o, rd_error_o;
integer i;
integer wr_delay, rd_delay;
    
reg [30*8: 1] testname;
async_fifo dut(
    wr_clk_i, rd_clk_i, rst_i, wdata_i, full_o, wr_en_i, wr_error_o,
    rdata_o, empty_o, rd_en_i, rd_error_o
);
// clock generation
initial begin
    wr_clk_i = 0;
    forever #(WR_CLK_TP/2.0) wr_clk_i = ~wr_clk_i;
end

// clock generation
initial begin
    rd_clk_i = 0;
    forever #(RD_CLK_TP/2.0) rd_clk_i = ~rd_clk_i;
end

//reset apply, release

initial begin
    $value$plusargs("testname=%s",testname);
    rst_i = 1; // Apply reset
    wdata_i = 0;
    wr_en_i = 0;
    rd_en_i = 0;
    @(posedge wr_clk_i);       // Hold reset for a certain time period
    rst_i = 0; // Release reset


    case (testname)
        "test_full": begin
            write_fifo(DEPTH);
        end
        "test_empty": begin
            write_fifo(DEPTH);
            read_fifo(DEPTH);
        end
        "test_full_error": begin
            write_fifo(DEPTH+1);
        end
        "test_empty_error": begin
            write_fifo(DEPTH);
            read_fifo(DEPTH+1);
        end
        "test_concurrent_wr_rd": begin
            fork
            begin
            for(i=1; i<500; i=i+1)begin
                write_fifo(1);
                wr_delay = $urandom_range(1, 10);
                repeat(wr_delay) @(posedge wr_clk_i);
            end
            end
            begin
            for(i=1; i<500; i=i+1)begin
                read_fifo(1);
                rd_delay = $urandom_range(1, 10);
                repeat(rd_delay) @(posedge wr_clk_i);
            end
            end
            join
        end
    endcase
    #50;
    $finish;
end

task write_fifo(input integer num_wr);
begin
    for (i = 0; i<num_wr; i=i+1)begin
        @(posedge wr_clk_i);
        wr_en_i = 1;
        wdata_i = $random;
    end
    @(posedge wr_clk_i);
    wr_en_i = 0;
    wdata_i = 0;
end
endtask

task read_fifo(input integer num_rd);
begin
    for (i = 0; i<num_rd; i=i+1)begin
        @(posedge rd_clk_i);
        rd_en_i = 1;
    end
    @(posedge rd_clk_i);
    rd_en_i = 0;
end
endtask
endmodule
