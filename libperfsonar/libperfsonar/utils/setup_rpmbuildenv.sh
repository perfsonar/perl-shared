#!/bin/bash

##get package name
PACKAGE=$(ls | grep \.spec | head -n 1 | sed s/\.spec//)
if [ -z "$PACKAGE" ]; then
    echo "Unable to determine package. Make sure working directory has a .spec file"
    exit 1
fi

## create directory
mkdir -p rpms/scripts
cd rpms

## symlink build scripts from shared
ln -s ../shared/rpms/Vagrantfile ./Vagrantfile
cd scripts
ln -s ../../shared/rpms/scripts/psrpm* ./

## create build script
cat > build << EOF
#!/bin/bash

psrpm_build_perl $PACKAGE

EOF

## create buibuild_sharedd script
cat > build_shared << EOF
#!/bin/bash

psrpm_build_perl libperfsonar perl-shared

EOF