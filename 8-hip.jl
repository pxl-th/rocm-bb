using Pkg
using BinaryBuilder

name = "HIP"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/ROCm-Developer-Tools/HIP/archive/rocm-$(version).tar.gz",
        "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24"),
    DirectorySource("./bundled-hip"),
]

script = raw"""
# TODO no need to move.
mv ${WORKSPACE}/srcdir/scripts/rocm-clang* ${prefix}

cd ${WORKSPACE}/srcdir/HIP*/

# Disable tests.
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"

mkdir build && cd build

# Sets HIP_COMPILER=clang & HIP_RUNTIME=rocclr.
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
export HSA_PATH=${prefix}
export PATH="${prefix}/bin:${prefix}/tools:${PATH}"

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
CXXFLAGS="-isystem ${prefix}/include/include -isystem ${prefix}/include/compiler/lib -isystem ${prefix}/include/compiler/lib/include -isystem ${prefix}/include/elf $CXXFLAGS " \
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DROCM_PATH=${prefix} \
    -DHSA_PATH=${prefix}/hsa \
    -DHIP_PLATFORM=${HIP_PLATFORM} \
    -DHIP_RUNTIME=${HIP_RUNTIME} \
    -DHIP_COMPILER=${HIP_COMPILER} \
    -D__HIP_ENABLE_PCH=OFF \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]

products = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    # BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
    BuildDependency(PackageSpec(;
        name="ROCmLLVM_jll",
        path=joinpath(DEV_DIR, "ROCmLLVM_jll"),
        version)),
    BuildDependency(PackageSpec(;
        name="rocm_cmake_jll",
        path=joinpath(DEV_DIR, "rocm_cmake_jll"),
        version)),
    Dependency(PackageSpec(;
        name="hsakmt_roct_jll",
        path=joinpath(DEV_DIR, "hsakmt_roct_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="hsa_rocr_jll",
        path=joinpath(DEV_DIR, "hsa_rocr_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="rocminfo_jll",
        path=joinpath(DEV_DIR, "rocminfo_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmDeviceLibs_jll",
        path=joinpath(DEV_DIR, "ROCmDeviceLibs_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmCompilerSupport_jll",
        path=joinpath(DEV_DIR, "ROCmCompilerSupport_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmOpenCLRuntime_jll",
        path=joinpath(DEV_DIR, "ROCmOpenCLRuntime_jll"));
        compat=string(version)),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
