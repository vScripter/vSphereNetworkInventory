## vSphere Network Inventory
PowerShell Module that contains consolidated customized cmdlets designed to make it easier to report on current vSphere network inventory configurations.

## TODO
#### Commands
- [x] Get-VMGuestNetworkConfiguration
- [x] Get-VMHostNetworkConfiguration
- [ ] Get-DvsConfiguration
- [ ] Get-VssConfiguration
- [x] Get-VMHostVtepInterface
- [ ] [nsx configuration cmdlets]

#### Features
- [ ] Pester Tests
- [ ] Error handling

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

4. Before running these commands, it is assumed that you have PowerCLI installed and that you have already connected to a vCenter Server or ESXi host/s. The steps to do that are outside the scope of this repo.


## Examples

### Report on ESXi Host Network Configuration for all hosts
#### Just view the output in GridView

```powershell
Get-VMHost | Get-VMHostNetworkConfiguration -Verbose | Out-GridView
```

#### Generate .CSV report of config

```powershell
Get-VMHost | Get-VMHostNetworkConfiguration -Verbose | Export-Csv ~\Desktop\esxiNetworkConfigurations.csv -NoTypeInformation -Force
```

### Report on VM Guest Network Configuration for all guests
#### Just view the output in GridView

```powershell
Get-VM | Get-VMGuestNetworkConfiguration -Verbose | Out-GridView
```

#### Generate .CSV report of config

```powershell
Get-VM | Get-VMGuestNetworkConfiguration -Verbose | Export-Csv ~\Desktop\guestNetworkConfigurations.csv -NoTypeInformation -Force
```


## Platform Testing

#### vSphere
- [x] vSphere 6.x
- [ ] vSphere 5.5
- [ ] vSphere 5.1

#### PowerCLI
- [x] PowerCLI 6.3 Release 1

#### Windows PowerShell
- [ ] Version 5
- [x] Version 4
- [x] Version 3


