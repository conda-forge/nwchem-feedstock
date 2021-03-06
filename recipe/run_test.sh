#!/bin/bash -f
set -ex

if [[ "$mpi" == "openmpi" ]]; then
    export OMPI_MCA_plm_rsh_agent=sh
fi

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


cd $NWCHEM_TOP/QA
./doafewqmtests.mpi 2 | tee tests.log
# fail if one of the tests failed
! grep "NWChem execution failed" tests.log || exit 1
