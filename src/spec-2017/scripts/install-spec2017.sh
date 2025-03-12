# Copyright (c) 2020 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

# install build-essential (gcc and g++ included) and gfortran
apt-get install -y gfortran

# mount the SPEC2017 ISO file and install SPEC to the disk image
mkdir /home/gem5/mnt
mount -o loop -t iso9660 /home/gem5/cpu2017-1.1.0.iso /home/gem5/mnt
mkdir /home/gem5/spec2017
if [ "${ISA}" = "x86" ]; then
   echo "y" | /home/gem5/mnt/install.sh -d /home/gem5/spec2017 -u linux-x86_64
fi
cd /home/gem5/spec2017
. /home/gem5/mnt/shrc
umount /home/gem5/mnt
rm -f /home/gem5/cpu2017-1.1.0.iso

# use the example config as the template
if [ "${ISA}" = "x86" ]; then
   cp /home/gem5/spec2017/config/Example-gcc-linux-x86.cfg /home/gem5/spec2017/config/myconfig.${ISA}.cfg
fi

# use sed command to remove the march=native flag when compiling
# this is necessary as the packer script runs in kvm mode, so the details of the CPU will be that of the host CPU
# the -march=native flag is removed to avoid compiling instructions that gem5 does not support
# finetuning flags should be manually added
sed -i "s/-march=native//g" /home/gem5/spec2017/config/myconfig.${ISA}.cfg

# add -fgnu89-inline
# https://www.spec.org/cpu2017/Docs/faq.html#Build.06
# use sed command to add -fgnu89-inline to the C and C++ flags to avoid complaints about
# multiple definitions for 502.gcc_r / 602.gcc_s
sed -i '/628\.pop2_s:  #lang='\''F,C'\''/ {N;N;a\
\n502.gcc_r,602.gcc_s:  #lang='\''CXX,C'\''\
   PORTABILITY   = -fgnu89-inline
}' /home/gem5/spec2017/config/myconfig.${ISA}.cfg

# add -fcommon flags
# https://www.spec.org/cpu2017/Docs/faq.html#Build.07
# use sed command to add -fcommon to the C and C++ Fortran flags which occurs when using GCC 10 (and later)
# to avoid complaints about ultiple definitions for 525.x264_r / 625.x264_s
sed -i '/628\.pop2_s:  #lang='\''F,C'\''/ {N;N;a\
\n525.x264_r,625.x264_s:  #lang='\''CXX,C'\''\
   PORTABILITY\t= -fcommon
}' /home/gem5/spec2017/config/myconfig.${ISA}.cfg

# add -fallow-argument-mismatch to the C, C++, and Fortran flags
# https://www.spec.org/cpu2017/Docs/faq.html#Build.08
# use sed command to add -fallow-argument-mismatch which occurs when using GCC 10 (and later)
# as per the recommendation from the spec website for 527.cam4_r / 627.cam4_s,  
# 521.wrf_r / 621.wrf_s, and 628.pop2_s
sed -i '/628\.pop2_s:  #lang='\''F,C'\''/ {N;N;a\
   PORTABILITY  = -fallow-argument-mismatch
}' /home/gem5/spec2017/config/myconfig.${ISA}.cfg
sed -i '/521\.wrf_r,621\.wrf_s:  #lang='\''F,C'\''/ {N;N;a\
   PORTABILITY  = -fallow-argument-mismatch
}' /home/gem5/spec2017/config/myconfig.${ISA}.cfg
 sed -i '/527\.cam4_r,627\.cam4_s:  #lang='\''F,C'\''/ {n; s/$/ -fallow-argument-mismatch/}' config/myconfig.${ISA}.cfg

# prevent runcpu from calling sysinfo
# https://www.spec.org/cpu2017/Docs/config.html#sysinfo-program
# this is necessary as the sysinfo program queries the details of the system's CPU
# the query causes gem5 runtime error
sed -i "s/command_add_redirect = 1/sysinfo_program =\ncommand_add_redirect = 1/g" /home/gem5/spec2017/config/myconfig.${ISA}.cfg

# build all SPEC workloads
# build_ncpus: number of cpus to build the workloads
# gcc_dir: where to find the compilers (gcc, g++, gfortran)
runcpu --config=myconfig.${ISA}.cfg --define build_ncpus=$(nproc) --define gcc_dir="/usr" --action=build all

# the above building process will produce a large log file
# this command removes the log files to avoid copying out large files unnecessarily
rm -f /home/gem5/spec2017/result/*
