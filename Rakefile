require 'jeweler'

MAIN_PLUGIN_VERSION = '0.0.1'

plugins = {
        "boxgrinder-build-local-delivery-plugin"  => { :dir => "delivery/local", :desc => 'Local Delivery Plugin' },
        "boxgrinder-build-s3-delivery-plugin"     => { :dir => "delivery/s3", :desc => 'Amazon Simple Storage Service (Amazon S3) Delivery Plugin' },
        "boxgrinder-build-sftp-delivery-plugin"   => { :dir => "delivery/sftp", :desc => 'SSH File Transfer Protocol Delivery Plugin' },


        "boxgrinder-build-rpm-based-os-plugin"    => { :dir => "os/rpm-based", :desc => 'RPM Based Operating System Plugin' },
        "boxgrinder-build-rhel-based-os-plugin"   => { :dir => "os/rhel-based", :desc => 'Red Hat Enterprise Linux Based Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>= 0.0.1' }},
        "boxgrinder-build-fedora-os-plugin"       => { :dir => "os/fedora", :desc => 'Fedora Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>= 0.0.1' }},
        "boxgrinder-build-centos-os-plugin"       => { :dir => "os/centos", :desc => 'CentOS Operating System Plugin', :deps => { 'boxgrinder-build-rhel-based-os-plugin' => '>= 0.0.1' }},
        "boxgrinder-build-rhel-os-plugin"         => { :dir => "os/rhel", :desc => 'Red Hat Enterprise Linux Operating System Plugin', :deps => { 'boxgrinder-build-rhel-based-os-plugin' => '>= 0.0.1' }}
}

plugins.each do |name, info|
  Dir.chdir(info[:dir]) do
    Jeweler::Tasks.new do |s|
      s.name              = name
      s.summary           = info[:desc]
      s.version           = info[:version].nil? ? MAIN_PLUGIN_VERSION : info[:version]
      s.email             = "info@boxgrinder.org"
      s.homepage          = "http://www.jboss.org/stormgrind/projects/boxgrinder/build.html"
      s.description       = "BoxGrinder Build #{info[:desc]}"
      s.authors           = ["Marek Goldmann"]
      s.rubyforge_project = "boxgrinder-build-plugins"
      s.files             =  FileList["lib/**.rb", "README", "LICENSE"]

      info[:deps].each do |dep, version|
        s.add_dependency dep, version
      end unless info[:deps].nil?

      s.add_dependency 'boxgrinder-build', '>= 0.4.2'
    end
  end
end
