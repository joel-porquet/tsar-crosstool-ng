#!/bin/bash

# This script is responsible for saving the current configuration into a
# sample to be used later on as a pre-configured target.

# What we need to save:
#  - the .config file
#  - the uClibc .config file if uClibc selected
#  - info about who reported the sample

# We'll need the stdout later, save it
exec 7>&1

. "${CT_LIB_DIR}/scripts/functions"

# Don't care about any log file
exec >/dev/null
rm -f "${tmp_log_file}"

# Parse the configuration file
CT_TestOrAbort "Configuration file not found. Please create one." -f .config
. .config

# Do not use a progress bar
unset CT_LOG_PROGRESS_BAR

# Parse architecture-specific functions
. "${CT_LIB_DIR}/scripts/build/arch/${CT_ARCH}.sh"

# Target tuple: CT_TARGET needs a little love:
CT_DoBuildTargetTuple

# Kludge: if any of the config options needs either CT_TARGET or CT_TOP_DIR,
# re-parse them:
. .config

# Override log options
unset CT_LOG_PROGRESS_BAR CT_LOG_ERROR CT_LOG_INFO CT_LOG_EXTRA CT_LOG_DEBUG LOG_ALL
CT_LOG_WARN=y
CT_LOG_LEVEL_MAX="WARN"

# Create the sample directory
if [ ! -d "samples/${CT_TARGET}" ]; then
    mkdir -p "samples/${CT_TARGET}"
fi

# Save the crosstool-NG config file
sed -r -e 's|^(CT_PREFIX_DIR)=.*|\1="${HOME}/x-tools/${CT_TARGET}"|;'       \
       -e 's|^# CT_LOG_TO_FILE is not set$|CT_LOG_TO_FILE=y|;'              \
       -e 's|^# CT_LOG_FILE_COMPRESS is not set$|CT_LOG_FILE_COMPRESS=y|;'  \
       -e 's|^(CT_LOCAL_TARBALLS_DIR)=.*|\1="${HOME}/src"|;'                \
    <.config                                                                \
    >"samples/${CT_TARGET}/crosstool.config"

# Function to copy a file to the sample directory
# Needed in case the file is already there (think of a previously available sample)
# Usage: CT_DoAddFileToSample <source> <dest>
CT_DoAddFileToSample() {
    source="$1"
    dest="$2"
    inode_s=$(ls -i "${source}" |awk '{ print $1; }')
    inode_d=$(ls -i "${dest}" 2>/dev/null |awk '{ print $1; }' || true)
    if [ "${inode_s}" != "${inode_d}" ]; then
        cp "${source}" "${dest}"
    fi
}

if [ "${CT_TOP_DIR}" = "${CT_LIB_DIR}" ]; then
    samp_top_dir="\${CT_LIB_DIR}"
else
    samp_top_dir="\${CT_TOP_DIR}"
fi

# Save the uClibc .config file
if [ -n "${CT_LIBC_UCLIBC_CONFIG_FILE}" ]; then
    # We save the file, and then point the saved sample to this file
    CT_DoAddFileToSample "${CT_LIBC_UCLIBC_CONFIG_FILE}" "samples/${CT_TARGET}/${CT_LIBC}-${CT_LIBC_VERSION}.config"
    sed -r -i -e 's|^(CT_LIBC_UCLIBC_CONFIG_FILE=).+$|\1"'"${samp_top_dir}"'/samples/${CT_TARGET}/${CT_LIBC}-${CT_LIBC_VERSION}.config"|;' \
        "samples/${CT_TARGET}/crosstool.config"
else
    # remove any dangling files
    for f in "samples/${CT_TARGET}/${CT_LIBC}-"*.config; do
        if [ -f "${f}" ]; then rm -f "${f}"; fi
    done
fi

# Restore stdout now, to be interactive
exec >&7

# Fill-in the reported-by info
[ -f "samples/${CT_TARGET}/reported.by" ] && . "samples/${CT_TARGET}/reported.by"
old_name="${reporter_name}"
old_url="${reporter_url}"
read -p "Reporter name [${reporter_name}]: " reporter_name
read -p "Reporter URL [${reporter_url}]: " reporter_url
if [ -n "${reporter_comment}" ]; then
  echo "Old comment if you need to copy-paste:"
  printf "${reporter_comment}"
fi
echo "Reporter comment (Ctrl-D to finish):"
reporter_comment=$(cat)

( echo "reporter_name=\"${reporter_name:=${old_name}}\""
  echo "reporter_url=\"${reporter_url:=${old_url}}\""
  printf "reporter_comment=\"${reporter_comment}\"\n"
) >"samples/${CT_TARGET}/reported.by"
