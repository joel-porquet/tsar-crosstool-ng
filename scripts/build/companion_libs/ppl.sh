# This file adds the functions to build the PPL library
# Copyright 2009 Yann E. MORIN
# Licensed under the GPL v2. See COPYING in the root of this package

do_ppl_get() { :; }
do_ppl_extract() { :; }
do_ppl() { :; }
do_ppl_target() { :; }

# Overide functions depending on configuration
if [ "${CT_PPL_CLOOG}" = "y" ]; then

# Download PPL
do_ppl_get() {
    CT_GetFile "ppl-${CT_PPL_VERSION}"                                      \
        http://www.cs.unipr.it/ppl/Download/ftp/releases/${CT_PPL_VERSION}  \
        ftp://ftp.cs.unipr.it/pub/ppl/releases/${CT_PPL_VERSION}
}

# Extract PPL
do_ppl_extract() {
    CT_Extract "ppl-${CT_PPL_VERSION}"
    CT_Patch "ppl-${CT_PPL_VERSION}"
}

do_ppl() {
    mkdir -p "${CT_BUILD_DIR}/build-ppl"
    cd "${CT_BUILD_DIR}/build-ppl"

    CT_DoStep INFO "Installing PPL"

    CT_DoLog EXTRA "Configuring PPL"
    CFLAGS="${CT_CFLAGS_FOR_HOST}"                  \
    CT_DoExecLog ALL                                \
    "${CT_SRC_DIR}/ppl-${CT_PPL_VERSION}/configure" \
        --build=${CT_BUILD}                         \
        --host=${CT_HOST}                           \
        --prefix="${CT_PREFIX_DIR}"                 \
        --with-libgmp-prefix="${CT_PREFIX_DIR}"     \
        --with-libgmpxx-prefix="${CT_PREFIX_DIR}"   \
        --disable-shared                            \
        --enable-static                             \
        --disable-debugging                         \
        --disable-assertions                        \
        --disable-ppl_lcdd                          \
        --disable-ppl_lpsol

    # Maybe-options:
    # --enable-interfaces=...
    # --enable-optimization=speed  or sspeed (yes, with 2 's')

    CT_DoLog EXTRA "Building PPL"
    CT_DoExecLog ALL make ${PARALLELMFLAGS}

    if [ "${CT_PPL_CHECK}" = "y" ]; then
        CT_DoLog EXTRA "Checking PPL"
        CT_DoExecLog ALL make ${PARALLELMFLAGS} -s check
    fi

    CT_DoLog EXTRA "Installing PPL"
    CT_DoExecLog ALL make install

    CT_EndStep
}

fi # CT_PPL_CLOOG
