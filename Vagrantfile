# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'pp'

# Plugin Dependency
if !Vagrant.has_plugin?('vagrant-triggers') 
  puts "The vagrant-triggers plugin is required. Please install with \"vagrant plugin install vagrant-triggers\""
  exit
end

if !Vagrant.has_plugin?('vagrant-vbox-snapshot') 
  puts "The vagrant-vbox-snapshot plugin is required. Please install with \"vagrant plugin install vagrant-vbox-snapshot\""
  exit
end

# Minimal memory requirements

# puppetmaster: 768 MB
# controller:   1280 MB
# network:  512 MB
# compute:  1024 MB

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end

vagrant_base = File.expand_path(File.dirname(__FILE__))
environment = YAML.load_file("#{vagrant_base}/environment/config.yaml")['current_environment']
environment_dir = File.expand_path("#{vagrant_base}/environment/#{environment}/")

unless File.exist?("#{environment_dir}/base.yaml")
  puts "Missing environment #{environment}"
  exit(-1)
end

s = IO.read("#{environment_dir}/base.yaml")
s = s.gsub('#{environment}', environment.to_s) 
base_config = YAML.load(s)

# Provision environment
Vagrant.configure("2") do |config|
    
    # General virtualbox settings
    config.vm.provider :virtualbox do |vb|
#        vb.gui = true
    end

    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    # List Nodes
    nodes = Dir["#{environment_dir}/nodes/*.yaml"].map { |v| File.basename(v, '.yaml')}
    
    nodes.each do |node|
        s = IO.read("#{environment_dir}/nodes/#{node}.yaml")
        s = s.gsub('#{environment}', environment.to_s) 
        node_config = YAML.load(s)
        node_config.each { |k,v| node_config[k] = base_config.deep_merge(v) }
        node_config = Marshal.load(Marshal.dump(node_config) )#deep clone

        node_config.each do |sub_node, sub_node_config|

            sub_node_config = node_config.values[0].deep_merge(sub_node_config) #merge node base 
            sub_node_config = Marshal.load(Marshal.dump(sub_node_config) )#deep clone

            config.vm.define sub_node do |vm_config|
                vm_config.vm.hostname   = "#{sub_node.gsub('_', '-')}.#{sub_node_config['domain']}"
                vm_config.vm.box        = sub_node_config['box']
                vm_config.vm.box_url    = sub_node_config['box_url']

                vm_config.ssh.password  = "vagrant" 

                vm_config.vm.provider :virtualbox do |vb|
                    vb.customize ["modifyvm", :id, "--memory",  sub_node_config['memory']]
                    vb.customize ["modifyvm", :id, "--cpus",    sub_node_config['cores']]  unless sub_node_config['cores'].nil?
                    vb.customize ["modifyvm", :id, "--vrde", "on"]                         unless sub_node_config['vrdp'].nil?
                    vb.customize ["modifyvm", :id, "--vrdeport", sub_node_config['vrdp']]  unless sub_node_config['vrdp'].nil?
                    vb.customize ["modifyvm", :id, "--vrdemulticon", "on"]                 unless sub_node_config['vrdp'].nil?
                end

                # Define networks
                ip_suffix = sub_node_config['ip_suffix']
                unless sub_node_config['networks'].nil?
                    sub_node_config['networks'].each do |interface, interface_cfg|
#                        next if interface_cfg == 'nil' || interface_cfg.nil?
                        if interface_cfg == 'nil' || interface_cfg.nil?
                            next unless base_config['networks'].has_key?(interface)

                            ip          	= base_config['networks'][interface]['ip']
                            netmask     	= base_config['networks'][interface]['netmask']
			    network_type	= base_config['networks'][interface]['type']
                            auto_cfg    	= false
                        else
                            ip          	= interface_cfg['ip']
                            netmask     	= interface_cfg['netmask']
			    network_type	= interface_cfg['type'].nil? 		? 'private_network' : interface_cfg['type']
                            auto_cfg    	= interface_cfg['autoconf'].nil? 	? true : interface_cfg['autoconf']
                        end
                        ip          = ip.gsub('#{ip_suffix}', ip_suffix.to_s) if ip_suffix
#                        puts 'ip: ' + ip.to_s + ', netmask: ' + netmask.to_s + ', auto: ' + auto_cfg.to_s
                        vm_config.vm.network network_type, ip: ip, netmask: netmask, auto_config: auto_cfg
                    end
                end

                # Define portforwarding
                port_offset = sub_node_config['port_offset']
                
                unless sub_node_config['port_forward'].nil?
                    sub_node_config['port_forward'].each do |port_forward_config|
                        host = port_forward_config['host']
                        host = host.gsub('#{port_offset}', port_offset.to_s) if port_offset
#                       puts 'port guest: ' + port_forward_config['guest'].to_s + ', host: ' + host.to_s
			if port_forward_config['guest_ip'].nil?
                            vm_config.vm.network :forwarded_port, guest: port_forward_config['guest'], host: host
			else
                            guest_ip = port_forward_config['guest_ip']
                            guest_ip = guest_ip.gsub('#{environment}', environment.to_s)
			    puts 'port guest: ' + port_forward_config['guest'].to_s + ', host: ' + host.to_s + ', guest_ip: ' + guest_ip.to_s
			    vm_config.vm.network :forwarded_port, guest: port_forward_config['guest'], host: host, guest_ip: guest_ip
			end
                    end
                end

                # Add extra disks
                # FIXME: works only for one disk... (probably due to ruby problems with vb.customize)
                unless sub_node_config['extra_disks'].nil?
                    disk_nr     = 1
                    disk_dir    = 'storage'
                    sub_node_config['extra_disks'].each do |disk_config|
                        vm_config.vm.provider :virtualbox do |vb|
                            file_name = "#{disk_dir}/#{sub_node}.disk#{disk_nr}.vdi"
                            vb.customize ["createhd", "--filename", file_name, '--size', disk_config['size']]
                            vb.customize ["storageattach", :id, '--storagectl', 'SATA Controller', '--port', disk_nr, '--device', 0, '--type', 'hdd', '--medium', file_name]
                        end
                        disk_nr = disk_nr + 1
                    end
                end


                #Provision scripts
                unless sub_node_config['provisioner'].nil?
                    sub_node_config['provisioner'].each do |script|
                        vm_config.vm.provision "shell", path: "scripts/" + script
                        # Take snapshot after running shell script
                        vm_config.vm.provision "trigger" do |trigger|
                            trigger.fire do
                                snapshot_name = "after_" + script.gsub('.sh', '').gsub(/\//, '_')
                                run "vagrant snapshot take #{sub_node} #{snapshot_name}"
                            end
                        end
                    end
                end
                #puts 'vm_config: ' + pp(vm_config.vm)
            end
        end
    end
end
