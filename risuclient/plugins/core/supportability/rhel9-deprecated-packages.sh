#!/bin/bash

# Copyright (C) 2022 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Reports packages documented to be deprecated in RHEL 8
# description: Reports in-use packages that will be deprecated in next major release
# priority: 1
# kb: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9-beta/html-single/considerations_in_adopting_rhel_9/index#removed-packages_assembly_changes-to-packages

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

RELEASE=$(discover_rhrelease)

[[ ${RELEASE} -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ ${RELEASE} -gt "8" ]]; then
    echo "test not applicable to EL9 releases or higher" >&2
    exit ${RC_SKIPPED}
fi

flag=0

echo "Following packages will be deprecated in RHEL9:" >&2

for package in team libteam iptables-nft ipset network-scripts python3-syspurpose zchunk libdb mcpp python3-pytz adobe-source-sans-pro-fonts adwaita-qt amanda amanda-client amanda-libs amanda-server ant-contrib antlr3 antlr32 aopalliance apache-commons-collections apache-commons-compress apache-commons-exec apache-commons-jxpath apache-commons-parent apache-ivy apache-parent apache-resource-bundles apache-sshd apiguardian assertj-core auto autoconf213 autogen base64coder batik bea-stax bea-stax-api bouncycastle bsh buildnumber-maven-plugin byaccj cal10n cbi-plugins cdparanoia cdparanoia-devel cdparanoia-libs cdrdao cmirror codehaus-parent codemodel compat-exiv2-026 compat-guile18 compat-libpthread-nonshared compat-openssl10 compat-sap-c++-10 ctags ctags-etags custodia dbus-c++ dbus-c++-devel dbus-c++-glib dbxtool dirsplit dleyna-connector-dbus dleyna-core dleyna-renderer dleyna-server dnssec-trigger dptfxtract drpm drpm-devel dvd+rw-tools dyninst-static eclipse-ecf eclipse-emf eclipse-license ed25519-java ee4j-parent elfutils-devel-static elfutils-libelf-devel-static enca enca-devel environment-modules-compat evince-browser-plugin exec-maven-plugin farstream02 felix-osgi-compendium felix-osgi-core felix-osgi-foundation felix-parent file-roller fipscheck fipscheck-devel fipscheck-lib firewire forge-parent fusesource-pom fuse-sshfs future gamin gamin-devel gavl gcc-toolset-10 gcc-toolset-10-annobin gcc-toolset-10-binutils gcc-toolset-10-binutils-devel gcc-toolset-10-build gcc-toolset-10-dwz gcc-toolset-10-dyninst gcc-toolset-10-dyninst-devel gcc-toolset-10-elfutils gcc-toolset-10-elfutils-debuginfod-client gcc-toolset-10-elfutils-debuginfod-client-devel gcc-toolset-10-elfutils-devel gcc-toolset-10-elfutils-libelf gcc-toolset-10-elfutils-libelf-devel gcc-toolset-10-elfutils-libs gcc-toolset-10-gcc gcc-toolset-10-gcc-c++ gcc-toolset-10-gcc-gdb-plugin gcc-toolset-10-gcc-gfortran gcc-toolset-10-gdb gcc-toolset-10-gdb-doc gcc-toolset-10-gdb-gdbserver gcc-toolset-10-libasan-devel gcc-toolset-10-libatomic-devel gcc-toolset-10-libitm-devel gcc-toolset-10-liblsan-devel gcc-toolset-10-libquadmath-devel gcc-toolset-10-libstdc++-devel gcc-toolset-10-libstdc++-docs gcc-toolset-10-libtsan-devel gcc-toolset-10-libubsan-devel gcc-toolset-10-ltrace gcc-toolset-10-make gcc-toolset-10-make-devel gcc-toolset-10-perftools gcc-toolset-10-runtime gcc-toolset-10-strace gcc-toolset-10-systemtap gcc-toolset-10-systemtap-client gcc-toolset-10-systemtap-devel gcc-toolset-10-systemtap-initscript gcc-toolset-10-systemtap-runtime gcc-toolset-10-systemtap-sdt-devel gcc-toolset-10-systemtap-server gcc-toolset-10-toolchain gcc-toolset-10-valgrind gcc-toolset-10-valgrind-devel gcc-toolset-9 gcc-toolset-9-annobin gcc-toolset-9-build gcc-toolset-9-perftools gcc-toolset-9-runtime gcc-toolset-9-toolchain GConf2 GConf2-devel genisoimage genwqe-tools genwqe-vpd genwqe-zlib genwqe-zlib-devel geoipupdate geronimo-annotation geronimo-jms geronimo-jpa geronimo-parent-poms gfbgraph gflags gflags-devel glassfish-annotation-api glassfish-el glassfish-fastinfoset glassfish-jaxb-core glassfish-jaxb-txw2 glassfish-jsp glassfish-jsp-api glassfish-legal glassfish-master-pom glassfish-servlet-api glew-devel glib2-fam glog glog-devel gmock gmock-devel gnome-boxes gnome-menus-devel gnome-online-miners gnome-shell-extension-disable-screenshield gnome-shell-extension-horizontal-workspaces gnome-shell-extension-no-hot-corner gnome-shell-extension-window-grouper gnome-themes-standard google-gson gphoto2 gssntlmssp gtest gtest-devel gtkmm24 gtkmm24-devel gtkmm24-docs gtksourceview3 gtksourceview3-devel gtkspell gtkspell-devel guile gutenprint-gimp gvfs-afc gvfs-afp gvfs-archive hawtjni highlight-gui hplip-gui httpcomponents-project icedax icu4j idm-console-framework ipython isl isl-devel isorelax istack-commons-runtime istack-commons-tools iwl3945-firmware iwl4965-firmware iwl6000-firmware jacoco jaf jakarta-oro janino jansi-native jarjar java-atk-wrapper javacc javacc-maven-plugin java_cup javaewah javaparser javapoet javassist jaxen jboss-annotations-1.2-api jboss-interceptors-1.2-api jboss-logmanager jboss-parent jctools jdepend jdependency jdom jdom2 jetty jffi jflex jgit jline jnr-netdb jolokia-jvm-agent jsch json_simple jss-javadoc js-uglify jtidy junit5 jvnet-parent jzlib ldapjdk-javadoc lensfun lensfun-devel libaec libaec-devel libappindicator-gtk3 libappindicator-gtk3-devel libavc1394 libblocksruntime libcacard libcacard-devel libcgroup libchamplain libchamplain-devel libchamplain-gtk libcroco libcroco-devel libcxl libcxl-devel libdap libdap-devel libdazzle-devel libdbusmenu libdbusmenu-devel libdbusmenu-doc libdbusmenu-gtk3 libdbusmenu-gtk3-devel libdnet libdnet-devel libdv libdwarf libdwarf-devel libdwarf-static libdwarf-tools libepubgen-devel libertas-sd8686-firmware libertas-usb8388-firmware libertas-usb8388-olpc-firmware libgdither libGLEW libgovirt libguestfs-benchmarking libguestfs-gfs2 libguestfs-java libguestfs-java-devel libguestfs-javadoc libguestfs-tools libguestfs-tools-c libhugetlbfs libhugetlbfs-devel libhugetlbfs-utils libIDL libIDL-devel libidn libiec61883 libindicator-gtk3 libindicator-gtk3-devel libiscsi-devel liblogging libmcpp libmetalink libmodulemd1 libmongocrypt libmtp-devel libmusicbrainz5 libmusicbrainz5-devel liboauth liboauth-devel libpfm-static libpurple libpurple-devel libraw1394 libsass libsass-devel libselinux-python libsqlite3x libtar libunwind libusal libvarlink libvirt-admin libvirt-bash-completion libvirt-daemon-driver-storage-gluster libvirt-daemon-driver-storage-iscsi-direct libvirt-gconfig libvirt-gobject libvncserver libwmf libwmf-devel libwmf-lite libXNVCtrl libyami log4j12 lucene mailman make-devel maven2 maven-antrun-plugin maven-assembly-plugin maven-clean-plugin maven-dependency-analyzer maven-dependency-plugin maven-doxia maven-doxia-sitetools maven-install-plugin maven-invoker maven-invoker-plugin maven-parent maven-plugins-pom maven-reporting-api maven-reporting-impl maven-scm maven-script-interpreter maven-shade-plugin maven-shared maven-verifier meanwhile mercurial metis metis-devel mingw32-bzip2 mingw32-bzip2-static mingw32-cairo mingw32-expat mingw32-fontconfig mingw32-freetype mingw32-freetype-static mingw32-gstreamer1 mingw32-harfbuzz mingw32-harfbuzz-static mingw32-icu mingw32-libjpeg-turbo mingw32-libjpeg-turbo-static mingw32-libpng mingw32-libpng-static mingw32-libtiff mingw32-libtiff-static mingw32-openssl mingw32-readline mingw32-sqlite mingw32-sqlite-static mingw64-adwaita-icon-theme mingw64-bzip2 mingw64-bzip2-static mingw64-cairo mingw64-expat mingw64-fontconfig mingw64-freetype mingw64-freetype-static mingw64-gstreamer1 mingw64-harfbuzz mingw64-harfbuzz-static mingw64-icu mingw64-libjpeg-turbo mingw64-libjpeg-turbo-static mingw64-libpng mingw64-libpng-static mingw64-libtiff mingw64-libtiff-static mingw64-nettle mingw64-openssl mingw64-readline mingw64-sqlite mingw64-sqlite-static modello mojo-parent mongo-c-driver mousetweaks mozjs52 mozjs52-devel mozjs60 mozjs60-devel mozvoikko msv-javadoc msv-manual munge-maven-plugin nbd-3.21-2.el9 nbdkit-gzip-plugin netcf netcf-devel netcf-libs nkf nss_nis nss-pam-ldapd objectweb-asm objectweb-pom ocaml-bisect-ppx ocaml-camlp4 ocaml-camlp4-devel ocaml-lwt-5.3.0-7.el9 ocaml-mmap-1.1.0-16.el9 ocaml-ocplib-endian-1.1-5.el9 ocaml-ounit-2.2.2-15.el9 ocaml-result-1.5-7.el9 ocaml-seq-0.2.2-4.el9 opencv-contrib opencv-core opencv-devel openhpi openhpi-libs OpenIPMI-perl openssh-cavs openssh-ldap openssl-ibmpkcs11 opentest4j os-maven-plugin pakchois pandoc paranamer parfait parfait-examples parfait-javadoc pcp-parfait-agent pcp-pmda-rpm pcsc-lite-doc perl-B-Debug perl-B-Lint perl-Class-Factory-Util perl-Class-ISA perl-DateTime-Format-HTTP perl-DateTime-Format-Mail perl-File-CheckTree perl-homedir perl-libxml-perl perl-Locale-Codes perl-Mozilla-LDAP perl-NKF perl-Object-HashBase-tools perl-Package-DeprecationManager perl-Pod-LaTeX perl-Pod-Plainer perl-prefork perl-String-CRC32 perl-SUPER perl-Sys-Virt perl-tests perl-YAML-Syck phodav-2.5-4.el9 pidgin pidgin-devel pidgin-sipe pinentry-emacs pinentry-gtk pipewire0.2-devel pipewire0.2-libs plexus-ant-factory plexus-bsh-factory plexus-cli plexus-component-api plexus-component-factories-pom plexus-components-pom plexus-i18n plexus-interactivity plexus-pom plexus-velocity plymouth-plugin-throbgress powermock ptscotch-mpich ptscotch-mpich-devel ptscotch-mpich-devel-parmetis ptscotch-openmpi ptscotch-openmpi-devel purple-sipe python2-mock python3-click python3-cpio python3-custodia python3-flask python3-gevent python3-html5lib python3-hypothesis python3-itsdangerous python3-jwt python3-mock python3-networkx-core python3-nss python3-openipmi python3-pillow python3-pydbus python3-pymongo python3-pyOpenSSL python3-reportlab python3-schedutils python3-scons python3-semantic_version python3-syspurpose python3-virtualenv python3-webencodings python3-werkzeug python-nss-doc python-redis python-schedutils python-slip python-varlink qemu-kvm-block-gluster qemu-kvm-block-iscsi qemu-kvm-tests qpdf qpid-proton qrencode qrencode-devel qrencode-libs qt5-qtcanvas3d qt5-qtcanvas3d-examples rarian rarian-compat re2c redhat-menus redhat-support-lib-python redhat-support-tool reflections regexp relaxngDatatype rhsm-gtk rpm-plugin-prioreset rubygem-abrt rubygem-abrt-doc rubygem-mongo rubygem-mongo-doc sane-frontends sanlk-reset scala scotch scotch-devel SDL_sound selinux-policy-minimum shrinkwrap sisu-mojos SLOF sonatype-oss-parent sonatype-plugins-parent sparsehash-devel spec-version-maven-plugin spice-0.14.3-4.el9 spice-client-win-x64 spice-client-win-x86 spice-glib spice-glib-devel spice-gtk spice-gtk3 spice-gtk3-devel spice-gtk3-vala spice-gtk-tools spice-parent spice-qxl-wddm-dod spice-server-devel spice-streaming-agent spice-vdagent-win-x64 spice-vdagent-win-x86 stax2-api stax-ex stringtemplate stringtemplate4 subscription-manager-initial-setup-addon subscription-manager-migration subscription-manager-migration-data subversion-javahl SuperLU SuperLU-devel system-storage-manager testng timedatex treelayout trousers tycho uglify-js univocity-output-tester univocity-parsers usbguard-notifier utf8cpp uthash velocity vinagre vino virt-dib virt-p2v-maker vm-dump-metrics-devel weld-parent wodim woodstox-core xmlgraphics-commons xmlstreambuffer xorg-x11-apps xorg-x11-drv-qxl xorg-x11-server-Xspice xpp3 xsane-gimp xsom xz-java yajl-devel ypbind ypserv yp-tools; do
    is_rpm ${package} >&2 && flag=1
done

if [[ $flag -eq "1" ]]; then
    echo $"Check RHEL9 deprecation notice" >&2
    exit ${RC_INFO}
fi

exit ${RC_OKAY}
