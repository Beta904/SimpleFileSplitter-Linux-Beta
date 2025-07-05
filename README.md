# SimpleFileSplitter

A simple, user-friendly Bash script with GUI to split and merge large files on USB drives.

## Features

- Supports many file formats (zip, iso, wup, app, nsp, xci, cia, and more)
- Splits files into parts sized from 100MB up to 20GB
- Saves split parts into a folder named `Data` on the selected USB drive
- Merges split parts back into the original file
- Easy GUI with Zenity dialogs
- Cross Linux USB detection via `lsblk`

## Requirements

- Bash shell
- Zenity installed (`sudo apt install zenity` on Debian/Ubuntu)
- Coreutils (split, cat)
- USB drives mounted on your system

## Usage

1. Make the script executable:

   ```bash
   chmod +x app.sh
