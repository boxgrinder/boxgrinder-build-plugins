%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-ebs-delivery-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Elastic Block Storage Delivery Plugin
Name: rubygem-%{gemname}
Version: 0.0.1
Release: 1%{?dist}
Group: Development/Languages
License: LGPL
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygems >= 1.2
Requires: ruby >= 0
Requires: rubygem(boxgrinder-build) => 0.6.0
Requires: rubygem(boxgrinder-build) < 0.7
Requires: rubygem(amazon-ec2) => 0.9.6
Requires: rubygem(amazon-ec2) < 0.10
Requires: rubygem(aws-s3) => 0.6.2
Requires: rubygem(aws-s3) < 0.7
BuildRequires: rubygems >= 1.2
BuildRequires: ruby >= 0

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Elastic Block Storage Delivery Plugin

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
* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.1-1
- Initial package
