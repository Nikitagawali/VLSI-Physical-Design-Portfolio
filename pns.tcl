#set_pg_via_master_rule pgvia_8x10 -via_array_dimension {8 10}

#set all_macros [get_cells -hierarchical -filter "is_hard_macro && !is_physical_only"]
#set hm(risc_core) [get_cells -filter "is_hard_macro==true" -physical_context *REG_FILE_*_RAM*]
#set hm(top) [remove_from_collection $all_macros $hm(risc_core)]


#create_keepout_margin -outer {3 3 3 3}  $all_macros


##################################################################################################
#			creating ports
##################################################################################################

set_block_pin_constraint -self -allowed_layers {M3 M4 M5 M6}
place_pins -self

set_block_pin_constraints -self -allowed_layers {M3 M5}
place_pins -ports [get_ports -filter "direction==in"]

set_block_pin_constraints -self -allowed_layers {M4 M6}
place_pins -ports [get_ports -filter "direction==out"]


#################################################################################################
#			creating Routing directions
################################################################################################

#get_site_defs
#set_attribute [get_site_defs unit] symmetry y
#set_attribute [get_site_defs unit] is_default true

#set_attribute [get_layers {M2 M4 M6 M8}] routing_direction horizontal
#set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction vertical
#get_attribute [get_layers M?] routing_direction

#report_ignored_layers
#set_ignored_layers -max_routing_layer M8
#report_ignored_layers



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

#create_pg_ring_pattern ring_pattern -horizontal_layer M7 -horizontal_width {1.5} \
			     -horizontal_spacing {1} \
			     -vertical_layer M8 -vertical_width {1.5} \
			     -vertical_spacing {1}
#set_pg_strategy core_ring   \
	 -pattern {{name: ring_pattern} \
           {nets: {VDD VSS}} {offset: {1 1}}} -core \
           -extension {{nets: VDD VSS} {direction: L} {side: 2} {stop: design_boundary_and_generate_pin}}

#set_pg_strategy_via_rule rail_via_rule -via_rule \
                         {{intersection: adjacent} {via_master: default}}


#compile_pg -strategies {core_ring} -via_rule rail_via_rule
                

####################################################################################################
#			creating rails
####################################################################################################
create_pg_std_cell_conn_pattern rail_pattern -layers M1 -rail_width {0.06 0.06}

set_pg_strategy M1_rails -core \
   -pattern {{name: rail_pattern}{nets: VDD VSS}}

compile_pg -strategies M1_rails

####################################################################################################
#			creating mesh
###################################################################################################

create_pg_mesh_pattern mesh_pattern \
   -layers {{{vertical_layer: M6} {width: 0.2}\
             {pitch: 10} {offset: 5}{spacing: interleaving}}\
            {{horizontal_layer: M5} {width: 0.3}\
             {pitch: 10} {offset: 4.7} {spacing: interleaving}}}

set_pg_strategy M5M6_mesh \
   -pattern {{name: mesh_pattern} \
             {nets: VDD VSS}} -core -extension {{stop: outermost_ring}}

compile_pg -strategies M5M6_mesh
                

check_pg_connectivity
check_pg_missing_vias
check_pg_drc 
