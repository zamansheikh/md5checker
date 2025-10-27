#!/bin/bash

# Function to generate MD5 hashes for each file and save them in the checks/ directory
function generate_md5_hashes() {
    local checks_dir="checks"
    
    # Create checks directory if it doesn't exist
    if [[ ! -d $checks_dir ]]; then
        mkdir $checks_dir
    fi

    echo "Generating MD5 checksums for all files in the current directory and its subdirectories (excluding checks/ folder and md5_checker.sh)..."
    
    # Find all files, excluding the md5_checker.sh itself and anything in the checks folder
    find . -type f ! -path "./checks/*" ! -name "md5_checker.sh" -print0 | while IFS= read -r -d '' file; do
        # Calculate checksum
        checksum=$(md5sum "$file" | awk '{print $1}')
        filename=$(basename "$file")
        
        # Store checksum in a .checks file inside the checks/ directory
        echo "$checksum" > "$checks_dir/$filename.checks"
    done

    echo "MD5 checksums saved in $checks_dir"
}

# Function to check MD5 hashes against stored .checks files
function check_md5_hashes() {
    local checks_dir="checks"
    if [[ ! -d $checks_dir ]]; then
        echo "The directory $checks_dir does not exist. Please generate checksums first."
        return
    fi

    echo "Checking file integrity by comparing checksums in $checks_dir..."

    # Initialize counters for matched and unmatched files
    total_files=0
    matched_files=0
    unmatched_files=0
    unmatched_list=()

    # Find all files, excluding the md5_checker.sh and anything in the checks folder
    while IFS= read -r -d '' file; do
        total_files=$((total_files + 1))
        filename=$(basename "$file")
        checks_file="$checks_dir/$filename.checks"

        # Check if .checks file exists
        if [[ -f $checks_file ]]; then
            # Read the stored checksum (removing any extra spaces or newlines)
            stored_checksum=$(tr -d '\n' < "$checks_file")
            
            # Calculate the current checksum
            current_checksum=$(md5sum "$file" | awk '{print $1}')
            
            # Compare the checksums
            if [[ "$stored_checksum" == "$current_checksum" ]]; then
                echo "$file: OK"
                matched_files=$((matched_files + 1))
            else
                echo "$file: FAILED"
                unmatched_files=$((unmatched_files + 1))
                unmatched_list+=("$file")
            fi
        else
            echo "Warning: Checksum file for $file not found in $checks_dir."
            unmatched_files=$((unmatched_files + 1))
            unmatched_list+=("$file")
        fi
    done < <(find . -type f ! -path "./checks/*" ! -name "md5_checker.sh" -print0)

    # Print result summary
    if [[ $unmatched_files -eq 0 ]]; then
        echo "All files match."
    else
        echo "Match: $matched_files out of $total_files files, $unmatched_files not matched."
        echo "Files that didn't match or had no checksum file:"
        for file in "${unmatched_list[@]}"; do
            echo "$file"
        done
    fi
}

# CLI Menu
function display_menu() {
    echo "--------------------------------"
    echo "       MD5 Hash Checker          "
    echo "--------------------------------"
    echo "1. Start MD5 Check (Generate .checks files)"
    echo "2. Match MD5 Hashes (Check against .checks files)"
    echo "3. Exit"
    echo "--------------------------------"
    echo -n "Choose an option: "
}

# Main loop
while true; do
    display_menu
    read -r choice

    case $choice in
        1)
            generate_md5_hashes
            ;;
        2)
            check_md5_hashes
            ;;
        3)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done

