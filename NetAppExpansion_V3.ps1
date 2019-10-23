# Script: NetApp share expansion script
# Author: Michael Botier

# create the credential object to pass the correct credentials to the connection command
$userName = "ansibletest"
$password = ConvertTo-SecureString "Ansible123!" -AsPlainText -Force

# set the credential object
$Cred = New-Object System.Management.Automation.PSCredential($userName, $password)

# connect to the NetApp Controller with the appropriate credentials
Connect-NcController 10.174.76.135 -Vserver dnstest-vault -Credential $Cred
#######################################################################################################

# check to make sure there is space available on the Volume
# check for available space
$volAvailable = Get-NcVol -Name ansibleVol| select -ExpandProperty Available
$volAvailableInGB = ($volAvailable / 1GB)

# now compare that to the total space and make sure we have not exceeded 80% usage
$volSize = Get-NcVolSize -Name ansibleVol|select -ExpandProperty VolumeSize
$volSizeInGB = ($volSize / 1GB)

# perform the space available validation
# if we have the space available, we will continue with the expansion
# if NOT, we will update a variable to pass back to HEAT that the automation cannot continue
if($volAvailableInGB -gt ($volSizeInGB * 0.2))
{
    Write-Host "We can continue with the Automation"
    $AutomationClearToContinue = $true
    # get the approval from the HEAT CI
    $approvalBool = $true
    # get the path for the Department Share to expand from the HEAT CI
    # Storage team will specify the limit of the expansion
    # for this test I set the expansion to 2GB
    $QuotaTargetToExpand = "/vol/ansibleVol/test111"
    $Unit = 'mb'
    
    $getCurrentQuotaSize = Get-NcQuota -QuotaTarget $QuotaTargetToExpand|select -ExpandProperty DiskLimit
    
    $QuotaDiskLimit = [int]$getCurrentQuotaSize/1000 # need to convert to integer
    
    $QuotaDiskLimitPercentIncrease = $QuotaDiskLimit * 0.1
    
    $newQuota = [math]::Ceiling($QuotaDiskLimitPercentIncrease + $QuotaDiskLimit) # this sets the new Quota size
    if(($volAvailableInGB + $newQuota) -gt ($volSizeInGB * 0.2))
    {
        $quotaAmountInMB = [string]$newQuota # here we convert the new Quota size to a string
        $Quota = $quotaAmountInMB
        $DiskLimit = $Quota+$Unit
        # expand the share
        if($approvalBool)
        {
        
            Set-NcQuota -Path $QuotaTargetToExpand -DiskLimit $DiskLimit -ErrorAction Stop
        }
        else{
            $feedback = "The expansion has not been approved"
        }
    }
    else{
        Write-Host "We have less than 20% available space left on the volume"
    }
}
else{
    Write-Host "We have less than 20% available space left on the volume"
}

  
    
    