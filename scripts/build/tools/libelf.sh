# Build script for libelf

is_enabled="${CT_LIBELF}"

do_print_filename() {
    [ "{CT_LIBELF}" = "y" ] || return 0
    echo "libelf-${CT_LIBELF_VERSION}"
}

do_tools_libelf_get() {
    # The server hosting libelf will return an "HTTP 300 : Multiple Choices"
    # error code if we try to download a file that does not exists there.
    # So we have to request the file with an explicit extension.
    CT_GetFile "libelf-${CT_LIBELF_VERSION}" .tar.gz http://www.mr511.de/software/
}

do_tools_libelf_extract() {
    CT_ExtractAndPatch "libelf-${CT_LIBELF_VERSION}"
}

do_tools_libelf_build() {
    CT_DoStep INFO "Installing libelf"
    mkdir -p "${CT_BUILD_DIR}/build-libelf"
    CT_Pushd "${CT_BUILD_DIR}/build-libelf"

    CT_DoLog EXTRA "Configuring libelf"
    CC="${CT_TARGET}-gcc"                                   \
    "${CT_SRC_DIR}/libelf-${CT_LIBELF_VERSION}/configure"   \
        --build=${CT_BUILD}                                 \
        --host=${CT_TARGET}                                 \
        --target=${CT_TARGET}                               \
        --prefix=/usr                                       \
        --enable-compat                                     \
        --enable-elf64                                      \
        --enable-shared                                     \
        --enable-extended-format                            \
        --enable-static                                     2>&1 |CT_DoLog ALL

    CT_DoLog EXTRA "Building libelf"
    make    2>&1 |CT_DoLog ALL

    CT_DoLog EXTRA "Installing libelf"
    make instroot="${CT_SYSROOT_DIR}" install   2>&1 |CT_DoLog ALL

    CT_Popd
    CT_EndStep
}

