#!/bin/bash

# Copyright (c) 2025 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

echo "Installing SPEC2017..."

# install build-essential (gcc and g++ included) and gfortran
add-apt-repository universe
apt update
apt install -y gfortran 
apt install -y gdb

# mount disk image
cd /home/gem5
mount -t iso9660 -o ro,exec,loop cpu2017-1.1.0.iso /mnt
cd /mnt
echo "yes" | bash install.sh -d /home/gem5/spec2017

cd /home/gem5/spec2017
source shrc
echo 'yes' | bash install.sh

# Update the SPEC2017 to latest version
echo y | runcpu --update

# Copy the config file
case "$ISA" in
  arm64)
    CONFIG="Example-gcc-linux-aarch64.cfg"
    ;;
  x86)
    CONFIG="Example-gcc-linux-x86.cfg"
    ;;
esac
cp "config/$CONFIG" "config/myconfig.${ISA}.cfg"

# Some fixes are needed in the configuration script
if [ "${ISA}" = "arm64" ]; then
  sed -i \
    's/^#%define GCCge10/%define GCCge10/' \
    config/myconfig.arm64.cfg
fi

# Install rate benchmarks
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=build intrate --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=runsetup intrate --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=build fprate --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=runsetup fprate --tuning=base

# Install speed benchmarks
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=build intspeed --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=runsetup intspeed --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=build fpspeed --tuning=base
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir=/usr --action=runsetup fpspeed --tuning=base

# Add permissions to avoid permission denied error for "/result/lock.CPU2026"
chmod -R 777 /home/gem5/spec2017/*  

# the above building process will produce a large log file
# this command removes the log files to avoid copying out large files unnecessarily
rm -f /home/gem5/spec2017/result/*

echo "Done installing SPEC2017."