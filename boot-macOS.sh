#!/usr/bin/env bash

# Usage: ./boot-macOS.sh [2k|fhd|fhd+|hd+]
# Default is fhd if no argument is provided.

RESOLUTION_ARG="${1:-fhd}"

if [[ "$RESOLUTION_ARG" == "2k" ]]; then
    RES="2560x1440"
    XRES="2560"
    YRES="1440"
elif [[ "$RESOLUTION_ARG" == "2k+" ]]; then
    RES="2560x1600"
    XRES="2560"
    YRES="1600"
elif [[ "$RESOLUTION_ARG" == "fhd" ]]; then
    RES="1920x1080"
    XRES="1920"
    YRES="1080"
elif [[ "$RESOLUTION_ARG" == "fhd+" ]]; then
    RES="1920x1200"
    XRES="1920"
    YRES="1200"
elif [[ "$RESOLUTION_ARG" == "hd+" ]]; then
    RES="1600x1000"
    XRES="1600"
    YRES="1000"
else
    echo "Usage: $0 [2k|2k+|fhd|fhd+|hd+]"
    exit 1
fi

echo "### Setting resolution to $RES ..."

# 1. Update OpenCore/config.plist
# Update Resolution
sed -i "/<key>Resolution<\/key>/{n;s/<string>.*<\/string>/<string>$RES<\/string>/}" OpenCore/config.plist
# Reset UIScale to 1
sed -i "/<key>UIScale<\/key>/{n;s/<integer>.*<\/integer>/<integer>1<\/integer>/}" OpenCore/config.plist

# 2. Update OpenCore-Boot.sh
# We look for the -device qxl-vga line
sed -i "s/-device qxl-vga,xres=[0-9]*,yres=[0-9]*/-device qxl-vga,xres=$XRES,yres=$YRES/" OpenCore-Boot.sh

# 3. Regenerate OpenCore image
echo "### Regenerating OpenCore image ..."
cd OpenCore
rm -f OpenCore.qcow2
./opencore-image-ng.sh --cfg config.plist --img OpenCore.qcow2
cd ..

# 4. Boot the VM
echo "### Starting VM ..."
./OpenCore-Boot.sh