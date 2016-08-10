
function Get-VMHostVtepInterface {

<#
.SYNOPSIS
    Gather VTEP interface inventory from all ESXi hosts
.DESCRIPTION
    Gather VTEP interface inventory from all ESXi hosts.
    This function was written with scale and speed in mind. It pull a host inventory using API calls and then unrolls API properties and
    assigned them to a PSCustomObject.

	Sample Output

VMHost       : esx001.vlab.local
Interface    : vmk2
MacAddress   : 00:50:56:66:4b:1c
IPv4Address  : 192.168.40.3
SubnetMask   : 255.255.255.0
DHCP         : False
MTU          : 1600
TsoEnabled   : True
NetworkStack : vxlan
PinnedPnic   :
vCenter      : vcenter.vlab.local

.OUTPUTS
    [System.Management.Automation.PSCustomObject]
.NOTES
	Author: Kevin Kirkpatrick
  	Email: Kevin(at)vmotioned(dot)com
    Web: https://github.com/vScripter
	Version: 1.0
  	Last Updated: 20150810
	Last Updated By: K. Kirkpatrick
  	Last Update Notes:
   	- Created
#>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param()

    BEGIN {

        Write-Verbose -Message "[Get-VMHostVtepInterface] Gathering VMHost Inventory"
        try {

            $vmHostInventory = $null
            $vmHostInventory = Get-View -ViewType HostSystem -Property Name,Config -ErrorAction 'Stop'

        } catch {

            throw "[Get-VMHostVtepInterface][ERROR] Could not gather VMHost inventory using 'Get-View'. $_"

        } # end try/catch

    } # end BEGIN block

    PROCESS {

        foreach ($vmHost in $vmHostInventory) {

            $vtepInterfaceQuery = $null
            $vtepInterfaceQuery = $vmHost.Config.Network.Vnic | Where-Object {$_.Spec.NetStackInstanceKey -eq 'vxlan'}

            $vmHostName = $null
            $vmHostName = $vmHost.Name

            [uri]$vCenter = $null
            $vCenter = $vmHost.Client.ServiceUrl

            Write-Verbose -Message "[Get-VMHostVtepInterface] Gathering VTEP VMkernel Interfaces for host {$vmHostName}"

            foreach ($vtep in $vtepInterfaceQuery) {

                $objVtepInt = @()
                $objVtepInt = [PSCustomObject] @{
                    VMHost       = $vmHostName
                    Interface    = $vtep.Device
                    MacAddress   = $vtep.Spec.Mac
                    IPv4Address  = $vtep.Spec.Ip.IpAddress
                    SubnetMask   = $vtep.Spec.Ip.SubnetMask
                    DHCP         = $vtep.Spec.Ip.Dhcp
                    MTU          = $vtep.Spec.Mtu
                    TsoEnabled   = $vtep.Spec.TsoEnabled
                    NetworkStack = $vtep.Spec.NetStackInstanceKey
                    PinnedPnic   = $vtep.Spec.PinnedPnic
                    vCenter      = $vCenter.Host
                } # end $objVtepInt

                $objVtepInt

            } # end foreach $vtep

        } # end foreach $vmHost

    } # end PROCESS block

    END {

        Write-Verbose -Message "[Get-VMHostVtepInterface] Processing complete"

    } # end END block

} # end function Get-VMHostVtepInterface

Export-ModuleMember -Function Get-VMHostVtepInterface


