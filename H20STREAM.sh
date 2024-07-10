#!/bin/zsh

# H20STREAM.sh - Comprehensive Smart ZSH Script for Unreliable USB MP3 Player File Management
# Author: Claude Sonnet 3.5
# Date: 7/9/24
# Version: 1.5

# Description:
# This script provides a robust solution for managing files on an unreliable USB flash drive MP3 player.
# It handles file transfers, folder creation, folder deletion, and folder listing, all while
# managing potential device disconnections. The script is designed to work with a specific
# USB drive named 'H2OSTREAMDM' on a Mac system.

# Features:
# - Copy files from a source folder to the USB drive, creating the destination folder if needed
# - Intelligent sorting of files based on track numbers or alphabetically
# - Delete a specified folder from the USB drive
# - List all folders on the USB drive
# - Automatic reconnection handling for all operations
# - Progress tracking for file transfers with a simple progress bar
# - Periodic logging while waiting for drive connection
# - Comprehensive logging of all operations and events
# - System sleep prevention during script execution

# Usage:
# ./H20STREAM.sh [copy|delete|list] [folder_path|folder_name]
#   copy [folder_path]: Copy files from the specified folder to the device
#   delete [folder_name]: Delete the specified folder from the device
#   list: List all folders on the device

# Example usage:
# ./H20STREAM.sh copy /path/to/music/folder
# ./H20STREAM.sh delete unwanted_folder
# ./H20STREAM.sh list

# Note: This script assumes the USB drive is formatted as FAT32.

# Global Variables
DRIVE_NAME="H2OSTREAMDM"
MOUNT_POINT="/Volumes/$DRIVE_NAME"
WAIT_INTERVAL=5  # Interval in seconds for periodic logging while waiting for the drive
PROGRESS_WIDTH=50  # Width of the progress bar

# Function: log_message
# Description: Logs a message to both the console and the log file
# Usage: log_message "Message"
# Arguments:
#   Message: The message to be logged
log_message() {
    echo "$1"
}

# Function: check_drive
# Description: Checks if the USB drive is currently connected and mounted
# Returns: 0 if the drive is connected, 1 otherwise
check_drive() {
    if [[ -d "$MOUNT_POINT" ]]; then
        return 0
    else
        return 1
    fi
}

# Function: wait_for_drive
# Description: Waits for the USB drive to be connected, logging a message every WAIT_INTERVAL seconds
# Usage: wait_for_drive
wait_for_drive() {
    log_message "Waiting for drive $DRIVE_NAME to be connected..."
    local wait_count=0
    while ! check_drive; do
        sleep 1
        ((wait_count++))
        if ((wait_count % WAIT_INTERVAL == 0)); then
            log_message "Still waiting for drive $DRIVE_NAME... (${wait_count} seconds)"
        fi
    done
    log_message "Drive $DRIVE_NAME connected."
}

# Function: extract_track_number
# Description: Extracts the track number from a filename, or returns the filename if no track number is found
# Usage: extract_track_number filename
# Arguments:
#   filename: The filename to extract the track number from
# Returns: The track number if found, or the original filename
extract_track_number() {
    local filename="$1"
    local track_number

    # Try to extract track number (assumes format like "track_16_of_17" or just "16")
    if [[ $filename =~ track_([0-9]+)_of_[0-9]+ ]]; then
        track_number="${match[1]}"
    elif [[ $filename =~ _([0-9]+)_ ]]; then
        track_number="${match[1]}"
    else
        track_number="$filename"
    fi

    echo "$track_number"
}

