%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-ebs-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Elastic Block Storage Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.5
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build-ec2-platform-plugin)
Requires: rubygem(amazon-ec2)
Requires: rubygem(aws)

BuildRequires: rubygem(boxgrinder-build) >= 0.8.0
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)
BuildRequires: rubygem(aws)
BuildRequires: rubygem(amazon-ec2)
BuildRequires: rubygem(echoe)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Elastic Block Storage Delivery Plugin

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
pushd %{buildroot}/%{geminstdir}
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
* Sun Jan 09 2011  <mgoldman@redhat.com> - 0.0.5-1
- Upstream release: 0.0.5
- Added BuildRoot tag to build for EPEL 5
- [BGBUILD-93] Add Red Hat Enterprise Linux 6 support
- [BGBUILD-131] Check if OS is supported before executing the plugin
- [BGBUILD-135] Display the region name when reporting the registered ami
- [BGBUILD-137] Show the appliance name in the ami registration notice
- [BGBUILD-75] Allow for some way to build and push EBS-backed AMIs to Amazon without bumping the version or release numbers in the .appl file

* Fri Dec 17 2010  <mgoldman@redhat.com> - 0.0.4-1
- Upstream release: 0.0.4

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.3-3
- Added BR: rubygem(echoe)

* Sun Nov 07 2010  <mgoldman@redhat.com> - 0.0.3-2
- Added 'check' section that executes tests

* Fri Nov 05 2010  <mgoldman@redhat.com> - 0.0.3-1
- [BGBUILD-86] EBS plugin should inform that it can be run only on EC2
- [BGBUILD-85] Adjust BoxGrinder spec files for review

* Wed Nov 03 2010  <mgoldman@redhat.com> - 0.0.2-1
- [BGBUILD-70] Enable Ephemeral Storage on EBS Images
- [BGBUILD-61] EBS availability_zone should be defaulted to current running instance availability zone
- [BGBUILD-67] Add Fedora 14 support for S3 delivery plugin and EBS delivery plugin

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.1-1
- Initial package
