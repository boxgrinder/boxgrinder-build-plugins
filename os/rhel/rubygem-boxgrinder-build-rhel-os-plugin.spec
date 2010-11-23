%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-rhel-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: Red Hat Enterprise Linux Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.6
Release: 1%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}

Requires: rubygem(boxgrinder-build)
Requires: rubygem(boxgrinder-build-rpm-based-os-plugin)

BuildRequires: rubygem(boxgrinder-build)
BuildRequires: rubygem(hashery)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build Red Hat Enterprise Linux Operating System Plugin

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
* Thu Nov 11 2010  <mgoldman@redhat.com> - 0.0.6-1
- [BGBUILD-87] Set default filesystem to ext4 for Fedora 13+

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.5-2
- Added 'check' section that executes tests

* Wed Nov 03 2010  <mgoldman@redhat.com> - 0.0.5-1
- [BGBUILD-82] Root password not set when selinux packages are added

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.4-1
- Initial package
