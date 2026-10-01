set tech_file ../../../router_pnr_flow/ref/tech/saed32nm_1p9m.tf
set synthetic_library dw_foundation.sldb

set mw_ref_libs ../../../router_pnr_flow/synthysis_DC/libs/mw_libs/saed32_io_fc
set mw_ref_libs ../../../router_pnr_flow/synthysis_DC/libs/mw_libs/saed32nm_lvt_1p9m

set my_mw_lib riscv_mw_lib.mw

create_mw_lib $my_mw_lib -technology $tech_file -mw_reference_library $mw_ref_libs -open

set target_library "../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \ 
		../../../router_pnr_flow/ref/DBs/saed32rvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32hvt_ss0p75v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32sramlp_ff0p95v125c_i0p95v.db"


set link_library "../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \ 
		../../../router_pnr_flow/ref/DBs/saed32rvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32hvt_ss0p75v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32sramlp_ff0p95v125c_i0p95v.db"

set ref_libs  "../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32lvt_ss0p95v125c.db \ 
		../../../router_pnr_flow/ref/DBs/saed32rvt_ss0p95v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32hvt_ss0p75v125c.db \
		../../../router_pnr_flow/ref/DBs/saed32sramlp_ff0p95v125c_i0p95v.db"
    
set_tlu_plus_files \
		-max_tluplus ../../../router_pnr_flow/ref/tech/saed32nm_1p9m_Cmax.lv.tluplus \
		 -min_tluplus ../../../router_pnr_flow/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus \
		-tech2itf_map ../../../router_pnr_flow/ref/tech/saed32nm_tf_itf_tluplus.map

#========================
# create RTL and read
#========================
analyze -format verilog [glob ../../../router_pnr_flow/routericc2flow/rtl/*.v]
elaborate msrv32_top
current_design msrv32_top

source -echo ../../../router_pnr_flow/synthysis_DC/constraints/floorplan_constraints.pcon 
read_sdc ../../../router_pnr_flow/synthysis_DC/constraints/constraints_file.sdc

set_svf RISC_V.svf
compile_ultra -no_autoungroup -no_boundary_optimization -gate_clock -self_gating -exact_map

write -hierarchy -format ddc -output ../output/riscv.ddc 
report_area > ../output/riscv.rpt
report_hierarchy > ../output/riscv.rpt
report_design > ../output/riscv.rpt
report_timing -path full > ../output/riscv.rpt
write -hierarchy -format verilog -output ../output/riscv.v
write_sdf  ../output/riscv.sdf
write_parasitics -output ../output/riscv_parastics_8_6
write_sdc ../output/riscv.sdc 
write -format ddc -h -o ../output/riscv.ddc 

# VLSI-Physical-Design-Portfolio
"RTL-to-GDSII physical implementation scripts, low-power UPF scripts, and design architectures for RISC-V SoCs."
