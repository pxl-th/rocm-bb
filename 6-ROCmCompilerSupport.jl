using Pkg
using BinaryBuilder

name = "ROCmCompilerSupport"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport/archive/rocm-$(version).tar.gz",
        "40a1ea50d2aea0cf75c4d17cdd6a7fe44ae999bf0147d24a756ca4675ce24e36"),
    DirectorySource("./bundled-compiler-support"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCm-CompilerSupport*/lib/comgr

mv ${WORKSPACE}/srcdir/scripts/* ${prefix}
mkdir build && cd build

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DLLVM_DIR=${prefix}/llvm/lib/cmake/llvm \
      -DLLD_DIR=${prefix}/llvm/lib/cmake/lld \
      -DClang_DIR=${prefix}/llvm/lib/cmake/clang \
      -DROCM_DIR=${prefix} \
      -DBUILD_TESTING:BOOL=OFF \
      ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]

products = [LibraryProduct(["libamd_comgr"], :libamd_comgr)]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    # BuildDependency(PackageSpec(;name="ROCmLLVM_jll", version)),
    BuildDependency(PackageSpec(;
        name="ROCmLLVM_jll",
        path=joinpath(DEV_DIR, "ROCmLLVM_jll"),
        version)),
    BuildDependency(PackageSpec(;
        name="rocm_cmake_jll",
        path=joinpath(DEV_DIR, "rocm_cmake_jll"),
        version)),
    Dependency(PackageSpec(;
        name="ROCmDeviceLibs_jll",
        path=joinpath(DEV_DIR, "ROCmDeviceLibs_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="hsa_rocr_jll",
        path=joinpath(DEV_DIR, "hsa_rocr_jll"));
        compat=string(version)),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.7")
