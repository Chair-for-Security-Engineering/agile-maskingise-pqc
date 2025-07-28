module frv_masked_cmp (
input wire         g_clk, ena, flush,
input wire resetn,
input wire  [31:0] remask0,
input wire  [31:0] remask1,
input wire  [31:0] remask2,

input  [31:0] a0,
input  [31:0] a1,
input  [31:0] b0,
input  [31:0] b1,

output [31:0] o_r0,
output [31:0] o_r1,

output wire o_rdy
);

reg  [11:0] seq_cnt;
always @(posedge g_clk) begin
  if (ena) begin
    if (seq_cnt[11] == 1) begin
      seq_cnt <= 12'b1;
    end else begin
    seq_cnt <= seq_cnt << 1;
    end
  end else if (flush) begin
    seq_cnt <= 12'b1;
  end
  else begin
    seq_cnt <= 12'b1;
  end
end

wire[31:0] xor0 = a0 ^ b0;
wire[31:0] xor1 = a1 ^ b1;
wire[15:0] o_stage10;
wire[15:0] o_stage11;
genvar stage1;
generate for(stage1 = 0; stage1 < 16; stage1 = stage1 + 1) begin
  frv_masked_and #(.BIT_WIDTH(1)) stage1_and(
				.g_clk(g_clk),
				.resetn(resetn),
				.clk_en(ena),
				.z0(remask0[stage1]),
				.z1(remask1[stage1]),
				.z2(remask2[stage1]),
				.ax(xor0[stage1*2]),
				.ay(xor0[(stage1*2)+1]),
				.bx(~xor1[stage1*2]),
				.by(~xor1[(stage1*2)+1]),
				.qx(o_stage10[stage1]),
				.qy(o_stage11[stage1])
			);
end
endgenerate

wire[15:0] o_stage11_ior = ~o_stage11;

wire[7:0] o_stage20;
wire[7:0] o_stage21;
genvar stage2;
generate for(stage2 = 0; stage2 < 8; stage2 = stage2 + 1) begin
    frv_masked_and #(.BIT_WIDTH(1)) stage2_and(
				.g_clk(g_clk),
				.resetn(resetn),
				.clk_en(ena),
				.z0(remask0[16+stage2]),
				.z1(remask1[16+stage2]),
				.z2(remask2[16+stage2]),
				.ax(o_stage10[stage2*2]),
				.ay(o_stage10[(stage2*2)+1]),
				.bx(~o_stage11_ior[stage2*2]),
				.by(~o_stage11_ior[(stage2*2)+1]),
				.qx(o_stage20[stage2]),
				.qy(o_stage21[stage2])
			);
end
endgenerate

wire[7:0] o_stage21_ior = ~o_stage21;

wire[3:0] o_stage30;
wire[3:0] o_stage31;
genvar stage3;
generate for(stage3 = 0; stage3 < 4; stage3 = stage3 + 1) begin
      frv_masked_and #(.BIT_WIDTH(1)) stage3_and(
				.g_clk(g_clk),
				.resetn(resetn),
				.clk_en(ena),
				.z0(remask0[24+stage3]),
				.z1(remask1[24+stage3]),
				.z2(remask2[24+stage3]),
				.ax(o_stage20[stage3*2]),
				.ay(o_stage20[(stage3*2)+1]),
				.bx(~o_stage21_ior[stage3*2]),
				.by(~o_stage21_ior[(stage3*2)+1]),
				.qx(o_stage30[stage3]),
				.qy(o_stage31[stage3])
			);
end
endgenerate

wire[3:0] o_stage31_ior = ~o_stage31;

wire[1:0] o_stage40;
wire[1:0] o_stage41;
genvar stage4;
generate for(stage4 = 0; stage4 < 2; stage4 = stage4 + 1) begin
      frv_masked_and #(.BIT_WIDTH(1)) stage4_and(
      .g_clk(g_clk),
      .resetn(resetn),
      .clk_en(ena),
      .z0(remask0[28+stage4]),
      .z1(remask1[28+stage4]),
      .z2(remask2[28+stage4]),
      .ax(o_stage30[stage4*2]),
      .ay(o_stage30[(stage4*2)+1]),
      .bx(~o_stage31_ior[stage4*2]),
      .by(~o_stage31_ior[(stage4*2)+1]),
      .qx(o_stage40[stage4]),
      .qy(o_stage41[stage4])
    );
end
endgenerate

wire[1:0] o_stage41_ior = ~o_stage41;

wire o_stage50;
wire o_stage51;
      frv_masked_and #(.BIT_WIDTH(1)) stage5_and(
      .g_clk(g_clk),
      .resetn(resetn),
      .clk_en(ena),
      .z0(remask0[30]),
      .z1(remask1[30]),
      .z2(remask2[30]),
      .ax(o_stage40[0]),
      .ay(o_stage40[1]),
      .bx(~o_stage41_ior[0]),
      .by(~o_stage41_ior[1]),
      .qx(o_stage50),
      .qy(o_stage51)
    );

assign o_r0 = {31'b0, o_stage50};
assign o_r1 = {31'b0, o_stage51};
assign o_rdy = seq_cnt[11];

endmodule



module frv_masked_cmov (
input wire         g_clk, ena, 

input wire  [31:0] remask0,
input wire  [31:0] remask1,
input wire  [31:0] remask2,

input wire resetn,

input  [31:0] old0,
input  [31:0] old1,
input  [31:0] cond0,
input  [31:0] cond1,
input  [31:0] new0,
input  [31:0] new1,


output [31:0] o_r0,
output [31:0] o_r1,

output wire rdy
);

wire[31:0] internalcond0;
wire[31:0] internalcond1;
genvar i;
generate for(i = 0; i < 32; i = i + 1) begin
        assign internalcond0[i] = cond0[0];
        assign internalcond1[i] = cond1[0];
    end
endgenerate

wire[31:0] a0 = old0 ^ new0;
wire[31:0] a1 = old1 ^ new1;

wire[31:0] b0;
wire[31:0] b1;

frv_masked_and #(.BIT_WIDTH(32)) i_dom_and(
				.g_clk(g_clk),
				.resetn(resetn),
				.clk_en(ena),
				.z0(remask0),
				.z1(remask1),
				.z2(remask2),
				.ax(a0),
				.ay(internalcond0),
				.bx(a1),
				.by(internalcond1),
				.qx(b0),
				.qy(b1)
			);

assign o_r0 = b0 ^ old0;
assign o_r1 = b1 ^ old1;

reg [1:0] ctr_ready;
always @(posedge g_clk)
  if (rdy)
    ctr_ready = 2'h1;
  else if (ena)
    ctr_ready = ctr_ready << 1;
  else
    ctr_ready = 2'h1;
assign rdy = ctr_ready[1];

endmodule

module decoder (
	clk,
	rst,
	port_a,
	port_b,
	port_r,
	port_c
);
	parameter integer D = 2;
	parameter integer N = D + 1;
	input clk;
	input rst;
	input [N - 1:0] port_a;
	input [N - 1:0] port_b;
	input [N - 1:0] port_r;
	output wire [N - 1:0] port_c;
	wire [N - 1:0] b_masked;
	wire [N - 1:0] b_masked_delayed;
	wire sum;
	assign b_masked = port_r ^ port_b;
	register_with_sync_reset #(.BITWIDTH(N)) delay_b_masked(
		.clk(clk),
		.rst(rst),
		.d(b_masked),
		.q(b_masked_delayed)
	);
	assign sum = ^b_masked_delayed;
	assign port_c = {N {sum}} & port_a;
endmodule
module dff (
	clk,
	d,
	q
);
	input clk;
	input d;
	output reg q;
	always @(posedge clk) q <= d;
endmodule
module dff_with_sync_reset (
	clk,
	rst,
	d,
	q
);
	input clk;
	input rst;
	input d;
	output reg q;
	always @(posedge clk)
		if (rst)
			q <= 1'b0;
		else
			q <= d;
endmodule
module dom_dep_multibit (
	clk,
	rst,
	port_a,
	port_b,
	port_r1,
	port_r2,
	port_c
);
	parameter integer D = 1;
	parameter integer BIT_WIDTH = 1;
	parameter integer PIPELINING = 1;
	parameter integer N = D + 1;
	parameter integer L = ((D + 1) * D) / 2;
	input clk;
	input rst;
	input [(BIT_WIDTH * N) - 1:0] port_a;
	input [(BIT_WIDTH * N) - 1:0] port_b;
	input [(BIT_WIDTH * N) - 1:0] port_r1;
	input [(BIT_WIDTH * L) - 1:0] port_r2;
	output wire [(BIT_WIDTH * N) - 1:0] port_c;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < BIT_WIDTH; _gv_i_1 = _gv_i_1 + 1) begin : gen_dom_dep_mulbit
			localparam i = _gv_i_1;
			dom_dep #(
				.D(D),
				.PIPELINING(PIPELINING)
			) dom_dep(
				.clk(clk),
				.rst(rst),
				.port_a(port_a[((BIT_WIDTH - 1) - i) * N+:N]),
				.port_b(port_b[((BIT_WIDTH - 1) - i) * N+:N]),
				.port_r1(port_r1[((BIT_WIDTH - 1) - i) * N+:N]),
				.port_r2(port_r2[((BIT_WIDTH - 1) - i) * L+:L]),
				.port_c(port_c[((BIT_WIDTH - 1) - i) * N+:N])
			);
		end
	endgenerate
