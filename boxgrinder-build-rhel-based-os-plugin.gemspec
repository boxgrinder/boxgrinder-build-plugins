# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{boxgrinder-build-rhel-based-os-plugin}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marek Goldmann"]
  s.date = %q{2010-07-04}
  s.description = %q{BoxGrinder Build Red Hat Enterprise Linux Based Operating System Plugin}
  s.email = %q{info@boxgrinder.org}
  s.homepage = %q{http://www.jboss.org/stormgrind/projects/boxgrinder/build.html}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{boxgrinder-build-plugins}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Red Hat Enterprise Linux Based Operating System Plugin}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<boxgrinder-build-rpm-based-os-plugin>, [">= 0.0.1"])
      s.add_runtime_dependency(%q<boxgrinder-build>, [">= 0.4.2"])
    else
      s.add_dependency(%q<boxgrinder-build-rpm-based-os-plugin>, [">= 0.0.1"])
      s.add_dependency(%q<boxgrinder-build>, [">= 0.4.2"])
    end
  else
    s.add_dependency(%q<boxgrinder-build-rpm-based-os-plugin>, [">= 0.0.1"])
    s.add_dependency(%q<boxgrinder-build>, [">= 0.4.2"])
  end
end

