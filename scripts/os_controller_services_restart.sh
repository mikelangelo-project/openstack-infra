#!/bin/bash 

service nova-api restart
service nova-cert restart
service nova-conductor restart
service nova-consoleauth restart
service nova-scheduler restart
service neutron-server restart
service keystone restart
service glance-api restart
service heat-api restart
service heat-api-cfn restart
service heat-api-cloudwatch restart
service cinder-api restart
service glance-registry restart
