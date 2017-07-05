$mynow = Get-Date
$id = ($mynow.Year.ToString("0000") + $mynow.Month.ToString("00") + $mynow.Day.ToString("00") + $mynow.Hour.ToString("00") + $mynow.Minute.ToString("00"))
$RGName = "RGS" + $id
$DeployName = "D" + $id
echo "Resource group will be " $RGName
Get-Date;
New-AzureRmResourceGroup -Name $RGName -Location "WestUS2";
Get-Date;
New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -Name $DeployName -Mode Incremental -TemplateParameterFile .\myParametersSendGrid.json -TemplateFile .\mainTemplate2.json;
Get-Date;
(Get-AzureRmPublicIpAddress -ResourceGroupName $RGName).IPAddress
