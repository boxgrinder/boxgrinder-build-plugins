require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

plugins = [
    {:name => "boxgrinder-build-local-delivery-plugin", :dir => "delivery/local", :desc => 'Local Delivery Plugin'},
    {:name => "boxgrinder-build-s3-delivery-plugin", :dir => "delivery/s3", :desc => 'Amazon Simple Storage Service (Amazon S3) Delivery Plugin', :runtime_deps => {'aws' => '~>2.3.21', 'amazon-ec2' => '~>0.9.6'}},
    {:name => "boxgrinder-build-sftp-delivery-plugin", :dir => "delivery/sftp", :desc => 'SSH File Transfer Protocol Delivery Plugin', :runtime_deps => {'net-sftp' => '~>2.0.4', 'net-ssh' => '~>2.0.20', 'progressbar' => '~>0.9.0'}},
    {:name => "boxgrinder-build-ebs-delivery-plugin", :dir => "delivery/ebs", :desc => 'Elastic Block Storage Delivery Plugin', :runtime_deps => {'amazon-ec2' => '~>0.9.6'}},

    {:name => "boxgrinder-build-rpm-based-os-plugin", :dir =>"os/rpm-based", :desc => 'RPM Based Operating System Plugin'},
    {:name => "boxgrinder-build-fedora-os-plugin", :dir => "os/fedora", :desc => 'Fedora Operating System Plugin', :runtime_deps => {'boxgrinder-build-rpm-based-os-plugin' => '~>0.0.8'}},
    {:name => "boxgrinder-build-rhel-os-plugin", :dir =>"os/rhel", :desc => 'Red Hat Enterprise Linux Operating System Plugin', :runtime_deps => {'boxgrinder-build-rpm-based-os-plugin' => '~>0.0.8'}},
    {:name => "boxgrinder-build-centos-os-plugin", :dir => "os/centos", :desc => 'CentOS Operating System Plugin', :runtime_deps => {'boxgrinder-build-rhel-os-plugin' => '~>0.0.6'}},

    {:name => "boxgrinder-build-vmware-platform-plugin", :dir =>"platform/vmware", :desc => 'VMware Platform Plugin'},
    {:name => "boxgrinder-build-ec2-platform-plugin", :dir => "platform/ec2", :desc => 'Elastic Compute Cloud (EC2) Platform Plugin'}
]

desc "Recreate Rakefiles for plugins"
task "rakefiles" do
  plugins.each do |plugin|

    runtime_dependencies = ["'boxgrinder-build ~>0.6.6'"]
    development_dependencies = ["'boxgrinder-build ~>0.6.6', 'hashery >=1.3.0'"]

    unless plugin[:runtime_deps].nil?
      plugin[:runtime_deps].each do |n, v|
        runtime_dependencies << "'#{n} #{v}'"
      end
    end

    rakefile = File.read("rake/PluginRakefileTemplate")

    File.open("#{plugin[:dir]}/Rakefile", "w") do |f|
      f.write(
          rakefile.
              gsub(/#NAME#/, plugin[:name]).
              gsub(/#DESCRIPTION#/, plugin[:desc]).
              gsub(/#RUNTIME_DEPENDENCIES#/, runtime_dependencies.join(', ')).
              gsub(/#DEVELOPMENT_DEPENDENCIES#/, development_dependencies.join(', ')))
    end
  end
end


task "clean" do
  plugins.each do |plugin|
    Dir.chdir plugin[:dir] do
      system "rake clean manifest"
    end
  end
end

desc "Builds all gems"
task "gem" do
  plugins.each do |plugin|
    Dir.chdir plugin[:dir] do
      system "rake clean manifest gem"
    end
  end
end

desc "Create RPM"
task :rpm, :target, :version, :arch, :needs => ['gem'] do |t, args|
  target  = args[:target]   || 'fedora'
  version = args[:version]  || 'rawhide'
  arch    = args[:arch]     || RbConfig::CONFIG['host_cpu']

  Dir["**/rubygem-*.spec"].each do |spec|
    `mock -r #{target}-#{version}-#{arch} --buildsrpm --sources #{File.dirname(spec)}/pkg/*.gem --spec #{spec} --resultdir #{File.dirname(spec)}/pkg/`
    exit 1 unless $? == 0
    `mock -r #{target}-#{version}-#{arch} --rebuild #{File.dirname(spec)}/pkg/*.rpm --resultdir #{File.dirname(spec)}/pkg/`
    exit 1 unless $? == 0
  end
end

libdir = Dir["../boxgrinder-core/lib"] + Dir["../boxgrinder-build/lib"] + Dir["platform/**/lib"] + Dir["os/**/lib"] + Dir["delivery/**/lib"]

desc "Runs RSpec test with code coverage"
Spec::Rake::SpecTask.new('spec:coverage') do |t|
  libdir.each do |d|
    t.libs.unshift "#{d}"
  end

  t.spec_files = FileList['**/spec/**/*-spec.rb']
  t.spec_opts = ['--colour', '--format', 'html:pkg/rspec_report.html', '-b']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,teamcity/*,/usr/lib/ruby/,.gem/ruby,/boxgrinder-core/,/boxgrinder-build/,/gems/']
  t.verbose = true
end

desc "Runs RSpec test"
Spec::Rake::SpecTask.new('spec') do |t|
  libdir.each do |d|
    t.libs.unshift "#{d}"
  end

  t.spec_files = FileList['**/spec/**/*-spec.rb']
  t.spec_opts = ['--colour', '--format', 's', '-b']
  t.rcov = false
  t.verbose = true
end
