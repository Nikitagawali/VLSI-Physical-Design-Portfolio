#####################################################################################################
#		 creating rings 
#####################################################################################################
remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect 

connect_pg_net

create_pg_ring_pattern ring_pattern -horizontal_layer M5 -horizontal_width {2} \
			     -horizontal_spacing {1.5} \
			     -vertical_layer M6 -vertical_width {2} \
			     -vertical_spacing {1.5} -corner_bridge true
set_pg_strategy core_ring   \
	 -pattern {{name: ring_pattern} \
           {nets: {VDD VSS}} {offset: {2 2}}} -core \
           -extension {{{side:1} {nets: VDD} {direction: B} {stop: design_boundary_and_generate_pin}} \
		{{side:2} {nets: VSS} {direction: L} {stop: design_boundary_and_generate_pin}}}

set_pg_strategy_via_rule rail_via_rule -via_rule \
                         {{intersection: adjacent} {via_master: default}}


compile_pg -strategies {core_ring} -via_rule rail_via_rule
                


####################################################################################################
#			creating mesh
###################################################################################################

create_pg_mesh_pattern mesh_pattern \
   -layers {{{vertical_layer: M6} {width: 0.26}\
             {pitch: 12} {offset: 4}{spacing: interleaving}}\
            {{horizontal_layer: M5} {width: 0.16}\
             {pitch: 12} {offset: 4} {spacing: interleaving}}} -via_rule {{intersection: all} {via_master: default}}

set_pg_strategy M5M6_mesh \
   -pattern {{name: mesh_pattern} \
             {nets: VDD VSS}} -core -extension {{stop:first_target}} 


compile_pg -strategies M5M6_mesh

#####################################################################################
#lower mesh
###############################################################################################

create_pg_mesh_pattern low_mesh_pattern \
   -layer {{vertical_layer: M2} {width: 0.096}\
             {pitch:15} {offset:5} {spacing:interleaving} {trim:true}}\
   -via_rule {{intersection: all} {via_master: default}}

set_pg_strategy M2_low_mesh \
   -pattern {{name: low_mesh_pattern} \
             {nets: VDD VSS}} -core -extension {{stop:outermost_ring}} 


compile_pg -strategies M2_low_mesh

             
########################################################################################
# macro ring for macros
########################################################################################
set macros [get_cells -hierarchical -physical_context -filter "is_hard_macro && !is_physical_only"]

create_pg_ring_pattern P_HM_ring -horizontal_layer M7 -horizontal_width {1} -vertical_layer M8 -vertical_width {1} -corner_bridge false

set_pg_strategy S_HM_ring_top -macros $macros -pattern { {pattern: P_HM_ring} {nets: {VSS VDD}} {offset: {0.3 0.3}} }

set_pg_strategy_via_rule S_ring_vias -via_rule { {{{strategies: {S_HM_ring_top}} {layers: {M7}}} {existing: {strap}}{via_master:{default}}} {{{strategies:{S_HM_ring_top}} {layers: {M8}}} {existing:{strap}}{via_master: {default}}} }

compile_pg -strategies {S_HM_ring_top} -via_rule S_ring_vias

create_pg_macro_conn_pattern macro_connect_pattern -pin_conn_type scattered_pin -layers {M7 M8}

set_pg_strategy macro_connect -pattern {{name: macro_connect_pattern} {nets: VSS VDD}} -macros "$macros"

compile_pg -strategies macro_connect
 

#############################################################################################
# creating rails
#########################################################################################

create_pg_std_cell_conn_pattern rail_pattern -layers M1

set_pg_strategy m1_rails -pattern {{name: rail_pattern} {nets:VDD VSS}} -core -blockage {{macros_with_keepout:ALU CSRF/MC}}

compile_pg -strategies m1_rails

#######################################################################################
# checks
##########################################################################################

check_pg_connectivity
check_pg_missing_vias
check_pg_drc
