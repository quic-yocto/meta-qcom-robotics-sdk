SYSROOT_PREPROCESS_FUNCS += "prepare_tcl8_versioned_sysroot_config"

prepare_tcl8_versioned_sysroot_config() {
    # Create versioned Tcl 8 config path only in sysroot.
    # This is for recipes such as expect that need Tcl 8 explicitly.
    install -d ${SYSROOT_DESTDIR}${libdir}/tcl8.6

    if [ -f ${SYSROOT_DESTDIR}${libdir}/tclConfig.sh ]; then
        cp -a ${SYSROOT_DESTDIR}${libdir}/tclConfig.sh \
              ${SYSROOT_DESTDIR}${libdir}/tcl8.6/tclConfig.sh
    fi

    if [ -f ${SYSROOT_DESTDIR}${libdir}/tclooConfig.sh ]; then
        cp -a ${SYSROOT_DESTDIR}${libdir}/tclooConfig.sh \
              ${SYSROOT_DESTDIR}${libdir}/tcl8.6/tclooConfig.sh
    fi

    # Remove generic Tcl config files from tcl8 sysroot to avoid conflicts with tcl.
    # expect should use ${STAGING_LIBDIR}/tcl8.6.
    rm -f ${SYSROOT_DESTDIR}/fixmepath
    rm -f ${SYSROOT_DESTDIR}/fixmepath.cmd

    rm -f ${SYSROOT_DESTDIR}${bindir_crossscripts}/tclConfig.sh
    rm -f ${SYSROOT_DESTDIR}${bindir_crossscripts}/tclooConfig.sh
    rm -f ${SYSROOT_DESTDIR}${libdir}/tclConfig.sh
    rm -f ${SYSROOT_DESTDIR}${libdir}/tclooConfig.sh
    rm -f ${SYSROOT_DESTDIR}${libdir}/pkgconfig/tcl.pc
}
