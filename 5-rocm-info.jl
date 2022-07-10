using Pkg
using BinaryBuilder

name = "rocminfo"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/rocminfo/archive/rocm-$(version).tar.gz",
        "6952b6e28128ab9f93641f5ccb66201339bb4177bb575b135b27b69e2e241996"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rocminfo*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DROCM_DIR=${prefix} \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("rocminfo", :rocminfo),
    ExecutableProduct("rocm_agent_enumerator", :rocm_agent_enumerator),
]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    Dependency(PackageSpec(;
        name="hsa_rocr_jll",
        path=joinpath(DEV_DIR, "hsa_rocr_jll"));
        compat=string(version)),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
