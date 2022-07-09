using Pkg
using BinaryBuilder

name = "ROCmDeviceLibs"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCm-Device-Libs/archive/rocm-$(version).tar.gz",
        "34a2ac39b9bb7cfa8175cbab05d30e7f3c06aaffce99eed5f79c616d0f910f5f"),
    DirectorySource("./bundled-device-libs"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
mkdir build && cd build

mv ${WORKSPACE}/srcdir/scripts/* ${prefix}

ln -s ${prefix}/bin/clang ${prefix}/tools/clang
ln -s ${prefix}/bin/lld ${prefix}/tools/lld

export PATH="${prefix}/bin:${prefix}/tools:${PATH}"

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
    -DClang_DIR="${prefix}/lib/cmake/clang" \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
platforms = expand_cxxstring_abis(platforms)
products = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency("Zlib_jll"),
]
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12")
