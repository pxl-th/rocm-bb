const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocminfo/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "6952b6e28128ab9f93641f5ccb66201339bb4177bb575b135b27b69e2e241996",
    v"4.5.2" => "5ea839cd1f317cbc72ea1e3634a75f33a458ba0cb5bf48377f08bb329c29222d",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
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

const PRODUCTS = [
    ExecutableProduct("rocminfo", :rocminfo),
    ExecutableProduct("rocm_agent_enumerator", :rocm_agent_enumerator),
]
const NAME = "rocminfo"

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
    ]
    DEV_DIR = ENV["JULIA_DEV_DIR"]
    dependencies = [
        Dependency(PackageSpec(;
            name="hsa_rocr_jll",
            path=joinpath(DEV_DIR, "hsa_rocr_jll"));
            compat=string(version)),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
