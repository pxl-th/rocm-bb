using Pkg
using BinaryBuilder

name = "hsa_rocr"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCR-Runtime/archive/rocm-$(version).tar.gz",
        "fa0e7bcd64e97cbff7c39c9e87c84a49d2184dc977b341794770805ec3f896cc"),
    DirectorySource("./bundled-rocr"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ROCR-Runtime*/

# Disable -Werror flag.
mv ${WORKSPACE}/srcdir/scripts/1-no-werror.patch ${WORKSPACE}/srcdir/ROCR-Runtime*/
atomic_patch -p1 ./1-no-werror.patch

mv ${WORKSPACE}/srcdir/scripts/* ${prefix}
mkdir build && cd build

# ln -s ${prefix}/bin/clang ${prefix}/tools/clang
# ln -s ${prefix}/bin/lld ${prefix}/tools/lld

export PATH="${prefix}/bin:${prefix}/tools:${PATH}"

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBITCODE_DIR=${prefix}/amdgcn/bitcode \
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
