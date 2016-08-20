require "formula"
require 'rexml/document'

class HetsDesktop < Formula
  @@version_commit = 'b259e3b3e05433b2018f45d5781000fa3af7cbdc'
  @@version_no = '0.99'
  @@version_unix_timestamp = '1471594578'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "#{@@version_no}-#{@@version_unix_timestamp}"
  revision 2

  bottle do
    root_url 'http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets'
    revision 2
    sha256 '016cc2e8e5186d2982ce57ba46a78fcadcdc212e6ba4ad32eefdbdf63c968d4a' => :mavericks
    sha256 '016cc2e8e5186d2982ce57ba46a78fcadcdc212e6ba4ad32eefdbdf63c968d4a' => :yosemite
    sha256 '016cc2e8e5186d2982ce57ba46a78fcadcdc212e6ba4ad32eefdbdf63c968d4a' => :el_capitan
  end

  depends_on 'cabal-install' => :build
  depends_on 'ghc' => :build
  depends_on 'gcc49' => :build
  depends_on 'glib' => :build
  depends_on 'binutils' => :build

  depends_on 'cairo' => :build
  depends_on 'fontconfig' => :build
  depends_on 'freetype' => :build
  depends_on 'gettext' => :build
  depends_on 'gtk' => :build

  depends_on :x11
  depends_on 'hets-commons'
  depends_on 'udrawgraph'
  depends_on 'libglade'

  depends_on 'darwin' => :recommended
  depends_on 'eprover' => :recommended
  depends_on 'factplusplus' => :recommended
  depends_on 'owltools' => :recommended
  depends_on 'pellet' => :recommended
  depends_on 'spass' => :recommended

  def install
    make_compile_target = 'hets.bin'
    make_install_target = 'install-hets'
    executable = 'hets'
    binary = "hets.bin"

    install_dependencies

    puts "Compiling #{executable}..."
    system(%(make #{make_compile_target}))
    system("strip #{binary}")

    puts 'Putting everything together...'
    system(%(make #{make_install_target} PREFIX="#{prefix}"))
    patch_wrapper_script(executable)
  end

  def caveats
  end

  protected

  def install_dependencies
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['-p', '--global', "--prefix=#{ghc_prefix}"]
    flags = %w()

    package_list = `ghc-pkg list`
    if !package_list.include?(' gtk-')
      puts 'Installing dependencies...'

      system('cabal', 'update')

      # GTK needs special treatment on macOS: The order of installation steps is
      # very important, as is the environment (pkg-config needs to be found).
      # See also http://stackoverflow.com/a/38919482/2068056
      ENV['PATH'] = "/usr/local/bin/:#{ENV['PATH']}"
      ENV['PKG_CONFIG_PATH'] = "/usr/local/lib/pkgconfig:"
      system('cabal', 'install', 'alex', 'happy', *opts)
      system('cabal', 'install', 'gtk2hs-buildtools', *opts)
      system('cabal', 'install', 'glib', *opts)
      system('cabal', 'install', 'gtk', '-f', 'have-quartz-gtk', *opts)
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          system('git', 'clone', '--depth=1', 'https://github.com/cmaeder/glade.git', 'glade')
          system('cabal', 'install', 'glade/glade.cabal', *opts, '--with-gcc=gcc-4.9')
        end
      end
    end
    system('cabal', 'install', '--only-dependencies', *flags, *opts)
  end

  # The wrapper script needs to use a shell that is certainly installed.
  # It needs to point to the correct executable.
  # Hets needs to have additional locale settings.
  # It also needs to use the hets-commons package which is located in a
  # different directory.
  def patch_wrapper_script(prog)
		wrapper_script_header = <<-WRAPPER_SCRIPT_HEADER
#!/bin/bash

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

COMMONSDIR="#{HOMEBREW_PREFIX.join('opt', 'hets-commons')}"
PROGDIR="#{prefix}"
PROG="#{prog}"

[[ -z ${HETS_JNI_LIBS} ]] && \\
		        HETS_JNI_LIBS="#{HOMEBREW_PREFIX.join('opt', 'factplusplus')}"
WRAPPER_SCRIPT_HEADER

		# Replace the header until (including) the line starting with PROG=
		inreplace(bin.join(prog), /\A.*PROG=[^\n]*$/m, wrapper_script_header)
    inreplace(bin.join(prog), 'BASEDIR', 'COMMONSDIR')
    inreplace(bin.join(prog), /PELLET_PATH=.*$/, "PELLET_PATH=#{HOMEBREW_PREFIX.join('opt', 'pellet', 'bin')}")
    inreplace(bin.join(prog), /^\s*exec\s+(["']).*COMMONSDIR[^\/]*/, 'exec \1${PROGDIR}')
  end
end
