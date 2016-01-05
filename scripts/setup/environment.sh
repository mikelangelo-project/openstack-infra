#!/bin/bash
#set -x

# production true false
# password set
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ ${SOURCE} != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

BASE_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
VAGRANT_DIR="$( dirname "$BASE_DIR" )"
ENVIRONMENT_BASE_DIR="$VAGRANT_DIR/environment"

if [ $1 ]; then
  ENV_INSTANCE=$1
else
  echo "Error: Environment number is missing"
  exit 1
fi

function setup_instance () {
  local _environment=$1
  local _environment_dir="$VAGRANT_DIR/environment/$_environment"

  if [ "$_environment" != "1" ]; then
    overide=true
    if [ -d "$_environment_dir" ] && [ "$_environment" != "1" ]; then
      read -p "Vagrant environment directory exists! Override (Y)es / (N)o - Only Switch? " choice
      case "$choice" in 
        n|N ) overide=false;;
        y|Y ) overide=true;;
        * ) overide=false;;
      esac
      #continue 
    fi
  else
    overide=false
  fi

  [ -d "$BASE_DIR/tmp" ] || mkdir "$BASE_DIR/tmp"

  if ${overide} ; then
    echo "Copy environment 1 to environment $_environment"
    cp -R "$ENVIRONMENT_BASE_DIR/1" "$_environment_dir"
    error=$((error + $?))
  else
    echo "Leave old environment directory"
  fi
  
  echo "Create new hiera vagrant_environment"

  sed -e "s/environment:.*/environment: ${_environment}/g" "$VAGRANT_DIR/files/hiera/vagrant.yaml" > "$BASE_DIR/tmp/vagrant-step1.yaml"
  error=$((error + $?))

  if [ ${error} -ne 0 ]; then
    echo "Error have occurred - leave old environment"
    exit 1
  fi

  mv  "$BASE_DIR/tmp/vagrant-step1.yaml" "$VAGRANT_DIR/files/hiera/vagrant.yaml"

  rm -rf "$BASE_DIR/tmp"

  echo "Switch current environment to $_environment"
  echo "current_environment: $_environment"     > "$VAGRANT_DIR/environment/config.yaml"
  echo "ENVIRONMENT=${_environment}"            > "$VAGRANT_DIR/environment/config.sh"
}

if [[ "$ENV_INSTANCE" =~ ^[0-9]+$ ]] && [ "$ENV_INSTANCE" -ge 1 -a "$ENV_INSTANCE" -le 5 ]; then
  setup_instance "$ENV_INSTANCE"
else
  echo "Error: Environment number must be between 1 and 5"
  exit 1
fi

exit 0
