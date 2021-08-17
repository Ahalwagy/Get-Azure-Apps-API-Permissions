

Import-Module AzureADPreview

$Credential = Get-Credentials

#Connect to AzureAD tenant
Connect-AzureAD -TenantDomain "TenantID" -Credential $Credential

#Outputfile

$date = Get-Date -Format yyyy_MM_dd_hh_mm_tt

$filename = "Azure_Apps_API_Permission_"+ $date + ".csv"

$Path = "D:\$filename"

$SPNs = Get-AzureADServicePrincipal -All $true 

#Scope = Delegated permission | Role = Application permission
#Scope = $sp.Oauth2Permissions | Role = $app.Approles

$apps = Get-AzureADApplication -All $true

foreach($app in $apps)
{
        $delegation= ""
        $application=""

        $rsc = $app.requiredResourceAccess | ConvertTo-Json -Depth 3 | ConvertFrom-Json 
        foreach($pr in $rsc ){

            foreach($a in $pr.ResourceAccess){
                if($a.Type -match "scope"){
                    $sp = $SPNs | Where-Object {$_.AppId -eq $pr.ResourceAppId}
                    $permission = $sp.Oauth2Permissions | Where-Object {$_.Id -eq $a.Id}
                    #$permission.Value
                    $delegation = $permission.Value + ";" + $delegation
                    } 
                elseif($a.Type -match "Role"){
                $sp = $SPNs | Where-Object {$_.AppId -eq $pr.ResourceAppId}
                $permission = $sp.AppRoles | Where-Object {$_.Id -eq $a.Id}
                #$permission.Value
                $application = $permission.Value + ";" + $application
                } 
            }
        }


        $owners =""

        $users = Get-AzureADApplicationOwner -ObjectId $app.ObjectId | select UserPrincipalName

        if($users){$users|ForEach-Object {$owners=$_.UserPrincipalName+";"+$owners}}


        $csvValue = New-Object psobject -Property @{
                          AppId = $app.AppId
                          ObjectId = $app.ObjectId
                          DisplayName = $App.Displayname
                          Delegation_Permission = $delegation
                          Application_Permission = $application
                          Owners=$owners
                        }
        $csvValue |Select AppId, ObjectId,DisplayName,Delegation_Permission,Application_Permission,Owners|Export-Csv $Path  -NoTypeInformation -Append -Encoding Default

                    $value =$csvValue.AppId  + ";" + $csvValue.ObjectId  + ";"+ $csvValue.DisplayName + ";"+ $csvValue.Delegation_Permission  + ";"+ $csvValue.Application_Permission + ";"+ $csvValue.Owners

                    Write-Host $value -ForegroundColor Green
}