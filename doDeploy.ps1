$mynow = Get-Date
$id = ($mynow.Year.ToString() + $mynow.Month.ToString() + $mynow.Day.ToString() + $mynow.Hour.ToString() + $mynow.Minute.ToString() + $mynow.Second.ToString())
$RGName = "R" + $id
$DeployName = "D" + $id
New-AzureRmResourceGroup -Name $RGName -Location "WestUS2"
$mynow
New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -Name $DeployName -Mode Incremental -TemplateParameterFile .\bootParameters.json -TemplateFile .\mainTemplate.json
Get-Date
