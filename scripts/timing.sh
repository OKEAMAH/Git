#!/bin/sh
command time -ao /tmp/make_log -f "%E [$*]" sh "$@"
