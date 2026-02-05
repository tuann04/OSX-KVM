# Step-by-Step macOS KVM Optimization Guide

Follow these steps to reproduce a high-performance, Retina-enabled macOS KVM setup.

---

### Step 1: Optimize Virtual Display (Host Side)
Modify your QEMU boot script to use **QXL** and the **SPICE** protocol. This provides smooth mouse movement and better 2D performance.

1.  **Update QEMU Arguments:**
    Add these flags to your `args` array:
    ```bash
    -device virtio-serial-pci \
    -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    -spice port=5900,addr=127.0.0.1,disable-ticketing=on \
    -device qxl-vga,xres=1920,yres=1080 \
    -display spice-app
    ```
2.  **Hyprland Integration:**
    Add this rule to `hyprland.conf` to ensure the window tiles correctly:
    ```text
    windowrule {
        name = remote-viewer-fix
        match:class = ^remote-viewer$
        tile = yes
    }
    ```

---

### Step 2: Establish SSH & Environment (Guest Side)
A fast shell makes configuration easier.

1.  **Enable SSH:** In macOS, turn on `Remote Login` in Sharing settings.
2.  **Connect:** `ssh -p 2222 user@localhost`
3.  **Install Oh My Zsh:**
    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```
4.  **Sync Plugins:** Install `zsh-autosuggestions` and `zsh-syntax-highlighting` via git clone into `~/.oh-my-zsh/custom/plugins`.

---

### Step 3: The Retina/HiDPI Hack (Guest Side)
Force macOS to enable sharp "Retina" scaling on the virtual display.

1.  **Enable HiDPI:**
    ```bash
    sudo defaults write /Library/Preferences/com.apple.windowserver.plist DisplayResolutionEnabled -bool true
    ```
2.  **Create Override Directory:**
    ```bash
    sudo mkdir -p /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-756e6b6e
    ```
3.  **Create Override File:**
    Create `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-756e6b6e/DisplayProductID-717` and paste the XML containing `<key>scale-resolutions</key>` (see previous logs for full XML).
4.  **Reboot & Select:** Go to Displays -> Advanced -> Show as list. Select a mode like **1600x1000 (HiDPI)**.

---

### Step 4: Automate Resolution Switching (Host Side)
Create `boot-macOS.sh` to automate the process of updating `config.plist` and the boot script simultaneously.

1.  The script should use `sed` to update:
    *   `OpenCore/config.plist`: `<key>Resolution</key>`
    *   `OpenCore-Boot.sh`: `-device qxl-vga,xres=...,yres=...`
2.  It must then run `./opencore-image-ng.sh` to regenerate the `OpenCore.qcow2` image before starting QEMU.

---

### Step 5: Native iPhone Passthrough (Hardware Side)
For stable Xcode/iPhone use, pass the entire USB Controller.

1.  **Identify Controller:** Use `lsusb -t` to find the bus, then trace it to the PCI address (e.g., `76:00.4`).
2.  **Check Isolation:** Ensure the PCI device is in its own IOMMU group via `readlink /sys/bus/pci/devices/0000:<ADDR>/iommu_group`.
3.  **VFIO Bind:** Unbind the device from `xhci_hcd` and bind to `vfio-pci`.
4.  **Add to Script:** 
    ```bash
    -device vfio-pci,host=76:00.4,bus=pcie.0
    ```