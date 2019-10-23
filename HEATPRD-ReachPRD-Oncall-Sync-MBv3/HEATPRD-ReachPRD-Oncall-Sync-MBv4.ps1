# Set TLS to 1.2 to allow for invoking a REST Get request
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# we need to get the heat groups based on them matching the current groups in REACH
Function GetOnCallTeamInfo($OnCallTeamNameHeat)
{
    #$OnCallTeamNameHeat = $teamFromQuery
	Invoke-Sqlcmd -ServerInstance "ismappwcdcqvm01" -Database "HEATSM" -Username "NTTReader" -Password "NTTHeat991" -Query "
SELECT OC.OnCallTeamName, OC.SupportedAreas, ISNULL(OC.SpecialInstructions, '') AS SpecialInstructions, OC.OnCallType, '' AS 'Shift Details', 
       OC.OwnerTeam, convert(nvarchar(MAX), Sch.ScheduleStart, 20) AS ScheduleStart, convert(nvarchar(MAX), Sch.ScheduleEnd, 20) AS ScheduleEnd,
       Sch.ContactPrimaryFullName, Sch.ContactPrimaryLoginID, ISNULL(Sch.ContactPrimaryDeviceNo, '') AS ContactPrimaryDeviceNo, Sch.ContactPrimaryMobile, 
                   Sch.ContactPrimaryWork, Sch.ContactPrimaryHome, Sch.ContactSecondaryFullName, Sch.ContactSecondaryLoginID, 
                   ISNULL(Sch.ContactSecondaryDeviceNo, '') AS ContactSecondaryDeviceNo, Sch.ContactSecondaryMobile, Sch.ContactSecondaryWork, Sch.ContactSecondaryHome, 
                   Sch.FirstEscalationFullName, Sch.FirstEscalationLoginID, Sch.FirstEscalationMobile, Sch.FirstEscalationWork, Sch.FirstEscalationHome, 
                   Sch.SecondEscalationFullName, Sch.SecondEscalationLoginID, Sch.SecondEscalationMobile, Sch.SecondEscalationWork, Sch.SecondEscalationHome
FROM NYUOnCall OC
JOIN NYUOnCallScheduled Sch ON Sch.NYUParentLink_RecID = OC.RecID 
WHERE sch.Type = 'SCH' 
       --/*Sch.ScheduleStart >= '07/02/2018'-- @ScheduleStartDate AND Sch.ScheduleEnd <=  '07/03/2018'--@ScheduleEndDate    */
       AND OC.OnCallTeamName = '$OnCallTeamNameHeat' AND OC.Status ='Active'
          AND GETDATE() between dbo.HEAT_ConvertDateTime(Sch.ScheduleStart) and dbo.HEAT_ConvertDateTime(Sch.ScheduleEnd)
UNION
SELECT OC.OnCallTeamName, OC.SupportedAreas, ISNULL(OC.SpecialInstructions, '') AS SpecialInstructions,OC.OnCallType,SCH.ShiftDetails AS 'Shift Details', 
       OC.OwnerTeam, convert(nvarchar(MAX), Sch.ScheduleStart, 20) AS ScheduleStart, convert(nvarchar(MAX), Sch.ScheduleEnd, 20) AS ScheduleEnd, Sch.ContactPrimaryFullName, 
       Sch.ContactPrimaryLoginID, ISNULL(Sch.ContactPrimaryDeviceNo, '') AS ContactPrimaryDeviceNo, Sch.ContactPrimaryMobile, Sch.ContactPrimaryWork, Sch.ContactPrimaryHome, 
                   Sch.ContactSecondaryFullName, Sch.ContactSecondaryLoginID, ISNULL(Sch.ContactSecondaryDeviceNo, '') AS ContactSecondaryDeviceNo, Sch.ContactSecondaryMobile, 
                   Sch.ContactSecondaryWork, Sch.ContactSecondaryHome, Sch.FirstEscalationFullName, Sch.FirstEscalationLoginID, Sch.FirstEscalationMobile, Sch.FirstEscalationWork, 
       Sch.FirstEscalationHome, Sch.SecondEscalationFullName, Sch.SecondEscalationLoginID, Sch.SecondEscalationMobile, Sch.SecondEscalationWork, Sch.SecondEscalationHome
FROM NYUOnCall OC 
INNER JOIN NYUOnCallScheduled Sch ON Sch.NYUParentLink_RecID = OC.RecID
WHERE sch.Type ='SFT' AND OnCallTeamName = '$OnCallTeamNameHeat' AND Status ='Active'
UNION 
SELECT OnCallTeamName,SupportedAreas,ISNULL(SpecialInstructions, '') AS SpecialInstructions,OnCallType, '' AS 'Shift Details',OwnerTeam, null AS ScheduleStart,
     null AS ScheduleEnd, ContactPrimaryName as 'ContactPrimaryFullName', ContactPrimaryLoginID, ISNULL(DeviceNumberPrimary, '') AS 'ContactPrimaryDeviceNo', 
                   ContactPrimaryMobile, ContactPrimaryWork, ContactPrimaryHome, ContactSecondaryName as 'ContactSecondaryFullName', ContactSecondaryLoginID,
       ISNULL(DeviceNumberSecondary, '') as 'ContactSecondaryDeviceNo', ContactSecondaryMobile,ContactSecondaryWork, ContactSecondaryHome, 
                   FirstEscalationName as 'FirstEscalationFullName', FirstEscalationLoginID, FirstEscalationMobile, FirstEscalationWork,FirstEscalationHome,
                   SecondEscalationName as 'SecondEscalationFullName', SecondEscalationLoginID, SecondEscalationMobile,SecondEscalationWork, SecondEscalationHome
FROM NYUOnCall
WHERE Status ='Active' AND OnCallType ='Standard' AND OnCallTeamName = '$OnCallTeamNameHeat'
ORDER BY OC.OnCallTeamName
"
}

