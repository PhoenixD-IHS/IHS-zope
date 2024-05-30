import os

import transaction


PAS = app.acl_users
if "root" not in PAS.users.listUserIds():
    PAS.users.manage_addUser(
        "root",
        "root",
        os.environ["ZOPE_ROOT_PASSWORD"],
        os.environ["ZOPE_ROOT_PASSWORD"],
    )

PAS.users.manage_updateUserPassword(
        "root",
        os.environ["ZOPE_ROOT_PASSWORD"],
        os.environ["ZOPE_ROOT_PASSWORD"],
    )
transaction.commit()
