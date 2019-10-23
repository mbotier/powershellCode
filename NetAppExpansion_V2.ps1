# Script: NetApp share expansion script
# Author: Michael Botier

# create the credential object to pass the correct credentials to the connection command
$userName = "ansibletest"
$password = ConvertTo-SecureString "Ansible123!" -AsPlainText -Force

# set the credential object
$Cred = New-Object System.Management.Automation.PSCredential($userName, $password)

# connect to the NetApp Controller with the appropriate credentials
Connect-NcController 10.174.76.135 -Vserver dnstest-vault -Credential $Cred

# get the approval from the HEAT CI
$approvalBool = $true

# get the path for the Department Share to expand from the HEAT CI
# Storage team will specify the limit of the expansion
# for this test I set the expansion to 2GB
$QuotaTargetToExpand = "/vol/ansibleVol/test111"
$Unit = 'g'
$DiskLimit = $Quota+$Unit
$getCurrentQuotaSize = Get-NcQuota -QuotaTarget $QuotaTargetToExpand|select DiskLimit

$QuotaDiskLimit = [int]$getCurrentQuotaSize.DiskLimit # need to convert to integer
$QuotaDiskLimitPercentIncrease = [math]::Ceiling($QuotaDiskLimit) # next to raise the value to its Ceiling

$newQuota = [math]::Ceiling($QuotaDiskLimitPercentIncrease/1000000) # this sets the new Quota size
$quotaIncreaseAmount = [string]$newQuota # here we convert the new Quota size to a string
$Quota = $quotaIncreaseAmount
$DiskLimit = $Quota+$Unit

# expand the share
if($approvalBool)
{
    Set-NcQuota -Path $QuotaTargetToExpand -DiskLimit $DiskLimit -ErrorAction Stop
}
else{
    $feedback = "The expansion has not been approved"
} 
