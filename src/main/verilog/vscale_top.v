`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_hasti_constants.vh"

module vscale_top(
                      input                        clk,
                      input                        reset,
                      input                        htif_pcr_req_valid,
                      output                       htif_pcr_req_ready,
                      input                        htif_pcr_req_rw,
                      input [`CSR_ADDR_WIDTH-1:0]  htif_pcr_req_addr,
                      input [`HTIF_PCR_WIDTH-1:0]  htif_pcr_req_data,
                      output                       htif_pcr_resp_valid,
                      input                        htif_pcr_resp_ready,
                      output [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data,
                      input [`CORE_IDX_WIDTH-1:0]  arbiter_next_core
                      );

   wire                                            resetn;

   wire [0:`NUM_CORES-1][`HASTI_ADDR_WIDTH-1:0]    imem_haddr ;
   wire [0:`NUM_CORES-1]                           imem_hwrite;
   wire [0:`NUM_CORES-1][`HASTI_SIZE_WIDTH-1:0]    imem_hsize ;
   wire [0:`NUM_CORES-1][`HASTI_BURST_WIDTH-1:0]   imem_hburst;
   wire [0:`NUM_CORES-1]                           imem_hmastlock;
   wire [0:`NUM_CORES-1][`HASTI_PROT_WIDTH-1:0]    imem_hprot ;
   wire [0:`NUM_CORES-1][`HASTI_TRANS_WIDTH-1:0]   imem_htrans;
   wire [0:`NUM_CORES-1][`HASTI_BUS_WIDTH-1:0]     imem_hwdata;
   wire [0:`NUM_CORES-1][`HASTI_BUS_WIDTH-1:0]     imem_hrdata;
   wire [0:`NUM_CORES-1]                           imem_hready;
   wire [0:`NUM_CORES-1][`HASTI_RESP_WIDTH-1:0]    imem_hresp ;

   //Signals between cores and arbiter
   wire [`HASTI_ADDR_WIDTH-1:0]                    dmem_haddr [0:`NUM_CORES-1];
   wire                                            dmem_hwrite [0:`NUM_CORES-1];
   wire [`HASTI_SIZE_WIDTH-1:0]                    dmem_hsize [0:`NUM_CORES-1];
   wire [`HASTI_BURST_WIDTH-1:0]                   dmem_hburst [0:`NUM_CORES-1];
   wire                                            dmem_hmastlock [0:`NUM_CORES-1];
   wire [`HASTI_PROT_WIDTH-1:0]                    dmem_hprot [0:`NUM_CORES-1];
   wire [`HASTI_TRANS_WIDTH-1:0]                   dmem_htrans [0:`NUM_CORES-1];
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hwdata [0:`NUM_CORES-1];
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hrdata [0:`NUM_CORES-1];
   wire                                            dmem_hready [0:`NUM_CORES-1];
   wire [`HASTI_RESP_WIDTH-1:0]                    dmem_hresp [0:`NUM_CORES-1];

   //Signals between arbiter and memory
   wire [`HASTI_ADDR_WIDTH-1:0]                    arbiter_dmem_haddr;
   wire                                            arbiter_dmem_hwrite;
   wire [`HASTI_SIZE_WIDTH-1:0]                    arbiter_dmem_hsize;
   wire [`HASTI_BURST_WIDTH-1:0]                   arbiter_dmem_hburst;
   wire                                            arbiter_dmem_hmastlock;
   wire [`HASTI_PROT_WIDTH-1:0]                    arbiter_dmem_hprot;
   wire [`HASTI_TRANS_WIDTH-1:0]                   arbiter_dmem_htrans;
   wire [`HASTI_BUS_WIDTH-1:0]                     arbiter_dmem_hwdata;
   wire [`HASTI_BUS_WIDTH-1:0]                     arbiter_dmem_hrdata;
   wire                                            arbiter_dmem_hready;
   wire [`HASTI_RESP_WIDTH-1:0]                    arbiter_dmem_hresp;

   wire                                            htif_reset;

   wire                                            htif_ipi_req_ready = 0;
   wire                                            htif_ipi_req_valid;
   wire                                            htif_ipi_req_data;
   wire                                            htif_ipi_resp_ready;
   wire                                            htif_ipi_resp_valid = 0;
   wire                                            htif_ipi_resp_data = 0;
   wire                                            htif_debug_stats_pcr;
   
   assign resetn = ~reset;
   assign htif_reset = reset;

   genvar i;
   generate
   for (i = 0; i < `NUM_CORES ; i++) begin : core_gen_block
       vscale_core vscale(
                          .clk(clk),
                          .core_id(i),
                          .imem_haddr(imem_haddr[i]),
                          .imem_hwrite(imem_hwrite[i]),
                          .imem_hsize(imem_hsize[i]),
                          .imem_hburst(imem_hburst[i]),
                          .imem_hmastlock(imem_hmastlock[i]),
                          .imem_hprot(imem_hprot[i]),
                          .imem_htrans(imem_htrans[i]),
                          .imem_hwdata(imem_hwdata[i]),
                          .imem_hrdata(imem_hrdata[i]),
                          .imem_hready(imem_hready[i]),
                          .imem_hresp(imem_hresp[i]),
                          .dmem_haddr(dmem_haddr[i]),
                          .dmem_hwrite(dmem_hwrite[i]),
                          .dmem_hsize(dmem_hsize[i]),
                          .dmem_hburst(dmem_hburst[i]),
                          .dmem_hmastlock(dmem_hmastlock[i]),
                          .dmem_hprot(dmem_hprot[i]),
                          .dmem_htrans(dmem_htrans[i]),
                          .dmem_hwdata(dmem_hwdata[i]),
                          .dmem_hrdata(dmem_hrdata[i]),
                          .dmem_hready(dmem_hready[i]),
                          .dmem_hresp(dmem_hresp[i]),
                          .htif_reset(htif_reset),
                          .htif_id(1'b0),
                          .htif_pcr_req_valid(htif_pcr_req_valid),
                          .htif_pcr_req_ready(htif_pcr_req_ready),
                          .htif_pcr_req_rw(htif_pcr_req_rw),
                          .htif_pcr_req_addr(htif_pcr_req_addr),
                          .htif_pcr_req_data(htif_pcr_req_data),
                          .htif_pcr_resp_valid(htif_pcr_resp_valid),
                          .htif_pcr_resp_ready(htif_pcr_resp_ready),
                          .htif_pcr_resp_data(htif_pcr_resp_data),
                          .htif_ipi_req_ready(htif_ipi_req_ready),
                          .htif_ipi_req_valid(htif_ipi_req_valid),
                          .htif_ipi_req_data(htif_ipi_req_data),
                          .htif_ipi_resp_ready(htif_ipi_resp_ready),
                          .htif_ipi_resp_valid(htif_ipi_resp_valid),
                          .htif_ipi_resp_data(htif_ipi_resp_data),
                          .htif_debug_stats_pcr(htif_debug_stats_pcr)
                          );
       end
   endgenerate

   vscale_arbiter arbiter(
                          .clk(clk),
                          .reset(reset),
                          .core_haddr(dmem_haddr),
                          .core_hwrite(dmem_hwrite),
                          .core_hsize(dmem_hsize),
                          .core_hburst(dmem_hburst),
                          .core_hmastlock(dmem_hmastlock),
                          .core_hprot(dmem_hprot),
                          .core_htrans(dmem_htrans),
                          .core_hwdata(dmem_hwdata),
                          .core_hrdata(dmem_hrdata),
                          .core_hready(dmem_hready),
                          .core_hresp(dmem_hresp),
                          .dmem_haddr(arbiter_dmem_haddr),
                          .dmem_hwrite(arbiter_dmem_hwrite),
                          .dmem_hsize(arbiter_dmem_hsize),
                          .dmem_hburst(arbiter_dmem_hburst),
                          .dmem_hmastlock(arbiter_dmem_hmastlock),
                          .dmem_hprot(arbiter_dmem_hprot),
                          .dmem_htrans(arbiter_dmem_htrans),
                          .dmem_hwdata(arbiter_dmem_hwdata),
                          .dmem_hrdata(arbiter_dmem_hrdata),
                          .dmem_hready(arbiter_dmem_hready),
                          .dmem_hresp(arbiter_dmem_hresp),
                          .next_core(arbiter_next_core)
       );

   vscale_dp_hasti_sram hasti_mem(
                                  .hclk(clk),
                                  .hresetn(resetn),
                                  .p1_haddr(imem_haddr),
                                  .p1_hwrite(imem_hwrite),
                                  .p1_hsize(imem_hsize),
                                  .p1_hburst(imem_hburst),
                                  .p1_hmastlock(imem_hmastlock),
                                  .p1_hprot(imem_hprot),
                                  .p1_htrans(imem_htrans),
                                  .p1_hwdata(imem_hwdata),
                                  .p1_hrdata(imem_hrdata),
                                  .p1_hready(imem_hready),
                                  .p1_hresp(imem_hresp),
                                  .p0_haddr(arbiter_dmem_haddr),
                                  .p0_hwrite(arbiter_dmem_hwrite),
                                  .p0_hsize(arbiter_dmem_hsize),
                                  .p0_hburst(arbiter_dmem_hburst),
                                  .p0_hmastlock(arbiter_dmem_hmastlock),
                                  .p0_hprot(arbiter_dmem_hprot),
                                  .p0_htrans(arbiter_dmem_htrans),
                                  .p0_hwdata(arbiter_dmem_hwdata),
                                  .p0_hrdata(arbiter_dmem_hrdata),
                                  .p0_hready(arbiter_dmem_hready),
                                  .p0_hresp(arbiter_dmem_hresp)
                                  );

endmodule // vscale_sim_top