endmodule
module dom_dep (
	clk,
	rst,
	port_a,
	port_b,
	port_r1,
	port_r2,
	port_c
);
	parameter integer D = 2;
	parameter integer N = D + 1;
	parameter integer L = ((D + 1) * D) / 2;
	parameter integer PIPELINING = 1;
	input clk;
	input rst;
	input [N - 1:0] port_a;
	input [N - 1:0] port_b;
	input [N - 1:0] port_r1;
	input [L - 1:0] port_r2;
	output wire [N - 1:0] port_c;
	wire [N - 1:0] a_delayed;
	wire [N - 1:0] dom_mul_out;
	wire [N - 1:0] dom_dec_out;
	generate
		if (PIPELINING == 1) begin : gen_pipline
			register_with_sync_reset #(.BITWIDTH(N)) delay_a(
				.clk(clk),
				.rst(rst),
				.d(port_a),
				.q(a_delayed)
			);
		end
		else begin : gen_no_pipeline
			assign a_delayed = port_a;
		end
	endgenerate
	dom_indep #(.D(D)) dom_mul(
		.clk(clk),
		.rst(rst),
		.port_a(port_a),
		.port_b(port_r1),
		.port_r(port_r2),
		.port_c(dom_mul_out)
	);
	decoder #(.D(D)) dom_dec(
		.clk(clk),
		.rst(rst),
		.port_a(a_delayed),
		.port_b(port_b),
		.port_r(port_r1),
		.port_c(dom_dec_out)
	);
	assign port_c = dom_mul_out ^ dom_dec_out;
endmodule
module dom_indep_multibit (
	clk,
	port_a,
	port_b,
	port_r,
	port_c
);
	parameter integer D = 1;
	parameter integer BIT_WIDTH = 1;
	parameter integer N = D + 1;
	parameter integer L = ((D + 1) * D) / 2;
	input clk;
	input [(BIT_WIDTH * N) - 1:0] port_a;
	input [(BIT_WIDTH * N) - 1:0] port_b;
	input [(BIT_WIDTH * L) - 1:0] port_r;
	output wire [(BIT_WIDTH * N) - 1:0] port_c;
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < BIT_WIDTH; _gv_i_2 = _gv_i_2 + 1) begin : gen_dom_indep_multbit
			localparam i = _gv_i_2;
			dom_indep #(.D(D)) dom_mul(
				.clk(clk),
				.port_a(port_a[((BIT_WIDTH - 1) - i) * N+:N]),
				.port_b(port_b[((BIT_WIDTH - 1) - i) * N+:N]),
				.port_r(port_r[((BIT_WIDTH - 1) - i) * L+:L]),
				.port_c(port_c[((BIT_WIDTH - 1) - i) * N+:N])
			);
		end
	endgenerate
endmodule
module dom_indep (
	clk,
	rst,
	port_a,
	port_b,
	port_r,
	port_c
);
	parameter integer D = 2;
	parameter integer N = D + 1;
	parameter integer L = ((D + 1) * D) / 2;
	input clk;
	input rst;
	input [N - 1:0] port_a;
	input [N - 1:0] port_b;
	input [L - 1:0] port_r;
	output wire [N - 1:0] port_c;
	wire [N - 1:0] partial_products [0:N - 1];
	wire [N - 1:0] partial_products_delayed [0:N - 1];
	genvar _gv_i_3;
	genvar _gv_j_1;
	generate
		for (_gv_i_3 = 0; _gv_i_3 < N; _gv_i_3 = _gv_i_3 + 1) begin : gen_sym_partial_product
			localparam i = _gv_i_3;
			assign partial_products[i][i] = port_a[i] & port_b[i];
			for (_gv_j_1 = i + 1; _gv_j_1 < N; _gv_j_1 = _gv_j_1 + 1) begin : gen_asym_partial_product
				localparam j = _gv_j_1;
				assign partial_products[i][j] = (port_a[i] & port_b[j]) ^ port_r[i + ((j * (j - 1)) / 2)];
				assign partial_products[j][i] = (port_a[j] & port_b[i]) ^ port_r[i + ((j * (j - 1)) / 2)];
			end
		end
		for (_gv_i_3 = 0; _gv_i_3 < N; _gv_i_3 = _gv_i_3 + 1) begin : gen_delayed_partial_product
			localparam i = _gv_i_3;
			register_with_sync_reset #(.BITWIDTH(N)) delay_partial_products(
				.clk(clk),
				.rst(rst),
				.d(partial_products[i]),
				.q(partial_products_delayed[i])
			);
		end
		for (_gv_i_3 = 0; _gv_i_3 < N; _gv_i_3 = _gv_i_3 + 1) begin : gen_result_by_recombining
			localparam i = _gv_i_3;
			assign port_c[i] = ^partial_products_delayed[i];
		end
	endgenerate
endmodule
module frv_gf256_aff (
	i_a,
	i_m,
	o_r
);
	input [7:0] i_a;
	input [63:0] i_m;
	output wire [7:0] o_r;
	wire [7:0] c7 = i_m[63:56];
	wire [7:0] c6 = i_m[55:48];
	wire [7:0] c5 = i_m[47:40];
	wire [7:0] c4 = i_m[39:32];
	wire [7:0] c3 = i_m[31:24];
	wire [7:0] c2 = i_m[23:16];
	wire [7:0] c1 = i_m[15:8];
	wire [7:0] c0 = i_m[7:0];
	wire [7:0] m7 = {8 {i_a[7]}} & c7;
	wire [7:0] m6 = {8 {i_a[6]}} & c6;
	wire [7:0] m5 = {8 {i_a[5]}} & c5;
	wire [7:0] m4 = {8 {i_a[4]}} & c4;
	wire [7:0] m3 = {8 {i_a[3]}} & c3;
	wire [7:0] m2 = {8 {i_a[2]}} & c2;
	wire [7:0] m1 = {8 {i_a[1]}} & c1;
	wire [7:0] m0 = {8 {i_a[0]}} & c0;
	assign o_r = ((((((m0 ^ m1) ^ m2) ^ m3) ^ m4) ^ m5) ^ m6) ^ m7;
endmodule
module frv_gf256_mul (
	i_a,
	i_b,
	o_r
);
	input [7:0] i_a;
	input [7:0] i_b;
	output wire [7:0] o_r;
	wire A0 = i_a[0];
	wire A1 = i_a[1];
	wire A2 = i_a[2];
	wire A3 = i_a[3];
	wire A4 = i_a[4];
	wire A5 = i_a[5];
	wire A6 = i_a[6];
	wire A7 = i_a[7];
	wire B0 = i_b[0];
	wire B1 = i_b[1];
	wire B2 = i_b[2];
	wire B3 = i_b[3];
	wire B4 = i_b[4];
	wire B5 = i_b[5];
	wire B6 = i_b[6];
	wire B7 = i_b[7];
	wire T1 = A0 && B0;
	wire T2 = A0 && B1;
	wire T3 = A1 && B0;
	wire T4 = A0 && B2;
	wire T5 = A1 && B1;
	wire T6 = A2 && B0;
	wire T7 = A0 && B3;
	wire T8 = A1 && B2;
	wire T9 = A2 && B1;
	wire T10 = A3 && B0;
	wire T11 = A1 && B3;
	wire T12 = A2 && B2;
	wire T13 = A3 && B1;
	wire T14 = A2 && B3;
	wire T15 = A3 && B2;
	wire T16 = A3 && B3;
	wire T17 = A4 && B4;
	wire T18 = A4 && B5;
	wire T19 = A5 && B4;
	wire T20 = A4 && B6;
	wire T21 = A5 && B5;
	wire T22 = A6 && B4;
	wire T23 = A4 && B7;
	wire T24 = A5 && B6;
	wire T25 = A6 && B5;
	wire T26 = A7 && B4;
	wire T27 = A5 && B7;
	wire T28 = A6 && B6;
	wire T29 = A7 && B5;
	wire T30 = A6 && B7;
	wire T31 = A7 && B6;
	wire T32 = A7 && B7;
	wire T33 = A0 ^ A4;
	wire T34 = A1 ^ A5;
	wire T35 = A2 ^ A6;
	wire T36 = A3 ^ A7;
	wire T37 = B0 ^ B4;
	wire T38 = B1 ^ B5;
	wire T39 = B2 ^ B6;
	wire T40 = B3 ^ B7;
	wire T41 = T40 && T36;
	wire T42 = T40 && T35;
	wire T43 = T40 && T34;
	wire T44 = T40 && T33;
	wire T45 = T39 && T36;
	wire T46 = T39 && T35;
	wire T47 = T39 && T34;
	wire T48 = T39 && T33;
	wire T49 = T38 && T36;
	wire T50 = T38 && T35;
	wire T51 = T38 && T34;
	wire T52 = T38 && T33;
	wire T53 = T37 && T36;
	wire T54 = T37 && T35;
	wire T55 = T37 && T34;
	wire T56 = T37 && T33;
	wire T57 = T2 ^ T3;
	wire T58 = T4 ^ T5;
	wire T59 = T6 ^ T32;
	wire T60 = T7 ^ T8;
	wire T61 = T9 ^ T10;
	wire T62 = T60 ^ T61;
	wire T63 = T11 ^ T12;
	wire T64 = T13 ^ T63;
	wire T65 = T14 ^ T15;
	wire T66 = T18 ^ T19;
	wire T67 = T20 ^ T21;
	wire T68 = T22 ^ T67;
	wire T69 = T23 ^ T24;
	wire T70 = T25 ^ T26;
	wire T71 = T69 ^ T70;
	wire T72 = T27 ^ T28;
	wire T73 = T29 ^ T32;
	wire T74 = T30 ^ T31;
	wire T75 = T52 ^ T55;
	wire T76 = T48 ^ T51;
	wire T77 = T54 ^ T76;
	wire T78 = T44 ^ T47;
	wire T79 = T50 ^ T53;
	wire T80 = T78 ^ T79;
	wire T81 = T43 ^ T46;
	wire T82 = T49 ^ T81;
	wire T83 = T42 ^ T45;
	wire T84 = T71 ^ T74;
	wire T85 = T41 ^ T16;
	wire T86 = T85 ^ T68;
	wire T87 = T66 ^ T65;
	wire T88 = T83 ^ T87;
	wire T89 = T58 ^ T59;
	wire T90 = T72 ^ T73;
	wire T91 = T74 ^ T17;
	wire T92 = T64 ^ T91;
	wire T93 = T82 ^ T92;
	wire T94 = T80 ^ T62;
	wire T95 = T94 ^ T90;
	wire T96 = T41 ^ T77;
	wire T97 = T84 ^ T89;
	wire T98 = T96 ^ T97;
	wire T99 = T57 ^ T74;
	wire T100 = T83 ^ T75;
	wire T101 = T86 ^ T90;
	wire T102 = T99 ^ T100;
	wire T103 = T101 ^ T102;
	wire T104 = T1 ^ T56;
	wire T105 = T90 ^ T104;
	wire T106 = T82 ^ T84;
	wire T107 = T88 ^ T105;
	wire T108 = T106 ^ T107;
	wire T109 = T71 ^ T62;
	wire T110 = T86 ^ T109;
	wire T111 = T110 ^ T93;
	wire T112 = T86 ^ T88;
	wire T113 = T89 ^ T112;
	wire T114 = T57 ^ T32;
	wire T115 = T114 ^ T88;
	wire T116 = T115 ^ T93;
	wire T117 = T93 ^ T1;
	assign o_r[0] = T117;
	assign o_r[1] = T116;
	assign o_r[2] = T113;
	assign o_r[3] = T111;
	assign o_r[4] = T108;
	assign o_r[5] = T103;
	assign o_r[6] = T98;
	assign o_r[7] = T95;
