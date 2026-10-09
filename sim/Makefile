# Synopsys VCS 2016 / UVM 1.2 - run from sim/
VCS ?= vcs
TOP ?= axi2apb_tb_top
TEST ?= axi2apb_test
UVM_DIR := ../uvm
FLIST := $(UVM_DIR)/build.flist
VCS_FLAGS := -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 -debug_access+all -lca
.PHONY: all compile run clean help
all: compile
compile:
	@mkdir -p logs build
	cd $(UVM_DIR) && $(VCS) $(VCS_FLAGS) -f build.flist -top $(TOP) -o ../sim/build/simv -l ../sim/logs/compile.log
run:
	@test -x build/simv || (echo "Compile first: make compile"; exit 1)
	./build/simv +UVM_TESTNAME=$(TEST) -l logs/simulation.log
clean:
	rm -rf build/* logs/* $(UVM_DIR)/csrc $(UVM_DIR)/simv.daidir $(UVM_DIR)/ucli.key $(UVM_DIR)/DVEfiles
help:
	@echo "make compile | make run | make run TEST=axi2apb_test | make clean"
