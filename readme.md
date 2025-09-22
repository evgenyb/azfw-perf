

## Get server IP address

```powershell
az vm show -d -g rg-norwayeast-azfwperf -n vm-server1-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server2-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server3-norwayeast --query privateIps -o tsv
az vm show -d -g rg-norwayeast-azfwperf -n vm-server4-norwayeast --query privateIps -o tsv
```

## Connect to server VMs via Bastion 

```powershell
az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-server1-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-server2-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-server3-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-server4-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin
```

## Connect to client VMs via Bastion 

```powershell
az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-client1-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-client2-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-client3-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin

az network bastion ssh --name bastion-norwayeast --resource-group rg-norwayeast-azfwperf --target-resource-id (az vm show --name vm-client4-norwayeast --resource-group rg-norwayeast-azfwperf --query id --output tsv) --auth-type password --username iac-admin
```

## Execute iperf3 command on client VMs

```bash
iperf3 -c 10.9.11.4 -t 600 -P 32
iperf3 -c 10.9.12.4 -t 600 -P 32
iperf3 -c 10.9.13.4 -t 600 -P 32
iperf3 -c 10.9.14.4 -t 600 -P 32
```

## Test plan

### Test bandwidth without Azure Firewall (10 min with 32 threads)

#### client1 -> server1
[SUM]   0.00-600.00 sec   739 GBytes  10.6 Gbits/sec               

#### client2 -> server2
[SUM]   0.00-600.00 sec   859 GBytes  12.3 Gbits/sec               

#### client3 -> server3
[SUM]   0.00-600.00 sec   859 GBytes  12.3 Gbits/sec               

#### client4 -> server4
[SUM]   0.00-600.00 sec   852 GBytes  12.2 Gbits/sec               

### Enable Firewall Standard SKU

Run #1
#### client1 -> server1
lost data
#### client2 -> server2
[SUM] 598.00-599.00 sec   198 MBytes  1.66 Gbits/sec  

#### client3 -> server3
[SUM] 596.00-597.00 sec   188 MBytes  1.57 Gbits/sec

#### client4 -> server4
[SUM] 598.00-599.00 sec   318 MBytes  2.66 Gbits/sec

Run #2
#### client1 -> server1
[SUM] 598.00-599.00 sec   221 MBytes  1.86 Gbits/sec  

#### client2 -> server2
[SUM]   0.00-600.00 sec   154 GBytes  2.21 Gbits/sec  

#### client3 -> server3
[SUM] 590.00-591.00 sec   304 MBytes  2.55 Gbits/sec    

#### client4 -> server4
[SUM]   0.00-600.00 sec   132 GBytes  1.89 Gbits/sec  


Run #3
#### client1 -> server1
[SUM] 489.00-490.00 sec   451 MBytes  3.79 Gbits/sec

#### client2 -> server2
[SUM] 486.00-487.00 sec   420 MBytes  3.52 Gbits/sec

#### client3 -> server3
[SUM] 481.00-482.00 sec   640 MBytes  5.37 Gbits/sec    

#### client4 -> server4
[SUM] 484.00-485.00 sec   454 MBytes  3.80 Gbits/sec  

Run #4
#### client1 -> server1
[SUM] 598.00-599.00 sec   516 MBytes  4.33 Gbits/sec

#### client2 -> server2
[SUM] 597.00-598.00 sec   865 MBytes  7.25 Gbits/sec

#### client3 -> server3
[SUM] 597.00-598.00 sec   939 MBytes  7.88 Gbits/sec    

#### client4 -> server4
[SUM] 597.00-598.00 sec  1.42 GBytes  12.2 Gbits/sec  

Run #5
#### client1 -> server1
[SUM]   0.00-600.01 sec   537 GBytes  7.69 Gbits/sec

#### client2 -> server2
[SUM]   0.00-600.01 sec   442 GBytes  6.33 Gbits/sec

#### client3 -> server3
[SUM]   0.00-600.01 sec   447 GBytes  6.40 Gbits/sec    

#### client4 -> server4
[SUM]   0.00-600.01 sec   505 GBytes  7.23 Gbits/sec  

### Test case 2
Run 4 test sessions for 60 min and observe the Azure bandwidth metrics


### Upgrade Firewall to Premium SKU

### Test bandwidth with Firewall Premium

```bash
iperf3 -c 10.9.11.4 -t 1800 -P 32
iperf3 -c 10.9.12.4 -t 1800 -P 32
iperf3 -c 10.9.13.4 -t 1800 -P 32
iperf3 -c 10.9.14.4 -t 1800 -P 32
```

Run #1
#### client1 -> server1
[SUM]   0.00-890.22 sec   512 GBytes  4.94 Gbits/sec

#### client2 -> server2
[SUM]   0.00-890.52 sec   392 GBytes  3.78 Gbits/sec

#### client3 -> server3
[SUM]   0.00-890.06 sec   494 GBytes  4.77 Gbits/sec

#### client4 -> server4
[SUM]   0.00-889.84 sec   457 GBytes  4.41 Gbits/sec

Run #2
#### client1 -> server1
[SUM]   0.00-460.84 sec   634 GBytes  11.8 Gbits/sec

#### client2 -> server2
[SUM]   0.00-459.47 sec   632 GBytes  11.8 Gbits/se

#### client3 -> server3
[SUM]   0.00-458.38 sec   631 GBytes  11.8 Gbits/sec

#### client4 -> server4
[SUM]   0.00-458.43 sec   631 GBytes  11.8 Gbits/sec