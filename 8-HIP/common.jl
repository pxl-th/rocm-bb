const HIPAMD_GIT = "https://github.com/ROCm-Developer-Tools/hipamd/"
const HIP_GIT = "https://github.com/ROCm-Developer-Tools/HIP/"
const ROCCLR_GIT = "https://github.com/ROCm-Developer-Tools/ROCclr/"
const OPENCL_GIT = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"

const HIPAMD_GIT_TAGS = Dict(
    v"4.5.2" => "b6f35b1a1d0c466b5af28e26baf646ae63267eccc4852204db1e0c7222a39ce2",
)
const HIP_GIT_TAGS = Dict(
    v"4.2.0" => "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24",
    v"4.5.2" => "c2113dc3c421b8084cd507d91b6fbc0170765a464b71fb0d96bb875df368f160",
)
const ROCCLR_GIT_TAGS = Dict(
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
)
const OPENCL_GIT_TAGS = Dict(
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT420 = raw"""
mv ${WORKSPACE}/srcdir/scripts/rocm-clang* ${prefix}

cd ${WORKSPACE}/srcdir/HIP*/

# Disable tests.
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"

mkdir build && cd build

# Sets HIP_COMPILER=clang & HIP_RUNTIME=rocclr.
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
export HSA_PATH=${prefix}/hsa
export PATH="${prefix}/bin:${prefix}/tools:${PATH}"

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
CXXFLAGS="-isystem ${prefix}/include/include -isystem ${prefix}/include/compiler/lib -isystem ${prefix}/include/compiler/lib/include -isystem ${prefix}/include/elf $CXXFLAGS " \
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DROCM_PATH=${prefix} \
    -DHSA_PATH=${prefix}/hsa \
    -DHIP_PLATFORM=${HIP_PLATFORM} \
    -DHIP_RUNTIME=${HIP_RUNTIME} \
    -DHIP_COMPILER=${HIP_COMPILER} \
    -D__HIP_ENABLE_PCH=OFF \
    ..

make -j${nproc}
make install
"""

const BUILDSCRIPT = raw"""
mv ${WORKSPACE}/srcdir/scripts/rocm-clang* ${prefix}

cd ${WORKSPACE}/srcdir/hipamd*/

mkdir build && cd build

# Sets HIP_COMPILER=clang & HIP_RUNTIME=rocclr.
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
export HSA_PATH=${prefix}/hsa

# export PATH="${prefix}/bin:${prefix}/tools:${PATH}"
# CXXFLAGS="-isystem ${prefix}/include/include -isystem ${prefix}/include/compiler/lib -isystem ${prefix}/include/compiler/lib/include -isystem ${prefix}/include/elf $CXXFLAGS " \

CC=${prefix}/rocm-clang \
CXX=${prefix}/rocm-clang++ \
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DHIP_COMMON_DIR=${WORKSPACE}/srcdir/HIP* \
    -DAMD_OPENCL_PATH=${WORKSPACE}/ROCm-OpenCL-Runtime* \
    -DROCCLR_PATH=${WORKSPACE}/ROCclr* \
    -DROCM_PATH=${prefix} \
    -DHSA_PATH=${prefix}/hsa \
    -DHIP_PLATFORM=${HIP_PLATFORM} \
    -DHIP_RUNTIME=${HIP_RUNTIME} \
    -DHIP_COMPILER=${HIP_COMPILER} \
    -D__HIP_ENABLE_PCH=OFF \
    ..

make -j${nproc}
make install
"""

const NAME = "HIP"
const PRODUCTS = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

function configure_build(version)
    archive = "archive/rocm-$version.tar.gz"
    if version == v"4.2.0"
        sources = [
            ArchiveSource(HIP_GIT * archive, HIP_GIT_TAGS[version]),
            DirectorySource("./bundled"),
        ]
    else
        sources = [
            ArchiveSource(HIPAMD_GIT * archive, HIPAMD_GIT_TAGS[version]),
            ArchiveSource(HIP_GIT * archive, HIP_GIT_TAGS[version]),
            ArchiveSource(ROCCLR_GIT * archive, ROCCLR_GIT_TAGS[version]),
            ArchiveSource(OPENCL_GIT * archive, OPENCL_GIT_TAGS[version]),
            DirectorySource("./bundled"),
        ]
    end

    @show sources

    DEV_DIR = ENV["JULIA_DEV_DIR"]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(;
            name="rocm_cmake_jll",
            path=joinpath(DEV_DIR, "rocm_cmake_jll"),
            version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency(PackageSpec(;
            name="hsa_rocr_jll",
            path=joinpath(DEV_DIR, "hsa_rocr_jll"));
            compat=string(version)),
        Dependency(PackageSpec(;
            name="rocminfo_jll",
            path=joinpath(DEV_DIR, "rocminfo_jll"));
            compat=string(version)),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency(PackageSpec(;
            name="ROCmCompilerSupport_jll",
            path=joinpath(DEV_DIR, "ROCmCompilerSupport_jll"));
            compat=string(version)),
    ]
    buildscript = version == v"4.2.0" ? BUILDSCRIPT420 : BUILDSCRIPT
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