function Get-VMHostNetworkConfiguration {

<#
.SYNOPSIS
	This script/function will return VMHost physical and virtual network configuration details
.DESCRIPTION
	This script/function will return VMHost physical and virtual network configuration details. It was written to take an in-depth audit of what is configured
	on the host, as well as what the configuration is on a vSphere Standard Switch and/or vSphere Distributed Switch.

	If you are querying multiple hosts that are managed by the same vCenter server, speed will greatly increase if you supply the vCenter server name in the -Server parameter

    Sample Output

Physical Adapter Connected to a Distributed Virtual Switch (DVS)
------------------------------------------------------------------
VMHost           : esx001.vlab.local
NICType          : Physical
Name             : vmnic0
PciID            : 0000:01:00.0
MACAddress       : e0:db:55:4e:2e:c9
Driver           : bnx2x
LinkSpeedMB      : 10000
DVSwitch         : vds-mgmt
DVSMTU           : 1600
VSSSwitch        :
VSSMTU           :
VMKMTU           :
DHCPEnabled      :
IPAddress        :
SubnetMask       :
DVSPortGroup     :
DVSPortGroupVLAN :
VSSPortGroup     :
VSSPortGroupVLAN :

Virtual Interface (vmk) Configuration
------------------------------------------
VMHost           : esx001.vlab.local
NICType          : Virtual
Name             : vmk1
PciID            :
MACAddress       : 00:50:56:6d:27:57
Driver           :
LinkSpeedMB      :
DVSwitch         :
DVSMTU           :
VSSSwitch        :
VSSMTU           :
VMKMTU           : 1600
DHCPEnabled      : False
IPAddress        : 192.168.40.2
SubnetMask       : 255.255.255.0
DVSPortGroup     : vxw-vmknicPg-dvs-42-0-f57571f7-10a3-43a0-8b65-b4009974e353
DVSPortGroupVLAN : 0
VSSPortGroup     :
VSSPortGroupVLAN :

Physical Adapter Connected to a vSphere Standard Switch (VSS)
--------------------------------------------------------
VMHost           : esx002.vlab.local
NICType          : Physical
Name             : vmnic0
PciID            : 0000:03:00.0
MACAddress       : 00:50:56:9c:ed:2a
Driver           : vmxnet3
LinkSpeedMB      : 10000
DVSwitch         :
DVSMTU           :
VSSSwitch        : vSwitch0
VSSMTU           : 1500
VMKMTU           :
DHCPEnabled      :
IPAddress        :
SubnetMask       :
DVSPortGroup     :
DVSPortGroupVLAN :
VSSPortGroup     :
VSSPortGroupVLAN :

.PARAMETER VMHost
	Name of VMHost (FQDN)
.PARAMETER Server
	Name of vCenter server, if desired
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	Get-VMHostNetworkConfiguration -VMHost ESXI01.corp.com | Out-GridView
.EXAMPLE
	Get-Cluster 'Prod Cluster' | Get-VMHost | Get-VMHostNetworkConfiguration | Export-Csv C:\VMHostNICReport.csv -NoTypeInformation
.NOTES
	Author: Kevin Kirkpatrick
  	Email: kevin@vmotioned.com
    Web: https://github.com/vScripter
	Version: 2.0
  	Last Updated: 20150601
	Last Updated By: K. Kirkpatrick
  	Last Update Notes:
   	- Updated Verbose & Warning messages
	- Added 'Processing Complete' in END block

#>

	[cmdletbinding()]
	param (
		[parameter(Mandatory = $true,
				   Position = 0,
				   ValueFromPipelineByPropertyName = $true)]
		[alias('Name')]
		$VMHost,

		[parameter(Mandatory = $false,
				   Position = 1)]
		[alias('VIServer', 'vCenter')]
		[ValidateScript({ Test-Connection -ComputerName $_ -Count 1 -Quiet })]
		[System.String]$Server
	)

	BEGIN {

		if ($Server) {

		<# grabbing the VDS PortGroup data here, IF a vCenter server name is specified, which will greatly speed up processing time if running a query
		on multiple VMHosts (as long as they are managed by the same vCenter server). If $server is not specified, this value is set below, on each
		host iteration, using the ServiceUri as the search base #>

			Write-Verbose -Message "[Get-VMHostNetworkConfiguration] Gathering VDS PortGroup Data from vCenter {$Server}"
			try {

				$dvPortGroupView = Get-View -Server $Server -ViewType DistributedVirtualPortgroup -Property Key, Config -ErrorAction 'Stop'

			} catch {

				Write-Warning -Message "[Get-VMHostNetworkConfiguration][$Server][ERROR] Could not gather VDS PortGroup Data. $_ "
				break

			} # end try/catch

		} # end if $Server

	} # end BEGIN block

	PROCESS {

		foreach ($vhost in $VMHost) {

			$vmHostView = $null
			$vmhostServerServiceURL = $null
			$pNics = $null
			$vNics = $null
			$dvData = $null
			$vsData = $null
			$dvPortGroup = $null
			$vsPortGroup = $null
			$finalResult = @()

			Write-Verbose -Message "[Get-VMHostNetworkConfiguration] Gathering NIC Detail from VMHost {$vhost}"
			try {

		<# Use Get-View to filter and only pull in the properties that we need to work with, on the host name in question and then assign sub-property values to variables so it will be easier to call
		in the PSCustomObject #>
				if ($Server) {

					$vmHostView = Get-View -Server $Server -ViewType HostSystem -Property Name, Config -Filter @{ "Name" = "$vhost" }

				} else {

					$vmHostView = Get-View -ViewType HostSystem -Property Name, Config -Filter @{ "Name" = "$vhost" }

				} # end if/else $Server

			} catch {

				Write-Warning -Message "[Get-VMHostNetworkConfiguration][$vhost][ERROR] Could not gather NIC detail. $_"
				break

			} # end try/catch

			$vmhostServerServiceURL = $vmHostView.Client.ServiceUrl

			try {

				if (-not ($Server)) {

					Write-Verbose -Message '[Get-VMHostNetworkConfiguration] Gathering VDS PortGroup Data'
			<# After testing, in large environments, I found that the PortGroup 'Key' value is not necessarily a unique ID. If connected to multiple vCenter servers,
			you could end up returning multiple values for vmk interface mappings to a VDS PortGroup, which is not desired and inaccurate. If a vCenter server name is
			provided in the -Server parameter, speed will be greatly increased. #>
					$dvPortGroupView = Get-View -ViewType DistributedVirtualPortgroup -Property Key, Config |
					Where-Object { $_.Client.ServiceUrl -eq "$vmhostServerServiceURL" }

				} # end if -not $Server

			} catch {

				Write-Warning -Message "[Get-VMHostNetworkConfiguration][$vhost][ERROR] Could not gather VDS PortGroup Data. $_"
				break

			} # end try/catch

			$pNics = $vmHostView.Config.Network.Pnic
			$vNics = $vmHostView.Config.Network.Vnic
			$dvData = $vmHostView.Config.Network.ProxySwitch
			$vsData = $vmHostView.Config.Network.Vswitch
			$dvPortGroup = $dvPortGroupView.Config
			$vsPortGroup = $vmHostView.Config.Network.PortGroup.Spec

			# Pull in detail for physical interface details
			foreach ($pnic in $pNics) {

				$objNic = $null
			<# At the time this script was written, the easiest way for me to pull in details about the DVS/VSS was to match the interface details found in one sub-property tree,
			with the details found in a different sub-property tree, and then return the desired property value. This methodology was the primary reason the $dvData and $vsData
			variables were created. This is also true for the virtual interface details, thus I will not include a comment for that section	#>
				$objNic = [PSCustomObject] @{
					VMHost = $vmHostView.Name
					NICType = 'Physical'
					Name = $pnic.Device
					PciID = $pnic.Pci
					MACAddress = $pnic.Mac
					Driver = $pnic.Driver
					LinkSpeedMB = $pnic.LinkSpeed.SpeedMB
					DVSwitch = ($dvData | Select-Object DVSName, pNic, MTU | Where-Object { $_.pnic -like "*-$($pnic.device)" }).DvsName
					DVSMTU = [System.String]($dvData | Select-Object DVSName, pNic, MTU | Where-Object { $_.pnic -like "*-$($pnic.device)" }).MTU
					VSSSwitch = ($vsData | Select-Object Name, pNic, MTU | Where-Object { $_.pnic -like "*-$($pnic.device)" }).Name
					VSSMTU = [System.String]($vsData | Select-Object Name, pNic, MTU | Where-Object { $_.pnic -like "*-$($pnic.device)" }).MTU
					VMKMTU = $null
					DHCPEnabled = $null
					IPAddress = $null
					SubnetMask = $null
					DVSPortGroup = $null
					DVSPortGroupVLAN = $null
					VSSPortGroup = $null
					VSSPortGroupVLAN = $null
				} # end obj

				$finalResult += $objNic

			} # end foreach $pnic

			# pull in info for virtual interface details
			foreach ($vnic in $vNics) {

				$objNic = $null

				$objNic = [PSCustomObject] @{
					VMHost = $vmHostView.Name
					NICType = 'Virtual'
					Name = $vnic.Device
					PciID = $null
					MACAddress = $vnic.Spec.Mac
					Driver = $null
					LinkSpeedMB = $null
					DVSwitch = $null
					DVSMTU = $null
					VSSSwitch = $null
					VSSMTU = $null
					VMKMTU = $vnic.Spec.Mtu
					DHCPEnabled = $vnic.Spec.Ip.Dhcp
					IPAddress = $vnic.Spec.Ip.IpAddress
					SubnetMask = $vnic.Spec.Ip.SubnetMask
					DVSPortGroup = ($dvPortGroup | Select-Object Key, Name, DefaultPortConfig | Where-Object { $_.Key -eq "$($vnic.Spec.DistributedVirtualPort.PortGroupKey)" }).Name
					DVSPortGroupVLAN = ($dvPortGroup | Select-Object Key, Name, DefaultPortConfig | Where-Object { $_.Key -eq "$($vnic.Spec.DistributedVirtualPort.PortGroupKey)" }).defaultportconfig.Vlan.VlanID
					VSSPortGroup = $vnic.Portgroup
					VSSPortGroupVLAN = ($vsPortGroup | Where-Object { $_.Name -eq "$($vnic.Portgroup)" }).VlanID
				} # end $objNic

				$finalResult += $objNic

			} # end roeach $vnic

			$finalResult

		} # end foreach $vhost

	} # end PROCESS block

	END {

		Write-Verbose -Message '[Get-VMHostNetworkConfiguration] Processing Complete'

	} # end END block

} # end function Get-VMHostNetworkConfiguration

