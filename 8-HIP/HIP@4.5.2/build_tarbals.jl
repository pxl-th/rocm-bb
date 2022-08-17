using Pkg
using BinaryBuilder

include("../common.jl")
# configure_build(v"4.5.2")
build_tarballs(
    ARGS, configure_build(v"4.5.2")...;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9")
