using Pkg
using BinaryBuilder

name = "ROCmOpenCLRuntime"
version = v"4.2.0"

sources = [
    ArchiveSource(
        "https://github.com/ROCm-Developer-Tools/ROCclr/archive/rocm-$(version).tar.gz",
        "c57525af32c59becf56fd83cdd61f5320a95024d9baa7fb729a01e7a9fcdfd78"),
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/archive/rocm-$(version).tar.gz",
        "18133451948a83055ca5ebfb5ba1bd536ed0bcb611df98829f1251a98a38f730"),
    DirectorySource("./bundled-rocm-opencl-runtime"),
]

script = raw"""
# TODO no need to move.
mv ${WORKSPACE}/srcdir/scripts/* ${prefix}

export PATH="${prefix}/bin:${prefix}/tools:${PATH}"
export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

# Build ROCclr
cd ${ROCclr_DIR}

# Link rt.
atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-link-lrt.patch

mkdir build && cd build

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENCL_DIR=${OPENCL_SRC} \
    ..

make -j${nproc}
make install

# TODO Build OpenCL
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]

products = [
    FileProduct("lib/libamdrocclr_static.a", :libamdrocclr_static),
    # TODO: LibraryProduct(["libOpenCL"], :libOpenCL),
]

DEV_DIR = ENV["JULIA_DEV_DIR"]
dependencies = [
    # BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
    BuildDependency(PackageSpec(;
        name="ROCmLLVM_jll",
        path=joinpath(DEV_DIR, "ROCmLLVM_jll"),
        version)),
    BuildDependency(PackageSpec(;
        name="rocm_cmake_jll",
        path=joinpath(DEV_DIR, "rocm_cmake_jll"),
        version)),
    Dependency(PackageSpec(;
        name="hsakmt_roct_jll",
        path=joinpath(DEV_DIR, "hsakmt_roct_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="hsa_rocr_jll",
        path=joinpath(DEV_DIR, "hsa_rocr_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmDeviceLibs_jll",
        path=joinpath(DEV_DIR, "ROCmDeviceLibs_jll"));
        compat=string(version)),
    Dependency(PackageSpec(;
        name="ROCmCompilerSupport_jll",
        path=joinpath(DEV_DIR, "ROCmCompilerSupport_jll"));
        compat=string(version)),
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_xorgproto_jll"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies,
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.7")
