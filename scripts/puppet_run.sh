#!/bin/bash

puppet agent -v --no-daemonize --onetime --trace --verbose --graph --debug --waitforcert 3 2>&1 | tee /var/log/puppet/agent-`date +%Y%m%d-%H%M%S`.log

