# ==============================================================================
# UNIVERSAL OPEN-SOURCE iCE40 TOOLCHAIN WRAPPER
# ==============================================================================
# Simply alter the variables in Section 1 for each new hardware design project.
# This makefile was made using Gemini AI
# ------------------------------------------------------------------------------
# 1. PROJECT SPECIFIC CONFIGURATION
# ------------------------------------------------------------------------------
# Target Module name (Must match your top-level Verilog module identifier)
TOP          = top_module

# List ALL Verilog source files needed for this design (separated by spaces)
VERILOG_SRCS = all files

# Name of your Physical Constraints File (without the .pcf extension)
# PCF_NAME     = VSDSquadronFM
CONSTRAINTS_DIR = Constraints
PCF_NAME = Master_Constraints
PCF_PATH = $(CONSTRAINTS_DIR)/$(PCF_NAME).pcf

# ------------------------------------------------------------------------------
# 2. HARDWARE SPECIFIC TARGETS
# ------------------------------------------------------------------------------
BOARD_FREQ   = 12        # Input Oscillator Frequency in MHz
FPGA_VARIANT = up5k
FPGA_PACKAGE = sg48

# Serial Comms Configuration
SERIAL_PORT  = /dev/ttyUSB0
BAUD_RATE    = 115200

# ==============================================================================
# UNIVERSAL OPEN-SOURCE iCE40 TOOLCHAIN WRAPPER
# ==============================================================================
# Simply alter the variables in Section 1 for each new hardware design project.
# ------------------------------------------------------------------------------
# 2. HARDWARE SPECIFIC TARGETS
# ------------------------------------------------------------------------------
BOARD_FREQ   = 12        # Input Oscillator Frequency in MHz
FPGA_VARIANT = up5k
FPGA_PACKAGE = sg48

# Serial Comms Configuration
SERIAL_PORT  = /dev/ttyUSB0
BAUD_RATE    = 115200

# ------------------------------------------------------------------------------
# 3. TOOLCHAIN EXECUTABLES MAP
# ------------------------------------------------------------------------------
YOSYS        = yosys
NEXTPNR      = nextpnr-ice40
ICEPACK      = icepack
ICEPROG      = iceprog
ICETIME      = icetime

# ==============================================================================
# 4. COMPILATION AUTOMATION RULES
# ==============================================================================

# Default rule: Typing 'make' executes the full build chain automatically
all: $(TOP).bin

# Step 1: Synthesis with optimization flags (-abc9 for routing, -dsp for hardware multipliers)
$(TOP).json: $(VERILOG_SRCS)
	$(YOSYS) -q -p "synth_ice40 -abc9 -device u -dsp -top $(TOP) -json $@" $(VERILOG_SRCS)

# Step 2: Place & Route mapping netlist to physical silicon package geometry
$(TOP).asc: $(TOP).json $(PCF_NAME).pcf
	$(NEXTPNR) --force --json $< --pcf $(PCF_NAME).pcf --asc $@ --freq $(BOARD_FREQ) --$(FPGA_VARIANT) --package $(FPGA_PACKAGE) --opt-timing

# Step 3: Compress layout configurations into target machine binary bitstream
$(TOP).bin: $(TOP).asc
	$(ICEPACK) -s $< $@

# ------------------------------------------------------------------------------
# 5. UTILITY COMMANDS (Phony Endpoints)
# ------------------------------------------------------------------------------

# Analyze and print static timing report (Checks if your logic keeps up with the clock)
timing: $(TOP).asc
	$(ICETIME) -p $(PCF_NAME).pcf -P $(FPGA_PACKAGE) -d $(FPGA_VARIANT) -t $<

# Flash binary bitstream directly down to onboard memory
flash: $(TOP).bin
	$(ICEPROG) $<

# Open pre-configured serial console to pass terminal data to/from the chip
terminal:
	picocom -b $(BAUD_RATE) $(SERIAL_PORT) --imap lfcrlf,crcrlf --omap delbs,crlf

# Complete directory cleaning rule (Deletes old artifact gates and bitstreams)
clean:
	rm -f *.json *.asc *.bin *.blif

.PHONY: all timing flash terminal clean