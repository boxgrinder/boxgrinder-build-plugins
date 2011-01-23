%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-fedora-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Fedora Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.7
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build-rpm-based-os-plugin) >= 0.0.11

BuildRequires: rubygem(boxgrinder-build-rpm-based-os-plugin) >= 0.0.11
BuildRequires: rubygem(hashery)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Fedora Operating System Plugin to build appliances based on Fedora OS.

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

%files doc
%defattr(-, root, root, -)
%{geminstdir}/spec
%{geminstdir}/Rakefile
%{geminstdir}/rubygem-%{gemname}.spec
%{geminstdir}/%{gemname}.gemspec
%{gemdir}/doc/%{gemname}-%{version}

%changelog
* Sun Jan 09 2011  <mgoldman@redhat.com> - 0.0.7-1
- Updated to upstream version: 0.0.7
- Added BuildRoot tag to build for EPEL 5
- [BGBUILD-131] Check if OS is supported before executing the plugin
- [BGBUILD-101] Don't use 'includes' subsection when specifying packages

* Sun Dec 12 2010  <mgoldman@redhat.com> - 0.0.6-1
- Updated to upstream version: 0.0.6
- [BGBUILD-113] Allow to specify supported file formats for operating system plugin
- [BGBUILD-73] Add support for kickstart files
- [BGBUILD-117] Remove Fedora 11 and 12 support

* Mon Nov 29 2010  <mgoldman@redhat.com> - 0.0.5-1
- Upstream release: 0.0.5
- [BGBUILD-106] No plugin-manager require for fedora os plugin

* Mon Nov 29 2010  <mgoldman@redhat.com> - 0.0.4-5
- Extended description, removed clean section

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.4-4
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Tue Nov 23 2010  <mgoldman@redhat.com> - 0.0.4-3
- Cleanup in Requires/BuildRequires

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.4-2
- Added %check section that executes tests

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.4-1
- Initial package
