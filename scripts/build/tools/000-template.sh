# Template file for a tool utility

# Put your download code here
do_tools_foobar_get() {
    # For example:
    # CT_GetFile "foobar-${CT_FOOBAR_VERSION}" http://foobar.com/releases/
    :
}

# Put your extract code here
do_tools_foobar_extract() {
    # For example:
    # CT_ExtractAndPatch "foobar-${CT_FOOBAR_VERSION}"
    :
}

# Put your build code here
do_tools_foobar_build() {
    # For example:
    # mkdir -p "${CT_BUILD_DIR}/build-foobar"
    # CT_Pushd "${CT_BUILD_DIR}/build-foobar"
    # CT_DoExecLog ALL                                        \
    # "${CT_SRC_DIR}/foobar-${CT_FOOBAR_VERSION}/configure"   \
    #     --build=${CT_BUILD}                                 \
    #     --host=${CT_TARGET}                                 \
    #     --prefix=/usr                                       \
    #     --foobar-options
    # CT_DoExecLog ALL make
    # CT_DoExecLog ALL make DESTDIR="${CT_SYSROOT_DIR}" install
    # CT_Popd
    :
}

