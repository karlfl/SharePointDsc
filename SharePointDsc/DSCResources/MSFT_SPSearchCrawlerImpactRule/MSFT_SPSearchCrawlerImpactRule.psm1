$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt32]
        $RequestLimit = 0,

        [Parameter()]
        [System.UInt32]
        $WaitTime = 0,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Crawler Impact Rule Setting for '$Name'"

    if (($RequestLimit -gt 0) -and ($WaitTime -gt 0))
    {
        throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{

            ServiceAppName = $params.ServiceAppName
            Name           = $params.Name
            RequestLimit   = $null
            WaitTime       = $null
            Ensure         = "Absent"
        }


        $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $serviceApp)
        {
            $nullReturn.ServiceAppName = $null
            return $nullReturn
        }
        else
        {
            $crawlerImpactRule = Get-SPEnterpriseSearchSiteHitRule -Identity $params.Name -SearchService $params.ServiceAppName
            if ($null -eq $crawlerImpactRule)
            {
                return $nullReturn
            }
            else
            {
                if ($crawlerImpactRule.Behavior -eq "0")
                {
                    return @{
                        ServiceAppName = $params.ServiceAppName
                        Name           = $params.Name
                        RequestLimit   = $crawlerImpactRule.HitRate
                        WaitTime       = 0
                        Ensure         = "Present"
                    }
                }
                else
                {
                    return @{
                        ServiceAppName = $params.ServiceAppName
                        Name           = $params.Name
                        RequestLimit   = 0
                        WaitTime       = $crawlerImpactRule.HitRate
                        Ensure         = "Present"
                    }
                }
            }
        }
    }

    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt32]
        $RequestLimit = 0,

        [Parameter()]
        [System.UInt32]
        $WaitTime = 0,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )


    Write-Verbose -Message "Setting Crawler Impact Rule Setting for '$Name'"

    if (($RequestLimit -gt 0) -and ($WaitTime -gt 0))
    {
        throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"
    }

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Crawler Impact Rule $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $behavior = "0"
            $hitRate = 0
            if ($null -eq $params.RequestLimit)
            {
                $behavior = "1"
                $hitRate = $params.WaitTime
            }
            else
            {
                $behavior = "0"
                $hitRate = $params.RequestLimit
            }

            $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            if ($null -eq $serviceApp)
            {
                throw "The Search Service Application does not exist."
            }
            New-SPEnterpriseSearchSiteHitRule -Name $params.Name `
                -Behavior $behavior `
                -HitRate $hitRate `
                -SearchService $serviceApp
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating Crawler Impact Rule $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $behavior = "0"
            $hitRate = 0
            if ($null -eq $params.RequestLimit)
            {
                $behavior = "1"
                $hitRate = $params.WaitTime
            }
            else
            {
                $behavior = "0"
                $hitRate = $params.RequestLimit
            }
            $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            if ($null -eq $serviceApp)
            {
                throw "The Search Service Application does not exist."
            }

            Remove-SPEnterpriseSearchSiteHitRule -Identity $params.Name `
                -SearchService $serviceApp `
                -ErrorAction SilentlyContinue

            New-SPEnterpriseSearchSiteHitRule -Name $params.Name `
                -Behavior $behavior `
                -HitRate $hitRate `
                -SearchService $serviceApp

        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Crawler Impact Rule $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            if ($null -eq $serviceApp)
            {
                throw "The Search Service Application does not exist."
            }
            Remove-SPEnterpriseSearchSiteHitRule -Identity $params.Name `
                -SearchService $serviceApp `
                -ErrorAction SilentlyContinue
        }
    }


}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt32]
        $RequestLimit = 0,

        [Parameter()]
        [System.UInt32]
        $WaitTime = 0,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    Write-Verbose -Message "Testing Crawler Impact Rule Setting for '$Name'"

    if (($RequestLimit -gt 0) -and ($WaitTime -gt 0))
    {
        throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"
    }

    $behavior = ""
    if ($RequestLimit -ne 0)
    {
        $behavior = "RequestLimit"
    }
    else
    {
        $behavior = "WaitTime"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ServiceAppName",
            "Name",
            $behavior)
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ServiceAppName",
            "Name",
            "Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource

