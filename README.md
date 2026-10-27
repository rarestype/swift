# swift

Builds the Swift compiler and standard library for Linux, from Apple’s release tags plus a short list of upstream fixes, as archives that replace those parts of Apple’s toolchain.

Each archive is extracted over the `usr` of Apple’s toolchain for the same release. It replaces only files that Apple’s toolchain already has, of the same kind: the compiler (`swift-frontend`, which links LLVM) with its own libraries, and the runtime and standard library, dynamic and static, with their modules. Everything else stays Apple’s: the driver, SwiftPM, Foundation, LLDB, and what runs while compiling outside the compiler, which is the swift-syntax libraries, the macro plugins, and `swift-plugin-server`. The compiler identifies itself exactly as Apple’s does, since it has to load the modules that Apple’s compiler built. `usr/share/swift/rarest-overlay.txt` records which fixes a toolchain carries.


## Releases

`Releases/<release>` pins one Swift release, such as `6.4.1-RELEASE`. It lists the upstream commits to cherry-pick, as `<swiftlang repository> <commit>`. A commit qualifies if it is already in one of Apple’s branches, or is our own fix with an open pull request upstream. When an Apple release contains a commit, the build fails until the commit is removed from the list, so the list never carries a patch that does nothing. Every patch has a reproducer in `Tests/Reproducers`.

A release gets an archive even when its list is empty, so that the path the images depend on keeps working.

The `Watch` workflow opens an issue every Monday for each Swift release that has no pin file yet.


## Building a release

1. Add `Releases/<release>`, carrying over each patch the release doesn’t contain, in a pull request. The pull request builds and tests it.
2. Once it merges, run `Deploy` with the release. It publishes `swift-<release>-<commit>`, which is never replaced, with an archive and a checksum for each architecture.
3. Bump the image to the new archive and checksums.

Each architecture builds on a standard GitHub runner, in about three hours. The build uses the compiler and standard library settings of Apple’s `buildbot_linux,no_assertions` preset, and installs the components that Apple’s toolchain ships.


## The gate

Before a release is published, for each architecture:

- `Scripts/Compare` checks that the archive can replace Apple’s files. The standard library and runtime, which both builds compile with the compiler they just built, must export exactly the same symbols as Apple’s, and every module interface must have been compiled with the same flags. What the host compiler builds, such as `swift-frontend`, can’t match exactly, because Apple builds its compiler with an older host compiler and linker. So with the archive installed over a copy of Apple’s toolchain, every executable and library in it must still find every library and symbol it needs, and every runpath must stay inside the toolchain.
- `Scripts/Test` installs the archive over Apple’s toolchain, as the images do. It runs each reproducer, optimized, and builds a package that uses a macro, to check that the compiler still runs macro plugins.
