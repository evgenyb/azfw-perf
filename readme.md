```powershell
$vmId = (az vm show --name vm-hub-westeurope --resource-group rg-westeurope-azfwperf --query id --output tsv)
az network bastion ssh --name bastion-westeurope --resource-group rg-westeurope-azfwperf --target-resource-id $vmId --auth-type password --username iac-admin
```