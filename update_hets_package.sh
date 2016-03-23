#!/bin/bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

source "$base_dir/functions.sh"

sync_hets_repositories
bottle_all_formulas
update_all_formulas
commit_formula_changes
push_formula_changes
