%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-ebs-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Elastic Block Storage Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.3
Release: 2%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build) => 0.6.3
Requires: rubygem(boxgrinder-build) < 0.7
Requires: rubygem(amazon-ec2) => 0.9.6
Requires: rubygem(amazon-ec2) < 0.10

BuildRequires: rubygem(boxgrinder-build) => 0.6.3
BuildRequires: rubygem(boxgrinder-build) < 0.7
BuildRequires: rubygem(rake) < 0.10
BuildRequires: rubygem(rspec) < 2.0.0

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
