// UART receiver, 8N1 framing (1 start bit, 8 data bits LSB-first, 1 stop
// bit, no parity). Samples the middle of each bit -- the classic
// technique that tolerates small bit-boundary misalignment between an
// external transmitter and this receiver's own clock. rx_serial is an
// external, unclocked input, so it is run through a 2-flop synchronizer
// before the FSM ever looks at it.
module uart_rx #(
    parameter CLKS_PER_BIT = 4
) (
    input  wire       clk,
    input  wire       rst,

    input  wire       rx_serial,
    output reg  [7:0] rx_data,
    output reg        rx_done
);

    localparam IDLE      = 3'd0,
               START_BIT = 3'd1,
               DATA_BITS = 3'd2,
               STOP_BIT  = 3'd3,
               CLEANUP   = 3'd4;

    reg [2:0]                    state;
    reg [$clog2(CLKS_PER_BIT):0] clk_count;
    reg [2:0]                    bit_index;
    reg [7:0]                    data_reg;

    reg rx_sync;
    reg rx_serial_sync;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync        <= 1'b1;
            rx_serial_sync <= 1'b1;
        end else begin
            rx_sync        <= rx_serial;
            rx_serial_sync <= rx_sync;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            rx_done   <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_serial_sync == 1'b0)
                        state <= START_BIT;
                end

                START_BIT: begin
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_serial_sync == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA_BITS;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count           <= 0;
                        data_reg[bit_index] <= rx_serial_sync;
                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state     <= STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        rx_data <= data_reg;
                        rx_done <= 1'b1;
                        state   <= CLEANUP;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                CLEANUP: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
