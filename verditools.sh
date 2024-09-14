#!/bin/bash

# Run csh and sys.chsrc at the beginning
source csh
source sys.chsrc

# Function to display the menu
display_menu() {
    clear
    echo "================================="
    echo " Design Tool Script"
    echo "================================="
    echo "1. Run VCS Simulation"
    echo "2. Modify Testbench File"
    echo "3. Open Verdi and Read FSDB File"
    echo "4. Invoke DC Compiler Tool"
    echo "5. Quit"
    echo "================================="
    echo -n "Select an option [1-5]: "
}

# Function to select a file using zenity
select_file() {
    zenity --file-selection --title="Select a file"
}

# Function to select a directory using zenity
select_directory() {
    zenity --file-selection --directory --title="Select a directory"
}

# Function to modify the testbench file
modify_testbench() {
    verilog_file=$(zenity --file-selection --title="Select the Verilog file to include")
    tb_file=$(zenity --file-selection --title="Select the testbench file to modify")

    # Check if the files exist
    if [[ ! -f "$verilog_file" || ! -f "$tb_file" ]]; then
        zenity --error --text="Error: One or both files do not exist."
        exit 1
    fi

    # Add `include` directive at the top of the testbench file
    sed -i "1i\`include \"$verilog_file\"" "$tb_file"

    # Check if 'initial begin' exists and add the commands
    if grep -q "initial begin" "$tb_file"; then
        sed -i "/initial begin/a \$fsdbDumpvars();\n\$finish;" "$tb_file"
    else
        zenity --warning --text="'initial begin' block not found in $tb_file. Skipping FSDB commands insertion."
    fi

    # Ensure that `$finish;` is added before `endmodule`
    if grep -q "endmodule" "$tb_file"; then
        sed -i "/endmodule/i \$finish;" "$tb_file"
    else
        zenity --warning --text="'endmodule' not found in $tb_file. Skipping \$finish; insertion."
    fi
}

# Function to run VCS simulation
run_vcs() {
    filename=$(zenity --file-selection --title="Select the Verilog filename for simulation")
    if [[ -z "$filename" ]]; then
        zenity --error --text="Error: No file selected."
        exit 1
    fi

    vcs -full64 "$filename" -debug_access+all -lca -kdb

    zenity --info --text="VCS simulation completed. Follow the instructions provided to proceed."
}

# Function to open Verdi and read FSDB file
open_verdi() {
    zenity --info --text="This function assumes you have already run VCS on the testbench file. You can now run Verdi to view the simulation waveforms."
}

# Function to invoke DC Compiler tool
invoke_dc_compiler() {
    work_dir=$(select_directory)
    if [[ -z "$work_dir" ]]; then
        zenity --error --text="Error: No directory selected."
        exit 1
    fi

    cd "$work_dir" || exit

    rtl_source_files=$(select_file)
    constraints_file=$(select_file)
    design_name=$(zenity --entry --title="Enter Design Name" --text="Enter the design name (e.g., full_adder):")

    if [[ -z "$rtl_source_files" || -z "$constraints_file" || -z "$design_name" ]]; then
        zenity --error --text="Error: Missing required input."
        exit 1
    fi

    # DC Compiler commands
    {
        echo "set PDK_PATH ./../ref"
        echo "source ./rm_setup/dc_setup.tcl"
        echo "set RTL_SOURCE_FILES $rtl_source_files"
        echo "start_gui"
        echo "define_design_lib WORK -path ./WORK"
        echo "analyze -format verilog \${RTL_SOURCE_FILES}"
        echo "elaborate $design_name"
        echo "report_design"
        echo "report_area"
        echo "report_units"
        echo "read_sdc -echo $constraints_file"
        echo "compile_ultra"
    } > dc_commands.tcl

    # Run the DC Compiler with the generated commands
    dc_shell -f dc_commands.tcl
}

# Main loop
while true; do
    display_menu
    read -r option
    case $option in
        1) run_vcs ;;
        2) modify_testbench ;;
        3) open_verdi ;;
        4) invoke_dc_compiler ;;
        5) exit 0 ;;
        *) zenity --error --text="Invalid option. Please select a number between 1 and 5." ;;
    esac
    read -r -p "Press Enter to return to the menu..."
done
