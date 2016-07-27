## vSphere Network Inventory
PowerShell Module that contains consolidated customized cmdlets meant to easily correlate and report on current vSphere Network Inventory &amp; Configurations.

## Installation

1. Clone, Fork or download the .zip of the master source code
  * To download, you can copy/paste this into a PowerShell console, and it will download the module into your ``Downloads`` directory.
  ```powershell
(New-Object System.Net.WebClient).DownloadFile("https://github.com/vScripter/vSphereNetworkInventory/archive/master.zip","$ENV:USERPROFILE\Downloads\vSphereNetworkInventory.zip")
```

2. If you download the source:
  * Un-Block the .zip before un-zipping
  * Un-zip the source code

3. Move the 'vSphereNetworkInventory' directory into a valid PSModulePath directory
  * You can run the following, in PowerShell, to list valid directories:
  ```powershell
  $ENV:PSModulePath -split ';'
  ```
  * Open PowerShell and run:
  ```powershell
  Import-Module vSphereNetworkInventory
  ```
  * Note: You may need to adjust your ExecutionPolicy
