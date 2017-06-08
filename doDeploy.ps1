$mynow = Get-Date
$id = ($mynow.Year.ToString("0000") + $mynow.Month.ToString("00") + $mynow.Day.ToString("00") + $mynow.Hour.ToString("00") + $mynow.Minute.ToString("00") + $mynow.Second.ToString("00"))
$RGName = "R" + $id
$DeployName = "D" + $id
echo "Resource group will be " $RGName
New-AzureRmResourceGroup -Name $RGName -Location "WestUS2"
Get-Date
New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -Name $DeployName -Mode Incremental -TemplateParameterFile .\bootParameters.json -TemplateFile .\mainTemplate.json
Get-Date
