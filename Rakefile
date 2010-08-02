require 'rake'

plugins = {
        "boxgrinder-build-local-delivery-plugin"  => { :dir => "delivery/local", :desc => 'Local Delivery Plugin', :deps => { 'boxgrinder-build' => '0.5.0' }},
        "boxgrinder-build-s3-delivery-plugin"     => { :dir => "delivery/s3", :desc => 'Amazon Simple Storage Service (Amazon S3) Delivery Plugin', :deps => { 'boxgrinder-build' => '0.5.0', 'aws-s3' => '>=0.6.2', 'amazon-ec2' => '>=0.9.6' }},
        "boxgrinder-build-sftp-delivery-plugin"   => { :dir => "delivery/sftp", :desc => 'SSH File Transfer Protocol Delivery Plugin', :deps => { 'boxgrinder-build' => '0.5.0', 'net-sftp' => '>=2.0.4', 'net-ssh' => '>=2.0.20', 'progressbar' => '>=0.9.0' }},

        "boxgrinder-build-rpm-based-os-plugin"    => { :dir => "os/rpm-based", :desc => 'RPM Based Operating System Plugin', :deps => { 'boxgrinder-build' => '0.5.1' }},
        "boxgrinder-build-fedora-os-plugin"       => { :dir => "os/fedora", :desc => 'Fedora Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>=0.0.3' }},
        "boxgrinder-build-rhel-os-plugin"         => { :dir => "os/rhel", :desc => 'Red Hat Enterprise Linux Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>=0.0.3' }},
        "boxgrinder-build-centos-os-plugin"       => { :dir => "os/centos", :desc => 'CentOS Operating System Plugin', :deps => { 'boxgrinder-build-rhel-os-plugin' => '>=0.0.1' }},

        "boxgrinder-build-vmware-platform-plugin" => { :dir => "platform/vmware", :desc => 'VMware Platform Plugin', :deps => { 'boxgrinder-build' => '0.5.0' } },
        "boxgrinder-build-ec2-platform-plugin"    => { :dir => "platform/ec2", :desc => 'Elastic Compute Cloud (EC2) Platform Plugin', :deps => { 'boxgrinder-build' => '0.5.0' } }
}

task "rakefiles" do
  plugins.each do |name, info|

    dependencies = []

    unless info[:deps].nil?
      info[:deps].each  do |n, v|
        dependencies << "'#{n} #{v}'"
      end
    end

    rakefile = "require 'echoe'

Echoe.new('#{name}') do |p|
  p.project     = 'BoxGrinder Build'
  p.author      = 'Marek Goldmann'
  p.summary     = '#{info[:desc]}'
  p.description = 'BoxGrinder Build #{info[:desc]}'
  p.url         = 'http://www.jboss.org/stormgrind/projects/boxgrinder.html'
  p.email       = 'info@boxgrinder.org'
  p.runtime_dependencies = [#DEPENDENCIES#]
end"

    File.open( "#{info[:dir]}/Rakefile", "w" ) {|f| f.write( rakefile.gsub(/#DEPENDENCIES#/, dependencies.join(', ')) ) }
  end
end

desc "Cleans and builds gems for all plugins"
task "package" => [ "rakefiles" ] do
  plugins.each_value do |info|
    Dir.chdir(info[:dir]) do
      puts `rake clean manifest repackage` if File.exists?( "Rakefile" )
    end
  end
end