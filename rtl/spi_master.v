`timescale 1ns/1ps

// SPI Mode 0 master with one 8-bit transfer per start pulse.
module spi_master #(
    parameter integer CLKS_PER_HALF = 2
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] tx_data,
    input  wire       miso,
    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,
    output reg        sclk,
    output reg        mosi,
    output reg        cs_n
);

    localparam integer COUNT_WIDTH = (CLKS_PER_HALF <= 1) ? 1 : $clog2(CLKS_PER_HALF);
    localparam IDLE = 1'b0;
    localparam TRANSFER = 1'b1;

    reg state;
    reg [COUNT_WIDTH-1:0] clk_count;
    reg [2:0] bit_count;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    // The divider controls each half period of SCLK.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_count <= 0;
            tx_shift  <= 0;
            rx_shift  <= 0;
            rx_data   <= 0;
            busy      <= 0;
            done      <= 0;
            sclk      <= 0;
            mosi      <= 0;
            cs_n      <= 1;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    if (start) begin
                        state     <= TRANSFER;
                        clk_count <= 0;
                        bit_count <= 3'd7;
                        tx_shift  <= tx_data;
                        rx_shift  <= 0;
                        mosi      <= tx_data[7];
                        cs_n      <= 1'b0;
                        busy      <= 1'b1;
                    end else begin
                        mosi <= 1'b0;
                    end
                end

                TRANSFER: begin
                    if (clk_count == CLKS_PER_HALF - 1) begin
                        clk_count <= 0;
                        if (!sclk) begin
                            // Mode 0 leading edge: sample MISO.
                            sclk     <= 1'b1;
                            rx_shift <= {rx_shift[6:0], miso};
                        end else begin
                            // Mode 0 trailing edge: prepare the next MOSI bit.
                            sclk <= 1'b0;
                            if (bit_count == 0) begin
                                rx_data <= rx_shift;
                                busy    <= 1'b0;
                                done    <= 1'b1;
                                cs_n    <= 1'b1;
                                mosi    <= 1'b0;
                                state   <= IDLE;
                            end else begin
                                bit_count <= bit_count - 1'b1;
                                tx_shift  <= {tx_shift[6:0], 1'b0};
                                mosi      <= tx_shift[6];
                            end
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    busy  <= 1'b0;
                    sclk  <= 1'b0;
                    cs_n  <= 1'b1;
                end
            endcase
        end
    end

    // Guard against a divider value that cannot produce a clock.
    `ifndef SYNTHESIS
    initial begin
        if (CLKS_PER_HALF < 1)
            $error("CLKS_PER_HALF must be at least 1");
    end
    `endif

endmodule
