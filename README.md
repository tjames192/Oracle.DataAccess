# Oracle.DataAccess

# Examples

```powershell
$ComputerName = "oracle.contoso.com"
$service ="database"
$instance ="database"
$userid = "username"
$password = "password"

Import-Module .\Oracle.DataAccess.psm1 -verbose
$sql = @"
SELECT style, path
  FROM database@server.contoso.com    style,
       contoso_style                   b,
       database@server.contoso.com  img
WHERE     style = attribute
       --AND entry_date > SYSDATE - 365
       AND TYPE = 'PHOTO'
       AND style = style
"@ 

Connect-TNS -host $ComputerName -service $service -instance $instance -userid $userid -password $password
$dt = Get-DataTable -sql $sql
Disconnect
$dt
