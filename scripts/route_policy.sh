#!/bin/bash
set -euo pipefail

event_name=$1
ref_type=${2:-}
github_ref=${3:-}
input_mode=${4:-}
schedule=${5:-}

run_code_checks=true
run_build=true
run_release=false
run_autofix=false
run_publisher=false
run_maintenance=false
mode="build"

if [[ "$event_name" == "pull_request" ]]; then
  :
elif [[ "$event_name" == "schedule" ]]; then
  if [[ "$schedule" == "17 3 1 * *" ]]; then
     run_maintenance=true
     mode="monthly-maintenance"
  else
     run_autofix=true
     mode="lint-fix"
  fi
elif [[ "$event_name" == "workflow_dispatch" ]]; then
  mode="${input_mode:-build}"
  if [[ "$mode" == "lint-fix" ]]; then
     run_autofix=true
  elif [[ "$mode" == "publish-tag" ]]; then
     if [[ "$ref_type" == "tag" && "$github_ref" == refs/tags/v* ]]; then
        run_code_checks=false
        run_build=true
        run_publisher=true
     else
        echo "Error: publish-tag mode requires a v* tag context. Found: $github_ref" >&2
        exit 1
     fi
  elif [[ "$mode" == release-* ]]; then
     run_build=true
     run_release=true
  elif [[ "$mode" == "monthly-maintenance" ]]; then
     run_maintenance=true
  fi
elif [[ "$event_name" == "push" && "$ref_type" == "tag" && "$github_ref" == refs/tags/v* ]]; then
   run_publisher=true
fi

echo "run_code_checks=$run_code_checks"
echo "run_build=$run_build"
echo "run_release=$run_release"
echo "run_autofix=$run_autofix"
echo "run_publisher=$run_publisher"
echo "run_maintenance=$run_maintenance"
echo "mode=$mode"
