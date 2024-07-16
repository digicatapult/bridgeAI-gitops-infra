#!/usr/bin/env bash

# sanatise environment
# check that sops is installed along with gpg
# check that the environment provided exists

# decrypt the secrets for the environment
# load into gpg the public keys for the environment from the certs folder
# re-encrypt the environment secrets

print_usage() {
  echo "Encrypts secrets for a specified cluster"
  echo ""
  echo "Usage:"
  echo "  ./scripts/encrypt-secrets.sh [ -h ] [ -a ] <cluster_name>"
  echo ""
  echo "Flags: "
  echo "  -a        Re-encrypts all secrets. You must have a valid PGP secret key in your GPG keyring for the environment for this operation to succeed"
  echo "  -h        Prints this message"
}

REENCRYPT_ALL=""
while getopts ":ah" opt; do
  case ${opt} in
    h )
      print_usage
      exit 0
      ;;
    a )
      REENCRYPT_ALL="yes"
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     echo "\n"
     print_usage
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))
CLUSTER=$1

assert_cluster() {
  local cluster=$1

  printf "Checking cluster $cluster is configured correctly..."
  if [ ! -d "./clusters/$cluster" ]; then
    echo -e "Cannot update secrets for cluster $cluster which does not exist"
    exit 1
  fi
  printf "OK\n"
}

assert_command() {
  local command=$1

  printf "Checking for presense of $command..."
  local path_to_executable=$(command -v ${command})

  if [ -z "$path_to_executable" ] ; then
    echo -e "Cannot find ${command} executable. Is it on your \$PATH?"
    exit 1
  fi
  printf "OK\n"
}

# sanity check


assert_cluster $CLUSTER
assert_command gpg
assert_command sops

# check we can decrypt secrets if we need to
if [ ! -z "$REENCRYPT_ALL" ]; then
  for filename in ./clusters/$CLUSTER/secrets/*.yaml; do
    printf "Checking if $filename is encrypted..."
    is_encrypted=$(cat $filename | egrep "^sops:$")

    if [ -z "$is_encrypted" ]; then
      printf "No encryption detected\n"
    else
      printf "Encryption detected\n"
      printf "Checking we can decrypt $filename..."
      sops --decrypt --encrypted-regex '^(data|stringData)$' $filename &> /dev/null
      sops_ret=$?

      if [ "$sops_ret" -ne "0" ]; then
        printf "NOT OK\nError decrypting file $filename. Do you have an appropriate gpg private key in your keychain?\n"
        exit 1
      fi
      printf "OK\n"
    fi
  done
fi
# load all the relevant public keys

# setup a temp directory for importing these keys into
IMPORT_DIR=$(mktemp -d -t gnugp.XXXXXXXXXX)
chmod 700 $IMPORT_DIR
for filename in ./certs/$CLUSTER/*.asc; do
  GNUPGHOME=$IMPORT_DIR gpg --import $filename &> /dev/null
done

# get the key ids as a comman separated list
PGP_KEYS=$(GNUPGHOME=$IMPORT_DIR gpg --list-keys | awk '{$1=$1};1' | egrep '^[0-9a-fA-f]{40}$' | paste -d, -s -)

# Check if we should be re-encryping everything or not
if [ -z "$REENCRYPT_ALL" ]; then
  # encrypt only unencrypted files
  for fullfile in ./clusters/$CLUSTER/secrets/*.yaml; do
    is_encrypted=$(cat $fullfile | egrep "^sops:$")
    if [ -z "$is_encrypted" ]; then
      printf "Encrypting $fullfile..."
      GNUPGHOME=$IMPORT_DIR sops --encrypt --encrypted-regex '^(data|stringData)$' \
        --pgp $PGP_KEYS --in-place $fullfile &> /dev/null
      filename=$(basename $fullfile)
      mv $fullfile $(dirname $fullfile)/${filename%%.*}.yaml
      printf "OK\n"
    else
      printf "Skipping encrypted file $fullfile\n"
    fi
  done
else
  # now re-encrypt the files
  for fullfile in ./clusters/$CLUSTER/secrets/*.yaml; do
    printf "Re-encrypting $fullfile..."

    is_encrypted=$(cat $fullfile | egrep "^sops:$")
    if [ ! -z "$is_encrypted" ]; then
      sops --decrypt --encrypted-regex '^(data|stringData)$' --in-place $fullfile &> /dev/null
    fi

    GNUPGHOME=$IMPORT_DIR sops --encrypt --encrypted-regex '^(data|stringData)$' \
      --pgp $PGP_KEYS --in-place $fullfile &> /dev/null
    filename=$(basename $fullfile)
    mv $fullfile $(dirname $fullfile)/${filename%%.*}.yaml
    printf "OK\n"
  done
fi
