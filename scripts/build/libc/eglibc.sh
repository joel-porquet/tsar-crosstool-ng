# eglibc build functions (initially by Thomas JOURDAN).

# Add the definitions common to glibc and eglibc
#   do_libc_extract
#   do_libc_start_files
#   do_libc
#   do_libc_finish
#   do_libc_add_ons_list
#   do_libc_min_kernel_config
. "${CT_LIB_DIR}/scripts/build/libc/glibc-eglibc.sh-common"

# Download eglibc repository
do_eglibc_get() {
    CT_HasOrAbort svn

    case "${CT_LIBC_VERSION}" in
        trunk)  svn_url="svn://svn.eglibc.org/trunk";;
        *)      svn_url="svn://svn.eglibc.org/branches/eglibc-${CT_LIBC_VERSION}";;
    esac

    case "${CT_EGLIBC_CHECKOUT}" in
        y)  svn_action="checkout";;
        *)  svn_action="export --force";;
    esac

    CT_DoExecLog ALL svn ${svn_action} -r "${CT_EGLIBC_REVISION:-HEAD}" "${svn_url}" "$(pwd)"

    # Compress eglibc
    CT_DoExecLog ALL mv libc "eglibc-${CT_LIBC_VERSION}"
    CT_DoExecLog ALL tar cjf "eglibc-${CT_LIBC_VERSION}.tar.bz2" "eglibc-${CT_LIBC_VERSION}"

    # Compress linuxthreads, localedef and ports
    # Assign them the name the way ct-ng like it
    for addon in linuxthreads localedef ports; do
        CT_DoExecLog ALL mv "${addon}" "eglibc-${addon}-${CT_LIBC_VERSION}"
        CT_DoExecLog ALL tar cjf "eglibc-${addon}-${CT_LIBC_VERSION}.tar.bz2" "eglibc-${addon}-${CT_LIBC_VERSION}"
    done
}

# Download glibc
do_libc_get() {
    # eglibc is only available through subversion, there are no
    # snapshots available. Moreover, addons will be downloaded
    # simultaneously.

    # build filename
    eglibc="eglibc-${CT_LIBC_VERSION}.tar.bz2"
    eglibc_linuxthreads="${CT_LIBC}-linuxthreads-${CT_LIBC_VERSION}.tar.bz2"
    eglibc_localedef="${CT_LIBC}-localedef-${CT_LIBC_VERSION}.tar.bz2"
    eglibc_ports="${CT_LIBC}-ports-${CT_LIBC_VERSION}.tar.bz2"

    # Check if every tarballs are already present
    if [    -f "${CT_TARBALLS_DIR}/${eglibc}"                   \
         -a -f "${CT_TARBALLS_DIR}/${eglibc_linuxthreads}"      \
         -a -f "${CT_TARBALLS_DIR}/${eglibc_localedef}"         \
         -a -f "${CT_TARBALLS_DIR}/${eglibc_ports}"             \
       ]; then
        CT_DoLog DEBUG "Already have 'eglibc-${CT_LIBC_VERSION}'"
        return 0
    fi

    if [    -f "${CT_LOCAL_TARBALLS_DIR}/${eglibc}"                 \
         -a -f "${CT_LOCAL_TARBALLS_DIR}/${eglibc_linuxthreads}"    \
         -a -f "${CT_LOCAL_TARBALLS_DIR}/${eglibc_localedef}"       \
         -a -f "${CT_LOCAL_TARBALLS_DIR}/${eglibc_ports}"           \
         -a "${CT_FORCE_DOWNLOAD}" != "y"                           \
       ]; then
        CT_DoLog DEBUG "Got 'eglibc-${CT_LIBC_VERSION}' from local storage"
        for file in ${eglibc} ${eglibc_linuxthreads} ${eglibc_localedef} ${eglibc_ports}; do
            CT_DoExecLog ALL ln -s "${CT_LOCAL_TARBALLS_DIR}/${file}" "${CT_TARBALLS_DIR}/${file}"
        done
        return 0
    fi

    # Not found locally, try from the network
    CT_DoLog EXTRA "Retrieving 'eglibc-${CT_LIBC_VERSION}'"

    CT_MktempDir tmp_dir
    CT_Pushd "${tmp_dir}"

    do_eglibc_get
    CT_DoLog DEBUG "Moving 'eglibc-${CT_LIBC_VERSION}' to tarball directory"
    for file in ${eglibc} ${eglibc_linuxthreads} ${eglibc_localedef} ${eglibc_ports}; do
        CT_DoExecLog ALL mv -f "${file}" "${CT_TARBALLS_DIR}"
    done

    CT_Popd

    # Remove source files
    CT_DoExecLog ALL rm -rf "${tmp_dir}"

    if [ "${CT_SAVE_TARBALLS}" = "y" ]; then
        CT_DoLog EXTRA "Saving 'eglibc-${CT_LIBC_VERSION}' to local storage"
        for file in ${eglibc} ${eglibc_linuxthreads} ${eglibc_localedef} ${eglibc_ports}; do
            CT_DoExecLog ALL mv -f "${CT_TARBALLS_DIR}/${file}" "${CT_LOCAL_TARBALLS_DIR}"
            CT_DoExecLog ALL ln -s "${CT_LOCAL_TARBALLS_DIR}/${file}" "${CT_TARBALLS_DIR}/${file}"
        done
    fi

    return 0
}

