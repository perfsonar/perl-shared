# perfSONAR Shared PERL Libraries and Tools

This repository contains libraries and tools shared amongst perfSONAR components written in PERL. It is most often included as a git submodule in those repositories. 

## What's in this repository?
This repository contains the following PERL libraries:
* Client libraries to the lookup service and measurement archive
* Configuration file utilities
* Regular testing tool parsers and registration modules
* Logging utilities
* Utilities for handling DNS, IP addresses, NTP, GeoLookups, HTTP and other common protocols
* Utilties for configuring, starting and stopping operating system services

It also contains the following command-line tools:
* Tools for finding missing dependencies and unpackaged files (see the *utils* directory)
* Tools for critiquing PERL code (see the *docs* directory)

## Using this repository as a git submodule
You may use this repository as a git submodule in another project. You may then do things like symbolic link to the PERL libraries or have easy access to the packaging tools. Run the following to create the submodule in a directory called *shared* in your repository :

```bash
git submodule add https://github.com/perfsonar/perl-shared shared
```

If you want to use the PERL libraries from this submodule in your project, you may create symbolic links in the directory where you keep your own PERL modules. For example, if the PERL modules in my repository generally live under the *lib* directory, then I can run the following commands to link to the *perfSONAR_PS::Utils::DNS* module:

```bash
mkdir -p lib/perfSONAR_PS/Utils/
cd lib/perfSONAR_PS/Utils/
ln -s ../../../shared/lib/perfSONAR_PS/Utils/DNS.pm DNS.pm
```

If a change is made to this repository that you would like to pull into a repository referencing it as a submodule, you will need to run a few extra commands in that repository. Remember that by default a submodule points at a specific commit. To update which commit it points to run the following in the repository with the submodude reference:

```bash
git submodule foreach git pull origin master
git commit -a -m "Updating to latest shared"
git push
```

It's also worth noting that any clones of your repository will not download the submodule unless you include the `--recursive` option. Example:

```bash
git clone --recursive https://github.com/perfsonar/myproject.git
```

If you forget the `--recursive` option you can fetch the submodule contents as follows:

```bash
git submodule init
git submodule update
```

For more on submodules see the [GitHub submodule documentation](http://git-scm.com/book/en/v2/Git-Tools-Submodules).

## Building RPMs

You can build the RPMs with the following commands:

```bash
cd rpms
vagrant up
vagrant ssh
build
```

For more information on building and testing RPMs see rpms/RPM_README.md.
