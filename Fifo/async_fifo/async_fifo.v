module async_fifo(
    wr_clk_i, rd_clk_i, rst_i, wdata_i, full_o, wr_en_i,  wr_error_o,
    rdata_o, empty_o, rd_en_i, rd_error_o
);

parameter DEPTH = 16, WIDTH = 8, PTR_WIDTH = 4;

input wr_clk_i, rd_clk_i, rst_i, wr_en_i, rd_en_i;
input [WIDTH-1:0]wdata_i;
output reg [WIDTH-1:0]rdata_o;
output reg full_o, rd_error_o, wr_error_o, empty_o;

reg [PTR_WIDTH-1:0]wr_ptr, rd_ptr;
reg [PTR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
reg [PTR_WIDTH-1:0]wr_ptr_rd_clk, rd_ptr_wr_clk;
reg [PTR_WIDTH-1:0]wr_ptr_gray_rd_clk, rd_ptr_gray_wr_clk;
reg wr_toggle_f, rd_toggle_f, wr_toggle_f_rd_clk, rd_toggle_f_wr_clk;

reg [WIDTH-1:0]fifo[DEPTH-1:0];
integer i;

// Write operation 
// Reset will be applied w.rt. write clock only (Either can be done in read interface also but not both)

always @(posedge wr_clk_i)begin
    if (rst_i)begin
        rdata_o <= 0;
        full_o <= 0;
        empty_o <= 1;
        wr_error_o <= 0;
        rd_error_o <= 0;
        wr_ptr <= 0;
        rd_ptr <= 0;
        wr_ptr_gray <= 0;
        rd_ptr_gray <= 0;
        wr_ptr_rd_clk <= 0;
        rd_ptr_wr_clk <= 0;
        wr_ptr_gray_rd_clk <= 0;
        rd_ptr_gray_wr_clk <= 0;
        wr_toggle_f <= 0;
        rd_toggle_f <= 0;
        wr_toggle_f_rd_clk <= 0;
        rd_toggle_f_wr_clk <= 0;

        for(i = 0; i< DEPTH; i = i+1)begin
            fifo[i] <= 1;
        end
    end else begin
        wr_error_o <= 0;
        if (wr_en_i)begin
            if(full_o)begin
                wr_error_o <= 1;
            end else begin
                fifo[wr_ptr] <=  wdata_i;
                if (wr_ptr == DEPTH-1)wr_toggle_f <= ~ wr_toggle_f;
                 wr_ptr <= (wr_ptr == DEPTH - 1) ? 0 : wr_ptr + 1;
                wr_ptr_gray <= {wr_ptr[3], wr_ptr[3:1]^wr_ptr[2:0]}; //Gray code conversion to avoid glitches
            end
        end
    end
end

//Read operation

always @(posedge rd_clk_i)begin
    if (!rst_i)begin
        rd_error_o <= 0;
        if(rd_en_i)begin
            if(empty_o)begin
                rd_error_o <= 1;
            end else begin
                rdata_o <= fifo[rd_ptr];
                if(rd_ptr == DEPTH-1) rd_toggle_f <= ~ rd_toggle_f;
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                rd_ptr_gray <= {rd_ptr[3], rd_ptr[3:1]^rd_ptr[2:0] };
            end
        end
    end
end

// Synchronisation (1 stage both ways)
// wrt ot wr_clk
always @(posedge wr_clk_i)begin
    rd_ptr_gray_wr_clk <= rd_ptr;
    rd_toggle_f_wr_clk <= rd_toggle_f;
end
//wrt read clk
always @(posedge rd_clk_i)begin
    wr_ptr_gray_rd_clk <= wr_ptr;
    wr_toggle_f_rd_clk <= wr_toggle_f;
end

// Empty Full condition
always @(*)begin
    empty_o = (wr_ptr_gray_rd_clk == rd_ptr_gray) && (wr_toggle_f_rd_clk == rd_toggle_f);
    full_o = (rd_ptr_gray_wr_clk == wr_ptr_gray) && (rd_toggle_f_wr_clk != wr_toggle_f);
end
endmodule
