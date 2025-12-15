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
sim:/cpu_reset_tb/DUT.IF.pc \
sim:/cpu_reset_tb/DUT.pc_F\
sim:/cpu_reset_tb/DUT.pc_D \
sim:/cpu_reset_tb/DUT.intr_ack \
sim:/cpu_reset_tb/DUT.intr_active \
sim:/cpu_reset_tb/DUT.intr_ret \
sim:/cpu_reset_tb/DUT.ID.CU.i_state \
sim:/cpu_reset_tb/DUT.ID.CU.i_next_state \
sim:/cpu_reset_tb/DUT.ID.reg_write \
sim:/cpu_reset_tb/DUT.ID.mem_read \
sim:/cpu_reset_tb/DUT.ID.mem_write \
sim:/cpu_reset_tb/DUT.ID.alu_op \
sim:/cpu_reset_tb/DUT.ID.wb_sel \
sim:/cpu_reset_tb/DUT.ID.jmp_chk \
sim:/cpu_reset_tb/DUT.ID.alu_src_b \
sim:/cpu_reset_tb/DUT.EX.alu_out \
sim:/cpu_reset_tb/DUT.EX.flags_out \
sim:/cpu_reset_tb/DUT.EX.branch_taken \
sim:/cpu_reset_tb/DUT.EX.branch_target \
sim:/cpu_reset_tb/DUT.ID.RF.R \
sim:/cpu_reset_tb/DUT.MEM_UNIT.mem \
sim:/cpu_reset_tb/DUT.EX.alu_out \
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
sim:/cpu_reset_tb/DUT.mem_read_M

# ===============================
# Run full simulation
# ===============================
run -all

# ===============================
# End simulation
# ===============================
#quit -sim