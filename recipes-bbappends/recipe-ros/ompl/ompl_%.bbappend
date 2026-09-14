FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI += "file://0001-build-remove-boost-system.patch"
SRC_URI:remove = "file://0001-FindPython.cmake-install_python-Allow-to-set-differe.patch"

# Fix QA Issue [buildpaths]: Remove TMPDIR references from all installed files
do_install:append() {
    # Traverse all files in the image directory
    if [ -d ${D}${ros_prefix} ]; then
        bbnote "Scanning all files in ${D}${ros_prefix} for buildpaths"
        find ${D}${ros_prefix} -type f | while read file; do
            case "$file" in
                *.cmake)
                    # Fix CMake config files - use CMake variables
                    bbnote "Fixing CMake file: $file"
                    # Replace STAGING_DIR_HOST + ros_prefix with ${_IMPORT_PREFIX}
                    sed -i "s|${STAGING_DIR_HOST}${ros_prefix}|\${_IMPORT_PREFIX}|g" "$file"
                    # Replace remaining STAGING_DIR_HOST paths
                    sed -i "s|${STAGING_DIR_HOST}|\${CMAKE_SYSROOT}|g" "$file"
                    ;;
                *.pc)
                    # Fix pkg-config files - use pkg-config variables
                    bbnote "Fixing pkg-config file: $file"
                    # Replace STAGING_DIR_HOST + ros_prefix with ${prefix}
                    sed -i "s|${STAGING_DIR_HOST}${ros_prefix}|\${prefix}|g" "$file"
                    # Replace remaining STAGING_DIR_HOST paths (remove them)
                    sed -i "s|${STAGING_DIR_HOST}||g" "$file"
                    ;;
                *.py)
                    # ompl ships demo/benchmark scripts (share/ompl/demos/*.py,
                    # bin/ompl_benchmark_statistics.py) whose interpreter line is
                    # rewritten to the build-time native python
                    # (${TMPDIR}/.../hosttools/python3). That absolute build path
                    # trips both [buildpaths] and [file-rdeps] QA. Normalise the
                    # first-line shebang to the portable form; only touch line 1
                    # so script bodies are left untouched.
                    if head -1 "$file" | grep -q "^#!.*python"; then
                        bbnote "Fixing python shebang: $file"
                        sed -i "1s|^#!.*python[0-9.]*|#!/usr/bin/env python3|" "$file"
                    fi
                    ;;
            esac
        done
    fi
}