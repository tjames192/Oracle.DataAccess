param (
	[Parameter(Mandatory = $false)]
	[string] $OracleDLL = "C:\oracle\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
)

$SCRIPT:conn = $null

function Load {
	param (
		[Parameter(Mandatory = $true)] [string] $OracleDLL,
		[Parameter(Mandatory = $false)] [switch] $passThru
	)
	$name = $OracleDLL
	$asm = [System.Reflection.Assembly]::LoadFile($name)
	if ($passThru) { $asm }
}


function Connect {
	[CmdletBinding()]
	Param( 
		[Parameter(Mandatory = $true)] [string]$ConnectionString,
		[Parameter(Mandatory = $false)] [switch]$PassThru 
	)
	$conn = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($ConnectionString)
	$conn.Open()
	if (!$PassThru) {
		$SCRIPT:conn = $conn 
		Write-Verbose ("Connected with {0}" -f $conn.ConnectionString)
	}
	else {
		$conn
	}
}

function Connect-TNS {
	[CmdletBinding()]
	Param( 
		[Parameter(Mandatory = $true)] [string]$host,
		[Parameter(Mandatory = $true)] [string]$service,
		[Parameter(Mandatory = $true)] [string]$instance,
		[Parameter(Mandatory = $true)] [string]$UserId,
		[Parameter(Mandatory = $true)] [string]$Password,
		[Parameter(Mandatory = $false)] [switch]$PassThru 
	)
	$TNS = @"
(
	DESCRIPTION = 
		(ADDRESS = 
			(PROTOCOL = TCP)
			(HOST = $host)
			(PORT = 1524)
		)
		(CONNECT_DATA = 
			(SERVICE_NAME = $service)
			(INSTANCE_NAME = $instance)
		)
)
"@
	$connectString = ("Data Source={0};User Id={1};Password={2};" -f $TNS, $UserId, $Password)
	Connect $connectString -PassThru:$PassThru
}

function Get-Connection ($conn) {
	if (!$conn) { $conn = $SCRIPT:conn }
	$conn
}

function Disconnect {
	[CmdletBinding()]
	Param( 
		[Parameter(Mandatory = $false)]
		[Oracle.ManagedDataAccess.Client.OracleConnection]$conn
	)
	$conn = Get-Connection($conn)
	if (!$conn) {
		Write-Verbose "No connection is available to disconnect from"; return
	}
	if ($conn -and $conn.State -eq [System.Data.ConnectionState]::Closed) {
		Write-Verbose "Connection is already closed"; return
	}
	$conn.Close()
	Write-Verbose ("Closed connection to {0}" -f $conn.ConnectionString)
	$conn.Dispose()
}

function Get-DataTable {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false)]
		[Oracle.ManagedDataAccess.Client.OracleConnection]$conn, 
 
		[Parameter(Mandatory = $true)] [string]$sql
	)
	$conn = Get-Connection($conn)
	$cmd = $conn.CreateCommand()
	$cmd.CommandText = $sql
	
	$rdr = $cmd.ExecuteReader()
	$columns = @($(for ($i = 0; $i -lt $rdr.FieldCount; $i++) { $rdr.GetName($i) }))
	$values = (0..($rdr.FieldCount - 1))
	$hash = @{ }
	#$timer = [System.Diagnostics.Stopwatch]::StartNew()
	while ($rdr.Read()) {
		$fieldCount = $rdr.GetOracleValues($values)	
		0..($fieldCount - 1) | % { 
			$c = $columns[$_] 
			$v = $values[$_].value
			$hash[$c] = $v
		}
		new-object -TypeName psobject -Property $hash
	}
	#$Timer.Stop()
	#$Timer.ElapsedMilliseconds

	<# not working
    $da = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($cmd)
	$output = @()
    $output = New-Object System.Data.DataSet
    $da.Fill($output)
	$output
	#>
}

Load -OracleDLL $OracleDLL