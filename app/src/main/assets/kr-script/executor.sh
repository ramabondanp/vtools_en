# Parameter description
# $1 Script path
# $2 Task ID

# The specific script to be executed, passed when running executor.sh, e.g. ./executor.sh test.sh
script_path="$1"

# Define global variables
export EXECUTOR_PATH="$({EXECUTOR_PATH})"
export START_DIR="$({START_DIR})"
export TEMP_DIR="$({TEMP_DIR})"
export ANDROID_UID="$({ANDROID_UID})"
export ANDROID_SDK="$({ANDROID_SDK})"
export SDCARD_PATH="$({SDCARD_PATH})"
export BUSYBOX="$({BUSYBOX})"
export MAGISK_PATH="$({MAGISK_PATH})"
export PACKAGE_NAME="$({PACKAGE_NAME})"
export PACKAGE_VERSION_NAME="$({PACKAGE_VERSION_NAME})"
export PACKAGE_VERSION_CODE="$({PACKAGE_VERSION_CODE})"
export APP_USER_ID="$({APP_USER_ID})"

# ROOT_PERMISSION value: true or false
export ROOT_PERMISSION=$({ROOT_PERMISSION})

# Fix the issue where scripts cannot write to the default cache directory /data/local/tmp when running without root permission
export TMPDIR="$TEMP_DIR"

# Toolkit tools directory
export TOOLKIT="$({TOOLKIT})"
# Add toolkit to the application executable path
if [[ ! "$TOOLKIT" = "" ]]; then
    # export PATH="$PATH:$TOOLKIT"
    PATH="$PATH:$TOOLKIT"
fi

# Install full BusyBox functionality
if [[ -f "$TOOLKIT/kr_install_busybox.sh" ]]; then
    sh "$TOOLKIT/kr_install_busybox.sh"
fi

# Check whether a specific working directory is provided
if [[ "$START_DIR" != "" ]] && [[ -d "$START_DIR" ]]
then
    cd "$START_DIR"
fi

# Run the script
if [[ -f "$script_path" ]]; then
    chmod 755 "$script_path"
    # sh "$script_path"     # before 2019.09.02
    source "$script_path"   # after 2019.09.02
else
    echo "${script_path} is missing" 1>&2
fi
