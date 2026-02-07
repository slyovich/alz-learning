#!/bin/bash
set -e

# Add subnet + nsg for private endpoint in vnet connectivity 001
# Add the default NSG rules to block all inbound traffic
# Add NSG rule to allow inbound traffic from the VM boostrap subnet