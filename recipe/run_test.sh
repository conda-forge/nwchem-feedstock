#!/bin/bash -f
set -ex

export OMP_NUM_THREADS=1
export NWCHEM_TOP=$SRC_DIR
export NWCHEM_EXECUTABLE=$PREFIX/bin/nwchem
export NWCHEM_TARGET=""
export MPIRUN_PATH=$PREFIX/bin/mpirun 
# nwchem cannot deal with path lengths >255 characters
#export NWCHEM_BASIS_LIBRARY=$PREFIX/share/nwchem/libraries/
mkdir -p $SRC_DIR/src/basis
ln -s $PREFIX/share/nwchem/libraries/ $SRC_DIR/src/basis/libraries
# not sure this env var actually has any effect
# (the tests may be looking for the libraries at a relative location)
export NWCHEM_BASIS_LIBRARY=$SRC_DIR/src/basis/libraries/
unset USE_SIMINT
# ARMCI_NETWORK is used in QAs
export ARMCI_NETWORK=$(echo $armci_network | tr "[:lower:]" "[:upper:]" | sed --expression='s/_/-/g' )
echo "ARMCI_NETWORK is $ARMCI_NETWORK"

cd $NWCHEM_TOP/QA
ls -lrt 
#export CONDA_FORGE_DOCKER_RUN_ARGS="--shm-size 256m"
if [[ $(uname -s) == "Linux" ]]; then
    echo 'output of df -h /dev/shm' `df -h /dev/shm`
    mpirun -n 1 df -h /dev/shm || true
fi
ompi_info --all|grep MCA\ btl:
#export OMPI_MCA_btl=^openib,smcuda
if [[ "$mpi" == "openmpi" ]]; then
    export OMPI_MCA_plm_rsh_agent=ssh
fi
export OMPI_MCA_btl=self,tcp
#export OMPI_MCA_btl_base_verbose=40
./doafewqmtests.mpi 2 1 
#echo " %%%% h2o_opt.out %%%%"
#cat $NWCHEM_TOP/QA/testoutputs/h2o_opt.out
#tail -300 $NWCHEM_TOP/QA/testoutputs/h2o_opt.out
#echo " %%%% end of h2o_opt.out %%%%"
#echo " %%%% localize-ibo-aa.out %%%%"
#cat $NWCHEM_TOP/QA/testoutputs/localize-ibo-aa.out
#echo " %%%% end of localize-ibo-aa.out %%%%"

