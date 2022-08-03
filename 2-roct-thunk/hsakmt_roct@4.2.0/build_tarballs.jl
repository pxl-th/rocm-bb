using Pkg
using BinaryBuilder

name = "hsakmt_roct"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface/archive/rocm-$(version).tar.gz",
        "cc325d4b9a96062f2ad0515fce724a8c64ba56a7d7f1ac4a0753941b8599c52e"),
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
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.7")
