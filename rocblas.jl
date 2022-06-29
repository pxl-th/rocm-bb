# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocBLAS"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ROCmSoftwarePlatform/rocBLAS/archive/rocm-$(version).tar.gz",
        "547f6d5d38a41786839f01c5bfa46ffe9937b389193a8891f251e276a1a47fb0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocBLAS*/
mkdir build

export ROCM_PATH=${prefix}
export HIP_CLANG_PATH=${prefix}/tools
export HIP_PATH=${prefix}/hip
export HIP_CLANG_HCC_COMPAT_MODE=1
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
export HIP_ROCCLR_HOME=${prefix}/lib
export HIP_LIB_PATH=${prefix}/hip/lib
export HIPCC_VERBOSE=1

export TENSILE_ARCHITECTURE="gfx900"

export PATH="${prefix}/tools:${prefix}/hip/bin:${PATH}"
export LD_LIBRARY_PATH="${prefix}/lib:${prefix}/lib64:${LD_LIBRARY_PATH}"

ln -s ${prefix}/bin/clang ${prefix}/tools/clang
ln -s ${prefix}/bin/lld ${prefix}/tools/lld

# NOTE this is needed to avoid errors with zipping files older than 1980.
unset SOURCE_DATE_EPOCH
# pip install yaml
pip install -U pip wheel setuptools

# TODO: set correct path
# HIP_CLANG_INCLUDE_PATH=${prefix}/hip/include

cmake -S . -B build \
    -DROCM_PATH={prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_CXX_COMPILER=${prefix}/hip/bin/hipcc \
    -DBUILD_WITH_TENSILE=ON \
    -DBUILD_WITH_TENSILE_HOST=ON \
    -DTensile_LIBRARY_FORMAT=yaml \
    -DTensile_COMPILER=hipcc \
    -DTensile_ARCHITECTURE=$TENSILE_ARCHITECTURE \
    -DTensile_LOGIC=asm_full \
    -DTensile_CODE_OBJECT_VERSION=V3 \
    -DBUILD_CLIENTS_TESTS=OFF \
    -DBUILD_CLIENTS_BENCHMARKS=OFF \
    -DBUILD_CLIENTS_SAMPLES=OFF \
    -DBUILD_TESTING=OFF

make -C build install

rm ${prefix}/tools/clang
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["librocblas"], :librocblas, ["rocblas/lib"]),
]

# Dependencies that must be installed before this package can be built
# DEV_DIR = "/home/pxl-th/.julia/dev"
dependencies = [
    BuildDependency(PackageSpec(;name="ROCmLLVM_jll", version)),
    BuildDependency("rocm_cmake_jll"),
    # BuildDependency(PackageSpec(;
    #     name="rocm_cmake_jll", version, path=joinpath(DEV_DIR, "rocm_cmake_jll"))),
    Dependency("ROCmCompilerSupport_jll", version),
    Dependency("ROCmOpenCLRuntime_jll", version),
    Dependency("rocminfo_jll"),
    # Dependency(PackageSpec(;
    #     name="rocminfo_jll", path=joinpath(DEV_DIR, "rocminfo_jll"));
    #     compat=string(version)),
    Dependency("hsa_rocr_jll", version),
    Dependency("HIP_jll", version),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    preferred_gcc_version=v"8", preferred_llvm_version=v"11")
