package=native_cctools
$(package)_version=809
$(package)_download_path=https://github.com/apple-oss-distributions/cctools/archive/refs/tags
$(package)_file_name=cctools-$($(package)_version).tar.gz
$(package)_sha256_hash=ab0f789ac5d1913dd11bd73384fecd7a13e0e3666c4a2483dc750465376238d4
$(package)_build_subdir=cctools2odcctools/odcctools-$($(package)_version)
$(package)_dependencies=native_libuuid native_openssl
$(package)_ld64_download_file=ld64-127.2.tar.gz
$(package)_ld64_download_path=https://github.com/apple-oss-distributions/ld64/archive/refs/tags
$(package)_ld64_file_name=$($(package)_ld64_download_file)
$(package)_ld64_sha256_hash=acfc5c3340a24ad8696ff22027b121cb3807c75fade7dec48b2b52494698e05f
$(package)_dyld_download_file=dyld-195.5.tar.gz
$(package)_dyld_download_path=https://github.com/apple-oss-distributions/dyld/archive/refs/tags
$(package)_dyld_file_name=$($(package)_dyld_download_file)
$(package)_dyld_sha256_hash=3b4eec5b5878c3ad224a91d9bfbedd3aa46192e063da2ec0bba5e4eca6fb5627
$(package)_toolchain4_download_file=10cc648683617cca8bcbeae507888099b41b530c.tar.gz
$(package)_toolchain4_download_path=https://github.com/mingwandroid/toolchain4/archive
$(package)_toolchain4_file_name=toolchain4-1.tar.gz
$(package)_toolchain4_sha256_hash=d82a7f324d9e7bfe4e62a70b1500e97f9f4abffcdf0025f2e7caf1dec79d30e5
$(package)_clang_download_file=clang+llvm-3.2-x86-linux-ubuntu-12.04.tar.gz
$(package)_clang_download_path=http://llvm.org/releases/3.2
$(package)_clang_file_name=clang-llvm-3.2-x86-linux-ubuntu-12.04.tar.gz
$(package)_clang_sha256_hash=b9d57a88f9514fa1f327a1a703756d0c1c960f4c58494a5bd80313245d13ffff

define $(package)_fetch_cmds
$(call fetch_file,$(package),$($(package)_download_path),$($(package)_download_file),$($(package)_file_name),$($(package)_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_ld64_download_path),$($(package)_ld64_download_file),$($(package)_ld64_file_name),$($(package)_ld64_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_dyld_download_path),$($(package)_dyld_download_file),$($(package)_dyld_file_name),$($(package)_dyld_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_clang_download_path),$($(package)_clang_download_file),$($(package)_clang_file_name),$($(package)_clang_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_toolchain4_download_path),$($(package)_toolchain4_download_file),$($(package)_toolchain4_file_name),$($(package)_toolchain4_sha256_hash))
endef

define $(package)_set_vars
$(package)_config_opts=--target=$(host) --with-sysroot=$(OSX_SDK)
$(package)_cflags+=-m32
$(package)_cxxflags+=-m32
$(package)_cppflags+=-D__DARWIN_UNIX03 -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS
$(package)_ldflags+=-m32 -Wl,-rpath=\\$$$$$$$$\$$$$$$$$ORIGIN/../lib
$(package)_ldflags+=-L$$(native_cctools_extract_dir)/clang+llvm-3.2-x86-linux-ubuntu-12.04/lib
endef
define $(package)_extract_cmds
  tar --strip-components=1 -xf $($(package)_source_dir)/$($(package)_toolchain4_file_name) && \
  ln -sf $($(package)_source) cctools2odcctools/$($(package)_file_name) && \
  ln -sf $($(package)_source_dir)/$($(package)_ld64_file_name) cctools2odcctools/$($(package)_ld64_file_name) && \
  ln -sf $($(package)_source_dir)/$($(package)_dyld_file_name) cctools2odcctools/$($(package)_dyld_file_name) && \
  tar xf $($(package)_source_dir)/$($(package)_clang_file_name) && \
  mkdir -p $(SDK_PATH) sdks &&\
  cd sdks; ln -sf $(OSX_SDK) MacOSX$(OSX_SDK_VERSION).sdk
endef

define $(package)_preprocess_cmds
  sed -i "s|GCC_DIR|LLVM_CLANG_DIR|g" cctools2odcctools/extract.sh && \
  sed -i "s|llvmgcc42-2336.1|clang+llvm-3.2-x86-linux-ubuntu-12.04|g" cctools2odcctools/extract.sh && \
  sed -i "s|/llvmCore/include/llvm-c|/include/llvm-c \$$$${LLVM_CLANG_DIR}/include/llvm |" cctools2odcctools/extract.sh && \
  sed -i "s|fAC_INIT|AC_INIT|" cctools2odcctools/files/configure.ac && \
  sed -i 's/\# Dynamically linked LTO/\t ;\&\n\t linux*)\n# Dynamically linked LTO/' cctools2odcctools/files/configure.ac && \
  cd cctools2odcctools; ./extract.sh --osxver $(OSX_SDK_VERSION) && \
  sed -i "s|define\tPC|define\tPC_|" odcctools-809/include/architecture/sparc/reg.h
endef

define $(package)_config_cmds
  $($(package)_autoconf)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install && \
  cd ../../clang+llvm-3.2-x86-linux-ubuntu-12.04 && \
  mkdir -p $($(package)_staging_prefix_dir)/lib/clang/3.2/include && \
  mkdir -p $($(package)_staging_prefix_dir)/bin && \
  cp -P bin/clang bin/clang++ $($(package)_staging_prefix_dir)/bin/ &&\
  cp lib/libLTO.so $($(package)_staging_prefix_dir)/lib/ && \
  cp lib/clang/3.2/include/* $($(package)_staging_prefix_dir)/lib/clang/3.2/include/ && \
  echo "#!/bin/sh" > $($(package)_staging_prefix_dir)/bin/$(host)-dsymutil && \
  echo "exit 0" >> $($(package)_staging_prefix_dir)/bin/$(host)-dsymutil && \
  chmod +x $($(package)_staging_prefix_dir)/bin/$(host)-dsymutil
endef
