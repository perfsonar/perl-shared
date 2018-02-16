# perfSONAR RPM Build Scripts

This directory contains [Vagrant](https://www.vagrantup.com) VM definitions and a set of  scripts for building RPMs, in particular RPMs for the perfSONAR perl package (though the basic processes should be able to be extended to other types of packages). These scripts live in the perl-shared repo because many of the perfSONAR components import this as a git submodule. From the submodule, these scripts can be used as a base setup for that package's build infrastructure. 

## RPM Build and Test Install Quickstart

```bash
cd rpms
vagrant up
vagrant ssh
build
exit
vagrant up ps-rpminstall-el7
vagrant ssh ps-rpminstall-el7
sudo yum install <package-name>
```

## Vagrant VMs

The *Vagrantfile* described two virtual machines: one to use for building the RPMs and another for testing installation via yum. The VMs are described below.

### ps-rpmbuild-el7 VM

The VM named ps-rpmbuild-el7 is intended to be a machine where the RPMs are built. This is the default VM, so any `vagrant` commands that do not specify a VM, will use this. 

An important feature of this VM is the */vagrant* directory. The */vagrant* is the source code directory shared with the base system. Any changes you make to the code or spec file on the base system will get reflected in the build host and vice verse. This make it very convenient for making edits to the spec file and other aspects of the code. 

You can bring up this VM with:

```
vagrant up
```

You can login to the VM with:

```
vagrant ssh
```

You can build the RPMs with the `build` command:

```
build
```

You can shutdown to the VM with:

```
vagrant halt
```

You can destroy to the VM with:

```
vagrant destroy
```

This script does a few things:

* It runs `make dist` on the source code under the */vagrant* shared directory to build the source tarball
* Builds an SRPM
* Builds the SRPM into binary RPMs using mock
* Publishes the RPMs to a you repository on the VM that can be accessed at *http://10.0.1.10/repo*

There are additional commands on this VM as detailed in the *VM Command Reference* section. Once the RPMs are build and published to the local yum repo, you can use the ps-rpminstall-el7 VM to test installation as detailed in the next section.

### ps-rpminstall-el7 VM

The VM named ps-rpminstall-el7 is used for testing the installation of RPMs created on ps-rpmbuild-el7. It is essentially a clean CentOS 7 installation with a yum repo configured to look http://10.0.1.10/repo (a.k.a ps-rpmbuild-el7). It also has the perfSONAR primary, staging and nightly repos configured by default. You can run `yum install <package-name>` to grab RPMs. As long as the RPMs on ps-rpmbuild-el7 have a higher version than anything in the other yum repos, it will install the rpms you built.

You can bring up this VM with:

```
vagrant up ps-rpminstall-el7
```

You can login to the VM with:

```
vagrant ssh ps-rpminstall-el7
```

You can shutdown to the VM with:

```
vagrant halt ps-rpminstall-el7
```

You can destroy to the VM with:

```
vagrant destroy ps-rpminstall-el7
```

## Build VM Command Reference

The build VM has a few convenience commands in the default path to help do common tasks such as build other rpms, publish rpms to the local repo and lean the build environment. All the commands are in the default PATH and there is no need to sudo (they will use sudo as needed). Commands are as follows:

* **psrpm_build_perl** - This command builds a perl package assuming the standard structure of a perfSONAR perl repo (i.e. has a `make dist` target and .spec file. It has the following arguments:
    * *PACKAGE* - Required.This argument is the name of the package. Think of it as the name of the RPM spec file without the .spec suffix. 
    * *GITREPO* - Optional. Name of the perfSONAR github repo to checkout. If not provided will just use the **/vagrant** directory.
    * *BRANCH* - Optional. The name of the branch or tag to build from git. 

* **psrpm_clean_buildenv** - Removes and recreates empty subdirectories under */home/vagrant/rpmbuild* as well as clears out */home/vagrant/mock-results/epel-7-x86_64*

* **psrpm_clean_repo** - Clears out the yum repo directory under */var/www/html/repo/*

* **psrpm_mock** - This command builds a given SRPM using mock. Only accepts one argument:
    * *SRPM* - Required. The path to the SRPM to build.

* **psrpm_publish** - Copies contents of */home/vagrant/mock-results/epel-7-x86_64* to */var/www/html/repo/* and runs `createrepo` to rebuild yum repo

    
## Creating RPM Build Environment for New Repository

The perl-shared repository is already setup, but if you want to create a similar environment for a different repository that includes the perl-shared module as a submodule, there are tools to make that easier. The basic process is as follows:

1. Import perl-shared as a gitsubmodule named **shared** (you may skip if already done):

```
git submodule add https://github.com/perfsonar/perl-shared shared
git submodule init
git submodule update
```

2. Run the `./shared/utils/setup_rpmbuildenv.sh` command. This creates a directory called *rpms* with a script called *build* that will build a package from the spec file in the directory where etup_rpmbuildenv.sh.

3. Customize the build script and add any scripts as you see fit.
