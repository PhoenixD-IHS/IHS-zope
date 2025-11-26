#!/bin/bash

if [ ! -d /usr/local/share/ihs/ihs-instances/blob ]; then
    cp -r /usr/local/share/ihs/ihs-instances.templates/blob /usr/local/share/ihs/ihs-instances/
fi

if [ ! -d /usr/local/share/ihs/ihs-instances/fs ]; then
    cp -r /usr/local/share/ihs/ihs-instances.templates/fs /usr/local/share/ihs/ihs-instances/
fi

# set root password
/usr/local/share/ihs/bin/zopeinstance run /usr/local/share/ihs/set_zope_password.py

# start zope instance
/usr/local/share/ihs/bin/zopeinstance start
exec "$@"
