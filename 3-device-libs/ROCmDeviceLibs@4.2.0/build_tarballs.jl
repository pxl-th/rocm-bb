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
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
products = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
    Dependency("Zlib_jll"),
]
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.7")
