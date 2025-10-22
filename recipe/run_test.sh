#!/bin/bash
set -ex
export ARCH=$(uname -m)
echo ARCH is $ARCH
echo target_platform is $target_platform
if [[ "$target_platform" == linux-aarch64 || "$target_platform" == linux-ppc64le ]]; then
    echo "skipping QA tests on $target_platform"
    echo "because of non working MPI"
    exit 0
fi
env
echo pwd is $(pwd)
export OMP_NUM_THREADS=1
export NWCHEM_TOP=$SRC_DIR
export NWCHEM_EXECUTABLE=$(which nwchem)
export NWCHEM_TARGET=""
export MPIRUN_PATH=$(which mpirun)
# nwchem cannot deal with path lengths >255 characters
#export NWCHEM_BASIS_LIBRARY=$PREFIX/share/nwchem/libraries/
#mkdir -p $SRC_DIR/src/basis
#ln -s $PREFIX/share/nwchem/libraries/ $SRC_DIR/src/basis/libraries
# not sure this env var actually has any effect
# (the tests may be looking for the libraries at a relative location)
#export NWCHEM_BASIS_LIBRARY=$SRC_DIR/src/basis/libraries/
unset USE_SIMINT
# ARMCI_NETWORK is used in QAs
export ARMCI_NETWORK=$(echo $armci_network | tr "[:lower:]" "[:upper:]" | sed -e 's/_/-/g' )
echo "ARMCI_NETWORK is $ARMCI_NETWORK"

cd QA
ls -lrt 
export CONDA_FORGE_DOCKER_RUN_ARGS="--shm-size 256m"
ompi_info --all|grep MCA\ btl:
#export OMPI_MCA_btl=^openib,smcuda
#if [[ "$mpi" == "openmpi" ]]; then
    export OMPI_MCA_plm_rsh_agent=ssh
    export OMPI_MCA_btl=self,tcp
    export OMPI_MCA_osc=^ucx
    export OMPI_MCA_btl_tcp_if_include=lo
    export OMPI_MCA_btl=self,tcp
#fi
#export OMPI_MCA_btl_base_verbose=40
env|egrep -i armci
echo "armci_network is " $armci_network
if [[ $armci_network  == 'mpi_pt' ]]; then
    QA_NPROC=1
else
    QA_NPROC=2
fi
./doafewqmtests.mpi $QA_NPROC 
