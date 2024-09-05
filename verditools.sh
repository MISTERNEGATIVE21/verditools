#!/bin/bash

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
    local file
    file=$(zenity --file-selection --title="Select a file")
    echo $file
}

# Function to select a directory using zenity
select_directory() {
    local dir
    dir=$(zenity --file-selection --directory --title="Select a directory")
    echo $dir
}

# Function to modify the testbench file
modify_testbench() {
    echo -n "Enter the filename of the Verilog file to include (e.g., design.v): "
    read verilog_file

    echo -n "Enter the filename of the testbench file (e.g., design_tb.v): "
    read tb_file

    # Check if the files exist
    if [[ ! -f "$verilog_file" ]]; then
        echo "Error: Verilog file $verilog_file does not exist."
        exit 1
    fi

    if [[ ! -f "$tb_file" ]]; then
        echo "Error: Testbench file $tb_file does not exist."
        exit 1
    fi

    # Add `include` directive at the top of the testbench file
    sed -i "1i`include \"$verilog_file\"" "$tb_file"

    # Check if 'initial begin' exists and add the commands
    if grep -q "initial begin" "$tb_file"; then
        sed -i "/initial begin/a $fsdbDumpvars();\n$finish;" "$tb_file"
    else
        echo "Warning: 'initial begin' block not found in $tb_file. Skipping FSDB commands insertion."
    fi

    # Ensure that `$finish;` is added before `endmodule`
    if grep -q "endmodule" "$tb_file"; then
        sed -i "/endmodule/i $finish;" "$tb_file"
    else
        echo "Warning: 'endmodule' not found in $tb_file. Skipping $finish; insertion."
    fi

    echo "Testbench file $tb_file has been modified successfully."
}

# Function to run VCS simulation
run_vcs() {
    echo -n "Enter the Verilog filename (e.g., design.v): "
    read filename
    echo "Running VCS simulation on $filename..."
    vcs -full64 $filename -debug_access+all -lca -kdb
    echo "VCS simulation completed."

    echo "To proceed, follow the instructions below:"
    echo "1. Ensure you have the following keywords in your testbench file:"
    echo "   `include \"$filename\""
    echo "   $fsdbDumpvars();"
    echo "   $finish;"
    echo "2. Run the following command to invoke Verdi and read the FSDB file:"
    echo "   ./simv Verdi dc_shell"
}

# Function to open Verdi and read FSDB file
open_verdi() {
    echo "This function assumes you have already run VCS on the testbench file."
    echo "You can now run Verdi to view the simulation waveforms."
    echo "Follow the instructions provided in the previous step."
}

# Function to invoke DC Compiler tool
invoke_dc_compiler() {
    echo "Select the working directory where RTL and constraints files are located."
    work_dir=$(select_directory)

    echo "You selected: $work_dir"

    echo "Select the RTL source file."
    rtl_source_files=$(zenity --file-selection --title="Select the RTL source file" --filename="$work_dir/")
    echo "You selected: $rtl_source_files"

    echo "Select the constraints file."
    constraints_file=$(zenity --file-selection --title="Select the constraints file" --filename="$work_dir/")
    echo "You selected: $constraints_file"

    echo -n "Enter the design name (e.g., full_adder): "
    read design_name

    echo "Invoking DC Compiler tool..."
    echo "Setting PDK_PATH:"
    echo "set PDK_PATH ./../ref"
    echo "Sourcing DC setup Tcl file:"
    echo "source ./rm_setup/dc_setup.tcl"
    echo "Setting RTL_SOURCE_FILES:"
    echo "set RTL_SOURCE_FILES $rtl_source_files"
    echo "Starting GUI..."
    echo "start_gui"
    echo "Defining Design library path..."
    echo "define_design_lib WORK -path ./WORK"
    echo "Analyzing HDL source file..."
    echo "analyze -format verilog \${RTL_SOURCE_FILES}"
    echo "Elaborating design..."
    echo "elaborate $design_name"
    echo "Running design reports..."
    echo "report_design"
    echo "report_area"
    echo "report_units"
    echo "Reading constraints file..."
    echo "read_sdc -echo $constraints_file"
    echo "Compiling and optimizing design..."
    echo "compile_ultra"
}

# Main loop
while true; do
    display_menu
    read option
    case $option in
        1)
            run_vcs
            ;;
        2)
            modify_testbench
            ;;
        3)
            open_verdi
            ;;
        4)
            invoke_dc_compiler
            ;;
        5)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select a number between 1 and 5."
            ;;
    esac
    echo -n "Press Enter to return to the menu..."
    read
done
