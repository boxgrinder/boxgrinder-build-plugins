%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-ec2-platform-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Elastic Compute Cloud (EC2) Platform Plugin
Name: rubygem-%{gemname}
Version: 0.0.9
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}
Requires: rubygem(boxgrinder-build) >= 0.8.0
Requires: rsync
Requires: wget
Requires: util-linux-ng

BuildRequires: rubygem(boxgrinder-build) >= 0.8.0
BuildRequires: rubygem(hashery)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Elastic Compute Cloud (EC2) Platform Plugin to convert appliances to EC2 format

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
* Thu Jan 06 2011  <mgoldman@redhat.com> - 0.0.9-1
- Upstream release: 0.0.9
- [BGBUILD-129] Use partitions labels instead of device path in grub and fstab
- [BGBUILD-68] Global .boxgrinder/config or rc style file for config
- [BGBUILD-131] Check if OS is supported before executing the plugin
- [BGBUILD-93] Add Red Hat Enterprise Linux 6 support

* Mon Dec 20 2010  <mgoldman@redhat.com> - 0.0.8-1
- Upstream release: 0.0.8
- [BGBUILD-123] Remove RPM database recreation code
- [BGBUILD-122] Remove kernel recreation for Fedora EC2 images

* Mon Dec 13 2010  <mgoldman@redhat.com> - 0.0.7-1
- Upstream release: 0.0.7
- [BGBUILD-110] For EC2 images don't use root account, use ec2-user instead
- [BGBUILD-117] Remove Fedora 11 and 12 support

* Fri Dec 03 2010  <mgoldman@redhat.com> - 0.0.6-1
- Upstream release: 0.0.6
- [BGBUILD-111] Don't install ec2-ami-tools by default in AMIs
- [BGBUILD-109] readdir64 bugfix for i386 base AMIs

* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.5-3
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.5-2
- [BGBUILD-85] Adjust BoxGrinder spec files for review
- Added 'check' section that executes tests

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.5-1
- Initial package
