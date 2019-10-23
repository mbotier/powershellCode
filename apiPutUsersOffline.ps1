
$bodyForJsonCallOffline =
@"
{
    "group_name": "Ivanti HEAT",
    "group_members": [ "menjir01", "vasquj01"]
}
"@

Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/offlineuser?api_token=8Hkq2hB16G6gnmW' -Body $bodyForJsonCallOffline -Method Post