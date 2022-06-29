# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocm_cmake"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/rocm-cmake/archive/rocm-$(version).tar.gz",
                  "299e190ec3d38c2279d9aec762469628f0b2b1867adc082edc5708d1ac785c3b"), # 4.2.0
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*/

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("share/rocm/cmake", :cmake_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
