%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-local-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Local Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.4
Release: 2%{?dist}
Group: Development/Languages
License: LGPL
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygems >= 1.2
Requires: ruby >= 0
Requires: rubygem(boxgrinder-build) => 0.6.3
Requires: rubygem(boxgrinder-build) < 0.7
BuildRequires: rubygems >= 1.2
BuildRequires: ruby >= 0

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
* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.4-2
- Added 'check' section that executes tests

* Fri Nov 05 2010  <mgoldman@redhat.com> - 0.0.4-1
- [BGBUILD-85] Adjust BoxGrinder spec files for review

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.3-1
- Initial package
