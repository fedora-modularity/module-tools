# module-tools / module-builder

The Vagrantfile in this folder can be used to provision and run a virtual
machine to let users build modules locally.

## Configuration

To avoid having to tweak files which are under source control (like the
Vagrantfile itself) to adapt the box to the local situation, configuration
parameters can be set in the file `config.yaml`. All parameters are described
and their default values are defined in `defaults.yaml`.

### Accessing local folders from the box

In order to allow easy access to the necessary files from the local host system
and the box, two host folders are exported via NFS to the box:

* A folder containing module repositories. Unless configured otherwise (which
  you should do), this is set to `modules` in this folder on the host. It gets
  mounted to `~vagrant/modules` in the box. The configuration key for this is
  `configuration/folders/modules`.

* A folder pointing to storage in which to build modules. This defaults to
  `modulebuild` in the home directory (which is the default value used by the
  module build service) and gets mounted to `~vagrant/modulebuild` in the box.
  The configuration key for this is `configuration/folders/modulebuild`.
