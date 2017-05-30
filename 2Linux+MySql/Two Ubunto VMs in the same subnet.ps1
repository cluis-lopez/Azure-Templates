$stName = "clopezstorage"
$locName = "westeurope"
$rgName = "LinuxMySQL"

$maq1 = "LinuxMySql1"
$maq2 = "LinuxMySql2"

$username ="<your username here>"
$password ="<your password here>"

New-AzureRmResourceGroup -Name $rgName -Location $locName

$storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -Type "Standard_LRS" -Location $locName

$ssh = New-AzureRmNetworkSecurityRuleConfig -Name "LinuxSSH" -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$nsg = New-AzureRmNetworkSecurityGroup -Name "AccessSSH" -ResourceGroupName $rgname -Location $locname -SecurityRules $ssh

$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name singleSubnet -AddressPrefix 10.0.0.0/24 -NetworkSecurityGroup $nsg
$vnet = New-AzureRmVirtualNetwork -Name TestNet -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet

$Pword = ConvertTo-SecureString -String $password -AsPlainText -Force
$cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $username, $PWord

foreach ($vmname in $maq1, $maq2){
    $pip = New-AzureRmPublicIpAddress -Name ($vmname+"ip") -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
    $nic = New-AzureRmNetworkInterface -Name ($vmname+"NIC") -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
   
    $vm = New-AzureRmVMConfig -VMName $vmname -VMSize "Basic_A0"
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmname -Credential $cred
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName Canonical -Offer UbuntuServer -Skus 17.04 -Version "latest"
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

    $osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/"+$vmname+"OSDisk.vhd")
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name ($vmname+"vmosdisk") -VhdUri $osDiskUri -CreateOption fromImage

    # Add a 10GB datadisk to the machine

    $vm = Add-AzureRmVMDataDisk -VM $vm -Name ($vmname+"DataDisk") -VhdUri ($storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/"+$vmname+"DataDisk.vhd")) -DiskSizeInGB 10  -Caching ReadWrite -Lun 0 -CreateOption Empty
    
    New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm
}
