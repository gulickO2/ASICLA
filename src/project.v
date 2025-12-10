/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Simple 16-sample logic analyzer. Captures ui_in[7:0] on each clock once armed.
  // Arm with uio_in[0] (pulse high). Read samples via uo_out using address on uio_in[4:1].
  // Status on uio_out[7:5]: done, capturing, armed.

  reg [7:0] sample_mem [0:15];
  reg [3:0] wr_addr;
  reg arm_sync, arm_meta, arm_prev;
  reg armed, capturing, done;

  wire [3:0] rd_addr = {uio_in[4], uio_in[3], uio_in[2], uio_in[1]};
  wire arm_pulse = arm_sync & ~arm_prev;  // synchronize and edge-detect arm input

  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arm_meta   <= 1'b0;
      arm_sync   <= 1'b0;
      arm_prev   <= 1'b0;
      armed      <= 1'b0;
      capturing  <= 1'b0;
      done       <= 1'b0;
      wr_addr    <= 4'd0;
      for (i = 0; i < 16; i = i + 1) begin
        sample_mem[i] <= 8'h00;
      end
    end else begin
      // Synchronize arm input
      arm_meta <= uio_in[0];
      arm_sync <= arm_meta;
      arm_prev <= arm_sync;

      if (arm_pulse) begin
        armed     <= 1'b1;
        capturing <= 1'b1;
        done      <= 1'b0;
        wr_addr   <= 4'd0;
      end

      if (capturing) begin
        sample_mem[wr_addr] <= ui_in;
        wr_addr <= wr_addr + 4'd1;
        if (wr_addr == 4'd15) begin
          capturing <= 1'b0;
          done      <= 1'b1;
          armed     <= 1'b0;
        end
      end
    end
  end

  assign uo_out  = sample_mem[rd_addr];
  assign uio_out = {done, capturing, armed, 5'b0};
  assign uio_oe  = 8'b11100000;  // status on uio_out[7:5], rest inputs

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:5], 1'b0};

endmodule
