#!/bin/bash

. /init_couchdb.sh
touch /initialized.txt
exec tail -f /dev/null
