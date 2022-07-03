# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Pkg
using BinaryBuilder

name = "HIP"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ROCm-Developer-Tools/HIP/archive/rocm-$(version).tar.gz",
        "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24"),
    DirectorySource("./bundled-hip"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/HIP*/

# # disable tests
# atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"

apk add coreutils dateutils

mkdir build && cd build
ln -s ${prefix}/bin/clang ${prefix}/tools/clang

export ROCM_PATH=${prefix}
export HIP_PLATFORM=amd
export HIP_LIB_PATH=${prefix}/hip/lib
export HIP_ROCCLR_HOME=${prefix}/lib
export HIP_CLANG_PATH=${prefix}/tools
export DEVICE_LIB_PATH=${prefix}/amdgcn/bitcode
export HSA_PATH=${prefix}

cmake -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
      -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -D__HIP_ENABLE_PCH=OFF \
      ..

make -j${nproc}
make install

# Cleanup
rm ${prefix}/tools/clang
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("ROCmCompilerSupport_jll", v"4.2.0"),
    Dependency("ROCmOpenCLRuntime_jll", v"4.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    julia_compat="1.7", preferred_gcc_version=v"8")
