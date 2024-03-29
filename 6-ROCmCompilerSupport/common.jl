const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport/"
const GIT_TAGS = Dict(
    v"4.2.0" => "40a1ea50d2aea0cf75c4d17cdd6a7fe44ae999bf0147d24a756ca4675ce24e36",
    v"4.5.2" => "e45f387fb6635fc1713714d09364204cd28fea97655b313c857beb1f8524e593",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
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

const PRODUCTS = [LibraryProduct(["libamd_comgr"], :libamd_comgr)]
const NAME = "ROCmCompilerSupport"

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
        DirectorySource("./bundled"),
    ]
    DEV_DIR = ENV["JULIA_DEV_DIR"]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(;
            name="rocm_cmake_jll",
            path=joinpath(DEV_DIR, "hsa_rocr_jll"),
            version)),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency(PackageSpec(;
            name="hsa_rocr_jll",
            path=joinpath(DEV_DIR, "hsa_rocr_jll")),
            compat=string(version)),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
