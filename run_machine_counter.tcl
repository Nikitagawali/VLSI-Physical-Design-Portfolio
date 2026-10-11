#===================================
#LIB_FILES
#================================

set tech_file ../../../router_pnr_flow/ref/tech/saed32nm_1p9m.tf

set ref_lib "../../../router_pnr_flow/ref/CLIBs/saed32_1p9m_tech.ndm/ ../../../router_pnr_flow/ref/CLIBs/saed32_hvt.ndm/ ../../../router_pnr_flow/ref/CLIBs/saed32_lvt.ndm/ ../../../router_pnr_flow/ref/CLIBs/saed32_rvt.ndm/ ../../../router_pnr_flow/ref/CLIBs/saed32_sram_lp.ndm"

create_lib -technology $tech_file -ref_libs $ref_lib machine_counter.dlib

#===================================
# Read netlist and SDC
#===================================

read_verilog ../../synthesis/output/machine_counter.v

#read_sdc ../../synthesis/output/riscv.sdc

#===================================
#read parasitics
#===================================

read_parasitic_tech -layermap ../../../router_pnr_flow/ref/tech/saed32nm_tf_itf_tluplus.map -tlup ../../../router_pnr_flow/ref/tech/saed32nm_1p9m_Cmax.lv.nxtgrd -name maxTLU
read_parasitic_tech -layermap ../../../router_pnr_flow/ref/tech/saed32nm_tf_itf_tluplus.map -tlup ../../../router_pnr_flow/ref/tech/saed32nm_1p9m_Cmin.lv.nxtgrd -name minTLU

#===================================
#MCMM
#==================================

source -echo ../design_data/mcmm_alu.tcl

remove_scenarios -all
remove_modes -all
remove_corners -all
current_corner default
set_parasitic_parameters -early_spec minTLU -late_spec minTLU
set_process_number 0.99 -corners default

set_process_label slow -corners default
set_temperature 125 -corners default
set_voltage 0.95 -corners default

set_scenario_status -active true -dynamic_power true [get_scenarios func.ss_m40c]

#===================================
# UPF
#===================================

source -echo ../../PnR/design_data/router.upf 
commit_upf 
check_mv_design

#==================================
# SANITY CHECKS
#==================================

check_netlist
check_timing
report_design_mismatch -verbose
save_block -as upf_done_machine

#===================================
# routing layer
#===================================

get_site_defs
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

set_attribute [get_layers {M2 M4 M6 M8}] routing_direction horizontal
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction vertical

get_attribute [get_layers M?] routing_direction
report_ignored_layers

set_ignored_layers -max_routing_layer M8
report_ignored_layers

#=======================================
# fllorplanning
#=======================================
initialize_floorplan -core_offset {10}

shape_blocks

set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6}
place_pins -self

get_lib_cells *CAP*

create_boundary_cells -right_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT \
		-left_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT \
		 -top_boundary_cells saed32_hvt|saed32_hvt_std/DCAP_HVT \
		 -bottom_boundary_cells saed32_hvt|saed32_hvt_std/DCAP_HVT
check_legality

save_block -as floorplan_done_machine

#===================================
# creating TIE cells
#====================================

#find available tie-cells
get_lib_cells -filter "function_id == a0.0"
get_lib_cells -filter "function_id == Ia0.0"

#making tie cells available for synthesis
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

report_lib -parasitic_tech machine_counter.dlib

#====================================
#powerplann
#====================================

source -echo ../scripts/pns.tcl 

save_block -as pns_done_machine

#===================================
#placement
#===================================
#create_placement -timing_driven
#legalize_placement
#place_opt

magnet_placement [get_ports ms_riscv32_mp_clk_in]
create_placement -congestion

refine_placement

legalize_placement

current_scenario
set_scenario_status {func.ss_m40c} -dynamic_power true
report_power

#=================================
#cts
#=================================
#check congestion,pin density,cell density

source -echo ../scripts/ndr.tcl

report_routing_rules -verbose
report_clock_routing_rules
report_timing
check_pg_drc

set CTS_CELLS [get_lib_cells "*/NBUFF*LVT */NBUFF*RVT */INVX*_LVT */INVX*_RVT */CGL* */LSUP* */*DFF*"]
set_dont_touch $CTS_CELLS false
set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts $CTS_CELLS

report_scenarios
current_scenario

report_clock
report_power_domains

set_host_options -max_cores 16

clock_opt

report_timing
report_timing -delay_type min
report_constraint

#============================
#	routing
#============================

source -echo ../design_data/tech/saed32nm_ant_1p9m.tcl
route_auto
route_opt

check_pg_drc
check_routes

report_timing -delay_type min
report_timing -delay_type max
report_constraints -all_violators

write_gds ../output/machine_counter.gds
