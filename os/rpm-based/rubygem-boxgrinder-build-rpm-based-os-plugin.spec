%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-rpm-based-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: RPM Based Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.11
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build) >= 0.8.0
Requires: appliance-tools
Requires: yum-utils

BuildRequires: rubygem(hashery)
BuildRequires: rubygem(boxgrinder-build) >= 0.8.0
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build RPM Based Operating System Plugin

%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires:%{name} = %{version}-%{release}

%description doc
Documentation for %{name}

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}

%check
pushd %{buildroot}/%{geminstdir}/spec
rake spec
popd

%files
%defattr(-, root, root, -)
%dir %{geminstdir}
%{geminstdir}/lib
%doc %{geminstdir}/CHANGELOG
%doc %{geminstdir}/LICENSE
%doc %{geminstdir}/README
%doc %{geminstdir}/Manifest
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%attr(0644,root,root) %{geminstdir}/lib/boxgrinder-build-rpm-based-os-plugin/src/motd.init

%files doc
%defattr(-, root, root, -)
%{geminstdir}/spec
%{geminstdir}/Rakefile
%{geminstdir}/rubygem-%{gemname}.spec
%{geminstdir}/%{gemname}.gemspec
%{gemdir}/doc/%{gemname}-%{version}

%changelog
* Tue Jan 04 2011  <mgoldman@redhat.com> - 0.0.11-1
- Upstream release: 0.0.11
- [BGBUILD-79] Allow to use BoxGrinder Build as a library
- [BGBUILD-126] Use encrypted password in kickstart files
- [BGBUILD-129] Use partitions labels instead of device path in grub and fstab
- [BGBUILD-72] Add support for growing (not pre-allocated) disks for KVM/Xen
- [BGBUILD-101] Don't use 'includes' subsection when specifying packages

* Tue Dec 21 2010  <mgoldman@redhat.com> - 0.0.10-1
- Updated to upstream version: 0.0.10
- [BGBUILD-100] Enable boxgrinder_build to create a Fedora image with encrypted partition(s)
- [BGBUILD-125] Create kickstart files in RPM-based OS plugin in a temporary directory

* Sun Dec 12 2010  <mgoldman@redhat.com> - 0.0.9-1
- Updated to upstream version: 0.0.9
- [BGBUILD-59] Remove all image modifications user is not expecting
- [BGBUILD-113] Allow to specify supported file formats for operating system plugin
- [BGBUILD-73] Add support for kickstart files
- [BGBUILD-42] No man pages installed in appliances

* Fri Nov 26 2010  <mgoldman@redhat.com> - 0.0.8-3
- Removed clean section, updated URL, fixed attr for motd.init file

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.8-2
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Mon Nov 22 2010  <mgoldman@redhat.com> - 0.0.8-1
- Updated to upstream version: 0.0.8
- [BGBUILD-102] Start X on boot when X Window System group or base-x group is specified

* Thu Nov 11 2010  <mgoldman@redhat.com> - 0.0.7-1
- Updated to upstream version: 0.0.7
- [BGBUILD-87] Set default filesystem to ext4 for Fedora 13+

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.6-2
- Added 'check' section that executes tests

* Wed Nov 03 2010  <mgoldman@redhat.com> - 0.0.6-1
- Updated to upstream version: 0.0.6
- [BGBUILD-82] Root password not set when selinux packages are added

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.5-1
- Initial package
