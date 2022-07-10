using Pkg
using BinaryBuilder

name = "rocBLAS"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/ROCmSoftwarePlatform/rocBLAS/archive/rocm-$(version).tar.gz",
        "547f6d5d38a41786839f01c5bfa46ffe9937b389193a8891f251e276a1a47fb0"),
    DirectorySource("./bundled-rocblas"),
]

script = raw"""
mv ${WORKSPACE}/srcdir/scripts/hipcc-wrapper ${prefix}

cd ${WORKSPACE}/srcdir/rocBLAS*/
mkdir build

export ROCM_PATH=${prefix}
export HIP_PATH=${prefix}/hip

# HIP env variables: https://github.com/ROCm-Developer-Tools/HIP/blob/rocm-4.2.0/bin/hipcc
export HIP_PLATFORM=amd
export HSA_PATH=${prefix}
export HIP_ROCCLR_HOME=${prefix}/lib
export HIP_CLANG_PATH=${prefix}/tools

# Other HIPCC env variables.
export HIPCC_VERBOSE=1
export HIP_LIB_PATH=${prefix}/hip/lib
export DEVICE_LIB_PATH=${prefix}/amdgcn/bitcode
export HIP_CLANG_HCC_COMPAT_MODE=1

# ROCM_PATH=${prefix} \
# HIP_PATH=${prefix}/hip \
# HIP_PLATFORM=amd \
# HSA_PATH=${prefix} \
# HIP_ROCCLR_HOME=${prefix}/lib \
# HIP_CLANG_PATH=${prefix}/tools \
# HIPCC_VERBOSE=1 \
# HIP_LIB_PATH=${prefix}/hip/lib \
# DEVICE_LIB_PATH=${prefix}/amdgcn/bitcode \
# HIP_CLANG_HCC_COMPAT_MODE=1 \

export PATH="${prefix}/bin:${prefix}/tools:${prefix}/hip/bin:${PATH}"
export LD_LIBRARY_PATH="${prefix}/lib:${prefix}/lib64:${LD_LIBRARY_PATH}"

ln -s ${prefix}/bin/clang ${prefix}/tools/clang
ln -s ${prefix}/bin/lld ${prefix}/tools/lld

# NOTE
# Add explicit device norm calls for blas.
atomic_patch -p1 $WORKSPACE/srcdir/patches/add-norm.patch

# NOTE
# Looking at hcc-cmd, it is clear that it is omitting 'hip/include' directory.
# Therefore we symlink to other directory that it looks at.
# TODO is there a better fix?
mkdir ${prefix}/lib/include
ln -s ${prefix}/hip/include/* ${prefix}/lib/include

# NOTE
# This is needed to avoid errors with zipping files older than 1980.
# See: https://github.com/pypa/wheel/issues/418
unset SOURCE_DATE_EPOCH
pip install -U pip wheel setuptools

export TENSILE_ARCHITECTURE="gfx900"

CXX=${prefix}/hipcc-wrapper \
CXXFLAGS="$CXXFLAGS -fcf-protection=none " \
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DROCM_PATH={prefix} \
    -DBUILD_VERBOSE=ON \
    -DBUILD_WITH_TENSILE=ON \
    -DBUILD_WITH_TENSILE_HOST=ON \
    -DTensile_LIBRARY_FORMAT=yaml \
    -DTensile_COMPILER=hipcc \
    -DTensile_LOGIC=asm_full \
    -DTensile_CODE_OBJECT_VERSION=V3 \
    -DTensile_ARCHITECTURE=$TENSILE_ARCHITECTURE \
    -DBUILD_CLIENTS_TESTS=OFF \
    -DBUILD_CLIENTS_BENCHMARKS=OFF \
    -DBUILD_CLIENTS_SAMPLES=OFF \
    -DBUILD_TESTING=OFF

make -j${nproc} -C build install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)

products = [LibraryProduct(["librocblas"], :librocblas, ["rocblas/lib"])]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    BuildDependency(PackageSpec(;name="ROCmLLVM_jll", version)),
    BuildDependency(PackageSpec(;
        name="rocm_cmake_jll", version,
        path=joinpath(DEV_DIR, "rocm_cmake_jll"))),
    Dependency(PackageSpec(;
        name="ROCmCompilerSupport_jll",
        path=joinpath(DEV_DIR, "ROCmCompilerSupport_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmOpenCLRuntime_jll",
        path=joinpath(DEV_DIR, "ROCmOpenCLRuntime_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="rocminfo_jll", path=joinpath(DEV_DIR, "rocminfo_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="hsa_rocr_jll",
        path=joinpath(DEV_DIR, "hsa_rocr_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="HIP_jll", path=joinpath(DEV_DIR, "HIP_jll"));
        compat=string(version)),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