Function listgroupinfo($group_name)
{
	$url = 'https://nyureachlab.nyumc.org/reach/api/group/list?api_token=8Hkq2hB16G6gnmW'
	$body =
	@"
{
    "group_name": "$group_name"
}
"@
	
	$groupinfo = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
	$groupinfo.GetEnumerator() | where { $_.group_name -eq "$group_name" }
}

# we now need to create the HTML report file which will be used as the body of the HTML email notification of who is on call
if(Test-Path C:\MCIT\Scripts\Powershell\reachHtmlReport.html)
{
    Remove-Item C:\MCIT\Scripts\Powershell\reachHtmlReport.html
}
new-item -ItemType File -Path C:\MCIT\Scripts\Powershell\reachHtmlReport.html
$htmlContent = @"
    <!DOCTYPE html>
        <html lang='en'>
            <head>
                <style>
                    h1{
                        font-family: Helvetica, sans-serif;
                        color: blue;
                    }
                </style>
            </head>
            <body>
                <h1>NYU Langone MCIT</h1>
                <h2>On Call Schedule<h2>
                
            </body>
        </html>
"@

Add-Content -Path C:\MCIT\Scripts\Powershell\reachHtmlReport.html $htmlContent

# get REACH teams
$jsonFromRestCall = @()
$jsonFromRestCall += Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/list?api_token=8Hkq2hB16G6gnmW' -Method Get

$reachGroups = @()
$reachGroups += $jsonFromRestCall.group_name

$heatGroups = @()
$heatGroupsFiltered = @()
foreach($jsonItem in $jsonFromRestCall)
{
    $heatGroups += GetOnCallTeamInfo($jsonItem.group_name)|select OnCallTeamName, ContactPrimaryLoginID, ContactSecondaryLoginID, FirstEscalationLoginID, SecondEscalationLoginID
}


foreach($heatGroup in $heatGroups)
{
    if($reachGroups.GetEnumerator() -match $heatGroup.OnCallTeamName)
    {
        # we now have the correct groups to work with in REACH
        write-host "reach group: " $heatGroup.OnCallTeamName
        # we now need to get online and offline users for each group
        # get each groups online users and offline users and remove them
    }
    
    foreach($user in $((listgroupinfo($heatGroup.OnCallTeamName)).group_onlinemembers.user_username))
    {
$bodyForRemove =
	@"
{
    "group_name": "$($heatGroup.OnCallTeamName)",
    "members": ["$user"]
}
"@

$url2 = 'https://nyureachlab.nyumc.org/reach/api/group/removeuser?api_token=8Hkq2hB16G6gnmW'

Invoke-RestMethod -Uri $url2 -Method Post -Body $bodyForRemove -ContentType "application/json"
    }
    foreach($user in $((listgroupinfo($heatGroup.OnCallTeamName)).group_offlinemembers.user_username))
    {
$bodyForRemove =
	@"
{
    "group_name": "$($heatGroup.OnCallTeamName)",
    "members": ["$user"]
}
"@

$url2 = 'https://nyureachlab.nyumc.org/reach/api/group/removeuser?api_token=8Hkq2hB16G6gnmW'

Invoke-RestMethod -Uri $url2 -Method Post -Body $bodyForRemove -ContentType "application/json"
    }
##########################################################################################################
# we have now removed the users from REACH and now we need to add the users from HEAT
#
$user1 = $heatGroup.ContactPrimaryLoginID
$user2 = $heatGroup.ContactSecondaryLoginID
$user3 = $heatGroup.FirstEscalationLoginID
$user4 = $heatGroup.SecondEscalationLoginID

$bodyForAdd =
	@"
{
    "group_name": "$($heatGroup.OnCallTeamName)",
    "members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

$url2 = 'https://nyureachlab.nyumc.org/reach/api/group/adduser?api_token=8Hkq2hB16G6gnmW'

Invoke-RestMethod -Uri $url2 -Method Post -Body $bodyForAdd -ContentType "application/json"
############################################################################################################
# we now have to put them on call
$bodyForOnCall =
	@"
{
    "group_name": "$($heatGroup.OnCallTeamName)",
    "group_members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

$urlForOnCall = 'https://nyureachlab.nyumc.org/reach/api/group/oncalluser?api_token=8Hkq2hB16G6gnmW'

Invoke-RestMethod -Uri $urlForOnCall -Method Post -Body $bodyForOnCall -ContentType "application/json"
}

$jsonFromRestCallAfterUpdate = @()
$jsonFromRestCallAfterUpdate += Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/list?api_token=8Hkq2hB16G6gnmW' -Method Get
$jsonFromRestCallAfterUpdate|ForEach-Object {
Add-Content -Path C:\MCIT\Scripts\Powershell\reachHtmlReport.html "<h2>TEAM: $($_.group_name)</h2>"
$_.group_onlinemembers|ForEach-Object{
Add-Content -Path C:\MCIT\Scripts\Powershell\reachHtmlReport.html "<p>USER: <strong>$($_.user_username)</strong> is on call</p>"
}
}
$htmlContent1 = get-content C:\MCIT\Scripts\Powershell\reachHtmlReport.html

$emailFrom1 = 'michael.botier@nyulangone.org'
$mailSubject1 = 'test email'
$emailTo1 = 'michael.botier@nyulangone.org'

Send-MailMessage -to $emailTo1 -From $emailFrom1 -Subject $mailSubject1 -SmtpServer smtp.nyumc.org -Body ($htmlContent1|Out-String) -BodyAsHtml


