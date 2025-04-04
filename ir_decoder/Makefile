NAME = ir_decoder
VERILOG += top.v ir_decoder.v
INC = ./
LPF = karnix_cabga256.lpf
DEVICE = 25k
PACKAGE = CABGA256
FTDI_CHANNEL = 0 ### FT2232 has two channels, select 0 for channel A or 1 for channel B
#
FLASH_METHOD := flash
UPLOAD_METHOD := openloader

.PHONY: clean
all: $(NAME).bit

.PHONY: upload
upload: $(NAME).bit
ifeq ("$(UPLOAD_METHOD)", "ecpprog")
	$(MAKE) upload_ecpprog
else
ifeq ("$(UPLOAD_METHOD)", "openloader")
	$(MAKE) upload_openloader
else
ifeq ("$(UPLOAD_METHOD)", "")
	echo "Upload method has not been chosen, set UPLOAD_METHOD env variable to 'ecpprog' or 'openloader'."
else
	echo "Unsupported upload method: $(UPLOAD_METHOD)."
endif
endif
endif

.PHONY: upload_openloader
upload_openloader:
ifeq ("$(FLASH_METHOD)", "flash")
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) -f --reset $(NAME).bit
else
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) $(NAME).bit
endif

.PHONY: upload_ecpprog
upload_ecpprog:
ifeq ("$(FLASH_METHOD)", "flash")
	ecpprog -I $(if $(filter $(FTDI_CHANNEL),0),A,B) -X $(NAME).bit
else
	ecpprog -I $(if $(filter $(FTDI_CHANNEL),0),A,B) -S $(NAME).bit
endif



fw: $(NAME).bit

$(NAME).bit: $(LPF) $(VERILOG)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" -p "read_verilog -sv $(VERILOG)" -p "synth_ecp5 -json $(NAME).json -top top" -l $(NAME).yosys.log
	nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(LPF) --lpf-allow-unconstrained -l $(NAME).nextpnr.log 
	ecppack --compress --freq 38.8 --input $(NAME)_out.config --bit $(NAME).bit
	$(MAKE) check


.PHONY: graph 
graph: $(LPF) $(VERILOG)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" -p "read_verilog -sv +/ecp5/cells_bb.v" -p "hierarchy -check -top top" -p "proc; opt; fsm; memory; opt" -p "synth_ecp5 -noabc9 -top top -json $(NAME).json" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot" $(VERILOG) -l $(NAME).yosys.log
	@if [ -f "`which dot`" ]; then \
		echo "Generating PDFs with schematics..."; \
		dot -Tpdf -O $(NAME).dot; \
	else \
		echo "Note: 'dot' utility is not installed, PDF won't be generated!"; \
	fi
	netlistsvg -o $(NAME).svg $(NAME).json
	#@echo "Generating SVGs with routing and placement..."
	#nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(LPF) --lpf-allow-unconstrained --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg -l $(NAME).nextpnr.log
	$(MAKE) check
	@if [ -f "`which xdot`" ]; then \
		xdot $(NAME).dot; \
	else \
		echo "xdot utility is not installed, cannot show you DOT file:"; \
		ls -al $(NAME).dot; \
	fi
	@if [ -f "`which firefox`" ]; then \
		firefox $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg $(NAME).*pdf; \
	else \
		echo "Firefox is not installed, cannot show you SVG and PDF files:"; \
		ls -al $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg $(NAME).*pdf; \
	fi


.PHONY: sim
sim: $(VERILOG) $(NAME)_tb.v $(shell yosys-config --datdir)/ice40/cells_sim.v
	iverilog $^ -o $(NAME)_tb.out
	./$(NAME)_tb.out
	gtkwave $(NAME)_tb.vcd $(NAME)_tb.gtkw &

check:
	@echo "Checking for warnings..."
	@(grep Warn $(NAME).yosys.log $(NAME).nextpnr.log; echo)

.PHONY: clean
clean:
	rm -f *.bit *.txt *.log *.json .blif *.out *.svg *.dot *.pdf *out.config *.vcd



