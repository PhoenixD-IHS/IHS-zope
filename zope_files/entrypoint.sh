#!/bin/bash

# set root password
/usr/local/share/ihs/bin/zopeinstance run /usr/local/share/ihs/set_zope_password.py

# start zope instance
/usr/local/share/ihs/bin/zopeinstance start
exec "$@"
