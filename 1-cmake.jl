using Pkg
using BinaryBuilder

name = "rocm_cmake"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/rocm-cmake/archive/rocm-$(version).tar.gz",
        "299e190ec3d38c2279d9aec762469628f0b2b1867adc082edc5708d1ac785c3b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)
products = [FileProduct("share/rocm/cmake", :cmake_dir)]
dependencies = []

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
