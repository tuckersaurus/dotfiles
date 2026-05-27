#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

echo "post-start.sh ..."

echo "     ...complete!"
