from Products.ZODBMountPoint.MountedObject import manage_addMounts
import transaction

# add temp_folder
if "temp_folder" not in dir(app):
    manage_addMounts(app, ["/temp_folder"])
    transaction.commit()

# add Select folder
if "Select" not in dir(app):
    app.manage_importObject("Select.zexp", set_owner=1)
    transaction.commit()

app.manage_delObjects(["index_html"])
app.manage_importObject("index_html.zexp", set_owner=1)
transaction.commit()
