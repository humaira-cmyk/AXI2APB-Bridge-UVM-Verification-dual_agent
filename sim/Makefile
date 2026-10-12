# ============================================================
# AXI2APB UVM Verification Makefile
# Per-test build folder under sim/out/
# Synopsys VCS 2016 + UVM 1.2
#
# Run from:
#   /root/Documents/AXI2APB_Bridge_UVM_Verification/sim
#
# Example:
#   make sim TEST=axi2apb_write_backpressure_test
#
# Result:
#   sim/out/build_axi2apb_write_backpressure_test/
# ============================================================

VCS      := vcs
TEST     ?= axi2apb_reset_test

OUT_ROOT := out
RUN_DIR  := $(OUT_ROOT)/build_$(TEST)

# All current directed tests
TESTS := \
	axi2apb_reset_test \
	axi2apb_single_write_test \
	axi2apb_single_read_test \
	axi2apb_wait_state_test \
	axi2apb_write_backpressure_test \
	axi2apb_read_backpressure_test \
	axi2apb_simultaneous_rw_test \
	axi2apb_back_to_back_write_test \
	axi2apb_back_to_back_read_test \
	axi2apb_mixed_rw_test \
	axi2apb_id_test \
	axi2apb_user_test \
	axi2apb_pslverr_test

.PHONY: compile sim regression summary clean clean_all help

compile:
	@echo ""
	@echo "============================================================"
	@echo " Compiling test: $(TEST)"
	@echo " Output folder : $(RUN_DIR)"
	@echo "============================================================"
	@mkdir -p $(OUT_ROOT)
	@rm -rf $(RUN_DIR)
	@mkdir -p $(RUN_DIR)

	@cd ../uvm && rm -rf csrc simv.daidir simv.vdb simv vc_hdrs.h ucli.key cm.log tr_db.log waveform.vpd vcdplus.vpd

	cd ../uvm && $(VCS) \
		-full64 \
		-sverilog \
		-timescale=1ns/1ps \
		-ntb_opts uvm-1.2 \
		-debug_access+all \
		-lca \
		-cm line+cond+tgl+assert \
		-f build.flist \
		-top axi2apb_tb_top \
		-o simv \
		-l ../sim/$(RUN_DIR)/compile_$(TEST).log

	@cd ../uvm && \
	for f in csrc simv.daidir simv.vdb simv vc_hdrs.h ucli.key cm.log tr_db.log; do \
		if [ -e "$$f" ]; then mv "$$f" ../sim/$(RUN_DIR)/; fi; \
	done

	@echo ""
	@echo "Compile complete."
	@echo "Build folder: $(RUN_DIR)"

sim: compile
	@echo ""
	@echo "============================================================"
	@echo " Running test : $(TEST)"
	@echo " Run folder   : $(RUN_DIR)"
	@echo "============================================================"

	cd $(RUN_DIR) && \
	./simv \
		+UVM_TESTNAME=$(TEST) \
		-cm line+cond+tgl+assert \
		+vcs+vcdpluson \
		+vpdfile+waveform.vpd \
		-l log_build_$(TEST).log

	@echo ""
	@echo "============================================================"
	@echo " Test finished: $(TEST)"
	@echo " Files saved in:"
	@echo " $(RUN_DIR)"
	@echo "============================================================"

regression:
	@for t in $(TESTS); do \
		echo ""; \
		echo "############################################################"; \
		echo " Running $$t"; \
		echo "############################################################"; \
		$(MAKE) sim TEST=$$t || exit $$?; \
	done
# ============================================================
# 1. Pehle check karo waveform file bani hai
# ============================================================
ls -lh out/build_axi2apb_reset_test/waveform.vpd

# ============================================================
# 2. DVE mein waveform open karo
# ============================================================
dve -vpd out/build_axi2apb_reset_test/waveform.vpd &


# ============================================================
# PERMANENT FIX:
# Apne Makefile ke end mein ye target add kar do
# ============================================================

gui:
	@if [ ! -f "$(RUN_DIR)/waveform.vpd" ]; then \
		echo "ERROR: Waveform not found: $(RUN_DIR)/waveform.vpd"; \
		echo "First run: make sim TEST=$(TEST)"; \
		exit 1; \
	fi
	dve -vpd $(RUN_DIR)/waveform.vpd &


# ============================================================
# Uske baad kisi bhi test ki wave aise open hogi:
# ============================================================

make gui TEST=axi2apb_reset_test

# Single write:
make gui TEST=axi2apb_single_write_test

# Wait-state:
make gui TEST=axi2apb_wait_state_test

# Write backpressure:
make gui TEST=axi2apb_write_backpressure_test

summary:
	@echo ""
	@echo "============================================================"
	@echo " AXI2APB DIRECTED TEST SUMMARY"
	@echo "============================================================"
	@for d in $(OUT_ROOT)/build_*; do \
		if [ -d "$$d" ]; then \
			log=$$(ls "$$d"/log_build_*.log 2>/dev/null | head -1); \
			if [ -n "$$log" ]; then \
				echo ""; \
				echo "---- $$d ----"; \
				grep -E "SCOREBOARD SUMMARY|AXI2APB VERIFICATION|UVM_WARNING :|UVM_ERROR :|UVM_FATAL :" "$$log" || true; \
			fi; \
		fi; \
	done

clean:
	rm -rf $(RUN_DIR)

clean_all:
	rm -rf $(OUT_ROOT)/build_*

help:
	@echo ""
	@echo "Compile + run one test:"
	@echo "  make sim TEST=axi2apb_single_write_test"
	@echo ""
	@echo "Run all directed tests:"
	@echo "  make regression"
	@echo ""
	@echo "Show summaries:"
	@echo "  make summary"
	@echo ""
	@echo "Clean one test:"
	@echo "  make clean TEST=axi2apb_single_write_test"
	@echo ""
	@echo "Clean all test folders:"
	@echo "  make clean_all"

