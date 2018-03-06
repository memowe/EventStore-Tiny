#!/bin/sh

echo "\nModules:"
find lib -name '*.pm' | sort | xargs wc

echo "\nTests:"
find t -type f -not -path '*_demo/*' | sort | xargs wc
