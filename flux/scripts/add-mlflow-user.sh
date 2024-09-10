#!/bin/bash
set -euo pipefail
MLFLOW_CREDENTIALS_FILE="$HOME/.mlflow/credentials"
MLFLOW_TRACKING_PASSWORD="${MLFLOW_TRACKING_PASSWORD:-}"
MLFLOW_TRACKING_USERNAME="${MLFLOW_TRACKING_USERNAME:-}"

MLFLOW_TRACKING_URI=""  # dc-mlops.co.uk

TARGET_USERNAME=
TARGET_PASSWORD=
ADMIN_STATUS="${ADMIN_STATUS:-false}"

init_env() {
    MLFLOW_API_URI="https://${MLFLOW_TRACKING_URI}/api/2.0/mlflow"

    # Ensure directory exists
    mkdir -p $(dirname ${MLFLOW_CREDENTIALS_FILE})

    # Create credentials file
    cat <<EOF > ${MLFLOW_CREDENTIALS_FILE}
[mlflow]
mlflow_tracking_username = ${MLFLOW_TRACKING_USERNAME}
mlflow_tracking_password = ${MLFLOW_TRACKING_PASSWORD}
EOF

    # Construct the curl arguments with the password included
    CURL_EXTRA_ARGS=(
        -u "${MLFLOW_TRACKING_USERNAME}:${MLFLOW_TRACKING_PASSWORD}"
        -H "Accept: application/json"
        -H "Content-Type: application/json"
        -d "{\"username\":\"${TARGET_USERNAME}\",\"password\":\"${TARGET_PASSWORD}\",\"is_admin\":${ADMIN_STATUS}}"
    )
}

post_new_user() {
    curl -w "%{HTTP_CODE} returned by server\n" \
        -L "${MLFLOW_API_URI}/users/create" \
        -X POST "${CURL_EXTRA_ARGS[@]}" --fail-with-body
}

patch_new_admin() {
    curl -s -o /dev/null -w "%{HTTP_CODE} returned by server\n" \
        -L "${MLFLOW_API_URI}/users/update-admin" \
        -X PATCH "${CURL_EXTRA_ARGS[@]}" --fail-with-body
}

err_msg() {
    echo "error: $@"
    exit 1
}

print_options() {
    cat <<EOF
This script will create a new MLFlow user using any existing administrator credentials found either within the current shell or the default location for MLFlow credentials: ~/.mlflow/credentials.

MLFLOW_TRACKING_USERNAME and MLFLOW_TRACKING_PASSWORD are required variables, as mentioned above.

They can be exported with the following:
export MLFLOW_TRACKING_USERNAME=<mlflow_admin_username>
export MLFLOW_TRACKING_PASSWORD=<mlflow_admin_password>

If a target username exists, but doesn't have administrator privileges associated with the account, the script can also be used to promote them.

Usage:
./create-mlflow-user.sh [ -h ] [ -tupa ]

Options:
-t    Set the target domain or tracking URI, e.g. dc-mlops.co.uk
-u    Set the username, e.g. "username" without quotes
-p    Set the user's password, e.g. "password" without quotes
-a    Set administrator privileges for the user; defaults to "false".

Flags:
-h    Print this help message."
EOF
}

while getopts ":t:u:p:a:h" opt; do
    case ${opt} in
        h )
            print_options
            exit 0
            ;;
        t )
            MLFLOW_TRACKING_URI=${OPTARG}
            ;;
        u )
            TARGET_USERNAME=${OPTARG}
            ;;
        p )
            TARGET_PASSWORD=${OPTARG}
            ;;
        a )
            ADMIN_STATUS=${OPTARG}
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            echo "\n"
            print_options
            exit 1
            ;;
    esac
done

init_env

# Check the current shell
if [ -z "${MLFLOW_TRACKING_USERNAME}" ] || \
    [ -z "${MLFLOW_TRACKING_PASSWORD}" ]; then
    echo "warning: no MLFlow credentials were found in the shell"

    # Check for existing INI files
    if [ -f "${MLFLOW_CREDENTIALS_FILE}" ]; then
        credentials=$(cat "${MLFLOW_CREDENTIALS_FILE}")
        MLFLOW_TRACKING_USERNAME=$(echo "${credentials}" | awk -F "=" '/mlflow_tracking_username/ {print $2}' -)
        MLFLOW_TRACKING_PASSWORD=$(echo "${credentials}" | awk -F "=" '/mlflow_tracking_password/ {print $2}' -)
    else
        echo "warning: no MLFlow credentials were found in ~/.mlflow"
    fi
    err_msg "no admin credentials were found; exiting"
elif [ -z "${MLFLOW_TRACKING_URI}" ]; then
    err_msg "no domain was found; exiting"
else
    echo "info: admin credentials found"
    if [ -n "${TARGET_USERNAME}" ] && [ -n "${TARGET_PASSWORD}" ]; then
        # Create the target
        post_new_user || \
            err_msg "post request failed with HTTP code >= 400"

        if [ "${ADMIN_STATUS}" == "true" ]; then
            # Promote the target
            patch_new_admin || \
                err_msg "patch request failed with HTTP code >= 400"
        fi
    else
        err_msg "no new user details were supplied; exiting"
    fi
fi
