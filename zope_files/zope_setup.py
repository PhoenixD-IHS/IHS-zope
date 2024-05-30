import os
import uuid

import ZODB
import transaction
from Products.PluggableAuthService.PluggableAuthService import (
    PluggableAuthService,
)
from Products.ZODBMountPoint.MountedObject import manage_addMounts

# add temp_folder
if "temp_folder" not in dir(app):
    manage_addMounts(app, ["/temp_folder"])
    transaction.commit()

# add Select
if "Select" not in dir(app):
    app.manage_importObject("Select.zexp", set_owner=1)
    transaction.commit()

# add instances
if "ihs" not in dir(app):
    manage_addMounts(app, ["/ihs"])
    transaction.commit()

# replace index_html (redirect to Select/)
app.manage_delObjects(["index_html"])
app.manage_importObject("index_html.zexp", set_owner=1)
transaction.commit()

if not isinstance(app["acl_users"], PluggableAuthService):
    if "acl_temp" in dir(app):
        app.manage_delObjects("acl_temp")
        transaction.commit()

    # create PAS acl_users in temp folder
    folder = app.manage_addProduct["OFS"].manage_addFolder("acl_temp")
    app.acl_temp.manage_addProduct[
        "PluggableAuthService"
    ].addPluggableAuthService()
    PAS = app.acl_temp.acl_users
    transaction.commit()


    # add content to acl_users
    PAS.manage_addProduct["PluggableAuthService"].addZODBUserManager(
        "users", title="User Management"
    )
    PAS.manage_addProduct["PluggableAuthService"].addZODBRoleManager(
        "roles", title="Role Management"
    )
    PAS.manage_addProduct["PluggableAuthService"].addHTTPBasicAuthHelper(
        "httpAuth", title="HTTP Basic Auth"
    )
    PAS.manage_addProduct["PluggableAuthService"].addCookieAuthHelper(
        "cookieAuth", title="Cookie Auth", cookie_name="IHSauth"
    )

    # activate interfaces
    PAS.users.manage_activateInterfaces(
        ["IAuthenticationPlugin", "IUserEnumerationPlugin", "IUserAdderPlugin"]
    )
    PAS.roles.manage_activateInterfaces(
        ["IRolesPlugin", "IRoleEnumerationPlugin", "IRoleAssignerPlugin"]
    )
    PAS.httpAuth.manage_activateInterfaces(
        ["IExtractionPlugin", "IChallengePlugin"]
    )
    PAS.cookieAuth.manage_activateInterfaces(["IExtractionPlugin"])

    # make sure roles Manager and Owner are defined
    for role in ["Manager", "Owner"]:
        if len(PAS.roles.enumerateRoles(role, exact_match=True)) == 0:
            PAS.roles.manage_addRole(role, None, "")

    # add user root with role Manager
    rand_pass = str(uuid.uuid4()) + str(uuid.uuid4())
    PAS.users.manage_addUser(
        "root",
        "root",
        rand_pass,
        rand_pass
    )
    PAS.roles.manage_assignRoleToPrincipals("Manager", ["root"], None)
    transaction.commit()

    # replace zope acl_users with PAS
    app.manage_delObjects("acl_users")
    app.manage_pasteObjects(app.acl_temp.manage_cutObjects("acl_users"))
    transaction.commit()
    app.manage_delObjects("acl_temp")
    transaction.commit()
