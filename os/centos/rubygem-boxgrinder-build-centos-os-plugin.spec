%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname boxgrinder-build-centos-os-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%global rubyabi 1.8

Summary: CentOS Operating System Plugin
Name: rubygem-%{gemname}
Version: 0.0.5
Release: 2%{?dist}
Group: Development/Languages
License: LGPLv3+
URL: http://www.jboss.org/boxgrinder
Source0: http://rubygems.org/gems/%{gemname}-%{version}.gem

Requires: ruby(abi) = %{rubyabi}

Requires: rubygem(boxgrinder-build)
Requires: rubygem(boxgrinder-build-rhel-os-plugin)

BuildRequires: rubygem(hashery)
BuildRequires: rubygem(boxgrinder-build-rhel-os-plugin)
BuildRequires: rubygem(echoe)
BuildRequires: rubygem(rake)
BuildRequires: rubygem(rspec)

BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
BoxGrinder Build CentOS Operating System Plugin

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
* Wed Nov 24 2010  <mgoldman@redhat.com> - 0.0.5-2
- Added BR: rubygem(rake), BR: rubygem(echoe), BR: rubygem(rspec)

* Wed Nov 10 2010  <mgoldman@redhat.com> - 0.0.5-1
- [BGBUILD-88] CentOS plugin uses #ARCH# instead of #BASE_ARCH#

* Mon Nov 08 2010  <mgoldman@redhat.com> - 0.0.4-2
- Added %check section that executes tests

* Mon Oct 18 2010  <mgoldman@redhat.com> - 0.0.4-1
- Initial package
