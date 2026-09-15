#Copyright (c) 2026 Qualcomm Innovation Center, Inc. All rights reserved.
#SPDX-License-Identifier: BSD-3-Clause-Clear
#
# rootfs-symlink.bbclass
# Purpose:
#   Creates configured symbolic links inside the image root filesystem during
#   rootfs post-processing.
#
# Main responsibilities:
#   1. Read link definitions from ROOTFS_SYMLINK_PAIRS.
#   2. Parse each entry as a source / destination symlink pair.
#   3. Ensure the destination parent directory exists inside IMAGE_ROOTFS.
#   4. Create or replace symbolic links using ln -snf semantics.
#
# Typical usage:
#   Useful for image recipes that need compatibility links or fixed filesystem
#   aliases without modifying the installed package payload directly.
#
# Function: do_rootfs_create_symlinks
# Placeholder shell task body. The real implementation is provided by the
# following Python task of the same name.
do_rootfs_create_symlinks() {
    :
}

# Function: do_rootfs_create_symlinks
# Create symbolic links inside ${IMAGE_ROOTFS} based on
# ROOTFS_SYMLINK_PAIRS during ROOTFS_POSTPROCESS_COMMAND execution.
python do_rootfs_create_symlinks () {
    import os
    import subprocess

    dvar = d.getVar('IMAGE_ROOTFS')  
    pairs = d.getVar('ROOTFS_SYMLINK_PAIRS') or ""
    pairs = pairs.split()

    if not pairs:
        bb.note("rootfs-symlink: ROOTFS_SYMLINK_PAIRS not set, skip")
        return

    for p in pairs:
        if ':' in p:
            src, dest = p.split(':', 1)
        else:
            parts = p.split(None, 1)
            if len(parts) != 2:
                bb.warn(f"rootfs-symlink: can't parse '{p}', should be 'SRC:DEST' or 'SRC DEST', skip")
                continue
            src, dest = parts

        src = src.strip()
        dest = dest.strip()

        if not src or not dest:
            bb.warn(f"rootfs-symlink: empty SRC/DEST ('{p}'), skip")
            continue

        abs_dest = os.path.join(dvar, dest.lstrip('/'))
        dest_dir = os.path.dirname(abs_dest)

        os.makedirs(dest_dir, exist_ok=True)

        try:
            subprocess.check_call(['ln', '-snf', src, abs_dest])
            bb.note(f"rootfs-symlink: ln -snf {src} -> {abs_dest}")
        except subprocess.CalledProcessError as e:
            bb.fatal(f"rootfs-symlink: create link fail: {src} -> {abs_dest}, error: {e}")
}

# Register the symlink creation task as a rootfs post-processing step so the
# links are applied after the root filesystem content has been assembled.
ROOTFS_POSTPROCESS_COMMAND:append = " do_rootfs_create_symlinks; "
