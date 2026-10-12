#!/bin/bash
#---------------------------------------------------------------------------
# build_perf_libs.sh : zlib and libelf (elfutils) for perf, static, riscv64
#
#   ./scripts/build_perf_libs.sh
#
# What build_perf.sh needs to resolve symbols (ROADMAP.md D2): with libelf
# perf reads the symbol tables of the programs it samples and of the
# kernel's modules, so that perf report sorts by function. Only libelf is
# built (not libdw: no DWARF unwinding or source lines), against zlib for
# the compressed sections. Both go to $PREFIX, which build_perf.sh uses
# when it is there.
#
# The sources are downloaded once into $SRC (zlib.net, sourceware.org).
#---------------------------------------------------------------------------
set -e

ZLIB_VER=${ZLIB_VER:-1.3.2}
ELFUTILS_VER=${ELFUTILS_VER:-0.196}
SRC=${SRC:-$HOME/mmlitex_build/perf_libs_src}
PREFIX=${PREFIX:-$HOME/mmlitex_build/perf_libs}
HOST=riscv64-unknown-linux-gnu

export PATH=/opt/riscv/bin:$PATH
mkdir -p "$SRC" "$PREFIX"
cd "$SRC"

[ -f zlib-$ZLIB_VER.tar.gz ] ||
    wget -q https://zlib.net/zlib-$ZLIB_VER.tar.gz
[ -f elfutils-$ELFUTILS_VER.tar.bz2 ] ||
    wget -q https://sourceware.org/elfutils/ftp/$ELFUTILS_VER/elfutils-$ELFUTILS_VER.tar.bz2

# zlib
rm -rf zlib-$ZLIB_VER && tar xzf zlib-$ZLIB_VER.tar.gz
( cd zlib-$ZLIB_VER &&
  CC=$HOST-gcc AR=$HOST-ar RANLIB=$HOST-ranlib CFLAGS="-O2 -fPIC" \
      ./configure --prefix="$PREFIX" --static &&
  make -j"$(nproc)" && make install )

# libelf only (lib/ and libelf/ of elfutils)
rm -rf elfutils-$ELFUTILS_VER && tar xjf elfutils-$ELFUTILS_VER.tar.bz2
( cd elfutils-$ELFUTILS_VER &&
  ./configure --host=$HOST --prefix="$PREFIX" \
      --disable-debuginfod --disable-libdebuginfod --disable-nls \
      --without-bzlib --without-lzma --without-zstd \
      --program-prefix=eu- \
      CFLAGS="-O2 -fPIC -Wno-error" \
      CPPFLAGS="-I$PREFIX/include" LDFLAGS="-L$PREFIX/lib" &&
  make -C lib -j"$(nproc)" &&
  make -C libelf -j"$(nproc)" libelf.a &&
  mkdir -p "$PREFIX/include" "$PREFIX/lib" &&
  cp libelf/libelf.a "$PREFIX/lib/" &&
  cp libelf/libelf.h libelf/gelf.h libelf/nlist.h "$PREFIX/include/" )

ls -l "$PREFIX/lib/libz.a" "$PREFIX/lib/libelf.a"
