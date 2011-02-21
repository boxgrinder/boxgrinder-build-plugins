%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-local-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Local Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.8
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://boxgrinder.org/
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build) >= 0.8.1
Requires: rubygem(boxgrinder-build) < 0.9.0

BuildRequires: rubygem(boxgrinder-build) >= 0.8.1
BuildRequires: rubygem(boxgrinder-build) < 0.9.0
BuildRequires: rubygem(hashery)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Local Delivery Plugin

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
* Fri Feb 18 2011  <mgoldman@redhat.com> - 0.0.8-1
- Upstream release: 0.0.8
- [BGBUILD-161] Local delivery plugin does not deliver appliance to target path if packaging set to false
- [BGBUILD-165] Use version in dependencies in gem and in RPM only where necessary

* Wed Jan 05 2011  <mgoldman@redhat.com> - 0.0.7-1
- Upstream release: 0.0.7
- Added BuildRoot tag to build for EPEL 5
- [BGBUILD-138] enablerepo path is not escaped when calling repoquery

* Tue Dec 14 2010  <mgoldman@redhat.com> - 0.0.6-1
- Upstream release: 0.0.6
- [BGBUILD-115] PackageHelper should take directory instead of file list to package

* Mon Nov 29 2010  <mgoldman@redhat.com> - 0.0.5-1
- Upstream release: 0.0.5
- [BGBUILD-105] No plugin-manager require for local delivery plugin

* Tue Nov 23 2010  <mgoldman@redhat.com> - 0.0.4-3
- Cleaned Requires/Build Requires
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.4-2
- Added 'check' section that executes tests

* Fri Nov 05 2010  <mgoldman@redhat.com> - 0.0.4-1
- [BGBUILD-85] Adjust BoxGrinder spec files for review

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.3-1
- Initial package
