# This is the setup-hook that gets installed automatically whenever a package
# takes a dependency on this package.
# TODO(fzakaria): Understand how to integrate shellcheck similar to
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders.nix#L274

fixupOutputHooks+=('if [ -z "${dontPatchELF-}" ]; then nix-harden-needed-hook "$prefix"; fi')

nix-harden-needed-hook() {
    # TODO(fzakaria): Understand the difference between $out and $prefix
    local dir="$1"
    [ -e "$dir" ] || return 1

    header "Hardening the dynamic shared libraries in $dir"

    for i in $(find $dir -type f -name '*.so*'); do
        # sometimes there can be linker scripts matching *.so*
        if isELF "$i"; then
	    echo "Fixing soname path for $i"
            patchelf --set-soname $i $i
        fi
    done

    stopNest
}

