

## Get server IP address

```powershell
az vm show -d -g rg-norwayeast-azfwperf -n vm-server1-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server2-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server3-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server4-norwayeast --query privateIps -o tsv
```

## Connect to client VMs via Bastion 

```powershell
$vmId = (az vm show --name vm-client1-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv)
az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id $vmId --auth-type password --username iac-admin
```

## Execute iperf3 command on client VMs

```bash
iperf3 -c 10.9.11.4 -t 600 -p 32
iperf3 -c 10.9.12.4 -t 600 -p 32
iperf3 -c 10.9.13.4 -t 600 -p 32
iperf3 -c 10.9.14.4 -t 600 -p 32
```


## Test plan

### Test bandwidth without Azure Firewall

### Enable Firewall Standard SKU

### Test bandwidth with Firewall Standard

### Upgrade Firewall to Premium SKU

### Test bandwidth with Firewall Standard
