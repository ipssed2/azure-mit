# This procedure seems to be necessary to create images from certain types of VMs.
# I found that when I switched to Windows 2016, the old techniques for creating images no longer worked.
# This includes:
# - using the "Capture" button on the Azure portal page for the VM (the button does not appear), and 
# - using Save-AzureRmVMImage, which gives the error "The Capture action is only supported on a Virtual
#   Machine with blob based disks. Please use the 'Image' resource APIs to create
#   an Image from a managed Virtual Machine.
#
# This script is adapted from https://blogs.msdn.microsoft.com/igorpag/2017/03/14/azure-managed-disks-deep-dive-lessons-learned-and-benefits/  
# Mark Riordan 2017-06-08

param([string]$targetrgname='', [string]$targetstorageaccountname='')

if ($targetrgname -eq '' -or $targetstorageaccountname -eq '') {
	echo "Usage:  createImage.ps1 -targetrgname resourceGroupName -targetstorageaccountname targetStorageAcctName";
	echo "  resourceGroupName is the resource group where the image will be stored"
	echo "  targetstorageaccountname  is the storage account where the image will be stored"
	echo "For production use -targetrgname RGMITBase -targetstorageaccountname mitbaseimages";
	echo "For testing use    -targetrgname RGTestImages -targetstorageaccountname mittestimages"
	exit;
}

Set-StrictMode -Version latest 

$mynow = Get-Date
$mynow
$id = ($mynow.Year.ToString("0000") + $mynow.Month.ToString("00") + $mynow.Day.ToString("00") + $mynow.Hour.ToString("00") + $mynow.Minute.ToString("00") + $mynow.Second.ToString("00"))

# List the available resource groups.
Get-AzureRmResourceGroup | Select-Object ResourceGroupName | Out-String -Stream;
echo "You are going to create an image from a VM you have sysprepped.";
# Prompt the user for the one where the VM resides.
$sourcergname = Read-Host -Prompt 'Type the resource group where the VM resides, from the list above'

# Find the VM in the resource group.
$VM = Find-AzureRmResource -ResourceGroupNameEquals $sourcergname -ResourceType "Microsoft.Compute/virtualMachines"
$VMName = $VM.Name

Get-Date;
echo "Stopping VM";
Stop-AzureRmVM -ResourceGroupName $sourcergname -Name $VM.Name
Get-Date;

# This seems to be necessary in order to populate some of the obscure VM attributes, 
# even though we computed $VM above.
$VM = Get-AzureRmVM -ResourceGroupName $sourcergname -Name $VMName
echo ("Image will be based on " + $VM.StorageProfile.OsDisk.Name);
$mdiskURL = Grant-AzureRmDiskAccess -ResourceGroupName $sourcergname -DiskName $VM.StorageProfile.OsDisk.Name -Access Read -DurationInSecond 3600

# Target information
$ImageName = "MITImage" + $id;
$containername = "images"

$storageacccountkey = Get-AzureRmStorageAccountKey -ResourceGroupName $targetrgname -Name $targetstorageaccountname
 
$storagectx = New-AzureStorageContext -StorageAccountName $targetstorageaccountname -StorageAccountKey $storageacccountkey[0].Value
 
$targetcontainer = New-AzureStorageContainer -Name $containername -Context $storagectx -Permission Blob
$targetcontainer = Get-AzureStorageContainer -Name "images" -Context $storagectx
$destdiskname = "Disk" + $id + ".vhd";
$sourceSASurl = $mdiskURL.AccessSAS

Get-Date;
echo ("Slowly copying disk to " + $destdiskname)

$ops = Start-AzureStorageBlobCopy -AbsoluteUri $sourceSASurl -DestBlob $destdiskname -DestContainer $targetcontainer.Name -DestContext $storagectx
 
Get-AzureStorageBlobCopyState -Container $targetcontainer.Name -Blob $destdiskname -Context $storagectx -WaitForComplete

Get-Date;

$sourceimagediskBlob = Get-AzureStorageBlob -Context $storagectx -Container $targetcontainer.Name -Blob $destdiskname
 
$sourceimagediskURL = ($sourceimagediskBlob.Context.BlobEndPoint) + $containername + "/" + $destdiskname;
 
$location = $VM.Location
$targetimagecfg = New-AzureRmImageConfig -Location $location
 
Set-AzureRmImageOsDisk -Image $targetimagecfg -OsType "Windows" -OsState "Generalized" -BlobUri $sourceimagediskURL;

echo ("Creating " + $ImageName)
$targetimage = New-AzureRmImage -Image $targetimagecfg -ImageName $ImageName -ResourceGroupName $targetrgname

Get-Date;
