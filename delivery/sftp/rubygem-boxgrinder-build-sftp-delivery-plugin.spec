%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-sftp-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: SSH File Transfer Protocol Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.5
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build) >= 0.7.0
Requires: rubygem(net-sftp)
Requires: rubygem(net-ssh)
Requires: rubygem(progressbar)

BuildRequires: rubygem(boxgrinder-build) >= 0.7.0
BuildRequires: rubygem(net-sftp)
BuildRequires: rubygem(net-ssh)
BuildRequires: rubygem(progressbar)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build SSH File Transfer Protocol Delivery Plugin to deliver
appliances to remote servers using SFTP protocol.

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
* Tue Dec 14 2010  <mgoldman@redhat.com> - 0.0.5-1
- Upstream release: 0.0.5
- [BGBUILD-115] PackageHelper should take directory instead of file list to package

* Mon Nov 29 2010  <mgoldman@redhat.com> - 0.0.4-1
- Upstream release: 0.0.4
- [BGBUILD-108] No plugin-manager require for sftp delivery plugin

* Tue Nov 23 2010  <mgoldman@redhat.com> - 0.0.3-3
- Cleaned Requires/Build Requires
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.3-2
- Added 'check' section that executes tests

* Fri Nov 05 2010  <mgoldman@redhat.com> - 0.0.3-1
- [BGBUILD-85] Adjust BoxGrinder spec files for review

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.2-1
- Initial package
