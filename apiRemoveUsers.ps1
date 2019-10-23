$bodyForJsonCallRemove =
@"
{
    "group_name": "Ivanti HEAT",
    "members": ["fernad04", "moraly01", "menjir01", "vasquj01"]
}
"@

Invoke-RestMethod -Uri 'https://nyureachlab.nyumc.org/reach/api/group/removeuser?api_token=8Hkq2hB16G6gnmW' -Body $bodyForJsonCallRemove -Method Post