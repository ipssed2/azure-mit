# This procedure seems to be necessary to create images from certain types of VMs.
# I found that when I switch to Windows 2016, the old techniques for creating images no longer worked.
# This includes:
# - using the "Capture" button on the Azure portal page for the VM (the button does not appear), and 
# - using Save-AzureRmVMImage, which gives the error "The Capture action is only supported on a Virtual
#   Machine with blob based disks. Please use the 'Image' resource APIs to create
#   an Image from a managed Virtual Machine.
#
# This script is adapted from https://blogs.msdn.microsoft.com/igorpag/2017/03/14/azure-managed-disks-deep-dive-lessons-learned-and-benefits/  
# Mark Riordan 2017-06-08

$sourcergname = "R20176719550"
$targetrgname = "RGMITBase"
$storageacccountname = "mitbaseimages"
$containername = "images"
 
$VMName = "MOVEitTransfer"
$VM = Get-AzureRmVM -ResourceGroupName $sourcergname -Name $VMName
$OSDiskName = $VMName
$OSDisk = Get-AzureRmDisk -ResourceGroupName $sourcergname -DiskName $OSDiskName
 
$mdiskURL = Grant-AzureRmDiskAccess -ResourceGroupName $sourcergname -DiskName $VM.StorageProfile.OsDisk.Name -Access Read -DurationInSecond 3600
 
$storageacccountkey = Get-AzureRmStorageAccountKey -ResourceGroupName $targetrgname -Name $storageacccountname
 
$storagectx = New-AzureStorageContext -StorageAccountName $storageacccountname -StorageAccountKey $storageacccountkey[0].Value
 
$targetcontainer = New-AzureStorageContainer -Name $containername -Context $storagectx -Permission Blob
$targetcontainer = Get-AzureStorageContainer -Name "images" -Context $storagectx
$destdiskname = $VM.StorageProfile.OsDisk.Name + ".vhd";
$sourceSASurl = $mdiskURL.AccessSAS
 
$ops = Start-AzureStorageBlobCopy -AbsoluteUri $sourceSASurl -DestBlob $destdiskname -DestContainer $targetcontainer.Name -DestContext $storagectx
 
Get-AzureStorageBlobCopyState -Container $targetcontainer.Name -Blob $destdiskname -Context $storagectx -WaitForComplete
 
$sourceimagediskBlob = Get-AzureStorageBlob -Context $storagectx -Container $targetcontainer.Name -Blob $destdiskname
 
$sourceimagediskURL = ($sourceimagediskBlob.Context.BlobEndPoint) + $containername + “/” + $destdiskname;
 
$location = $VM.Location
$targetimagecfg = New-AzureRmImageConfig -Location $location
 
Set-AzureRmImageOsDisk -Image $targetimagecfg -OsType "Windows" -OsState "Generalized" -BlobUri $sourceimagediskURL;
 
$ImageName = "MITImage20170608"
$targetimage = New-AzureRmImage -Image $targetimagecfg -ImageName $ImageName -ResourceGroupName $targetrgname
