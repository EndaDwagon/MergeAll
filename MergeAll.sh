#!/bin/bash
START_TIME=$(date +%s)
if [ "$1" == "cleanup" ]; then
    echo "Running cleanup..."
    
    # Nuke work dirs
    rm -rf _ap_extracted _base_extracted _update_bin extracted

    # Nuke update-related files
    CLEANUP_FILES=(
        system.transfer.list system.new.dat system.patch.dat
        product.transfer.list product.new.dat product.patch.dat
        odm.transfer.list odm.new.dat odm.patch.dat
        vendor.transfer.list vendor.new.dat vendor.patch.dat
        system_dlkm.img system_dlkm.transfer.list system_dlkm.new.dat system_dlkm.patch.dat
        vendor_dlkm.transfer.list vendor_dlkm.new.dat vendor_dlkm.patch.dat
        system_ext.transfer.list system_ext.new.dat system_ext.patch.dat
        super.img super.img-old system.img system_dlkm.img system_ext.img
        vendor.img vendor_dlkm.img product.img odm.img Progress.txt
    )

    for file in "${CLEANUP_FILES[@]}"; do
        [ -f "$file" ] && rm -f "$file"
    done

    echo "Cleanup complete."
    exit 0
fi
set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 [path to base firmware ZIP] [path to update bin ZIP]"
    exit 1
fi

BASE_ZIP="$1"
UPDATE_ZIP="$2"
echo
echo "===== Samsung Beta Firmware Merger ====="
echo "= Coded by @EndaDwagon at t.me/endarom ="
echo "Base firmware: $BASE_ZIP"
echo "Update binary: $UPDATE_ZIP"
echo

# Check dependencies
for cmd in unzip tar lz4; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "$cmd is not installed. Installing..."
        sudo apt update && sudo apt install -y $cmd
    fi
done

# Extract base firmware zip
echo
echo "Extracting ODIN firmware ZIP..."
mkdir -p _base_extracted
unzip -q "$BASE_ZIP" -d _base_extracted

# Find AP tar inside base ZIP
echo
AP_TAR=$(find _base_extracted -type f -name "AP*.tar.md5" | head -n 1)
if [ -z "$AP_TAR" ]; then
    echo "Error: Could not find AP*.tar.md5 in base ZIP!"
    exit 1
fi

echo "Found AP package: $AP_TAR"

# Extract super.img.lz4 from AP
echo
echo "Extracting super.img.lz4 from AP..."
mkdir -p _ap_extracted
tar -xf "$AP_TAR" --wildcards --no-same-owner -C _ap_extracted 'super.img.lz4'

if [ ! -f _ap_extracted/super.img.lz4 ]; then
    echo "Error: super.img.lz4 not found in AP package!"
    exit 1
fi

# De-LZ4
echo
echo "Decompressing super.img.lz4..."
lz4 -d _ap_extracted/super.img.lz4 super.img
rm -f _ap_extracted/super.img.lz4

# Desparse super
echo
echo "Desparsing super..."
./imjtool super.img extract
mv super.img super.img-old 2>/dev/null
mv extracted/image.img super.img

# Extract super
echo "Extracting super"
./lpunpack super.img
echo "Super Extracted"

# Extract update bin
echo
echo "Extracting update bin..."
mkdir -p _update_bin
unzip -q "$UPDATE_ZIP" -d _update_bin
echo "Update BIN Extracted."

# Move required files out of update bin
REQUIRED_FILES=(
    system.transfer.list system.new.dat system.patch.dat
    product.transfer.list product.new.dat product.patch.dat
    odm.transfer.list odm.new.dat odm.patch.dat
    vendor.transfer.list vendor.new.dat vendor.patch.dat
    system_dlkm.img system_dlkm.transfer.list system_dlkm.new.dat system_dlkm.patch.dat
    vendor_dlkm.transfer.list vendor_dlkm.new.dat vendor_dlkm.patch.dat
    system_ext.transfer.list system_ext.new.dat system_ext.patch.dat
)

# Move each file if it exists
echo
echo "Moving required update files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "_update_bin/$file" ]; then
        mv "_update_bin/$file" . || echo "Failed to move $file"
    else
        echo "Warning: $file not found in update bin"
    fi
done
echo "Starting Merge..."

# System merge
echo
echo "Merging system..."
./BlockImageUpdate system.img system.transfer.list system.new.dat system.patch.dat
echo "System merge complete!"

# Product merge
echo
echo "Merging product..."
./BlockImageUpdate product.img product.transfer.list product.new.dat product.patch.dat
echo "Product merge complete!"

# Odm merge
echo
echo "Merging odm"
./BlockImageUpdate odm.img odm.transfer.list odm.new.dat odm.patch.dat
echo "Odm merge complete!"

# Vendor merge
echo
echo "Merging vendor..."
./BlockImageUpdate vendor.img vendor.transfer.list vendor.new.dat vendor.patch.dat
echo "Vendor merge complete!"
echo
echo "DO NOT PANIC IF YOU SEE ANY ERRORS PAST THIS POINT, YOUR DEVICE PROBABLY DOESNT HAVE THESE PARTITIONS"

# System_dlkm merge
echo
echo "Merging system_dlkm..."
./BlockImageUpdate system_dlkm.img system_dlkm.transfer.list system_dlkm.new.dat system_dlkm.patch.dat
echo "System_dlkm merge complete!"

# Vendor_dlkm merge
echo
echo "Merging vendor_dlkm..."
./BlockImageUpdate vendor_dlkm.img vendor_dlkm.transfer.list vendor_dlkm.new.dat vendor_dlkm.patch.dat
echo "Vendor_dlkm merge complete!"

#System_ext merge
echo
echo "Merging system_ext..."
./BlockImageUpdate system_ext.img system_ext.transfer.list system_ext.new.dat system_ext.patch.dat
echo "System_ext merge complete!"

# Cleanup
echo
echo "Cleaning Up..."
rm -rf _ap_extracted _base_extracted _update_bin extracted

# Nuke all the now unused update-related files
CLEANUP_FILES=(
    system.transfer.list system.new.dat system.patch.dat
    product.transfer.list product.new.dat product.patch.dat
    odm.transfer.list odm.new.dat odm.patch.dat
    vendor.transfer.list vendor.new.dat vendor.patch.dat
    system_dlkm.transfer.list system_dlkm.new.dat system_dlkm.patch.dat
    vendor_dlkm.transfer.list vendor_dlkm.new.dat vendor_dlkm.patch.dat
    system_ext.transfer.list system_ext.new.dat system_ext.patch.dat
    super.img super.img-old Progress.txt
)

for file in "${CLEANUP_FILES[@]}"; do
    [ -f "$file" ] && rm -f "$file"
done

echo "Cleanup complete."

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINS=$(((ELAPSED % 3600) / 60))
SECS=$((ELAPSED % 60))
echo
if [ $HOURS -gt 0 ]; then
    echo "Merge complete in ${HOURS}hr ${MINS}min ${SECS}sec"
elif [ $MINS -gt 0 ]; then
    echo "Merge complete in ${MINS}min ${SECS}sec"
else
    echo "Merge complete in ${SECS}sec"
fi