endmodule
module frv_lfsr32 (
	g_clk,
	g_resetn,
	update,
	extra_tap,
	prng,
	n_prng
);
	parameter RESET_VALUE = 32'h6789abcd;
	input wire g_clk;
	input wire g_resetn;
	input wire update;
	input wire extra_tap;
	output reg [31:0] prng;
	output wire [31:0] n_prng;
	wire n_prng_lsb = (((prng[31] ~^ prng[21]) ~^ prng[1]) ~^ prng[0]) ^ extra_tap;
	assign n_prng = {prng[30:0], n_prng_lsb};
	always @(posedge g_clk)
		if (!g_resetn)
			prng <= RESET_VALUE;
		else if (update)
			prng <= n_prng;
endmodule
module frv_masked_arith (
	i_a0,
	i_a1,
	i_b0,
	i_b1,
	i_gs,
	mask,
	remask,
	doadd,
	dosub,
	o_r0,
	o_r1
);
	input [31:0] i_a0;
	input [31:0] i_a1;
	input [31:0] i_b0;
	input [31:0] i_b1;
	input [31:0] i_gs;
	input mask;
	input remask;
	input doadd;
	input dosub;
	output wire [31:0] o_r0;
	output wire [31:0] o_r1;
	wire [32:0] amadd0;
	wire [32:0] amadd1;
	wire [31:0] opr_lhs_0;
	wire [31:0] opr_rhs_0;
	wire [31:0] opr_lhs_1;
	wire [31:0] opr_rhs_1;
	wire ci;
	assign opr_lhs_0 = i_a0;
	assign opr_rhs_0 = (doadd ? i_b0 : (dosub ? ~i_b0 : i_gs));
	assign opr_lhs_1 = (~mask ? i_a1 : i_gs);
	assign opr_rhs_1 = (doadd ? i_b1 : (dosub ? ~i_b1 : (remask ? i_gs : 32'd0)));
	assign ci = dosub;
	assign amadd0 = {opr_lhs_0, 1'b1} + {opr_rhs_0, ci};
	assign amadd1 = {opr_lhs_1, 1'b1} + {opr_rhs_1, ci};
	assign o_r0 = amadd0[32:1];
	assign o_r1 = amadd1[32:1];
endmodule
module frv_masked_faff (
	i_a0,
	i_a1,
	i_mt,
	i_gs,
	o_r0,
	o_r1
);
	input [31:0] i_a0;
	input [31:0] i_a1;
	input [63:0] i_mt;
	input [31:0] i_gs;
	output wire [31:0] o_r0;
	output wire [31:0] o_r1;
	wire [31:0] r0;
	wire [31:0] r1;
	frv_gf256_aff atr0_b0(
		.i_a(i_a0[7:0]),
		.i_m(i_mt),
		.o_r(r0[7:0])
	);
	frv_gf256_aff atr1_b0(
		.i_a(i_a1[7:0]),
		.i_m(i_mt),
		.o_r(r1[7:0])
	);
	frv_gf256_aff atr0_b1(
		.i_a(i_a0[15:8]),
		.i_m(i_mt),
		.o_r(r0[15:8])
	);
	frv_gf256_aff atr1_b1(
		.i_a(i_a1[15:8]),
		.i_m(i_mt),
		.o_r(r1[15:8])
	);
	frv_gf256_aff atr0_b2(
		.i_a(i_a0[23:16]),
		.i_m(i_mt),
		.o_r(r0[23:16])
	);
	frv_gf256_aff atr1_b2(
		.i_a(i_a1[23:16]),
		.i_m(i_mt),
		.o_r(r1[23:16])
	);
	frv_gf256_aff atr0_b3(
		.i_a(i_a0[31:24]),
		.i_m(i_mt),
		.o_r(r0[31:24])
	);
	frv_gf256_aff atr1_b3(
		.i_a(i_a1[31:24]),
		.i_m(i_mt),
		.o_r(r1[31:24])
	);
	assign o_r0 = i_gs ^ r0;
	assign o_r1 = i_gs ^ r1;
endmodule
module frv_masked_fmul (
	g_resetn,
	g_clk,
	ena,
	i_a0,
	i_a1,
	i_b0,
	i_b1,
	i_sqr,
	i_gs,
	o_r0,
	o_r1
);
	input g_resetn;
	input g_clk;
	input ena;
	input [31:0] i_a0;
	input [31:0] i_a1;
	input [31:0] i_b0;
	input [31:0] i_b1;
	input i_sqr;
	input [31:0] i_gs;
	output wire [31:0] o_r0;
	output wire [31:0] o_r1;
	parameter MASKING_ISE_DOM = 1'b1;
	wire [31:0] c_b0a0;
	wire [31:0] c_b1a1;
	wire [31:0] c_b100;
	wire [31:0] c_b000;
	assign c_b0a0 = (i_sqr ? i_a0 : i_b0);
	assign c_b1a1 = (i_sqr ? i_a1 : i_b1);
	assign c_b100 = (i_sqr ? 32'd0 : i_b1);
	assign c_b000 = (i_sqr ? 32'd0 : i_b0);
	wire [31:0] m00;
	wire [31:0] m11;
	wire [31:0] m01;
	wire [31:0] m10;
	frv_gf256_mul mult0_b0(
		.i_a(i_a0[7:0]),
		.i_b(c_b0a0[7:0]),
		.o_r(m00[7:0])
	);
	frv_gf256_mul mult1_b0(
		.i_a(i_a1[7:0]),
		.i_b(c_b1a1[7:0]),
		.o_r(m11[7:0])
	);
	frv_gf256_mul mult2_b0(
		.i_a(i_a0[7:0]),
		.i_b(c_b100[7:0]),
		.o_r(m01[7:0])
	);
	frv_gf256_mul mult3_b0(
		.i_a(i_a1[7:0]),
		.i_b(c_b000[7:0]),
		.o_r(m10[7:0])
	);
	frv_gf256_mul mult0_b1(
		.i_a(i_a0[15:8]),
		.i_b(c_b0a0[15:8]),
		.o_r(m00[15:8])
	);
	frv_gf256_mul mult1_b1(
		.i_a(i_a1[15:8]),
		.i_b(c_b1a1[15:8]),
		.o_r(m11[15:8])
	);
	frv_gf256_mul mult2_b1(
		.i_a(i_a0[15:8]),
		.i_b(c_b100[15:8]),
		.o_r(m01[15:8])
	);
	frv_gf256_mul mult3_b1(
		.i_a(i_a1[15:8]),
		.i_b(c_b000[15:8]),
		.o_r(m10[15:8])
	);
	frv_gf256_mul mult0_b2(
		.i_a(i_a0[23:16]),
		.i_b(c_b0a0[23:16]),
		.o_r(m00[23:16])
	);
	frv_gf256_mul mult1_b2(
		.i_a(i_a1[23:16]),
		.i_b(c_b1a1[23:16]),
		.o_r(m11[23:16])
	);
	frv_gf256_mul mult2_b2(
		.i_a(i_a0[23:16]),
		.i_b(c_b100[23:16]),
		.o_r(m01[23:16])
	);
	frv_gf256_mul mult3_b2(
		.i_a(i_a1[23:16]),
		.i_b(c_b000[23:16]),
		.o_r(m10[23:16])
	);
	frv_gf256_mul mult0_b3(
		.i_a(i_a0[31:24]),
		.i_b(c_b0a0[31:24]),
		.o_r(m00[31:24])
	);
	frv_gf256_mul mult1_b3(
		.i_a(i_a1[31:24]),
		.i_b(c_b1a1[31:24]),
		.o_r(m11[31:24])
	);
	frv_gf256_mul mult2_b3(
		.i_a(i_a0[31:24]),
		.i_b(c_b100[31:24]),
		.o_r(m01[31:24])
	);
	frv_gf256_mul mult3_b3(
		.i_a(i_a1[31:24]),
		.i_b(c_b000[31:24]),
		.o_r(m10[31:24])
	);
	generate
		if (MASKING_ISE_DOM == 1'b1) begin : DOM_masking
			wire [31:0] reshare0 = m01 ^ i_gs;
			wire [31:0] reshare1 = m10 ^ i_gs;
			wire [31:0] integr0;
			wire [31:0] integr1;
			FF_Nb #(
				.Nb(32),
				.EDG(1'b0)
			) ff_p0(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(reshare0),
				.dout(integr0)
			);
			FF_Nb #(
				.Nb(32),
				.EDG(1'b0)
			) ff_p1(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(reshare1),
				.dout(integr1)
			);
			assign o_r0 = m00 ^ integr0;
			assign o_r1 = m11 ^ integr1;
		end
		else begin : masking
			(* keep = "true" *) wire [31:0] refresh = (i_gs ^ m01) ^ m10;
			assign o_r0 = m00 ^ i_gs;
			assign o_r1 = m11 ^ refresh;
		end
	endgenerate
endmodule
module frv_masked_shfrot (
	s,
	shamt,
	rp,
	srli,
	slli,
	rori,
	r
);
	input [31:0] s;
	input [4:0] shamt;
	input [31:0] rp;
	input srli;
	input slli;
	input rori;
	output wire [31:0] r;
	wire left = slli;
	wire right = srli | rori;
	wire [31:0] l0 = s;
	wire [31:0] l1;
	wire [31:0] l2;
	wire [31:0] l4;
	wire [31:0] l8;
	wire [31:0] l16;
	wire l1_rpr = (rori ? l0[0] : rp[0]);
	wire [1:0] l2_rpr = (rori ? l1[1:0] : rp[2:1]);
	wire [3:0] l4_rpr = (rori ? l2[3:0] : rp[6:3]);
	wire [7:0] l8_rpr = (rori ? l4[7:0] : rp[14:7]);
	wire [15:0] l16_rpr = (rori ? l8[15:0] : rp[30:15]);
	wire [31:0] l1_left = {l0[30:0], rp[31]};
	wire [31:0] l1_right = {l1_rpr, l0[31:1]};
	wire l1_l = left && shamt[0];
	wire l1_r = right && shamt[0];
	wire l1_n = !shamt[0];
	assign l1 = (({32 {l1_l}} & l1_left) | ({32 {l1_r}} & l1_right)) | ({32 {l1_n}} & l0);
	wire [31:0] l2_left = {l1[29:0], rp[30:29]};
	wire [31:0] l2_right = {l2_rpr, l1[31:2]};
	wire l2_l = left && shamt[1];
	wire l2_r = right && shamt[1];
	wire l2_n = !shamt[1];
	assign l2 = (({32 {l2_l}} & l2_left) | ({32 {l2_r}} & l2_right)) | ({32 {l2_n}} & l1);
	wire [31:0] l4_left = {l2[27:0], rp[28:25]};
	wire [31:0] l4_right = {l4_rpr, l2[31:4]};
	wire l4_l = left && shamt[2];
	wire l4_r = right && shamt[2];
	wire l4_n = !shamt[2];
	assign l4 = (({32 {l4_l}} & l4_left) | ({32 {l4_r}} & l4_right)) | ({32 {l4_n}} & l2);
	wire [31:0] l8_left = {l4[23:0], rp[24:17]};
	wire [31:0] l8_right = {l8_rpr, l4[31:8]};
	wire l8_l = left && shamt[3];
	wire l8_r = right && shamt[3];
	wire l8_n = !shamt[3];
	assign l8 = (({32 {l8_l}} & l8_left) | ({32 {l8_r}} & l8_right)) | ({32 {l8_n}} & l4);
	wire [31:0] l16_left = {l8[15:0], rp[16:1]};
	wire [31:0] l16_right = {l16_rpr, l8[31:16]};
	wire l16_l = left && shamt[4];
	wire l16_r = right && shamt[4];
	wire l16_n = !shamt[4];
	assign l16 = (({32 {l16_l}} & l16_left) | ({32 {l16_r}} & l16_right)) | ({32 {l16_n}} & l8);
	assign r = l16;
endmodule
module register (
	clk,
	d,
	q
);
	parameter integer N = 2;
	input wire clk;
	input wire [N - 1:0] d;
	output wire [N - 1:0] q;
	genvar _gv_i_4;
	generate
		for (_gv_i_4 = 0; _gv_i_4 < N; _gv_i_4 = _gv_i_4 + 1) begin : gen_register
			localparam i = _gv_i_4;
			dff dff_i(
				.clk(clk),
				.d(d[i]),
				.q(q[i])
			);
		end
	endgenerate
endmodule
module register_with_sync_reset (
	clk,
	rst,
	d,
	q
);
	parameter integer BITWIDTH = 2;
	input clk;
	input rst;
	input wire [BITWIDTH - 1:0] d;
	output wire [BITWIDTH - 1:0] q;
	genvar _gv_i_5;
	generate
		for (_gv_i_5 = 0; _gv_i_5 < BITWIDTH; _gv_i_5 = _gv_i_5 + 1) begin : gen_register
			localparam i = _gv_i_5;
			dff_with_sync_reset dff_i(
				.clk(clk),
				.rst(rst),
				.d(d[i]),
				.q(q[i])
			);
		end
	endgenerate
endmodule
module FF_Nb (
	g_resetn,
	g_clk,
	ena,
	din,
	dout
);
	parameter integer Nb = 1;
	parameter [0:0] EDG = 1;
	input wire g_resetn;
	input wire g_clk;
	input wire ena;
	input wire [Nb - 1:0] din;
	output reg [Nb - 1:0] dout;
	generate
		if (EDG == 1'b1) begin : gen_posedge_ff
			always @(posedge g_clk)
				if (!g_resetn)
					dout <= {Nb {1'b0}};
				else if (ena)
					dout <= din;
		end
		else begin : gen_negedge_ff
			always @(negedge g_clk)
				if (!g_resetn)
					dout <= {Nb {1'b0}};
				else if (ena)
					dout <= din;
		end
	endgenerate
endmodule
module frv_masked_alu (
	g_clk,
	g_resetn,
	valid,
	flush,
	op_b2a,
	op_a2b,
	op_b_mask,
	op_b_remask,
	op_a_mask,
	op_a_remask,
	op_b_not,
	op_b_and,
	op_b_ior,
	op_b_xor,
	op_b_add,
	op_b_sub,
	op_b_srli,
	op_b_slli,
	op_b_rori,
	op_a_add,
	op_a_sub,
	op_f_mul,
	op_f_aff,
	op_f_sqr,
	op_cmov, // NEW
    op_cmpeq,
    op_cmpgt,
	prng_update,
	rs1_s0,
	rs1_s1,
	rs2_s0,
	rs2_s1,
    rs3_s0           , // RS3 Share 0 NEW
	rs3_s1           , // RS3 Share 1 NEW
	ready,
	rd_s0,
	rd_s1,
	z0,
	z1,
	z2,
	z3,
	z4,
	z5
);
	input wire g_clk;
	input wire g_resetn;
	input wire valid;
	input wire flush;
	input wire op_b2a;
	input wire op_a2b;
	input wire op_b_mask;
	input wire op_b_remask;
	input wire op_a_mask;
	input wire op_a_remask;
	input wire op_b_not;
	input wire op_b_and;
	input wire op_b_ior;
	input wire op_b_xor;
	input wire op_b_add;
	input wire op_b_sub;
	input wire op_b_srli;
	input wire op_b_slli;
	input wire op_b_rori;
	input wire op_a_add;
	input wire op_a_sub;
	input wire op_f_mul;
	input wire op_f_aff;
	input wire op_f_sqr;
	input wire op_cmov; // NEW
	input wire op_cmpeq;
	input wire op_cmpgt;
	input wire prng_update;
	localparam integer XLEN = 32;
	localparam integer XL = XLEN - 1;
	input wire [XL:0] rs1_s0;
	input wire [XL:0] rs1_s1;
	input wire [XL:0] rs2_s0;
	input wire [XL:0] rs2_s1;
	input  wire [XL:0] rs3_s0           ; // RS3 Share 0 NEW
	input  wire [XL:0] rs3_s1           ; // RS3 Share 1 NEW
	output wire ready;
	output wire [XL:0] rd_s0;
	output wire [XL:0] rd_s1;
	input wire [XL:0] z0;
	input wire [XL:0] z1;
	input wire [XL:0] z2;
	input wire [XL:0] z3;
	input wire [XL:0] z4;
	input wire [XL:0] z5;
	
	wire s_op_b2a;
	wire s_op_a2b;
	wire s_op_b_mask;
	wire s_op_b_remask;
	wire s_op_a_mask;
	wire s_op_a_remask;
	wire s_op_b_not;
	wire s_op_b_and;
	wire s_op_b_ior;
	wire s_op_b_xor;
	wire s_op_b_add;
	wire s_op_b_sub;
	wire s_op_b_srli;
	wire s_op_b_slli;
	wire s_op_b_rori;
	wire s_op_a_add;
	wire s_op_a_sub;
	wire s_op_f_mul;
	wire s_op_f_aff;
	wire s_op_f_sqr;
	assign s_op_b2a = op_b2a;
	assign s_op_a2b = op_a2b;
	assign s_op_b_mask = op_b_mask;
	assign s_op_b_remask = op_b_remask;
	assign s_op_a_mask = op_a_mask;
	assign s_op_a_remask = op_a_remask;
	assign s_op_b_not = op_b_not;
	assign s_op_b_and = op_b_and;
	assign s_op_b_ior = op_b_ior;
	assign s_op_b_xor = op_b_xor;
	assign s_op_b_add = op_b_add;
	assign s_op_b_sub = op_b_sub | op_cmpgt;
	assign s_op_b_srli = op_b_srli;
	assign s_op_b_slli = op_b_slli;
	assign s_op_b_rori = op_b_rori;
	assign s_op_a_add = op_a_add;
	assign s_op_a_sub = op_a_sub;
	assign s_op_f_mul = op_f_mul;
	assign s_op_f_aff = op_f_aff;
	assign s_op_f_sqr = op_f_sqr;
	/*
	wire [XL:0] z0;
	wire [XL:0] z1;
	wire [XL:0] z2;
	wire [XL:0] z3;
	wire [XL:0] z4;
	wire [XL:0] z5;
	*/
	
	wire [XL:0] madd0;
	wire [XL:0] madd1;	    
	wire [XL:0] mcmov0, mcmov1;
wire        cmov_rdy;
wire mcmov_ena = !flush && valid && op_cmov;
frv_masked_cmov mskcmov_ins (
.g_clk      (g_clk      ), 
.ena        (mcmov_ena), 
.remask0  (z0      ), 
.remask1  (z1      ), 
.remask2  (z2      ), 
.resetn(g_resetn),
.old0 (rs3_s0 & {32{mcmov_ena}}),
.old1 (rs3_s1 & {32{mcmov_ena}}),
.cond0 (op_b0 & {32{mcmov_ena}}),
.cond1 (op_b1 & {32{mcmov_ena}}),
.new0 (op_a0 & {32{mcmov_ena}}),
.new1 (op_a1 & {32{mcmov_ena}}),
.o_r0 (mcmov0),
.o_r1 (mcmov1),
.rdy(cmov_rdy)
);
	wire [XL:0] b2a_a0;
	wire [XL:0] b2a_b0;
	wire [XL:0] b2a_b1;
	parameter [0:0] MASKING_ISE_TRNG = 1'b0;
	parameter [0:0] MASKING_ISE_DOM = 1'b1;
	parameter [0:0] ENABLE_FAFF = 0;
	parameter [0:0] ENABLE_FMUL = 0;
	parameter [0:0] ENABLE_BARITH = 1;
	parameter [0:0] ENABLE_ARITH = 0;
	wire [XL:0] prng0;
	wire [XL:0] n_prng0;
	wire [XL:0] prng1;
	wire [XL:0] n_prng1;
	wire [XL:0] prng2;
	wire [XL:0] n_prng2;
/*
wire [575:0] kecout;
	keccak kec(
	   .CLK(g_clk),
	   .RESET(~g_resetn),
	   .ENABLE(1'b1),
	   .M(576'hDEADC0DE),
	   .PRNG_OUT(kecout)
	);
	assign z0 = kecout[31:0];
	assign z1 = kecout[63:32];
	assign z2 = kecout[95:64];
	assign z3 = kecout[127:96];
	assign z4 = kecout[159:128];
	assign z5 = kecout[191:160];
*/
	wire nrs2_opt = s_op_b_ior || s_op_b_sub; //|| op_cmpgt;
	wire [XL:0] op_a0;
	wire [XL:0] op_a1;
	wire [XL:0] op_b0;
	wire [XL:0] op_b1;
	assign op_a0 = rs1_s0;
	assign op_a1 = (s_op_b_ior ? ~rs1_s1 : (s_op_b2a ? rs1_s1 : (s_op_a2b ? {XLEN {1'b0}} : rs1_s1)));
	assign op_b0 = ({XLEN {s_op_b2a}} & b2a_b0) | ({XLEN {!(s_op_b2a || s_op_a2b)}} & rs2_s0);
	assign op_b1 = (nrs2_opt ? ~rs2_s1 : (s_op_b2a ? b2a_b1 : (s_op_a2b ? ~rs1_s1 : rs2_s1)));
	

wire [XL:0] mcmp0, mcmp1;
wire mcmp_ena = !flush && valid && op_cmpeq;

wire mcmp_rdy;
wire cmp_rdy = valid & mcmp_rdy;
frv_masked_cmp mskcmp_ins (
.g_clk(g_clk), 
.ena(mcmp_ena),
.flush(flush), 
.resetn(g_resetn),
.remask0(z1),
.remask1(z2),
.remask2(z3),

.a0(op_a0 & {32{mcmp_ena}}),
.a1(op_a1 & {32{mcmp_ena}}),
.b0(op_b0 & {32{mcmp_ena}}),
.b1(op_b1 & {32{mcmp_ena}}),

.o_r0(mcmp0),
.o_r1(mcmp1),

.o_rdy(mcmp_rdy)
);

	wire [XL:0] mxor0;
	wire [XL:0] mxor1;
	wire [XL:0] mand0;
	wire [XL:0] mand1;
	wire [XL:0] mior0;
	wire [XL:0] mior1;
	wire [XL:0] mnot0;
	wire [XL:0] mnot1;
	wire dologic = !flush && (((s_op_b_xor || s_op_b_and) || s_op_b_ior) || s_op_b_not);
	wire op_b_addsub = !flush && ((((s_op_b_add || s_op_b_sub) || s_op_b2a) || s_op_a2b));// || op_cmpgt);
	reg ctrl_do_arith;
	wire mlogic_ena = (valid && (dologic || op_b_addsub)) && !ctrl_do_arith;
	wire mlogic_rdy;
	secure_frv_masked_bitwise #(.MASKING_ISE_DOM(MASKING_ISE_DOM)) msklogic_ins(
		.g_resetn(g_resetn),
		.g_clk(g_clk),
		.ena(mlogic_ena),
		.i_remask0(z0),
		.i_remask1(z1),
		.i_remask2(z4),
		.i_remask3(z5),
		.i_a0(op_a0 & {32{mlogic_ena}}),
		.i_a1(op_a1 & {32{mlogic_ena}}),
		.i_b0(op_b0 & {32{mlogic_ena}}),
		.i_b1(op_b1 & {32{mlogic_ena}}),
		.o_xor0(mxor0),
		.o_xor1(mxor1),
		.o_and0(mand0),
		.o_and1(mand1),
		.o_ior0(mior0),
		.o_ior1(mior1),
		.o_not0(mnot0),
		.o_not1(mnot1),
		.rdy(mlogic_rdy)
	);
	assign b2a_a0 = rs1_s0;
	wire [XL:0] b2a_b1_lat;
	wire b2a_ini = s_op_b2a && mlogic_ena;
	FF_Nb #(.Nb(XLEN)) ff_b2a_b0(
		.g_resetn(g_resetn),
		.g_clk(g_clk),
		.ena(b2a_ini),
		.din(b2a_b1),
		.dout(b2a_b1_lat)
	);
	wire [XL:0] b2a_gs = z2 ^ z3;
	assign b2a_b1 = (mlogic_ena ? b2a_gs : b2a_b1_lat) & s_op_b2a;
	assign b2a_b0 = {XLEN {1'b0}};
	wire op_b2a_latched;
	FF_Nb ff_dob2a(
		.g_resetn(g_resetn),
		.g_clk(g_clk),
		.ena(valid),
		.din(s_op_b2a),
		.dout(op_b2a_latched)
	);
	wire [XL:0] madd0_gated = (op_b2a_latched ? madd0 : {XLEN {1'b0}});
	wire [XL:0] madd1_gated = (op_b2a_latched ? madd1 : {XLEN {1'b0}});
	wire [XL:0] madd0_gated_sync;
	wire [XL:0] madd1_gated_sync;
	wire madd_rdy;
	register_with_sync_reset #(.BITWIDTH(XLEN)) reg_mb2a0_out_v2(
		.clk(g_clk),
		.rst(!(s_op_b2a & madd_rdy)),
		.d(madd0_gated),
		.q(madd0_gated_sync)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) reg_mb2a1_out_v2(
		.clk(g_clk),
		.rst(!(s_op_b2a & madd_rdy)),
		.d(madd1_gated),
		.q(madd1_gated_sync)
	);
	wire [XL:0] mb2a0 = madd0_gated_sync ^ madd1_gated_sync;
	wire [XL:0] mb2a1 = b2a_b0 ^ b2a_b1;
	wire addsub_ena;
	wire sub = s_op_b_sub || s_op_a2b;//|| op_cmpgt;
	wire u_0 = mand0[0] ^ (mxor0[0] && sub);
	wire u_1 = mand1[0] ^ (mxor1[0] && sub);
	wire [XL:0] s_mand0 = {mand0[XL:1], u_0};
	wire [XL:0] s_mand1 = {mand1[XL:1], u_1};
	reg [2:0] ctrl_do_addsub;
	wire ctrl_do_addsub_o;
	always @(posedge g_clk)
		if (!g_resetn || (valid && madd_rdy))
			ctrl_do_addsub <= 3'b001;
		else if ((addsub_ena && (op_b_addsub && !s_op_b2a)) && (ctrl_do_addsub[2] != 1))
			ctrl_do_addsub <= ctrl_do_addsub << 1;
		else if ((addsub_ena && ((op_b_addsub && s_op_b2a) && mlogic_rdy)) && (ctrl_do_addsub[2] != 1))
			ctrl_do_addsub <= ctrl_do_addsub << 1;
	assign ctrl_do_addsub_o = ( (s_op_b_add || s_op_b_sub/* || op_cmpgt*/) ? ctrl_do_addsub[2] : |ctrl_do_addsub[2:1]);
	generate
		if (ENABLE_BARITH) begin : gen_masked_barith_enabled
			secure_frv_masked_barith #(.MASKING_ISE_DOM(MASKING_ISE_DOM)) mskaddsub_ins(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.flush(flush),
				.ena(ctrl_do_addsub_o),
				.sub(sub),
				.cmpgt(op_cmpgt),
				.i_gs0(z2),
				.i_gs1(z3),
				.mxor0(mxor0),
				.mxor1(mxor1),
				.mand0(s_mand0),
				.mand1(s_mand1),
				.o_s0(madd0),
				.o_s1(madd1),
				.rdy(madd_rdy)
			);
		end
		else begin : gen_masked_barith_disabled
			assign madd0 = 32'b00000000000000000000000000000000;
			assign madd1 = 32'b00000000000000000000000000000000;
			assign madd_rdy = addsub_ena;
		end
	endgenerate
  
	wire op_shr;
	wire shr_rdy;
	wire [4:0] shamt;
	wire [XL:0] mshr0;
	wire [XL:0] mshr1;
	assign shamt = rs2_s0[4:0];
	assign op_shr = (s_op_b_srli || s_op_b_slli) || s_op_b_rori;
	wrapper_frv_masked_shfrot shfrpt_ins(
		.clk(g_clk),
		.srli(s_op_b_srli),
		.slli(s_op_b_slli),
		.rori(s_op_b_rori),
		.ena(op_shr),
		.shamt(shamt),
		.s0(rs1_s0),
		.s1(rs1_s1),
		.rp0(z0),
		.r0(mshr0),
		.r1(mshr1),
		.ready(shr_rdy)
	);
	parameter integer SECURE_MASKING_OPERATION = 2;
	wire opmask = !flush && s_op_b_mask;
	wire remask = !flush && s_op_b_remask;
	wire op_msk = opmask || remask;
	wire [XL:0] rmask0;
	wire [XL:0] rmask1;
	wire msk_rdy;
	generate
		if (SECURE_MASKING_OPERATION == 0) begin : gen_reference_masking_operation
			assign rmask0 = z0 ^ rs1_s0;
			assign rmask1 = z0 ^ ({XLEN {remask}} & rs1_s1);
			assign msk_rdy = valid & op_msk;
		end
		else if (SECURE_MASKING_OPERATION == 1) begin : gen_new_randomness_masking
			assign rmask0 = z5 ^ rs1_s0;
			assign rmask1 = z5 ^ ({XLEN {remask}} & rs1_s1);
			assign msk_rdy = valid & op_msk;
		end
		else if (SECURE_MASKING_OPERATION == 2) begin : gen_new_rand_and_reg_mask
			wire [XL:0] remask0_in;
			wire [XL:0] remask1_in;
			assign remask0_in = z5 ^ rs1_s0;
			assign remask1_in = z5 ^ ({XLEN {remask}} & rs1_s1);
			register_with_sync_reset #(.BITWIDTH(XLEN)) delay_remask0(
				.clk(g_clk),
				.rst(!((s_op_b_mask | s_op_b_remask) & (valid & op_msk))),
				.d(remask0_in),
				.q(rmask0)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) delay_remask1(
				.clk(g_clk),
				.rst(!((s_op_b_mask | s_op_b_remask) & (valid & op_msk))),
				.d(remask1_in),
				.q(rmask1)
			);
			reg [1:0] ctr_msk_ready;
			always @(posedge g_clk)
				if (msk_rdy)
					ctr_msk_ready = 2'b01;
				else if (valid & op_msk)
					ctr_msk_ready = ctr_msk_ready << 1;
				else
					ctr_msk_ready = 2'b01;
			assign msk_rdy = ctr_msk_ready[1];
		end
	endgenerate
	wire [XL:0] amsk0;
	wire [XL:0] amsk1;
	wire op_amsk;
	wire amsk_rdy;
	generate
		if (ENABLE_ARITH == 1) begin : gen_masked_arith_enabled
			frv_masked_arith arithmask_ins(
				.i_a0(rs1_s0),
				.i_a1(rs1_s1),
				.i_b0(rs2_s0),
				.i_b1(rs2_s1),
				.i_gs(z0),
				.mask(op_a_mask),
				.remask(op_a_remask),
				.doadd(op_a_add),
				.dosub(op_a_sub),
				.o_r0(amsk0),
				.o_r1(amsk1)
			);
			assign op_amsk = ((s_op_a_mask || s_op_a_remask) || op_a_add) || op_a_sub;
			assign amsk_rdy = valid & op_amsk;
		end
		else begin : gen_masked_arith_disabled
			assign amsk0 = {XLEN {1'b0}};
			assign amsk1 = {XLEN {1'b0}};
			assign op_amsk = 1'b0;
			assign amsk_rdy = 1'b0;
		end
	endgenerate
	wire [XL:0] mfaff0;
	wire [XL:0] mfaff1;
	wire [XL:0] mfmul0;
	wire [XL:0] mfmul1;
	generate
		if (ENABLE_FAFF) begin : gen_FAFF_ENABLED
			frv_masked_faff makfaff_ins(
				.i_a0(rs1_s0),
				.i_a1(rs1_s1),
				.i_mt({rs2_s1, rs2_s0}),
				.i_gs(z0),
				.o_r0(mfaff0),
				.o_r1(mfaff1)
			);
		end
		else begin : gen_FAFF_DISABLED
			assign mfaff0 = 32'b00000000000000000000000000000000;
			assign mfaff1 = 32'b00000000000000000000000000000000;
		end
		if (ENABLE_FMUL) begin : gen_FMUL_ENABLED
			wire mskfmul_ena = op_f_mul || op_f_sqr;
			frv_masked_fmul #(.MASKING_ISE_DOM(MASKING_ISE_DOM)) mskfmul_ins(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(mskfmul_ena),
				.i_a0(rs1_s0),
				.i_a1(rs1_s1),
				.i_b0(rs2_s0),
				.i_b1(rs2_s1),
				.i_sqr(op_f_sqr),
				.i_gs(z0),
				.o_r0(mfmul0),
				.o_r1(mfmul1)
			);
		end
		else begin : gen_FMUL_DISABLED
			assign mfmul0 = 32'b00000000000000000000000000000000;
			assign mfmul1 = 32'b00000000000000000000000000000000;
		end
	endgenerate
	wire mskfield_rdy = valid && ((op_f_mul || op_f_aff) || op_f_sqr);
	assign addsub_ena = valid && op_b_addsub;
	always @(posedge g_clk)
		if (!g_resetn || (valid && ready))
			ctrl_do_arith <= 1'b0;
		else if (valid)
			ctrl_do_arith <= dologic || op_b_addsub;
	wire [XL:0] mnot0_muted;
	wire [XL:0] mxor0_muted;
	wire [XL:0] mand0_muted;
	wire [XL:0] mior0_muted;
	wire [XL:0] madd0_muted;
	wire [XL:0] mnot1_muted;
	wire [XL:0] mxor1_muted;
	wire [XL:0] mand1_muted;
	wire [XL:0] mior1_muted;
	wire [XL:0] madd1_muted;
	
	wire [XL:0] mcmov0_muted;
	wire [XL:0] mcmov1_muted;
	
	wire [XL:0] mcmpeq0_muted;
	wire [XL:0] mcmpeq1_muted;
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_cmov0(
		.clk(g_clk),
		.rst(!(op_cmov & cmov_rdy)),
		.d(mcmov0),
		.q(mcmov0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_cmov1(
		.clk(g_clk),
		.rst(!(op_cmov & cmov_rdy)),
		.d(mcmov1),
		.q(mcmov1_muted)
	);
	
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_cmpeq0(
		.clk(g_clk),
		.rst(!(op_cmpeq & mcmp_rdy)),
		.d(mcmp0),
		.q(mcmpeq0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_cmpeq1(
		.clk(g_clk),
		.rst(!(op_cmpeq & mcmp_rdy)),
		.d(mcmp1),
		.q(mcmpeq1_muted)
	);
	
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mnot0(
		.clk(g_clk),
		.rst(!(s_op_b_not & mlogic_rdy)),
		.d(mnot0),
		.q(mnot0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mnot1(
		.clk(g_clk),
		.rst(!(s_op_b_not & mlogic_rdy)),
		.d(mnot1),
		.q(mnot1_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mxor0(
		.clk(g_clk),
		.rst(!(s_op_b_xor & mlogic_rdy)),
		.d(mxor0),
		.q(mxor0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mxor1(
		.clk(g_clk),
		.rst(!(s_op_b_xor & mlogic_rdy)),
		.d(mxor1),
		.q(mxor1_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mand0(
		.clk(g_clk),
		.rst(!(s_op_b_and & mlogic_rdy)),
		.d(mand0),
		.q(mand0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mand1(
		.clk(g_clk),
		.rst(!(s_op_b_and & mlogic_rdy)),
		.d(mand1),
		.q(mand1_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mior0(
		.clk(g_clk),
		.rst(!(s_op_b_ior & mlogic_rdy)),
		.d(mior0),
		.q(mior0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mior1(
		.clk(g_clk),
		.rst(!(s_op_b_ior & mlogic_rdy)),
		.d(mior1),
		.q(mior1_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_madd0(
		.clk(g_clk),
		.rst(!((s_op_b_add | s_op_b_sub /*| op_cmpgt*/) & madd_rdy)),
		.d(madd0),
		.q(madd0_muted)
	);
	register_with_sync_reset #(.BITWIDTH(XLEN)) mute_madd1(
		.clk(g_clk),
		.rst(!((s_op_b_add | s_op_b_sub /*| op_cmpgt*/) & madd_rdy)),
		.d(madd1),
		.q(madd1_muted)
	);
	assign rd_s0 = ((((((mnot0_muted | mxor0_muted) | mand0_muted) | mior0_muted) | mshr0) | madd0_muted) | mb2a0) | rmask0 | mcmov0_muted | mcmpeq0_muted;
	assign rd_s1 = ((((((mnot1_muted | mxor1_muted) | mand1_muted) | mior1_muted) | mshr1) | madd1_muted) | mb2a1) | rmask1 | mcmov1_muted | mcmpeq1_muted;
	reg b2a_rdy;
	always @(posedge g_clk)
		if (madd_rdy)
			b2a_rdy <= 1'b1;
		else
			b2a_rdy <= 1'b0;
			
    wire cmov_rdy_delayed;
	register #(.N(1)) delay_cmov_rdy(
		.clk(g_clk),
		.d(cmov_rdy),
		.q(cmov_rdy_delayed)
	);
	
	wire cmpeq_rdy_delayed;
	register #(.N(1)) delay_cmpeq_rdy(
		.clk(g_clk),
		.d(mcmp_rdy),
		.q(cmpeq_rdy_delayed)
	);
	
	wire mlogic_rdy_delayed;
	register #(.N(1)) delay_logic_rdy(
		.clk(g_clk),
		.d(mlogic_rdy),
		.q(mlogic_rdy_delayed)
	);
	wire madd_rdy_delayed;
	register #(.N(1)) delay_madd_rdy(
		.clk(g_clk),
		.d(madd_rdy),
		.q(madd_rdy_delayed)
	);
	assign ready = (((((((dologic && mlogic_rdy_delayed) || ((s_op_b_add || s_op_b_sub /*|| op_cmpgt*/) && madd_rdy_delayed)) || (b2a_rdy && s_op_b2a)) || shr_rdy) || msk_rdy) || amsk_rdy) || mskfield_rdy) || (op_cmov && cmov_rdy_delayed) || (op_cmpeq &&cmpeq_rdy_delayed);
endmodule
module secure_frv_masked_barith (
	g_resetn,
	g_clk,
	flush,
	ena,
	sub,
	cmpgt,
	i_gs0,
	i_gs1,
	mxor0,
	mxor1,
	mand0,
	mand1,
	o_s0,
	o_s1,
	rdy
);
	input wire g_resetn;
	input wire g_clk;
	input wire flush;
	input wire ena;
	input wire sub;
	input wire cmpgt;
	input wire [31:0] i_gs0;
	input wire [31:0] i_gs1;
	input wire [31:0] mxor0;
	input wire [31:0] mxor1;
	input wire [31:0] mand0;
	input wire [31:0] mand1;
	output wire [31:0] o_s0;
	output wire [31:0] o_s1;
	output wire rdy;
	parameter [0:0] MASKING_ISE_DOM = 1'b1;
	parameter integer DELAY = 6;
	wire [31:0] p0;
	wire [31:0] p1;
	wire [31:0] g0;
	wire [31:0] g1;
	wire [31:0] p0_i;
	wire [31:0] p1_i;
	wire [31:0] g0_i;
	wire [31:0] g1_i;
	reg [DELAY - 1:0] seq_cnt = 6'b000000;
	reg toggel;
	always @(posedge g_clk)
		if (!g_resetn) begin
			toggel <= 0;
			seq_cnt <= 1;
		end
		else if (flush) begin
			toggel <= 0;
			seq_cnt <= 1;
		end
		else if (rdy) begin
			toggel <= 0;
			seq_cnt <= 1;
		end
		else if (ena) begin
			if (toggel)
				seq_cnt <= seq_cnt << 1;
			toggel <= ~toggel;
		end
		else
			seq_cnt <= 1;
	wire ini = ena && seq_cnt[0];
	assign p0_i = ({32 {ini}} & mxor0) | ({32 {!ini}} & p0);
	assign p1_i = ({32 {ini}} & mxor1) | ({32 {!ini}} & p1);
	assign g0_i = ({32 {ini}} & mand0) | ({32 {!ini}} & g0);
	assign g1_i = ({32 {ini}} & mand1) | ({32 {!ini}} & g1);
	frv_masked_barith_seq_process #(
		.MASKING_ISE_DOM(MASKING_ISE_DOM),
		.DELAY(DELAY)
	) seqproc_ins(
		.g_resetn(g_resetn),
		.g_clk(g_clk),
		.ena(ena),
		.i_gs0(i_gs0),
		.i_gs1(i_gs1),
		.toggel(toggel),
		.seq(seq_cnt),
		.i_pk0(p0_i),
		.i_pk1(p1_i),
		.i_gk0(g0_i),
		.i_gk1(g1_i),
		.o_pk0(p0),
		.o_pk1(p1),
		.o_gk0(g0),
		.o_gk1(g1)
	);
	wire [31:0] o_s0_gated = mxor0 ^ {g0[30:0], 1'b0};
	wire [31:0] o_s1_gated = mxor1 ^ {g1[30:0], sub};
  wire carry0 = mxor0[31] ^ g0[31];
  wire carry1 = mxor1[31] ^ g1[31];
  wire[31:0] o_carry0;
  wire[31:0] o_carry1;

  wire[31:0] o_carry0 = {31'b0 , carry0};
  wire[31:0] o_carry1 = {31'b0 , carry1};

	assign o_s0 = cmpgt ? o_carry0 : o_s0_gated;
	assign o_s1 = cmpgt ? o_carry1 : o_s1_gated;
	assign rdy = seq_cnt[DELAY - 1];
endmodule
module frv_masked_barith_seq_process (
	g_resetn,
	g_clk,
	ena,
	i_gs0,
	i_gs1,
	toggel,
	seq,
	i_pk0,
	i_pk1,
	i_gk0,
	i_gk1,
	o_pk0,
	o_pk1,
	o_gk0,
	o_gk1
);
	parameter [0:0] MASKING_ISE_DOM = 1'b0;
	parameter integer DELAY = 6;
	input wire g_resetn;
	input wire g_clk;
	input wire ena;
	input wire [31:0] i_gs0;
	input wire [31:0] i_gs1;
	input wire toggel;
	input wire [DELAY - 1:0] seq;
	input wire [31:0] i_pk0;
	input wire [31:0] i_pk1;
	input wire [31:0] i_gk0;
	input wire [31:0] i_gk1;
	output wire [31:0] o_pk0;
	output wire [31:0] o_pk1;
	output wire [31:0] o_gk0;
	output wire [31:0] o_gk1;
	reg [31:0] gkj0;
	reg [31:0] gkj1;
	reg [31:0] pkj0;
	reg [31:0] pkj1;
	always @(*) begin
		gkj0 = (((({32 {seq[0]}} & {i_gk0[30:0], 1'd0}) | ({32 {seq[1]}} & {i_gk0[29:0], 2'd0})) | ({32 {seq[2]}} & {i_gk0[27:0], 4'd0})) | ({32 {seq[3]}} & {i_gk0[23:0], 8'd0})) | ({32 {|seq[5:4]}} & {i_gk0[15:0], 16'd0});
		gkj1 = (((({32 {seq[0]}} & {i_gk1[30:0], 1'd0}) | ({32 {seq[1]}} & {i_gk1[29:0], 2'd0})) | ({32 {seq[2]}} & {i_gk1[27:0], 4'd0})) | ({32 {seq[3]}} & {i_gk1[23:0], 8'd0})) | ({32 {|seq[5:4]}} & {i_gk1[15:0], 16'd0});
		pkj0 = ((({32 {seq[0]}} & {i_pk0[30:0], 1'd0}) | ({32 {seq[1]}} & {i_pk0[29:0], 2'd0})) | ({32 {seq[2]}} & {i_pk0[27:0], 4'd0})) | ({32 {|seq[5:3]}} & {i_pk0[23:0], 8'd0});
		pkj1 = ((({32 {seq[0]}} & {i_pk1[30:0], 1'd0}) | ({32 {seq[1]}} & {i_pk1[29:0], 2'd0})) | ({32 {seq[2]}} & {i_pk1[27:0], 4'd0})) | ({32 {|seq[5:3]}} & {i_pk1[23:0], 8'd0});
	end
	localparam integer XLEN = 32;
	generate
		if (MASKING_ISE_DOM == 1'b1) begin : gen_sni_dom_indep
			wire ena_dom;
			wire ena_post_dom;
			assign ena_dom = (g_resetn & ena) & toggel;
			assign ena_post_dom = (g_resetn & ena) & !toggel;
			wire [31:0] i_tg0 = gkj0 & i_pk0;
			wire [31:0] i_tg1 = (i_gs0 ^ i_gk0) ^ (gkj0 & i_pk1);
			wire [31:0] i_tg2 = (i_gs0 ^ i_gk1) ^ (gkj1 & i_pk0);
			wire [31:0] i_tg3 = gkj1 & i_pk1;
			wire [31:0] tg0;
			wire [31:0] tg1;
			wire [31:0] tg2;
			wire [31:0] tg3;
			wire [31:0] tg0tg1;
			wire [31:0] tg2tg3;
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tg0(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tg0),
				.q(tg0)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tg1(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tg1),
				.q(tg1)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tg2(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tg2),
				.q(tg2)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tg3(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tg3),
				.q(tg3)
			);
			assign tg0tg1 = tg0 ^ tg1;
			assign tg2tg3 = tg2 ^ tg3;
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_o_gk0(
				.clk(g_clk),
				.rst(ena_post_dom),
				.d(tg0tg1),
				.q(o_gk0)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_o_gk1(
				.clk(g_clk),
				.rst(ena_post_dom),
				.d(tg2tg3),
				.q(o_gk1)
			);
			wire [31:0] i_tp0 = i_pk0 & pkj0;
			wire [31:0] i_tp1 = i_gs1 ^ (i_pk0 & pkj1);
			wire [31:0] i_tp2 = i_gs1 ^ (i_pk1 & pkj0);
			wire [31:0] i_tp3 = i_pk1 & pkj1;
			wire [31:0] tp0;
			wire [31:0] tp1;
			wire [31:0] tp2;
			wire [31:0] tp3;
			wire [31:0] tp0tp1;
			wire [31:0] tp2tp3;
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tp0(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tp0),
				.q(tp0)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tp1(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tp1),
				.q(tp1)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tp2(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tp2),
				.q(tp2)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_tp3(
				.clk(g_clk),
				.rst(ena_dom),
				.d(i_tp3),
				.q(tp3)
			);
			assign tp0tp1 = tp0 ^ tp1;
			assign tp2tp3 = tp2 ^ tp3;
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_o_pk0(
				.clk(g_clk),
				.rst(ena_post_dom),
				.d(tp0tp1),
				.q(o_pk0)
			);
			register_with_sync_reset #(.BITWIDTH(XLEN)) ff_o_pk1(
				.clk(g_clk),
				.rst(ena_post_dom),
				.d(tp2tp3),
				.q(o_pk1)
			);
		end
		else begin : gen_masking
			wire [31:0] pk0 = (i_gs1 ^ (i_pk0 & pkj1)) ^ (i_pk0 | ~pkj0);
			wire [31:0] pk1 = (i_gs1 ^ (i_pk1 & pkj1)) ^ (i_pk1 | ~pkj0);
			FF_Nb #(.Nb(32)) ff_pk0(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(pk0),
				.dout(o_pk0)
			);
			FF_Nb #(.Nb(32)) ff_pk1(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(pk1),
				.dout(o_pk1)
			);
			wire [31:0] gk0 = (i_gk0 ^ (gkj0 & i_pk1)) ^ (gkj0 | ~i_pk0);
			wire [31:0] gk1 = (i_gk1 ^ (gkj1 & i_pk1)) ^ (gkj1 | ~i_pk0);
			FF_Nb #(.Nb(32)) ff_gk0(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(gk0),
				.dout(o_gk0)
			);
			FF_Nb #(.Nb(32)) ff_gk1(
				.g_resetn(g_resetn),
				.g_clk(g_clk),
				.ena(ena),
				.din(gk1),
				.dout(o_gk1)
			);
		end
	endgenerate
endmodule
module frv_masked_and (
	g_clk,
	resetn,
	clk_en,
	z0,
	z1,
	z2,
	ax,
	ay,
	bx,
	by,
	qx,
	qy
);
	parameter integer BIT_WIDTH = 32;
	input wire g_clk;
	input wire resetn;
	input wire clk_en;
	input wire [BIT_WIDTH - 1:0] z0;
	input wire [BIT_WIDTH - 1:0] z1;
	input wire [BIT_WIDTH - 1:0] z2;
	input wire [BIT_WIDTH - 1:0] ax;
	input wire [BIT_WIDTH - 1:0] ay;
	input wire [BIT_WIDTH - 1:0] bx;
	input wire [BIT_WIDTH - 1:0] by;
	output wire [BIT_WIDTH - 1:0] qx;
	output wire [BIT_WIDTH - 1:0] qy;
	localparam integer D = 1;
	localparam integer N = D + 1;
	localparam integer L = ((D + 1) * D) / 2;
	wire clk = clk_en & g_clk;
	wire [(BIT_WIDTH * N) - 1:0] a;
	wire [(BIT_WIDTH * N) - 1:0] b;
	wire [(BIT_WIDTH * N) - 1:0] r1;
	wire [(BIT_WIDTH * L) - 1:0] r2;
	wire [(BIT_WIDTH * N) - 1:0] c;
	genvar _gv_i_6;
	generate
		for (_gv_i_6 = 0; _gv_i_6 < BIT_WIDTH; _gv_i_6 = _gv_i_6 + 1) begin : gen_port_mapping
			localparam i = _gv_i_6;
			assign a[((BIT_WIDTH - 1) - i) * N] = ax[i];
			assign a[(((BIT_WIDTH - 1) - i) * N) + 1] = bx[i];
			assign b[((BIT_WIDTH - 1) - i) * N] = ay[i];
			assign b[(((BIT_WIDTH - 1) - i) * N) + 1] = by[i];
			assign r1[((BIT_WIDTH - 1) - i) * N] = z0[i];
			assign r1[(((BIT_WIDTH - 1) - i) * N) + 1] = z1[i];
			assign r2[((BIT_WIDTH - 1) - i) * L] = z2[i];
			assign qx[i] = c[((BIT_WIDTH - 1) - i) * N];
			assign qy[i] = c[(((BIT_WIDTH - 1) - i) * N) + 1];
		end
	endgenerate
	dom_dep_multibit #(
		.D(D),
		.BIT_WIDTH(BIT_WIDTH)
	) dom_dep_multibit(
		.clk(clk),
		.rst(!resetn),
		.port_a(a),
		.port_b(b),
		.port_r1(r1),
		.port_r2(r2),
		.port_c(c)
	);
endmodule
module secure_frv_masked_bitwise (
	g_resetn,
	g_clk,
	ena,
	i_remask0,
	i_remask1,
	i_remask2,
	i_remask3,
	i_a0,
	i_a1,
	i_b0,
	i_b1,
	o_xor0,
	o_xor1,
	o_and0,
	o_and1,
	o_ior0,
	o_ior1,
	o_not0,
	o_not1,
	rdy
);
	parameter [0:0] MASKING_ISE_DOM = 1'b1;
	parameter integer INSECURE_XOR = 0;
	parameter integer BIT_WIDTH = 32;
	input wire g_resetn;
	input wire g_clk;
	input wire ena;
	input wire [BIT_WIDTH - 1:0] i_remask0;
	input wire [BIT_WIDTH - 1:0] i_remask1;
	input wire [BIT_WIDTH - 1:0] i_remask2;
	input wire [BIT_WIDTH - 1:0] i_remask3;
	input wire [BIT_WIDTH - 1:0] i_a0;
	input wire [BIT_WIDTH - 1:0] i_a1;
	input wire [BIT_WIDTH - 1:0] i_b0;
	input wire [BIT_WIDTH - 1:0] i_b1;
	output wire [BIT_WIDTH - 1:0] o_xor0;
	output wire [BIT_WIDTH - 1:0] o_xor1;
	output wire [BIT_WIDTH - 1:0] o_and0;
	output wire [BIT_WIDTH - 1:0] o_and1;
	output wire [BIT_WIDTH - 1:0] o_ior0;
	output wire [BIT_WIDTH - 1:0] o_ior1;
	output wire [BIT_WIDTH - 1:0] o_not0;
	output wire [BIT_WIDTH - 1:0] o_not1;
	output wire rdy;
	generate
		if (MASKING_ISE_DOM == 1'b1) begin : gen_masking_DOM
			frv_masked_and #(.BIT_WIDTH(BIT_WIDTH)) i_dom_and(
				.g_clk(g_clk),
				.resetn(g_resetn),
				.clk_en(ena),
				.z0(i_remask0),
				.z1(i_remask1),
				.z2(i_remask2),
				.ax(i_a0),
				.ay(i_b0),
				.bx(i_a1),
				.by(i_b1),
				.qx(o_and0),
				.qy(o_and1)
			);
		end
		else begin : gen_no_masking
			assign o_and0 = (i_remask0 ^ (i_a0 & i_b1)) ^ (i_a0 | ~i_b0);
			assign o_and1 = (i_remask0 ^ (i_a1 & i_b1)) ^ (i_a1 | ~i_b0);
		end
		if (INSECURE_XOR == 0) begin : gen_secure_non_leaking_version
			wire [BIT_WIDTH - 1:0] xor0;
			wire [BIT_WIDTH - 1:0] xor0_delayed;
			wire [BIT_WIDTH - 1:0] xor1;
			wire [BIT_WIDTH - 1:0] xor1_delayed;
			assign xor0 = (i_remask3 ^ i_a0) ^ i_b0;
			assign xor1 = (i_remask3 ^ i_a1) ^ i_b1;
			register_with_sync_reset #(.BITWIDTH(BIT_WIDTH)) delay_xor0(
				.clk(g_clk),
				.rst(!g_resetn),
				.d(xor0),
				.q(xor0_delayed)
			);
			register_with_sync_reset #(.BITWIDTH(BIT_WIDTH)) delay_xor1(
				.clk(g_clk),
				.rst(!g_resetn),
				.d(xor1),
				.q(xor1_delayed)
			);
			assign o_xor0 = xor0_delayed;
			assign o_xor1 = xor1_delayed;
		end
	endgenerate
	assign o_ior0 = o_and0;
	assign o_ior1 = ~o_and1;
	assign o_not0 = i_a0;
	assign o_not1 = ~i_a1;
	localparam integer PosEdg = 1;
	generate
		if (PosEdg == 1) begin : gen_ready_signal_for_only_positive_clocks
			reg [1:0] ctr_ready;
			always @(posedge g_clk)
				if (rdy)
					ctr_ready = 2'h1;
				else if (ena)
					ctr_ready = ctr_ready << 1;
				else
					ctr_ready = 2'h1;
			assign rdy = ctr_ready[1];
		end
		else begin : gen_ready_signal_for_double_pumped_clocks
			assign rdy = ena;
		end
	endgenerate
endmodule

module wrapper_frv_masked_shfrot (
	clk,
	srli,
	slli,
	rori,
	ena,
	shamt,
	s0,
	s1,
	rp0,
	r0,
	r1,
	ready
);
	parameter integer BIT_WIDTH = 32;
	input clk;
	input srli;
	input slli;
	input rori;
	input ena;
	input [4:0] shamt;
	input [BIT_WIDTH - 1:0] s0;
	input [BIT_WIDTH - 1:0] s1;
	input [BIT_WIDTH - 1:0] rp0;
	output wire [BIT_WIDTH - 1:0] r0;
	output wire [BIT_WIDTH - 1:0] r1;
	output wire ready;
	wire [BIT_WIDTH - 1:0] shfrot_s0_out;
	wire [BIT_WIDTH - 1:0] shfrot_s1_out;
	reg ctr_ready;
	initial ctr_ready = 0;
	always @(posedge clk)
		if (ready)
			ctr_ready <= 1'b0;
		else if (ena)
			ctr_ready <= 1'b1;
		else
			ctr_ready <= 1'b0;
	assign ready = ctr_ready;
	frv_masked_shfrot shfrot_s0(
		.shamt(shamt),
		.s(s0),
		.rp(rp0),
		.srli(srli),
		.slli(slli),
		.rori(rori),
		.r(shfrot_s0_out)
	);
	frv_masked_shfrot shfrot_s1(
		.shamt(shamt),
		.s(s1),
		.rp(rp0),
		.srli(srli),
		.slli(slli),
		.rori(rori),
		.r(shfrot_s1_out)
	);
	register_with_sync_reset #(.BITWIDTH(BIT_WIDTH)) sync_shift0(
		.clk(clk),
		.rst(!ena),
		.d(shfrot_s0_out),
		.q(r0)
	);
	register_with_sync_reset #(.BITWIDTH(BIT_WIDTH)) sync_shift1(
		.clk(clk),
		.rst(!ena),
		.d(shfrot_s1_out),
		.q(r1)
	);
endmodule