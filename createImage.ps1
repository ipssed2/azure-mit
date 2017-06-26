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
#
# Change the places marked with ##.

$mynow = Get-Date
$mynow
$id = ($mynow.Year.ToString("0000") + $mynow.Month.ToString("00") + $mynow.Day.ToString("00") + $mynow.Hour.ToString("00") + $mynow.Minute.ToString("00") + $mynow.Second.ToString("00"))

##  Change this resource group name to reflect where the VM is:
$sourcergname = "RGImg20170622e"

$ImageName = "MITImage" + $id;

$targetrgname = "RGMITBase"
$storageacccountname = "mitbaseimages"
$containername = "images"

## Change VMName to reflect the name of the VM from which the image will be created:
$VMName = "VMImg20170622e"

$VM = Get-AzureRmVM -ResourceGroupName $sourcergname -Name $VMName

## Change this disk name to reflect the disk drive of the VM from which we'll create the image
# You can learn this from the Azure portal under the source resource group.
# It is the Name of the "disk" resource:
$OSDiskName = "VMImg20170622e_disk1_eaa19ee9521e4913b2d256323f3902a9"

$OSDisk = Get-AzureRmDisk -ResourceGroupName $sourcergname -DiskName $OSDiskName

Get-Date;
echo "Stopping VM";
Stop-AzureRmVM -ResourceGroupName $sourcergname -Name $VM.Name
Get-Date;
 
$mdiskURL = Grant-AzureRmDiskAccess -ResourceGroupName $sourcergname -DiskName $VM.StorageProfile.OsDisk.Name -Access Read -DurationInSecond 3600
 
$storageacccountkey = Get-AzureRmStorageAccountKey -ResourceGroupName $targetrgname -Name $storageacccountname
 
$storagectx = New-AzureStorageContext -StorageAccountName $storageacccountname -StorageAccountKey $storageacccountkey[0].Value
 
$targetcontainer = New-AzureStorageContainer -Name $containername -Context $storagectx -Permission Blob
$targetcontainer = Get-AzureStorageContainer -Name "images" -Context $storagectx
# $destdiskname = $VM.StorageProfile.OsDisk.Name + "2.vhd";
$destdiskname = "Disk" + $id + ".vhd";
$sourceSASurl = $mdiskURL.AccessSAS

Get-Date
echo ("Copying disk to " + $destdiskname)

$ops = Start-AzureStorageBlobCopy -AbsoluteUri $sourceSASurl -DestBlob $destdiskname -DestContainer $targetcontainer.Name -DestContext $storagectx
 
Get-AzureStorageBlobCopyState -Container $targetcontainer.Name -Blob $destdiskname -Context $storagectx -WaitForComplete

Get-Date

$sourceimagediskBlob = Get-AzureStorageBlob -Context $storagectx -Container $targetcontainer.Name -Blob $destdiskname
 
$sourceimagediskURL = ($sourceimagediskBlob.Context.BlobEndPoint) + $containername + "/" + $destdiskname;
 
$location = $VM.Location
$targetimagecfg = New-AzureRmImageConfig -Location $location
 
Set-AzureRmImageOsDisk -Image $targetimagecfg -OsType "Windows" -OsState "Generalized" -BlobUri $sourceimagediskURL;

echo ("Creating " + $ImageName)
$targetimage = New-AzureRmImage -Image $targetimagecfg -ImageName $ImageName -ResourceGroupName $targetrgname

Get-Date
