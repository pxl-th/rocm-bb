using Pkg
using BinaryBuilder

name = "hsa_rocr"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCR-Runtime/archive/rocm-$(version).tar.gz",
        "fa0e7bcd64e97cbff7c39c9e87c84a49d2184dc977b341794770805ec3f896cc"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCR-Runtime*/

ln -s ${prefix}/bin/clang ${prefix}/tools/clang
ln -s ${prefix}/bin/lld ${prefix}/tools/lld

export PATH="${prefix}/tools:${PATH}"

mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DBITCODE_DIR=${prefix}/amdgcn/bitcode \
    -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
    -DClang_DIR="${prefix}/lib/cmake/clang" \
    ../src

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)
products = [LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64)]

DEV_DIR = "/home/pxl-th/.julia/dev"
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency(PackageSpec(;
        name="hsakmt_roct_jll",
        path=joinpath(DEV_DIR, "hsakmt_roct_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmDeviceLibs_jll",
        path=joinpath(DEV_DIR, "ROCmDeviceLibs_jll"));
        compat=string(version)),
    Dependency("NUMA_jll"),
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
    Dependency("Elfutils_jll"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
