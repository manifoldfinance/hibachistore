#!/bin/bash
echo "==> Conformace Check.."
./node_modules/.bin/prettier --write contracts/**/*.sol
