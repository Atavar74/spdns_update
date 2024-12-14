#requires -version 4
# notepad++ %USERPROFILE%\.ssh\etc\spdyn_update6.ps1
# powershell -NoProfile -ExecutionPolicy BYPASS -File "%USERPROFILE%\.ssh\etc\spdyn_update6.ps1" 'username' 'password'
# schtasks /create /tn "dyndns"	 /sc ONSTART /ru "Administrator" /rp "admin" /tr "powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Administrator\.ssh\etc\spdyn_update6.ps1'  'username' 'password'"
# schtasks /create /tn "dyndnsH" /sc HOURLY  /ru "Administrator" /rp "admin" /tr "powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Administrator\.ssh\etc\spdyn_update6.ps1'  'username' 'password'"

Clear-Host

# (optional) adjust your values
$fqdn = $args[0]
$pwd  = $args[1]
$user = $args[0]

# (optional) set full path to (writable) logfile and switch logging on ($true) or off ($false)
$myLogFile = $PSScriptRoot + "\spdyn_update.log"
$logging = $true

### simple logger ###
function log {
	param(
		[Parameter(ValueFromPipeline=$true)]
		$piped
	)

	if ($logging) {
		(Get-Date -Format "yyyy-MM-dd HH:mm:ss").ToString() + " " + `
			$piped | Out-File -FilePath $myLogFile -Append
		}
	# console output
	"$piped"
}

### Getting the IPv6 ###
try {
	### ...directly from the System. Either use the constant Address, or the randomized. Depending of what used for Firewall-opening
 	### This may help for adjustments: Get-NetIPAddress | Format-Table
	#$currentIP = (Get-NetIPAddress -AddressFamily IPv6 -PrefixOrigin RouterAdvertisement -SuffixOrigin Link ).IPAddress
	$currentIP = (Get-NetIPAddress -AddressFamily IPv6 -PrefixOrigin RouterAdvertisement -SuffixOrigin Random ).IPAddress
	"Current IPv6: " + $currentIP | log
} catch {
	"Current IPv6 ERROR: " + $_.Exception.Message | log
	exit 1
}

### Compare with registered Address, exit when same
try {
	"Resolve DNS Name " + "Using native Commandlet" | log
		$ipHostEntry = Resolve-DnsName $fqdn -Type AAAA -ErrorAction Stop
		$registeredIP = $ipHostEntry[0].IPAddress

} catch {
	"Resolve DNS Name " + $_.Exception.Message | log
	exit 1
}

if ($registeredIP -like $currentIP) {
	"Precheck " + "IP $currentIP already registered." | log
	exit 0
}

### Send registration
$secpasswd = ConvertTo-SecureString $pwd -AsPlainText -Force
$myCreds = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
$url = "https://update.spdyn.de/nic/update?hostname=$fqdn&myip=$currentIP"

try {
	$resp = Invoke-WebRequest -Uri $url -Credential $myCreds -UseBasicParsing -ErrorAction Stop
} catch {
	"Update DNS " + $_.Exception.Message | log
	exit 1
}
"SPDYN result " + $resp.Content | log
