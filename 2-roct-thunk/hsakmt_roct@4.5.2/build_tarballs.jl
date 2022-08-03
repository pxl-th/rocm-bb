using Pkg
using BinaryBuilder

name = "hsakmt_roct"
version = v"4.5.2"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface/archive/rocm-$(version).tar.gz",
        "fb8e44226b9e393baf51bfcb9873f63ce7e4fcf7ee7f530979cf51857ea4d24b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCT-Thunk-Interface*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
products = [LibraryProduct(["libhsakmt"], :libhsakmt)]
dependencies = [
    Dependency("NUMA_jll"),
    Dependency("libdrm_jll"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.8")
