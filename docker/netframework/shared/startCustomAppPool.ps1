#Remove any staging files from previous runs of the container
if(Test-Path "C:\run") {
    Remove-Item -Recurse -Force "C:\run"
}
# Create staging folder for contrast files
New-Item "C:\run\" -ItemType Directory -ErrorAction SilentlyContinue > $null

# Download the latest contrast agent assemblies from Nuget.org
Invoke-WebRequest "https://www.nuget.org/api/v2/package/Contrast.NET.Azure.AppService/" -OutFile c:\run\contrastAgent.zip
Expand-Archive C:\run\contrastAgent.zip -DestinationPath c:\run\contrastAgent

# Copy the config yaml
New-Item "C:\run\config" -ItemType Directory -ErrorAction SilentlyContinue > $null
Copy-Item -Path C:\shared\contrast_security.yaml -Destination C:\run\config\contrast_security.yaml -Force

# Setup required environment variables to set on the appPool
$envVars = @{
    "COR_ENABLE_PROFILING" = "1";
    "COR_PROFILER" = "{EFEB8EE0-6D39-4347-A5FE-4D0C88BC5BC1}";
    "COR_PROFILER_PATH_32" = "C:\run\contrastAgent\content\contrastsecurity\ContrastProfiler-32.dll";
    "COR_PROFILER_PATH_64" = "C:\run\contrastAgent\content\contrastsecurity\ContrastProfiler-64.dll";
    "CONTRAST_CONFIG_PATH" = "C:\run\config\contrast_security.yaml";
}


$appcmdExe = "$env:windir\System32\inetsrv\appcmd.exe"
$appPool = "CustomAppPool"

# (Re)Create appPool
& $appcmdExe delete apppool /name:"""$appPool""" > $null
& $appcmdExe add apppool /name:"""$appPool"""

# Set Environment variables on the app pool
foreach($envVarKey in $envVars.Keys) {
    $envVarValue = $envVars[$envVarKey]
    Write-Host "Setting env on $($appPool): $envVarKey, $envVarValue"

    & $appcmdExe set config -section:system.applicationHost/applicationPools /-"[name='$appPool'].environmentVariables.[name='$envVarKey']" /commit:apphost > $null
    & $appcmdExe set config -section:system.applicationHost/applicationPools /+"[name='$appPool'].environmentVariables.[name='$envVarKey',value='$envVarValue']" /commit:apphost
}
# Set the new app pool on our app
& $appcmdExe set app "Default Web Site/" /applicationPool:"""$appPool"""

# The ServiceMonitor process will restart IIS and exit when the IIS service shuts down.
C:\ServiceMonitor.exe w3svc