# Copy user provided eglibc configuration file if provided
do_libc_check_config() {
    if [ "${CT_EGLIBC_CUSTOM_CONFIG}" != "y" ]; then
        return 0
    fi

    CT_DoStep INFO "Checking C library configuration"

    CT_TestOrAbort "You did not provide an eglibc config file!" \
        -n "${CT_EGLIBC_OPTION_GROUPS_FILE}" -a \
        -f "${CT_EGLIBC_OPTION_GROUPS_FILE}"

    CT_DoExecLog ALL cp "${CT_EGLIBC_OPTION_GROUPS_FILE}" "${CT_CONFIG_DIR}/eglibc.config"

    # NSS configuration
    if grep -E '^OPTION_EGLIBC_NSSWITCH[[:space:]]*=[[:space:]]*n' "${CT_EGLIBC_OPTION_GROUPS_FILE}" >/dev/null 2>&1; then
        CT_DoLog DEBUG "Using fixed-configuration nsswitch facility"

        if [ "${CT_EGLIBC_BUNDLED_NSS_CONFIG}" = "y" ]; then
            nss_config="${CT_SRC_DIR}/eglibc-${CT_LIBC_VERSION}/nss/fixed-nsswitch.conf"
        else
            nss_config="${CT_EGLIBC_NSS_CONFIG_FILE}"
        fi
        CT_TestOrAbort "NSS config file not found!" -n "${nss_config}" -a -f "${nss_config}"

        CT_DoExecLog ALL cp "${nss_config}" "${CT_CONFIG_DIR}/nsswitch.config"
        echo "OPTION_EGLIBC_NSSWITCH_FIXED_CONFIG = ${CT_CONFIG_DIR}/nsswitch.config" \
            >> "${CT_CONFIG_DIR}/eglibc.config"

        if [ "${CT_EGLIBC_BUNDLED_NSS_FUNCTIONS}" = "y" ]; then
            nss_functions="${CT_SRC_DIR}/eglibc-${CT_LIBC_VERSION}/nss/fixed-nsswitch.functions"
        else
            nss_functions="${CT_EGLIBC_NSS_FUNCTIONS_FILE}"
        fi
        CT_TestOrAbort "NSS functions file not found!" -n "${nss_functions}" -a -f "${nss_functions}"

        CT_DoExecLog ALL cp "${nss_functions}" "${CT_CONFIG_DIR}/nsswitch.functions"
        echo "OPTION_EGLIBC_NSSWITCH_FIXED_FUNCTIONS = ${CT_CONFIG_DIR}/nsswitch.functions" \
            >> "${CT_CONFIG_DIR}/eglibc.config"
    else
        CT_DoLog DEBUG "Using full-blown nsswitch facility"
    fi

    CT_EndStep
}
