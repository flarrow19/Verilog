module fifo (
    // Write interface
    clk_i, rst_i, wdata_i, full_o, wr_en_i, wr_error_o,
    //Read Interface
    rdata_o, empty_o, rd_en_i, rd_error_o
);

// wr_ptr is internal to the design
parameter DEPTH = 16, WIDTH = 8, PTR_WIDTH = 4;

input clk_i, rst_i, wr_en_i, rd_en_i;
input [WIDTH-1:0]wdata_i;
output reg [WIDTH-1:0]rdata_o;
output reg empty_o, full_o, wr_error_o, rd_error_o;

reg [PTR_WIDTH-1:0]wr_ptr, rd_ptr;
reg wr_toggle_f, rd_toggle_f;
reg [WIDTH-1:0]mem[DEPTH-1:0];
integer i;

always @(posedge clk_i)begin
    if (rst_i == 1)begin
        wr_ptr = 0;
        rd_ptr = 0;
        rdata_o = 0;
        full_o = 0;
        empty_o = 1;
        wr_toggle_f = 0;
        rd_toggle_f = 0;
        wr_error_o = 0;
        rd_error_o = 0;

        for (i = 0; i< DEPTH; i++)begin
            mem[i] <= 0;
        end
    end

    else begin
        wr_error_o <= 0;
        rd_error_o <= 0;
        // reset is not applied
        // write can happen
        //store data in memory, increment the write pointer 
        if(wr_en_i == 1)begin
                if (full_o == 1)begin
                    wr_error_o <= 1;
                end
                else begin
                    mem[wr_ptr] <= wdata_i;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == DEPTH -1)wr_toggle_f <= ~wr_toggle_f;
                end
        end
        // read can happen
        // get data from memory, increment read pointer
        if (rd_en_i == 1)begin
                if(empty_o == 1)begin
                    rd_error_o <= 1;
                end
                else begin
                    rdata_o <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == DEPTH -1) rd_toggle_f <= ~rd_toggle_f;
                end
        end
    end
end
// Implementing Empty and Full condition
always @(*) begin
    empty_o = 0;
    full_o = 0;
    if (wr_ptr == rd_ptr)begin
        if (wr_toggle_f == rd_toggle_f) empty_o = 1;
        if (wr_toggle_f != rd_toggle_f) full_o = 1;
    end
end
endmodule
