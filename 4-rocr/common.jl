const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCR-Runtime/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "fa0e7bcd64e97cbff7c39c9e87c84a49d2184dc977b341794770805ec3f896cc",
    v"4.5.2" => "d99eddedce0a97d9970932b64b0bb4743e47d2740e8db0288dbda7bec3cefa80",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCR-Runtime*/

# Disable -Werror flag.
mv ${WORKSPACE}/srcdir/scripts/1-no-werror.patch ${WORKSPACE}/srcdir/ROCR-Runtime*/
atomic_patch -p1 ./1-no-werror.patch

mv ${WORKSPACE}/srcdir/scripts/* ${prefix}
mkdir build && cd build

# Force ROCm Clang.
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

const PRODUCTS = [LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64)]
const NAME = "hsa_rocr"

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
        DirectorySource("./bundled"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("NUMA_jll"),
        Dependency("XML2_jll"),
        Dependency("Zlib_jll"),
        Dependency("Elfutils_jll"),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
