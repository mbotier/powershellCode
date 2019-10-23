# Set TLS to 1.2

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$teamForQuery = "Ivanti HEAT" 

Function GetOnCallTeamInfo ($OnCallTeamName1)

{

    $OnCallTeamName1 = $teamForQuery

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

       AND OC.OnCallTeamName = '$OnCallTeamName1' AND OC.Status ='Active'

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

WHERE sch.Type ='SFT' AND OnCallTeamName = '$OnCallTeamName1' AND Status ='Active'

UNION 

SELECT OnCallTeamName,SupportedAreas,ISNULL(SpecialInstructions, '') AS SpecialInstructions,OnCallType, '' AS 'Shift Details',OwnerTeam, null AS ScheduleStart,

     null AS ScheduleEnd, ContactPrimaryName as 'ContactPrimaryFullName', ContactPrimaryLoginID, ISNULL(DeviceNumberPrimary, '') AS 'ContactPrimaryDeviceNo', 

                   ContactPrimaryMobile, ContactPrimaryWork, ContactPrimaryHome, ContactSecondaryName as 'ContactSecondaryFullName', ContactSecondaryLoginID,

       ISNULL(DeviceNumberSecondary, '') as 'ContactSecondaryDeviceNo', ContactSecondaryMobile,ContactSecondaryWork, ContactSecondaryHome, 

                   FirstEscalationName as 'FirstEscalationFullName', FirstEscalationLoginID, FirstEscalationMobile, FirstEscalationWork,FirstEscalationHome,
                   SecondEscalationName as 'SecondEscalationFullName', SecondEscalationLoginID, SecondEscalationMobile,SecondEscalationWork, SecondEscalationHome

FROM NYUOnCall
WHERE Status ='Active' AND OnCallType ='Standard' AND OnCallTeamName = '$OnCallTeamName1'
ORDER BY OC.OnCallTeamName
"
}

# get SQL query results into array
#$HeatQueryResults = @()
#$HeatQueryResults += GetOnCallTeamInfo($teamForQuery)
#$HeatQueryResults

# get json data from REST call and pass the sorted data to the proper array
$jsonFromRestCall = @()
$jsonFromRestCall += Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/list?api_token=8Hkq2hB16G6gnmW' -Method Get

$jsonFromRestGroupNames = $jsonFromRestCall|Where-Object {$_.group_name -match "Ivanti HEAT"}
$jsonFromRestGroupNames.group_name

$user1 = 'fernad04'
$user2 = 'moraly01'
$user3 = 'menjir01'
$user4 = 'vasquj01'

$bodyForJsonCallRemove =
@"
{
    "group_name": "Ivanti HEAT",
    "members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

$bodyForJsonCallAdd =
@"
{
    "group_name": "Ivanti HEAT",
    "members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

$bodyForJsonCallOnCall =
@"
{
    "group_name": "Ivanti HEAT",
    "group_members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

$bodyForJsonCallOffline =
@"
{
    "group_name": "Ivanti HEAT",
    "group_members": ["$user1", "$user2", "$user3", "$user4"]
}
"@

if($jsonFromRestGroupNames.group_offlinemembers.Length -eq 0)
{
    Write-host "there are no users in REACH"
    write-host "we need to add users to REACH"
    Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/adduser?api_token=8Hkq2hB16G6gnmW' -Body $bodyForJsonCallAdd -Method Post
    
}

if($jsonFromRestGroupNames.group_offlinemembers -contains $user1 -or $user2 -or $user3 -or $user4)
{
    Write-Host "we now need to put the users on call"
    Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/oncalluser?api_token=8Hkq2hB16G6gnmW' -Body $bodyForJsonCallOnCall -Method Post
}
