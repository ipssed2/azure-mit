@ECHO OFF
SET HOUR=%time:~0,2%
SET dtStamp9=%date:~-4%%date:~4,2%%date:~7,2%0%time:~1,1%%time:~3,2%%time:~6,2% 
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%%time:~6,2%

if "%HOUR:~0,1%" == " " (SET dtStamp=%dtStamp9%) else (SET dtStamp=%dtStamp24%)

SET RGName=R%dtStamp%

:: removed Measure-Command { from beginning because I can't find that cmd.
echo New-AzureRmResourceGroup -Name %RGName% -Location "WestUS2" >doit.ps1
echo New-AzureRmResourceGroupDeployment -ResourceGroupName %RGName% -Name D%dtStamp% -Mode Incremental -TemplateParameterFile .\bootParameters.json -TemplateFile .\mainTemplate.json >>doit.ps1
