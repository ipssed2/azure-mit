param([string]$Location='eastus')
$mynow = Get-Date
$id = ($mynow.Year.ToString("0000") + $mynow.Month.ToString("00") + $mynow.Day.ToString("00") + $mynow.Hour.ToString("00") + $mynow.Minute.ToString("00"))
$RGName = "TMRR" + $id
$DeployName = "TMRR" + $id
echo ("Resource group will be " + $RGName + " in " + $Location)
Get-Date;
New-AzureRmResourceGroup -Name $RGName -Location $Location;
Get-Date;
New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -Name $DeployName -Mode Incremental -TemplateParameterFile .\myParametersmittest1.json -TemplateFile .\mainTemplate.json;
Get-Date;
(Get-AzureRmPublicIpAddress -ResourceGroupName $RGName).IPAddress
