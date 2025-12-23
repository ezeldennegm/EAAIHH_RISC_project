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
# ===============================
# Add waveforms (organized)
# ===============================

# -------- Global --------
add wave -divider "GLOBAL"
add wave \
    sim:/cpu_reset_tb/clk \
    sim:/cpu_reset_tb/reset \
    sim:/cpu_reset_tb/OUT\
    sim:/cpu_reset_tb/intr

# -------- Fetch Stage --------
add wave -divider "FETCH (F)"
add wave \
    sim:/cpu_reset_tb/DUT.pc_F

# -------- Decode Stage --------
add wave -divider "DECODE (D)"
add wave \
    sim:/cpu_reset_tb/DUT.instr_D\
    sim:/cpu_reset_tb/DUT.A_D \
    sim:/cpu_reset_tb/DUT.B_D \
    sim:/cpu_reset_tb/DUT.mem_write_D \
    sim:/cpu_reset_tb/DUT.mem_read_D \
    sim:/cpu_reset_tb/DUT.alu_op_D \
    sim:/cpu_reset_tb/DUT.ID.RF.R

# -------- Decode Control / Forwarding --------
add wave -divider "DECODE CONTROL / FORWARDING"
add wave \
    sim:/cpu_reset_tb/DUT.ID.forward_src_a \
    sim:/cpu_reset_tb/DUT.ID.forward_src_b \
    sim:/cpu_reset_tb/DUT.ID.alu_src_a \
    sim:/cpu_reset_tb/DUT.ID.alu_src_b \
    sim:/cpu_reset_tb/DUT.ID.reg_1 \
    sim:/cpu_reset_tb/DUT.ID.reg_2

# -------- Control Unit (Hazards) --------
add wave -divider "CONTROL UNIT (Hazards)"
add wave \
    sim:/cpu_reset_tb/DUT.ID.CU.rt_ex \
    sim:/cpu_reset_tb/DUT.ID.CU.rt_mem \
    sim:/cpu_reset_tb/DUT.ID.CU.rt_wb \
    sim:/cpu_reset_tb/DUT.ID.CU.rt_dc \
    sim:/cpu_reset_tb/DUT.ID.CU.stall \
    sim:/cpu_reset_tb/DUT.ID.CU.prev_mem_read

# -------- Execute Stage --------
add wave -divider "EXECUTE (E)"
add wave \
    sim:/cpu_reset_tb/DUT.alu_op_E \
    sim:/cpu_reset_tb/DUT.A_E \
    sim:/cpu_reset_tb/DUT.B_E \
    sim:/cpu_reset_tb/DUT.mem_write_E \
    sim:/cpu_reset_tb/DUT.mem_read_E \
    sim:/cpu_reset_tb/DUT.alu_out_E \
    sim:/cpu_reset_tb/DUT.jmp_chk_E\
    sim:/cpu_reset_tb/DUT.branch_taken_EX\
    sim:/cpu_reset_tb/DUT.branch_target_EX\
    sim:/cpu_reset_tb/DUT.pc_F\
    sim:/cpu_reset_tb/DUT.EX.C\
    sim:/cpu_reset_tb/DUT.EX.V\
    sim:/cpu_reset_tb/DUT.EX.Z\
    sim:/cpu_reset_tb/DUT.EX.N

# -------- Memory Stage --------
add wave -divider "MEMORY (M)"
add wave \
    sim:/cpu_reset_tb/DUT.A_M \
    sim:/cpu_reset_tb/DUT.B_M \
    sim:/cpu_reset_tb/DUT.mem_write_M \
    sim:/cpu_reset_tb/DUT.mem_read_M \
    sim:/cpu_reset_tb/DUT.MEM_UNIT.mem

# -------- Write Back --------
add wave -divider "WRITE BACK (WB)"
add wave \
    sim:/cpu_reset_tb/DUT.wb_data_pre \
    sim:/cpu_reset_tb/DUT.wb_data
# ===============================
# Run full simulation
# ===============================
run -all

# ===============================
# End simulation
# ===============================
#quit -sim