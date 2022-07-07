using Pkg
using BinaryBuilder

name = "ROCmDeviceLibs"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCm-Device-Libs/archive/rocm-$(version).tar.gz",
        "34a2ac39b9bb7cfa8175cbab05d30e7f3c06aaffce99eed5f79c616d0f910f5f"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/

mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
    -DClang_DIR="${prefix}/lib/cmake/clang" \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)
products = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

DEV_DIR = "/home/pxl-th/.julia/dev"
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    # NOTE ok to use regular llvm?
    # BuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"12.0.1")),
    Dependency("Zlib_jll"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
