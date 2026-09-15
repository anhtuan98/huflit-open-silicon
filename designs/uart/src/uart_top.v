// Top-level UART: an independent 8N1 transmitter and receiver sharing one
// clock and one CLKS_PER_BIT bit-timing parameter. tx_serial and
// rx_serial are separate top-level ports -- loopback (tying one to the
// other) is done outside this module, e.g. by a testbench or by a board
// wiring TX to RX.
module uart_top #(
    parameter CLKS_PER_BIT = 4
) (
    input  wire       clk,
    input  wire       rst,

    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_serial,
    output wire       tx_busy,

    input  wire       rx_serial,
    output wire [7:0] rx_data,
    output wire       rx_done
);

    uart_tx #(
        .CLKS_PER_BIT (CLKS_PER_BIT)
    ) u_tx (
        .clk       (clk),
        .rst       (rst),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx_serial (tx_serial),
        .tx_busy   (tx_busy)
    );

    uart_rx #(
        .CLKS_PER_BIT (CLKS_PER_BIT)
    ) u_rx (
        .clk       (clk),
        .rst       (rst),
        .rx_serial (rx_serial),
        .rx_data   (rx_data),
        .rx_done   (rx_done)
    );

endmodule
