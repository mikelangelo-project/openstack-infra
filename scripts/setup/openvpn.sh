apt-get install openvpn
cp /vagrant/files/openvpn-ldap.conf /etc/openvpn/all.conf
update-rc.d openvpn defaults

