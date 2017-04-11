Configuration CompanyServer
{

    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainFqdn,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$DomainCredential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DnsServerIpAddress
    )

    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xSystemSecurity
    Import-DscResource -ModuleName xCredSSP
    Import-DscResource -ModuleName cPowerPlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    xDNSServerAddress DnsClient-Server
    {
        InterfaceAlias = 'Ethernet'
        AddressFamily = 'IPv4'
        Address = $DnsServerIpAddress
    }

    xComputer DomainJoin
    {
        Name = $ServerName
        DomainName = $DomainFqdn
        Credential = $DomainCredential
        DependsOn = '[xDNSServerAddress]DnsClient-Server'
    }

    xIEEsc Security-IEescAdmins
    {
        UserRole = 'Administrators'
        IsEnabled = $true
    }

    xIEEsc Security-IEescUsers
    {
        UserRole = 'Users'
        IsEnabled = $true
    }

    xUAC Security-UAC
    {
        Setting = 'NotifyChangesWithoutDimming'
    }

    xCredSSP CredSSP
    {
        Ensure = 'Present'
        Role = 'Server'
    }

    cPowerPlan PowerSettings
    {
        IsSingleInstance = 'Yes'
        PowerPlan = 'High performance'
    }
}