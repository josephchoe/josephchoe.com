#!/usr/bin/env bash

set -e

echo "Removing gems directory..."
rm -rf gems
echo "Removing vendor directory..."
rm -rf vendor
echo "Removing .bundle directory..."
rm -rf .bundle
echo "Removing Gemfile.lock file..."
rm -f Gemfile.lock
echo

if [ -z ${POSTURE+x} ]; then
  echo "(POSTURE is not set. Using \"operational\" by default.)"
  posture="operational"
else
  posture=$POSTURE
fi

echo
echo "Installing gems locally (posture: $posture)"
echo '= = ='

cmd="bundle install --standalone --path=./gems"

if [ operational == "$posture" ]; then
  cmd="$cmd --without=development:test"
fi

echo $cmd
($cmd)

echo '- - -'
echo '(done)'
echo
