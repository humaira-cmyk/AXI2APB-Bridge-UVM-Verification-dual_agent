VCS = vcs
TOP = uvm_tb
FLIST = build.flist

VCS_OPTS = -full64 \
           -sverilog \
           -timescale=1ns/1ps \
           -debug_access+all \
	   -ntb_opts uvm-1.2 \
           -kdb \
           -lca \
           -l compile.log
SIM_OPTS = -l sim.log

.PHONY: all compile sim clean

all: compile sim

compile:
	$(VCS) $(VCS_OPTS) -f $(FLIST) -top $(TOP)

sim:
	./simv $(SIM_OPTS)

clean:
	rm -rf simv simv.daidir csrc ucli.key
	rm -rf *.log *.vpd DVEfiles