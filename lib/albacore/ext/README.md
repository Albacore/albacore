# Folder: ext

The `ext` folder contains Albacore extensions. Write code in this folder
according to the following conventions:

 * doing `require 'albacore/ext/extension_name'` should add the extensions
   of `extension_name` to the current albacore application. This means
   that there should be no further requirement to call into albacore
   after such a `require` call has been done.
 * prefer to do extensions via `Albacore.subscribe` over extending
   at the call-site, monkey-patching, or including the extended in
   other class/module/object instances.