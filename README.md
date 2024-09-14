# Design Tool Script

This script is designed to streamline your design tool workflow by providing a menu-driven interface to run VCS simulations, modify testbench files, invoke DC Compiler tools, and more.

## Features

- **Run VCS Simulation**: Execute VCS simulations on your Verilog files.
- **Modify Testbench File**: Automatically include Verilog files in your testbench and insert simulation commands.
- **Open Verdi and Read FSDB File**: Instructions for viewing simulation waveforms with Verdi.
- **Invoke DC Compiler Tool**: Setup and run the DC Compiler tool for synthesis tasks.

## Prerequisites

- **Bash Shell**: The script is written for a bash shell environment.
- **Zenity**: Required for GUI dialogs.
- **VCS**: Synopsys VCS for running simulations.
- **DC Compiler**: Synopsys Design Compiler for synthesis.
- **Verdi**: Required for waveform viewing.

## Setup

1. **Download the Script**:
   ```bash
   curl -O https://raw.githubusercontent.com/MISTERNEGATIVE21/verditools/master/verditools.sh  && chmod +x verditools.sh  && ./verditools.sh
