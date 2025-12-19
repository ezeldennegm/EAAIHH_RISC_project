# ===============================
# Clean work library
# ===============================
vlib work

# ===============================
# Compile RTL files
# ===============================
vlog ALU.v
vlog control_unit.v
vlog reg_file.v
vlog Memory.v
vlog Fetch_stage.v
vlog decode_stage.v
vlog EX_stage.v
vlog CPU.v

# ===============================
# Compile testbench
# ===============================
vlog simple_tb.v

# ===============================
# Start simulation
# ===============================
vsim -voptargs=+acc work.cpu_reset_tb

# ===============================
# Add minimal waveforms
# ===============================
add wave -position insertpoint \
sim:/cpu_reset_tb/clk \
sim:/cpu_reset_tb/reset \
sim:/cpu_reset_tb/OUT \
sim:/cpu_reset_tb/DUT.ID.RF.R \
sim:/cpu_reset_tb/DUT.MEM_UNIT.mem \
sim:/cpu_reset_tb/DUT.A_D\
sim:/cpu_reset_tb/DUT.B_D\
sim:/cpu_reset_tb/DUT.mem_write_D\
sim:/cpu_reset_tb/DUT.A_E\
sim:/cpu_reset_tb/DUT.B_E\
sim:/cpu_reset_tb/DUT.mem_write_E\
sim:/cpu_reset_tb/DUT.A_M\
sim:/cpu_reset_tb/DUT.B_M\
sim:/cpu_reset_tb/DUT.mem_write_M\
sim:/cpu_reset_tb/DUT.mem_read_D\
sim:/cpu_reset_tb/DUT.mem_read_E\
sim:/cpu_reset_tb/DUT.mem_read_M\
sim:/cpu_reset_tb/DUT.alu_out_E\
sim:/cpu_reset_tb/DUT.wb_data_pre\
sim:/cpu_reset_tb/DUT.wb_data \
sim:/cpu_reset_tb/DUT.ID.forward_src_a \
sim:/cpu_reset_tb/DUT.ID.forward_src_b \
sim:/cpu_reset_tb/DUT.ID.alu_src_a \
sim:/cpu_reset_tb/DUT.ID.alu_src_b\
sim:/cpu_reset_tb/DUT.ID.forward_src_a \
sim:/cpu_reset_tb/DUT.ID.forward_src_b \
sim:/cpu_reset_tb/DUT.ID.alu_src_a \
sim:/cpu_reset_tb/DUT.ID.alu_src_b\
sim:/cpu_reset_tb/DUT.ID.reg_1\
sim:/cpu_reset_tb/DUT.ID.reg_2\
sim:/cpu_reset_tb/DUT.ID.CU.rt_ex\
sim:/cpu_reset_tb/DUT.ID.CU.rt_mem\
sim:/cpu_reset_tb/DUT.ID.CU.rt_wb\
sim:/cpu_reset_tb/DUT.ID.CU.rt_dc\
sim:/cpu_reset_tb/DUT.ID.CU.stall\
sim:/cpu_reset_tb/DUT.ID.CU.prev_mem_read
# ===============================
# Run full simulation
# ===============================
run -all

# ===============================
# End simulation
# ===============================
#quit -sim