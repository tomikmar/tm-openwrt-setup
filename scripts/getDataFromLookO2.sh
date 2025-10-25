#!/bin/sh

set -o nounset



# URL to download the file
URL="http://192.168.105.2/data.json"

# Base directory for storing files
BASE_DIR="/mnt/external-disk/iot/lookO2"
LOG_FILE="$BASE_DIR/lookO2-download.log"



# Check if required variables are set
if [ -z "${URL}" ]; then
    echo "Error: URL is not set" >&2
    exit 1
fi
if [ -z "${BASE_DIR}" ]; then
    echo "Error: BASE_DIR is not set" >&2
    exit 1
fi
if [ -z "${LOG_FILE}" ]; then
    echo "Error: LOG_FILE is not set" >&2
    exit 1
fi

# Check if BASE_DIR exists and is writable
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: BASE_DIR ($BASE_DIR) does not exist" >&2
    exit 2
fi
if [ ! -w "$BASE_DIR" ]; then
    echo "Error: BASE_DIR ($BASE_DIR) is not writable" >&2
    exit 2
fi



# Get current date and time
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H-%M-%S)

# Path to the destination directory
DIR="$BASE_DIR/$DATE"
FILENAME="lookO2-$DATE-$TIME.json"
FULL_PATH="$DIR/$FILENAME"

# Create directory if it doesn't exist
mkdir -p "$DIR"

# Download the file and save to the directory
if wget --timeout=10 -q -O "$FULL_PATH" "$URL" 2>/dev/null; then
    echo "$DATE $TIME - Downloading $URL successful, saved to $FULL_PATH" >> "$LOG_FILE"
else
    ERROR_CODE=$?
    echo "$DATE $TIME - Error downloading $URL, wget exit code: $ERROR_CODE" >> "$LOG_FILE"
fi

