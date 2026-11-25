`timescale 1ns/1ps

module tb_spi_master;
    parameter integer CLKS_PER_HALF = 2;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg [7:0] tx_data = 8'h00;
    reg miso = 1'b0;

    wire [7:0] rx_data;
    wire busy, done, sclk, mosi, cs_n;

    reg [7:0] slave_shift = 8'h00;
    reg [7:0] captured_tx = 8'h00;
    integer bit_samples = 0;
    integer completed_frames = 0;

    spi_master #(.CLKS_PER_HALF(CLKS_PER_HALF)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .miso(miso), .rx_data(rx_data), .busy(busy), .done(done),
        .sclk(sclk), .mosi(mosi), .cs_n(cs_n)
    );

    // The slave presents its first bit before the frame and advances
    // its output on each falling SCLK edge.
    always @(negedge sclk) begin
        if (!cs_n) begin
            slave_shift <= {slave_shift[6:0], 1'b0};
            miso <= slave_shift[6];
        end
    end

    always @(posedge sclk) begin
        if (!cs_n) begin
            captured_tx <= {captured_tx[6:0], mosi};
            bit_samples = bit_samples + 1;
        end
    end

    task run_frame;
        input [7:0] master_byte;
        input [7:0] slave_byte;
        begin
            @(negedge clk);
            while (busy) @(negedge clk);

            tx_data     = master_byte;
            slave_shift = slave_byte;
            miso        = slave_byte[7];
            captured_tx = 8'h00;
            bit_samples = 0;
            start       = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait (done === 1'b1);
            #1;
            if (rx_data !== slave_byte) begin
                $display("FAIL: expected RX %02h, got %02h", slave_byte, rx_data);
                $fatal(1);
            end
            if (captured_tx !== master_byte) begin
                $display("FAIL: expected TX %02h, captured %02h", master_byte, captured_tx);
                $fatal(1);
            end
            if (bit_samples != 8) begin
                $display("FAIL: expected 8 sample edges, got %0d", bit_samples);
                $fatal(1);
            end
            if (cs_n !== 1'b1 || sclk !== 1'b0 || busy !== 1'b0) begin
                $display("FAIL: SPI signals did not return to idle");
                $fatal(1);
            end

            completed_frames = completed_frames + 1;
            $display("PASS: TX=%02h RX=%02h", master_byte, rx_data);
            wait (done === 1'b0);
        end
    endtask

    initial begin
        $dumpfile("build/spi_master.vcd");
        $dumpvars(0, tb_spi_master);
    end

    initial begin
        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        run_frame(8'hA5, 8'h3C);
        run_frame(8'h00, 8'hFF);
        run_frame(8'hFF, 8'h00);
        run_frame(8'h96, 8'h69);

        if (completed_frames != 4) begin
            $display("FAIL: expected four completed frames");
            $fatal(1);
        end
        $display("PASS: all SPI frames completed with divider %0d", CLKS_PER_HALF);
        $finish;
    end

    initial begin
        #200000;
        $display("FAIL: testbench timeout");
        $fatal(1);
    end
endmodule
