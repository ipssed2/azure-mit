Measure-Command { New-AzureRmResourceGroupDeployment -ResourceGroupName RGDemo1 -Name DeployDemo1 -Mode Incremental -TemplateParameterFile .\bootParameters.json -TemplateFile .\mainTemplate.json }