# Function: sort_files_smart
# Description: Sorts files based on track number if present, otherwise alphabetically
# Usage: sort_files_smart file_array
# Arguments:
#   file_array: Array of filenames to be sorted
# Returns: Sorted array of filenames
sort_files_smart() {
    local -a files=("$@")
    local -a sorted_files

    # Create an array of "track_number:filename" or "filename:filename" pairs
    local -a pairs
    for file in "${files[@]}"; do
        local base_name="${file:t}"  # Get just the filename without the path
        local sort_key=$(extract_track_number "$base_name")
        pairs+=("$sort_key:$file")
    done

    # Sort the pairs
    sorted_pairs=($(printf "%s\n" "${pairs[@]}" | sort -n -t: -k1))

    # Extract just the filenames from the sorted pairs
    sorted_files=(${sorted_pairs[@]#*:})

    echo "${sorted_files[@]}"
}

# Function: display_progress
# Description: Displays a progress bar
# Usage: display_progress current_value max_value
# Arguments:
#   current_value: The current progress value
#   max_value: The maximum progress value
display_progress() {
    local current=$1
    local max=$2
    local percent=$((current * 100 / max))
    local completed=$((percent * PROGRESS_WIDTH / 100))
    local remaining=$((PROGRESS_WIDTH - completed))

    printf "\rProgress: [%s%s] %d%%" "$(printf '#%.0s' {1..$completed})" "$(printf ' %.0s' {1..$remaining})" $percent
}

# Function: check_drive
# Description: Checks if the USB drive is currently connected, mounted, and writable
# Returns: 0 if the drive is connected and writable, 1 otherwise
check_drive() {
    if [[ -d "$MOUNT_POINT" ]]; then
        # Try to create a temporary file to check write permissions
        if touch "$MOUNT_POINT/.test_write" 2>/dev/null; then
            rm "$MOUNT_POINT/.test_write"
            return 0
        else
            log_message "Drive detected but not writable. Treating as disconnected."
            return 1
        fi
    else
        return 1
    fi
}

# Function: wait_for_drive
# Description: Waits for the USB drive to be connected, mounted, and writable
# Usage: wait_for_drive
wait_for_drive() {
    log_message "Waiting for drive $DRIVE_NAME to be connected and writable..."
    local wait_count=0
    while ! check_drive; do
        sleep 1
        ((wait_count++))
        if ((wait_count % WAIT_INTERVAL == 0)); then
            log_message "Still waiting for drive $DRIVE_NAME... (${wait_count} seconds)"
        fi
    done
    log_message "Drive $DRIVE_NAME connected and writable."
}

# Function: copy_files
# Description: Copies files from a source folder to the USB drive, handling disconnections and tracking progress
# Usage: copy_files source_folder
# Arguments:
#   source_folder: Path to the folder containing files to be copied
copy_files() {
    local source_folder="$1"
    local dest_folder="$MOUNT_POINT/${source_folder:t}"
    
    # Ensure the drive is connected and writable before proceeding
    wait_for_drive
    
    # Create destination folder if it doesn't exist
    while ! mkdir -p "$dest_folder" 2>/dev/null; do
        log_message "Unable to create destination folder. Drive may have disconnected. Waiting for reconnection..."
        wait_for_drive
    done
    
    log_message "Destination folder created successfully."
    
    # Get list of files to copy and sort them
    local files_to_copy=($(find "$source_folder" -type f -print0 | xargs -0))
    files_to_copy=($(sort_files_smart "${files_to_copy[@]}"))
    
    local total_files=${#files_to_copy[@]}
    
    log_message "Files will be copied in the following order:"
    for ((i=1; i<=total_files; i++)); do
        log_message "$i. ${files_to_copy[$i]:t}"
    done
    log_message "Total files to copy: $total_files"
    log_message "---"
    
    local copied_files=0
    
    for file in "${files_to_copy[@]}"; do
        while true; do
            if check_drive; then
                if [[ ! -f "$dest_folder/${file:t}" ]] || [[ $(stat -f "%z" "$file") -ne $(stat -f "%z" "$dest_folder/${file:t}") ]]; then
                    log_message "Copying: ${file:t}"
                    if cp "$file" "$dest_folder/"; then
                        ((copied_files++))
                        display_progress $copied_files $total_files
                        break
                    else
                        log_message "Failed to copy ${file:t}. Drive may have disconnected. Retrying..."
                        wait_for_drive
                    fi
                else
                    log_message "Skipping: ${file:t} (already exists)"
                    ((copied_files++))
                    display_progress $copied_files $total_files
                    break
                fi
            else
                log_message "Drive disconnected. Waiting for reconnection..."
                wait_for_drive
            fi
        done
    done
    
    echo  # New line after progress bar
    log_message "All files copied successfully."
}


# Function: delete_folder
# Description: Deletes a specified folder from the USB drive, handling disconnections
# Usage: delete_folder folder_name
# Arguments:
#   folder_name: Name of the folder to be deleted from the USB drive
delete_folder() {
    local folder_name="$1"
    local folder_path="$MOUNT_POINT/$folder_name"
    
    while true; do
        if check_drive; then
            if [[ -d "$folder_path" ]]; then
                log_message "Deleting folder: $folder_name"
                rm -rf "$folder_path"
                if [[ $? -eq 0 ]]; then
                    log_message "Folder deleted successfully."
                    break
                else
                    log_message "Failed to delete folder. Retrying..."
                fi
            else
                log_message "Folder $folder_name does not exist on the drive."
                break
            fi
        else
            wait_for_drive
        fi
    done
}

# Function: list_folders
# Description: Lists all folders at the root level of the USB drive
# Usage: list_folders
list_folders() {
    while true; do
        if check_drive; then
            log_message "Folders on $DRIVE_NAME:"
            find "$MOUNT_POINT" -type d -depth 1 -exec basename {} \; | while read folder; do
                log_message "- $folder"
            done
            break
        else
            wait_for_drive
        fi
    done
}

# Function: prevent_sleep
# Description: Prevents the system from sleeping
prevent_sleep() {
    caffeinate -s -i &
    CAFFEINATE_PID=$!
    log_message "System sleep prevented. The machine will stay awake until the script completes."
}

# Function: allow_sleep
# Description: Allows the system to sleep
allow_sleep() {
    if [[ -n $CAFFEINATE_PID ]]; then
        kill $CAFFEINATE_PID
        log_message "System can now enter sleep mode if idle."
    fi
}

# Trap to ensure we allow sleep when the script exits
trap allow_sleep EXIT

# Main script logic
if [[ $# -lt 1 ]]; then
    log_message "Usage: $0 [copy|delete|list] [folder_path|folder_name]"
    log_message "  copy [folder_path]: Copy files from the specified folder to the device"
    log_message "  delete [folder_name]: Delete the specified folder from the device"
    log_message "  list: List all folders on the device"
    exit 1
fi

action="$1"

log_message "Script started with action: $action"

# Prevent system sleep before starting the main action
prevent_sleep

case "$action" in
    copy)
        if [[ $# -lt 2 ]]; then
            log_message "Please specify the source folder path for copying."
            exit 1
        fi
        target="$2"
        if [[ ! -d "$target" ]]; then
            log_message "Source folder does not exist: $target"
            exit 1
        fi
        wait_for_drive
        copy_files "$target"
        ;;
    delete)
        if [[ $# -lt 2 ]]; then
            log_message "Please specify the folder name to delete."
            exit 1
        fi
        target="$2"
        wait_for_drive
        delete_folder "$target"
        ;;
    list)
        list_folders
        ;;
    *)
        log_message "Invalid action. Use 'copy', 'delete', or 'list'."
        exit 1
        ;;
esac

log_message "Script execution completed."