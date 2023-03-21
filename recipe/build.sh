#!/bin/bash
set -ex

#=================================================
#=GA=Settings
#=================================================

export USE_MPI="y"
export USE_MPIF="y"
export USE_MPIF4="y"

#export MPI_LOC="$PREFIX" #location of openmpi installation
#export FC="${FC}"
export _FC=gfortran
#export CC="${CC}"
export _CC=gcc

#=================================================
#=NWChem=Settings
#=================================================
export NWCHEM_TOP="$SRC_DIR"

# select ARCH file and version
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
    export TARGET=LINUX64
    export NWCHEM_TARGET=LINUX64
else
    export TARGET=MACX64
    export NWCHEM_TARGET=MACX64
fi

export ARMCI_NETWORK=$(echo $armci_network | tr "[:lower:]" "[:upper:]" | sed --expression='s/_/-/g' )
#export NWCHEM_MODULES="all python gwmol"
#faster build
export NWCHEM_MODULES="nwdft driver solvation"
export USE_NOIO=Y
# disable native CPU optimizations
export USE_HWOPT=n

export BLASOPT="-L$PREFIX/lib -lopenblas -lpthread"
export BLAS_SIZE=4
export USE_64TO32=y

export LAPACK_LIB="$BLASOPT"

export SCALAPACK_SIZE=4
export SCALAPACK_LIB="-L$PREFIX/lib -lscalapack"

export LIBXC_INCLUDE="$PREFIX/include"
export LIBXC_LIB="$PREFIX/lib"

# https://github.com/simint-chem/simint-generator
export USE_SIMINT=1
export SIMINT_MAXAM=5
build_arch=$(echo $CONDA_TOOLCHAIN_HOST | cut -d - -f 1)
echo "build_arch is $build_arch"
if [[ "$build_arch" == "x86_64" ]]; then
    export SIMINT_VECTOR=AVX2
elif [[ "$build_arch" == "x86_64" ]]; then
    export SIMINT_VECTOR=scalar
else
    export SIMINT_VECTOR=scalar
fi
echo "SIMINT_VECTOR is $SIMINT_VECTOR"
#=================================================
#=Make=NWChem
#=================================================

cd "$NWCHEM_TOP"/src
# show compiler versions
${CC} -v
${FC} -v
#
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  export OMPI_CC="$CC"
  export OMPI_CXX="$CXX"
  export OMPI_FC="$FC"
  export OPAL_PREFIX="$PREFIX"
fi
make CC=${CC} _CC=${_CC} FC=${FC} _FC=${_FC}  DEPEND_CC=${CC_FOR_BUILD} nwchem_config
cat ${SRC_DIR}/src/config/nwchem_config.h
#make DEPEND_CC=${CC_FOR_BUILD} CC=${CC} _CC=${CC} 64_to_32 
export USE_FPICF=1
mkdir -p ${SRC_DIR}/tools/install/lib ${SRC_DIR}/tools/install/include || true
make DEPEND_CC=${CC_FOR_BUILD} CC=${CC} _CC=${_CC} FC=${FC} _FC=${_FC} CFLAGS_FORGA="-fPIC -Wl,-rpath,${PREFIX}/lib -L${PREFIX}/lib" FFLAGS_FORGA="-Wl,-rpath,${PREFIX}/lib -L${PREFIX}/lib" FFLAG_INT="-fdefault-integer-8"
if [[ "$?" != 0 ]]; then
    echo '%%%% tools/build/config.log %%%%%'
    cat $SRC_DIR/src/tools/build/config.log
    echo '%%%% tools/build/comex/config.log %%%%%'
    cat $SRC_DIR/src/tools/build/comex/config.log
fi
#=================================================
#=Install=NWChem
#=================================================

mkdir -p "$PREFIX"/share/nwchem/libraryps/
mkdir -p "$PREFIX"/etc

cp -r "$NWCHEM_TOP"/bin/$TARGET/* "$PREFIX"/bin
cp -r "$NWCHEM_TOP"/lib/$TARGET/* "$PREFIX"/lib
# cp -r "$NWCHEM_TOP"/include/$TARGET/* "$PREFIX"/include
cp -r "$NWCHEM_TOP"/src/basis/libraries "$PREFIX"/share/nwchem/
cp -r "$NWCHEM_TOP"/src/basis/libraries.bse "$PREFIX"/share/nwchem/
cp -r "$NWCHEM_TOP"/src/data "$PREFIX"/share/nwchem/
cp -r "$NWCHEM_TOP"/src/nwpw/libraryps "$PREFIX"/share/nwchem/

cat > "$PREFIX/etc/default.nwchemrc" << EOF
nwchem_basis_library $PREFIX/share/nwchem/libraries/
nwchem_nwpw_library $PREFIX/share/nwchem/libraryps/
ffield amber
amber_1 $PREFIX/share/nwchem/data/amber_s/
amber_2 $PREFIX/share/nwchem/data/amber_q/
amber_3 $PREFIX/share/nwchem/data/amber_x/
amber_4 $PREFIX/share/nwchem/data/amber_u/
spce $PREFIX/share/nwchem/data/solvents/spce.rst
charmm_s $PREFIX/share/nwchem/data/charmm_s/
charmm_x $PREFIX/share/nwchem/data/charmm_x/
EOF
mkdir -p "$PREFIX/etc/conda/activate.d/" "$PREFIX/etc/conda/deactivate.d/"

cat > "$PREFIX/etc/conda/activate.d/nwchem_env.sh" << "EOF"
export NWCHEM_BASIS_LIBRARY=$CONDA_PREFIX/share/nwchem/libraries/
export NWCHEM_NWPW_LIBRARY=$CONDA_PREFIX/share/nwchem/libraryps/
EOF
cat > "$PREFIX/etc/conda/activate.d/nwchem_env.fish" << "EOF"
    bash $CONDA_PREFIX/etc/conda/activate.d/nwchem_env.sh
EOF
