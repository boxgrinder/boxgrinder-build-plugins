%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-rpm-based-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: RPM Based Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.5
Release: 1%{?dist}
Group: Development/Languages
License: LGPL
URL: http://www.jboss.org/stormgrind/projects/boxgrinder.html
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygems >= 1.2
Requires: ruby >= 0
Requires: rubygem(boxgrinder-build) => 0.6.0
Requires: rubygem(boxgrinder-build) < 0.7
Requires: appliance-tools
Requires: yum-utils
Requires: ruby-libguestfs
BuildRequires: rubygems >= 1.2
BuildRequires: ruby >= 0

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build RPM Based Operating System Plugin

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%dir %{geminstdir}
%{geminstdir}/lib
%doc %{gemdir}/doc/%{gemname}-%{version}
%doc %{geminstdir}/%{gemname}.gemspec
%doc %{geminstdir}/rubygem-%{gemname}.spec
%doc %{geminstdir}/CHANGELOG
%doc %{geminstdir}/LICENSE
%doc %{geminstdir}/README
%doc %{geminstdir}/Manifest
%doc %{geminstdir}/Rakefile
%doc %{geminstdir}/spec
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%changelog
* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.5-1
- Initial package
