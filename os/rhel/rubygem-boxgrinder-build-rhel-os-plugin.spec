%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-rhel-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Red Hat Enterprise Linux Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.9
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://boxgrinder.org/
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build-rpm-based-os-plugin) >= 0.0.12

BuildRequires: rubygem(boxgrinder-build-rpm-based-os-plugin) >= 0.0.12
BuildRequires: rubygem(hashery)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Red Hat Enterprise Linux Operating System Plugin

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

%clean
rm -rf %{buildroot}

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

%files doc
%defattr(-, root, root, -)
%{geminstdir}/spec
%{geminstdir}/Rakefile
%{geminstdir}/rubygem-%{gemname}.spec
%{geminstdir}/%{gemname}.gemspec
%{gemdir}/doc/%{gemname}-%{version}

%changelog
* Mon Feb 21 2011  <mgoldman@redhat.com> - 0.0.9-1
- Upstream release: 0.0.9
- [BGBUILD-165] Use version in dependencies in gem and in RPM only where necessary

* Sat Jan 08 2011  <mgoldman@redhat.com> - 0.0.8-1
- Updated to upstream version: 0.0.8
- Added BuildRoot tag to build for EPEL 5
- [BGBUILD-130] Add virtio support out of the box
- [BGBUILD-93] Add Red Hat Enterprise Linux 6 support
- [BGBUILD-101] Don't use 'includes' subsection when specifying packages

* Sun Dec 12 2010  <mgoldman@redhat.com> - 0.0.7-1
- Updated to upstream version: 0.0.7
- [BGBUILD-113] Allow to specify supported file formats for operating system plugin
- [BGBUILD-73] Add support for kickstart files

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.6-2
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec), BR: rubygem(boxgrinder-build-rpm-based-os-plugin)

* Thu Nov 11 2010  <mgoldman@redhat.com> - 0.0.6-1
- [BGBUILD-87] Set default filesystem to ext4 for Fedora 13+

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.5-2
- Added 'check' section that executes tests

* Wed Nov 03 2010  <mgoldman@redhat.com> - 0.0.5-1
- [BGBUILD-82] Root password not set when selinux packages are added

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.4-1
- Initial package
