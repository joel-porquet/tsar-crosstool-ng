# Compute TSAR-specific values

CT_DoArchTupleValues() {
    # CT_ARCH is tsar but we want binutils and gcc to actually receive mipsel
    CT_TARGET_ARCH="mipsel"

    # override ct default (ie "-mlittle-endian")
    CT_ARCH_ENDIAN_CFLAGS="-EL"

    # override arch
    CT_ARCH_ARCH_CFLAG="-march=mips32"
    CT_ARCH_WITH_ARCH="--with-arch=mips32"

    # override ABI flags
    CT_ARCH_ABI_CFLAG="-mabi=32"
    CT_ARCH_WITH_ABI="--with-abi=32"
}
