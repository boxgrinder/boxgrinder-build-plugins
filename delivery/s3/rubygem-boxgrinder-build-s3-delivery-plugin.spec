%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-s3-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Amazon Simple Storage Service (Amazon S3) Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.6
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: euca2ools >= 1.3.1-4
Requires: rubygem(boxgrinder-build) >= 0.8.0
Requires: rubygem(amazon-ec2)
Requires: rubygem(aws)
# Fixes blankslate error
Requires: rubygem(builder)

BuildRequires: rubygem(boxgrinder-build) >= 0.8.0
BuildRequires: rubygem(hashery)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)
BuildRequires: rubygem(amazon-ec2)
BuildRequires: rubygem(aws)
# Fixes blankslate error
BuildRequires: rubygem(builder)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Amazon Simple Storage Service (Amazon S3) Delivery Plugin

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
* Wed Jan 05 2011  <mgoldman@redhat.com> - 0.0.6-1
- Upstream release: 0.0.6
- [BGBUILD-93] Add Red Hat Enterprise Linux 6 support
- [BGBUILD-132] Require only region name change for S3 plugin to register AMI in different region
- [BGBUILD-120] Add support for all EC2 regions
- [BGBUILD-135] Display the region name when reporting the registered ami
- [BGBUILD-137] Show the appliance name in the ami registration notice

* Fri Dec 17 2010  <mgoldman@redhat.com> - 0.0.5-2
- Added rubygem-builder dependency to fix blankslate gem requirements

* Tue Dec 14 2010  <mgoldman@redhat.com> - 0.0.5-1
- Upstream release: 0.0.5
- [BGBUILD-115] PackageHelper should take directory instead of file list to package
- [BGBUILD-55] Use euca2ools instead of ec2-ami-tools
- [BGBUILD-117] Remove Fedora 11 and 12 support

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.4-3
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec), BR: rubygem(amazon-ec2), BR: rubygem(aws)

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.4-2
- Added 'check' section that executes tests

* Fri Nov 05 2010  <mgoldman@redhat.com> - 0.0.4-1
- [BGBUILD-85] Adjust BoxGrinder spec files for review

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.3-1
- Initial package
