# H20STREAM.sh

H20STREAM.sh is a comprehensive ZSH script designed for managing files on an unreliable USB flash drive MP3 player. It provides robust file transfer capabilities, handling potential device disconnections and ensuring successful operations even with intermittent connectivity.

## Features

- Copy files from a source folder to the USB drive
- Delete specified folders from the USB drive
- List all folders on the USB drive
- Automatic reconnection handling for all operations
- Progress tracking for file transfers with a simple progress bar
- Console-based logging of operations
- System sleep prevention during script execution

## Requirements

- macOS operating system
- ZSH shell
- USB flash drive named 'H2OSTREAMDM' (can be customized in the script)

## Usage

The script supports three main operations: copy, delete, and list.

### Copy Files

To copy files from a source folder to the USB drive:

```
./H20STREAM.sh copy /path/to/source/folder
```

This will copy all files from the specified folder to the USB drive, creating the destination folder if it doesn't exist.

### Delete Folder

To delete a folder from the USB drive:

```
./H20STREAM.sh delete folder_name
```

Replace `folder_name` with the name of the folder you want to delete from the USB drive.

### List Folders

To list all folders on the USB drive:

```
./H20STREAM.sh list
```

This will display all folders at the root level of the USB drive.

## Customization

You can customize the following variables at the beginning of the script:

- `DRIVE_NAME`: The name of your USB drive
- `MOUNT_POINT`: The mount point of your USB drive
- `WAIT_INTERVAL`: The interval (in seconds) between checks for drive connectivity
- `PROGRESS_WIDTH`: The width of the progress bar