Export-ModuleMember -Function Get-VMHostNetworkConfiguration


function Get-VMGuestNetworkConfiguration {

    <#
    .SYNOPSIS
        Returns VM Guest network adapter information, including detail about the virtual & IP interfaces
    .DESCRIPTION
        Returns VM Guest network adapter information, including detail about the virtual & IP interfaces.
        This function aims to combine information that would typically take combining the output from more than one command to achieve. I also wrote it with scale in mind, thus, I focused on
        gathering information from the vSphere API and not native properties found as part of other PowerCLI cmdlet output.
        Running this assumes that you:
        1. Have PowerCLI installed
        2. You are already connected to at least one (or more) ESXi Hosts or vCenter Servers
        -IncludeVMHost parameter will let you choose if you wish to add that parameter/value to the output. Using the paramter adds (roughly) a 60% increase in processing time, which can be significant in larger environments.
        That said, it can also come in handy if you are managing any number of stand-alone ESXi systems.

        Sample Output

Name              : middle-esg-0
AdapterType       : vmxnet3
Label             : Network adapter 2
MacAddress        : 00:50:56:9c:60:a5
MacAddressType    : assigned
PortGroupName     : vxw-dvs-42-virtualwire-32-sid-5013-transit-right
PortGroupType     : Distributed
DVSwitchName      : vds-mgmt
IPAddress         : 192.168.1.11|fe80::250:56ff:fe9c:60a5
PrefixLength      : 29|64
DHCP              :
Connected         : True
StartConnected    : True
AllowGuestControl : True
Shares            : 50
ShareLevel        : normal
Status            : ok

    .PARAMETER IncludeVMHost
        Includes which VMHost the returned guest is running on.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .EXAMPLE
        Get-VM | Get-VMGuestNetworkAdapter
    .EXAMPLE
        Get-VMGuestNetworkAdapter -Name (Get-VM)
    .EXAMPLE
        Get-VMGuestNetworkAdapter -Name (Get-VM -Name SERVER1,SERVER2)
    .NOTES
        Author: Kevin Kirkpatrick
        Email: kevin@vmotioned.com
        GitHub: https://github.com/vScripter
        Version: 2.0
        Last Updated: 7/27/16
        Last Updated By: K. Kirkpatrick
        Last Update Notes:
            - Refactored and added some code based on new APIs
    #>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [cmdletbinding()]
    param (
        [parameter(Position = 0,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
        [alias('VM')]
        $Name,

        [parameter(Position = 1)]
        [Switch]$IncludeVMHost
    )

    BEGIN {

        Write-Verbose -Message "[Get-VMGuestNetworkAdapter] Processing Started"

        # query the API for dvPortGroups, but only query Key & Name properties to keep things quick; store this in mem for quick access, later on
        #$dvPortGroupApi = $null
        #$dvPortGroupApi = Get-View -ViewType DistributedVirtualPortgroup -Property Key,Name

        # query the API for network information; by default results are typically only dvPortGroups; store in mem for quick access, later on
        $dvPortGroupApi = Get-View -ViewType Network

        # query the API for all dvSwitches and store for later lookup
        $dvSwitchApi = $null
        $dvSwitchApi = Get-View -ViewType DistributedVirtualSwitch

    } # end BEGIN block

    PROCESS {

        foreach ($guest in $Name) {

            # access raw vSphere API
            $guestView = $null
            $guestView = $guest.ExtensionData

            # grab/parse the vCenter name to be used with future Get-View/API call filtering
            # commenting this out; 'Client' property deprecated
            #$guestClient = $null
            #$guestClient = ([uri]$guest.Client.ServiceUrl).Host

            # query hardware devices and then filter based on an object containing a 'MacAddress' property (which indicates that it's a network interface)
            $guestNicAdapterQuery = $null
            $guestNicAdapterQuery = $guestView.Config.Hardware.Device | Where-Object MacAddress

            foreach ($vNic in $guestNicAdapterQuery) {

                # use the mac address to compare/match so we can correlate/combine data from two separate APIs
                $ipInterface   = $null
                $ipInterface   = ($guestView.Guest.Net | Where-Object { $_.MacAddress -eq $vNic.MacAddress }).IpConfig

                # get the .NET type name of the vNIC backing object and resolve the type
                $portGroupType = $null
                $portGroupType = if(($vNic.backing).GetType().FullName -like '*distributed*') {

                            'Distributed'

                        } elseif ($vNic.DeviceInfo.Summary -eq 'None') {

                            # adding this logical so that 'Standard' is not returned for an adapter that exists but it not assigned to anything
                            'NotAssigned'

                        } elseif ($vNic.DeviceInfo.Summary -ne $null) {

                            'Standard'

                        }# end if/elseif

                # resolve/query the portGroupName, depending on the portGroupType
                $portGroupName = $null
                switch ($portGroupType) {

                    'Standard' {

                        $portGroupName = $vNic.DeviceInfo.Summary

                    } # end 'Standard'

                    'NotAssigned' {

                        $portGroupName = $vNic.DeviceInfo.Summary

                    } # end 'Standard'

                    'Distributed' {

                        # grab the dvPortGroup Key to use as a filter, below
                        $dvPortGroupKey = $null
                        $dvPortGroupKey = $vNic.Backing.Port.PortGroupKey

                        # select the proper dvPortGroup, based on a lookup of the dvPortGroup, based on the 'Key' value, and then return the 'friendly' Name
                        $portGroupName  = ($dvPortGroupApi | Where-Object { $_.Key -eq $dvPortGroupKey }).Name

                        <# look up the dvSwitch Name by using the same filtering used to resolve the dvPortGroup Name;
                        then, unroll the MoRef key value for the dvSwitch associated with the dvPortGroup;
                        then, cross-reference that, with the stored dictionary of dvSwitch information to resolve the name #>
                        $dvSwitchName   = $null
                        $dvSwitchName   = ($dvPortGroupApi | Where-Object { $_.Key -eq $dvPortGroupKey }).Config.DistributedVirtualSwitch.Value
                        # just re-use/overwrite the variable with new information
                        $dvSwitchName   = ($dvSwitchApi | Where-Object {$_.MoRef.Value -eq $dvSwitchName}).Name

                    } # end 'Distributed'

                } # end switch

                $objVmNic = @()
                $objVmNic = [PSCustomObject] @{
                    Name              = $guestView.Name
                    AdapterType       = $vNic.GetType().FullName.SubString(18).ToLower()
                    Label             = $vNic.DeviceInfo.Label
                    MacAddress        = $vNic.MacAddress
                    MacAddressType    = $vNic.AddressType
                    PortGroupName     = $portGroupName
                    PortGroupType     = $portGroupType
                    DVSwitchName      = $dvSwitchName
                    IPAddress         = $ipInterface.IpAddress.IpAddress -join '|'
                    PrefixLength      = $ipInterface.IpAddress.PrefixLength -join '|'
                    DHCP              = $ipInterface.Dhcp.Ipv4.Enable -join '|'
                    Connected         = $vNic.Connectable.Connected
                    StartConnected    = $vNic.Connectable.StartConnected
                    AllowGuestControl = $vNic.Connectable.AllowGuestControl
                    Shares            = $vNic.ResourceAllocation.Share.Shares
                    ShareLevel        = $vNic.ResourceAllocation.Share.Level
                    Status            = $vNic.Connectable.Status
                }

                if ($IncludeVMHost) {

                    # if the -IncludeVMHost switch paramter was used, add a VMHost property/value to the object before it's returned
                    Add-Member -InputObject $objVmNic -MemberType NoteProperty -Name 'VMHost' -Value $($guest.VMHost)
                    $objVmNic

                } else {

                    $objVmNic

                } # end if/else

            } # end foreach $vNic

        } # end foreach $guest

    } # end PROCESS block

} # end function Get-VMGuestNetworkConfiguration

Export-ModuleMember -Function Get-VMGuestNetworkConfiguration