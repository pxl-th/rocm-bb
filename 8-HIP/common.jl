const HIPAMD_GIT = "https://github.com/ROCm-Developer-Tools/hipamd/"
const HIP_GIT = "https://github.com/ROCm-Developer-Tools/HIP/"

# Needed, since ROCclr is no longer can be built as standalone project.
# So we build it here as well as in ROCmOpenCLRuntime.
const ROCM_GIT_CL = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr/"

const HIPAMD_GIT_TAGS = Dict(
    v"4.5.2" => "b6f35b1a1d0c466b5af28e26baf646ae63267eccc4852204db1e0c7222a39ce2",
)
const HIP_GIT_TAGS = Dict(
    v"4.2.0" => "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24",
    v"4.5.2" => "c2113dc3c421b8084cd507d91b6fbc0170765a464b71fb0d96bb875df368f160",
)

const GIT_TAGS_CL = Dict(
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
)
const GIT_TAGS_CLR = Dict(
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const CLR_CMAKE = Dict(
    v"4.2.0" => "",
    v"4.5.2" => raw"""
    export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
    export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

    # Build ROCclr
    cd ${ROCclr_DIR}
    mkdir build && cd build
    CC=${prefix}/rocm-clang CXX=${prefix}/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix}/rocclr \
        -DCMAKE_BUILD_TYPE=Release \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        ..
    make -j${nproc} # no install target
    """,
)

const NAME = "HIP"
const PRODUCTS = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

function configure_build(version)
    archive = "archive/rocm-$version.tar.gz"

    buildscript = raw"""
    mv ${WORKSPACE}/srcdir/scripts/rocm-clang* ${prefix}
    """ *
    CLR_CMAKE[version] *
    raw"""
    cd ${WORKSPACE}/srcdir/hipamd*/
    mkdir build && cd build
    export HIP_DIR=$(realpath ${WORKSPACE}/srcdir/HIP-*)

    CC=${prefix}/rocm-clang CXX=${prefix}/rocm-clang++ \
    cmake \
        -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
        -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${prefix}" \
        -DROCM_PATH=${prefix} \
        -DHIP_PLATFORM=amd \
        -DHIP_RUNTIME=rocclr \
        -DHIP_COMPILER=clang \
        -D__HIP_ENABLE_PCH=OFF \
        -DROCCLR_INCLUDE_DIR=${ROCclr_DIR}/include \
        -DROCCLR_PATH=${ROCclr_DIR} \
        -DHIP_COMMON_DIR=${HIP_DIR} \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        -DCMAKE_HIP_ARCHITECTURES="gfx906:xnack-" \
        -DLLVM_DIR="${prefix}/llvm/lib/cmake/llvm" \
        -DClang_DIR="${prefix}/llvm/lib/cmake/clang" \
        ..

    make -j${nproc}
    make install
    """

    sources = [
        ArchiveSource(HIP_GIT * archive, HIP_GIT_TAGS[version]),
        DirectorySource("./bundled"),
    ]
    if version == v"4.5.2"
        push!(
            sources,
            ArchiveSource(HIPAMD_GIT * archive, HIPAMD_GIT_TAGS[version]),
            ArchiveSource(ROCM_GIT_CL * "archive/rocm-$(version).tar.gz", GIT_TAGS_CL[version]),
            ArchiveSource(ROCM_GIT_CLR * "archive/rocm-$(version).tar.gz", GIT_TAGS_CLR[version]))
    end

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
        Dependency(PackageSpec(;
            name="ROCmOpenCLRuntime_jll",
            path=joinpath(DEV_DIR, "ROCmOpenCLRuntime_jll"));
            compat=string(version)),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
