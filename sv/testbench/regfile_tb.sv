`timescale 1ns/1ps

module regfile_tb;

//basic stuff
logic clk,
logic rst,

//read port interface (x2)
logic [4:0] rs1_addr,
logic [4:0] rs1_data,
logic [31:0] rs2_addr,
logic [31:0] rs2_data,

//write port interface
logic we,
logic [4:0] rd_addr,
logic [31:0] rd_data