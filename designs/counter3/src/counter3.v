// 3-bit synchronous up-counter, synchronous active-high reset.
module counter3 (
    input  wire       clk,
    input  wire       rst,
    output reg  [2:0] count
);

    always @(posedge clk) begin
        if (rst)
            count <= 3'b000;
        else
            count <= count + 3'b001;
    end

endmodule
