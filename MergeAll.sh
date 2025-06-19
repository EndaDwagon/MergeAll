#!/bin/bash
START_TIME=$(date +%s)
if [ "$1" == "cleanup" ]; then
    echo "Running cleanup..."
    
    # Nuke work dirs
    rm -rf _extracted _base_extracted _update_bin extracted cache output

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
        optics.transfer.list optics.new.dat optics.patch.dat
        prism.transfer.list prism.new.dat prism.patch.dat
        prism.img optics.img Merged_Firmware.zip
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
echo
CSC_TAR=$(find _base_extracted -type f -name "CSC*.tar.md5" | head -n 1)
if [ -z "$CSC_TAR" ]; then
    echo "Error: Could not find CSC*.tar.md5 in base ZIP!"
    exit 1
fi
echo "Found AP package: $AP_TAR"
echo "Found CSC package: $CSC_TAR"

# Extract optics and prism from csc
echo
echo "Extracting optics.img.lz4 and prism.img.lz4 from CSC..."
mkdir -p _extracted
tar -xf "$CSC_TAR" --no-same-owner -C _extracted optics.img.lz4 prism.img.lz4

# Extract super.img.lz4 from AP
echo
echo "Extracting super.img.lz4 from AP..."
tar -xf "$AP_TAR" --wildcards --no-same-owner -C _extracted 'super.img.lz4'

if [ ! -f _extracted/super.img.lz4 ]; then
    echo "Error: super.img.lz4 not found in AP package!"
    exit 1
fi

# De-LZ4
echo
echo "Decompressing lz4 images..."
lz4 -d _extracted/optics.img.lz4 optics.img
lz4 -d _extracted/prism.img.lz4 prism.img
lz4 -d _extracted/super.img.lz4 super.img
rm -rf _extracted/super.img.lz4
rm -rf _extracted/prism.img.lz4
rm -rf _extracted/optics.img.lz4

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
    optics.transfer.list optics.new.dat optics.patch.dat
    prism.transfer.list prism.new.dat prism.patch.dat
)

# Move each file if it exists
echo
echo "Moving required update files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "_update_bin/$file" ]; then
        mv "_update_bin/$file" . || echo "Skipped $file"
    else
        echo "$file was skipped"
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

# System_dlkm merge
if [ -f system_dlkm.img ]; then
    echo
    echo "Merging system_dlkm..."
    ./BlockImageUpdate system_dlkm.img system_dlkm.transfer.list system_dlkm.new.dat 		system_dlkm.patch.dat
    echo "System_dlkm merge complete!"
else
    echo
    echo "Skipping system_dlkm"
fi

# Vendor_dlkm merge
if [ -f vendor_dlkm.img ]; then
    echo
    echo "Merging vendor_dlkm..."
    ./BlockImageUpdate vendor_dlkm.img vendor_dlkm.transfer.list vendor_dlkm.new.dat vendor_dlkm.patch.dat
    echo "Vendor_dlkm merge complete!"
else
    echo
    echo "Skipping vendor_dlkm"
fi 

#System_ext merge
if [ -f system_ext.img ]; then
    echo
    echo "Merging system_ext..."
    ./BlockImageUpdate system_ext.img system_ext.transfer.list system_ext.new.dat system_ext.patch.dat
    echo "System_ext merge complete!"
else
    echo
    echo "Skipping system_ext"
fi

if [ -f optics.img ]; then
    echo
    echo "Merging optics..."
    ./BlockImageUpdate optics.img optics.transfer.list optics.new.dat optics.patch.dat
    echo "Optics merge complete!"
else
    echo
    echo "Skipping optics"
fi

if [ -f prism.img ]; then
    echo
    echo "Merging prism..."
    ./BlockImageUpdate prism.img prism.transfer.list prism.new.dat prism.patch.dat
    echo "Prism merge complete!"
else
    echo
    echo "Skipping prism"
fi

echo
echo "Zipping output images..."
mkdir -p output
MERGED_IMGS=(system.img vendor.img product.img odm.img system_ext.img system_dlkm.img vendor_dlkm.img optics.img prism.img)
for img in "${MERGED_IMGS[@]}"; do
    if [ -f "$img" ]; then
        mv "$img" output/
    fi
done
cd output
zip -r9 ../Merged_Firmware.zip ./*.img >/dev/null
cd ..
echo "ZIP archive created: Merged_Firmware.zip"

# Cleanup
echo
echo "Cleaning Up..."
rm -rf _extracted _base_extracted _update_bin extracted cache

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
    optics.transfer.list optics.new.dat optics.patch.dat
    prism.transfer.list prism.new.dat prism.patch.dat
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
