#!/bin/bash
# SimpleFileSplitter - Split and merge large files on USB drives
# Supports many file types, user-friendly GUI with zenity

USB_FOLDER_NAME="Data"
SUPPORTED_FORMATS=("zip" "iso" "mp4" "avi" "mp3" "7z" "tar" "gz" "wup" "app" "nsp" "xci" "cia" "nca" "tik" "hfs0" "bin")

LANG="EN"

declare -A TEXTS_EN=(
  [menu_title]="SimpleFileSplitter"
  [menu_split]="Split File"
  [menu_merge]="Merge Parts"
  [menu_exit]="Exit"
  [select_file]="Select file to split"
  [select_usb]="Select USB drive"
  [enter_split_size]="Enter split size (100M - 20G):"
  [error_no_file]="No file selected."
  [error_unsupported]="File type not supported."
  [error_no_usb]="No USB found."
  [error_no_size]="No split size entered."
  [error_invalid_size]="Split size must be between 100M and 20G."
  [confirm_split]="Split '%s' into parts of size %s?\nSave in:\n%s"
  [success_split]="File split successfully!"
  [error_split]="Error during splitting."
  [error_merge]="Error during merging."
  [success_merge]="File merged successfully!"
  [cancelled]="Cancelled."
)

t() {
  local key=$1
  echo "${TEXTS_EN[$key]}"
}

while true; do
  ACTION=$(zenity --list --title="$(t menu_title)" --column="Action" "$(t menu_split)" "$(t menu_merge)" "$(t menu_exit)" --height=200 --width=300)
  if [ $? -ne 0 ]; then exit 0; fi

  case "$ACTION" in
    "$(t menu_split)")
      FILE=$(zenity --file-selection --title="$(t select_file)")
      RET=$?
      if [ $RET -ne 0 ] || [ -z "$FILE" ]; then
        zenity --error --text="$(t error_no_file)"
        continue
      fi

      EXT="${FILE##*.}"
      EXT="${EXT,,}"

      SUPPORTED=0
      for f in "${SUPPORTED_FORMATS[@]}"; do
        if [ "$f" == "$EXT" ]; then
          SUPPORTED=1
          break
        fi
      done

      if [ $SUPPORTED -eq 0 ]; then
        zenity --error --text="$(t error_unsupported)"
        continue
      fi

      USBS=$(lsblk -o MOUNTPOINT,TRAN -nr | grep -i usb | awk '{print $1}' | grep '^/' || true)
      if [ -z "$USBS" ]; then
        zenity --error --text="$(t error_no_usb)"
        continue
      fi

      USB=$(echo "$USBS" | zenity --list --title="$(t select_usb)" --column="USB Drives" --height=200 --width=400)
      if [ $? -ne 0 ] || [ -z "$USB" ]; then
        zenity --error --text="$(t cancelled)"
        continue
      fi

      TARGET_DIR="$USB/$USB_FOLDER_NAME/$(basename "$FILE")"
      mkdir -p "$TARGET_DIR"

      SPLIT_SIZE=$(zenity --entry --title="$(t menu_split)" --text="$(t enter_split_size)" --entry-text="100M")
      if [ $? -ne 0 ] || [ -z "$SPLIT_SIZE" ]; then
        zenity --error --text="$(t error_no_size)"
        continue
      fi

      if ! [[ "$SPLIT_SIZE" =~ ^[0-9]+[MmGg]$ ]]; then
        zenity --error --text="$(t error_invalid_size)"
        continue
      fi

      NUM=${SPLIT_SIZE%[mMgG]}
      UNIT=${SPLIT_SIZE: -1}
      if [[ $UNIT == "M" || $UNIT == "m" ]]; then SPLIT_BYTES=$((NUM * 1024 * 1024)); else SPLIT_BYTES=$((NUM * 1024 * 1024 * 1024)); fi

      if (( SPLIT_BYTES < 100*1024*1024 || SPLIT_BYTES > 20*1024*1024*1024 )); then
        zenity --error --text="$(t error_invalid_size)"
        continue
      fi

      zenity --question --text="$(printf "$(t confirm_split)" "$(basename "$FILE")" "$SPLIT_SIZE" "$TARGET_DIR")"
      if [ $? -ne 0 ]; then
        zenity --info --text="$(t cancelled)"
        continue
      fi

      split -b "$SPLIT_BYTES" -d --additional-suffix=.part "$FILE" "$TARGET_DIR/$(basename "$FILE")_part_"
      if [ $? -eq 0 ]; then
        zenity --info --text="$(t success_split)"
      else
        zenity --error --text="$(t error_split)"
      fi
      ;;

    "$(t menu_merge)")
      DIR=$(zenity --file-selection --directory --title="Select directory with split parts")
      if [ $? -ne 0 ] || [ -z "$DIR" ]; then
        zenity --error --text="$(t cancelled)"
        continue
      fi

      OUTPUT_FILE=$(zenity --file-selection --save --confirm-overwrite --title="Save merged file as")
      if [ $? -ne 0 ] || [ -z "$OUTPUT_FILE" ]; then
        zenity --error --text="$(t cancelled)"
        continue
      fi

      BASENAME=$(basename "$OUTPUT_FILE")
      PARTS=( "$DIR/${BASENAME}_part_"*.part )
      if [ ! -e "${PARTS[0]}" ]; then
        zenity --error --text="No split parts found matching pattern ${BASENAME}_part_*.part in $DIR"
        continue
      fi

      IFS=$'\n' SORTED_PARTS=( $(ls -1v "$DIR/${BASENAME}_part_"*.part) )
      unset IFS

      cat "${SORTED_PARTS[@]}" > "$OUTPUT_FILE"
      if [ $? -eq 0 ]; then
        zenity --info --text="$(t success_merge)"
      else
        zenity --error --text="$(t error_merge)"
      fi
      ;;

    "$(t menu_exit)")
      exit 0
      ;;

    *)
      exit 0
      ;;
  esac
done

