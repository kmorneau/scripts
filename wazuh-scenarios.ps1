# wazuh-scenarios.ps1
# Enhanced Wazuh Training Scenario Lab with Error Handling

$LogName = "Application"
$Source  = "Wazuh-Scenario-Lab"
$MaxRetries = 3
$RetryDelayMs = 100

# Ensure the source exists
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
        New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop
        Write-Host "Event source '$Source' created successfully." -ForegroundColor Green
    }
}
catch {
    Write-Host "Error creating event source: $_" -ForegroundColor Red
    exit 1
}

function Write-WazuhEvent {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Id,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [ValidateLength(1, 32766)]
        [string]$Message
    )
    
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            Write-EventLog -LogName $LogName -Source $Source -EventId $Id -EntryType $Type -Message $Message -ErrorAction Stop
            return
        }
        catch {
            $attempt++
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Milliseconds $RetryDelayMs
            }
            else {
                Write-Host "Failed to write event after $MaxRetries attempts: $_" -ForegroundColor Red
            }
        }
    }
}

# -------- Scenarios --------

function Scenario1-DDoS {
    Write-Host "`n[*] Starting DDoS Attack Scenario..." -ForegroundColor Cyan
    for ($i = 1; $i -le 50; $i++) {
        $src = "203.0.113.$i"
        $msg = "DDoS simulation: blocked TCP SYN to 192.0.2.10:80 from $src via firewall UFW."
        Write-WazuhEvent -Id 1001 -Type Warning -Message $msg
        Write-Host "  [$i/50] Blocked from $src" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 50
    }
    Write-Host "[+] DDoS scenario complete." -ForegroundColor Green
}

function Scenario2-IronDoor {
    Write-Host "`n[*] Starting IronDoor Physical Access Scenario..." -ForegroundColor Cyan
    for ($i = 1; $i -le 3; $i++) {
        $msg = "IronDoor ACCESS_DENIED user_id=EMP332 badge=0xAB12 door=DataCenter-1 reason=INVALID_PIN attempt=$i"
        Write-WazuhEvent -Id 2001 -Type Warning -Message $msg
        Write-Host "  [Attempt $i] Access denied - Invalid PIN" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 300
    }
    $msgOK = "IronDoor ACCESS_GRANTED user_id=EMP999 badge=0xCD34 door=DataCenter-1 reason=VALID_PIN"
    Write-WazuhEvent -Id 2002 -Type Information -Message $msgOK
    Write-Host "  [Success] EMP999 granted access" -ForegroundColor Green
    Write-Host "[+] IronDoor scenario complete." -ForegroundColor Green
}

function Scenario3-Auth {
    Write-Host "`n[*] Starting Authentication Attack Scenario..." -ForegroundColor Cyan
    
    # Failed login attempts
    for ($i = 1; $i -le 5; $i++) {
        $msg = "Authentication attack: failed login attempt user=admin from 198.51.100.$i via SSH attempt=$i"
        Write-WazuhEvent -Id 3001 -Type Warning -Message $msg
        Write-Host "  [Failed Attempt $i] SSH login failure from 198.51.100.$i" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 200
    }
    
    # Suspicious account activity
    $msg2 = "Authentication attack: privilege escalation attempt user=john sudo command='whoami' denied"
    Write-WazuhEvent -Id 3002 -Type Error -Message $msg2
    Write-Host "  [Alert] Sudo escalation denied for user john" -ForegroundColor Red
    
    # Account lockout
    $msg3 = "Authentication attack: account lockout triggered user=admin after 5 failed attempts"
    Write-WazuhEvent -Id 3003 -Type Warning -Message $msg3
    Write-Host "  [Security] Admin account locked due to multiple failures" -ForegroundColor Yellow
    
    Write-Host "[+] Authentication attack scenario complete." -ForegroundColor Green
}

function Scenario4-Phishing {
    Write-Host "`n[*] Starting Phishing Email Scenario..." -ForegroundColor Cyan
    
    $msg1 = "Phishing simulation: mail gateway blocked from=<support@micr0s0ft-secure.com> to=<user1@example.com> reason=phishing_signature_hit"
    Write-WazuhEvent -Id 4001 -Type Warning -Message $msg1
    Write-Host "  [Blocked] Suspicious email from support@micr0s0ft-secure.com" -ForegroundColor Yellow

    $msg2 = "Phishing simulation: user1@example.com clicked suspicious URL http://malicious-login.example/phish"
    Write-WazuhEvent -Id 4002 -Type Error -Message $msg2
    Write-Host "  [Alert] User clicked malicious link" -ForegroundColor Red
    
    $msg3 = "Phishing simulation: credential harvester detected sending data to external IP 203.0.113.50"
    Write-WazuhEvent -Id 4003 -Type Error -Message $msg3
    Write-Host "  [Critical] Credentials exfiltrated to external server" -ForegroundColor Red
    
    Write-Host "[+] Phishing scenario complete." -ForegroundColor Green
}

function Scenario5-Exfiltration {
    Write-Host "`n[*] Starting Data Exfiltration Scenario..." -ForegroundColor Cyan
    
    for ($i = 1; $i -le 10; $i++) {
        $msg = "Data exfiltration simulation: outbound 5MB transfer from 192.0.2.10 to 203.0.113.200:443 (#$i)"
        Write-WazuhEvent -Id 5001 -Type Warning -Message $msg
        Write-Host "  [$i/10] 5MB transferred to suspicious external IP" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
    }
    
    $msg2 = "Data exfiltration simulation: scp user=alice file=C:\Secret\plan.txt dest=203.0.113.150:/upload/plan.txt"
    Write-WazuhEvent -Id 5002 -Type Error -Message $msg2
    Write-Host "  [Critical] Confidential file exfiltrated via SCP" -ForegroundColor Red
    
    Write-Host "[+] Data exfiltration scenario complete." -ForegroundColor Green
}

function Scenario6-Ransomware {
    Write-Host "`n[*] Starting Ransomware Attack Scenario..." -ForegroundColor Cyan
    
    for ($i = 1; $i -le 50; $i++) {
        $msg = "Ransomware simulation: file rename C:\Share\docs\file$i.docx -> C:\Share\docs\file$i.docx.encrypted"
        Write-WazuhEvent -Id 6001 -Type Warning -Message $msg
        if ($i % 10 -eq 0) {
            Write-Host "  [$i/50] Files encrypted..." -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds 40
    }
    
    $note = "Ransomware simulation: ransom note created C:\Share\README_RESTORE_FILES.txt"
    Write-WazuhEvent -Id 6002 -Type Error -Message $note
    Write-Host "  [Critical] Ransom note created - 50 files encrypted" -ForegroundColor Red
    
    Write-Host "[+] Ransomware scenario complete." -ForegroundColor Green
}

function Scenario7-Downtime {
    Write-Host "`n[*] Starting Service Downtime Scenario..." -ForegroundColor Cyan
    
    $msg1 = "Downtime simulation: nginx service crash on WEB01 status=1/FAILURE"
    Write-WazuhEvent -Id 7001 -Type Error -Message $msg1
    Write-Host "  [Alert] nginx service crashed on WEB01" -ForegroundColor Red
    
    $msg2 = "Downtime simulation: nginx service auto-restart on WEB01 restart_counter=3"
    Write-WazuhEvent -Id 7002 -Type Information -Message $msg2
    Write-Host "  [Info] Service restarting (attempt 3)..." -ForegroundColor Cyan
    
    Start-Sleep -Seconds 1
    
    $msg3 = "Downtime simulation: WEB01 recovered, service nginx running"
    Write-WazuhEvent -Id 7003 -Type Information -Message $msg3
    Write-Host "  [Success] Service recovered" -ForegroundColor Green

    $msg4 = "Downtime simulation: HOST_DOWN name=web01.example.com ip=192.0.2.20 duration=300s reason=No heartbeat"
    Write-WazuhEvent -Id 7004 -Type Error -Message $msg4
    Write-Host "  [Alert] Host down - no heartbeat for 300s" -ForegroundColor Red
    
    Start-Sleep -Seconds 1
    
    $msg5 = "Downtime simulation: HOST_RECOVERED name=web01.example.com ip=192.0.2.20"
    Write-WazuhEvent -Id 7005 -Type Information -Message $msg5
    Write-Host "  [Success] Host recovered" -ForegroundColor Green
    
    Write-Host "[+] Downtime scenario complete." -ForegroundColor Green
}

function Scenario8-Botnet {
    Write-Host "`n[*] Starting Botnet Detection Scenario..." -ForegroundColor Cyan
    
    for ($i = 1; $i -le 20; $i++) {
        $msg = "Botnet simulation: outbound beacon from 192.0.2.30 to 198.51.100.200:8080 interval=60s (#$i)"
        Write-WazuhEvent -Id 8001 -Type Warning -Message $msg
        if ($i % 5 -eq 0) {
            Write-Host "  [$i/20] Botnet beacons detected" -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds 60
    }
    
    $dns1 = "Botnet simulation: DNS query 192.0.2.30 -> abcdefghij.malware-c2.example"
    Write-WazuhEvent -Id 8002 -Type Warning -Message $dns1
    Write-Host "  [Alert] Suspicious DNS query to C2 domain" -ForegroundColor Yellow
    
    $dns2 = "Botnet simulation: DNS query 192.0.2.30 -> xyz1234.malware-c2.example"
    Write-WazuhEvent -Id 8003 -Type Warning -Message $dns2
    Write-Host "  [Alert] Second C2 domain contacted" -ForegroundColor Yellow
    
    Write-Host "[+] Botnet scenario complete." -ForegroundColor Green
}

function Scenario9-AUP {
    Write-Host "`n[*] Starting Acceptable Use Policy Violation Scenario..." -ForegroundColor Cyan
    
    $proxy1 = "AUP simulation: proxy ACCESS_DENIED user=student1 url=http://gambling-example.com category=Gambling"
    Write-WazuhEvent -Id 9001 -Type Warning -Message $proxy1
    Write-Host "  [Blocked] Gambling site access denied" -ForegroundColor Yellow
    
    $proxy2 = "AUP simulation: proxy ACCESS_DENIED user=student1 url=http://social-media.example/video123 category=StreamingMedia"
    Write-WazuhEvent -Id 9002 -Type Warning -Message $proxy2
    Write-Host "  [Blocked] Streaming media access denied" -ForegroundColor Yellow
    
    $audit1 = "AUP simulation: unauthorized software install attempt 'winget install tor' by user=student1"
    Write-WazuhEvent -Id 9003 -Type Error -Message $audit1
    Write-Host "  [Alert] Unauthorized software installation blocked" -ForegroundColor Red
    
    Write-Host "[+] AUP violation scenario complete." -ForegroundColor Green
}

function Run-All {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "   Running ALL Scenarios" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    $startTime = Get-Date
    
    Scenario1-DDoS
    Scenario2-IronDoor
    Scenario3-Auth
    Scenario4-Phishing
    Scenario5-Exfiltration
    Scenario6-Ransomware
    Scenario7-Downtime
    Scenario8-Botnet
    Scenario9-AUP
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "   ALL Scenarios Complete!" -ForegroundColor Green
    Write-Host "   Total Runtime: $($duration.TotalSeconds) seconds" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
}

# -------- Menu UI --------

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║          WAZUH SECURITY TRAINING SCENARIO LAB               ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please select one of the scenarios below to run:`n" -ForegroundColor Green
    
    Write-Host "ANALYST FUNDAMENTALS TRAINING" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host " 1: DDoS Attack" -ForegroundColor White
    Write-Host "    └─ Run Time: ~5 seconds | Simulates 50 blocked TCP SYN floods"
    Write-Host " 2: IronDoor - Unauthorized Physical Access" -ForegroundColor White
    Write-Host "    └─ Run Time: ~2 seconds | Door access attempts with invalid PIN"
    Write-Host " 3: Authentication Attack" -ForegroundColor White
    Write-Host "    └─ Run Time: ~2 seconds | Failed logins and privilege escalation"
    Write-Host " 4: Phishing E-mail Campaign" -ForegroundColor White
    Write-Host "    └─ Run Time: ~2 seconds | Suspicious emails and credential harvesting`n"
    
    Write-Host "SECURITY ANALYSTS TRAINING" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host " 5: Data Exfiltration" -ForegroundColor White
    Write-Host "    └─ Run Time: ~2 seconds | 50MB of data sent to external IP"
    Write-Host " 6: Ransomware Attack" -ForegroundColor White
    Write-Host "    └─ Run Time: ~3 seconds | 50 files encrypted with ransom note"
    Write-Host " 7: Service Downtime & Recovery" -ForegroundColor White
    Write-Host "    └─ Run Time: ~3 seconds | Service crash, restart, and recovery"
    Write-Host " 8: Botnet Detection" -ForegroundColor White
    Write-Host "    └─ Run Time: ~2 seconds | Outbound C2 beacons and DNS queries"
    Write-Host " 9: Acceptable Use Policy Violation" -ForegroundColor White
    Write-Host "    └─ Run Time: ~1 second | Blocked websites and unauthorized software`n"
    
    Write-Host "OPTIONS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host " A: Run ALL scenarios (sequential)" -ForegroundColor White
    Write-Host " Q: Quit" -ForegroundColor White
    Write-Host ""
}

function Get-ValidChoice {
    $validChoices = @("1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "Q")
    $choice = ""
    
    do {
        $choice = Read-Host "Enter your choice [1-9, A, Q]"
        if ($choice.ToUpper() -notin $validChoices) {
            Write-Host "Invalid choice. Please enter 1-9, A, or Q." -ForegroundColor Red
        }
    } while ($choice.ToUpper() -notin $validChoices)
    
    return $choice.ToUpper()
}

# -------- Main Loop --------

do {
    Show-Menu
    $choice = Get-ValidChoice
    
switch ($choice) {
        "1" { Scenario1-DDoS }
        "2" { Scenario2-IronDoor }
        "3" { Scenario3-Auth }
        "4" { Scenario4-Phishing }
        "5" { Scenario5-Exfiltration }
        "6" { Scenario6-Ransomware }
        "7" { Scenario7-Downtime }
        "8" { Scenario8-Botnet }
        "9" { Scenario9-AUP }
        "A" { Run-All }
        "Q" { 
            Write-Host "`nExiting Wazuh Training Lab. Goodbye!" -ForegroundColor Green
            break 
        }
    }
    
    if ($choice -ne "Q") {
        Write-Host "`nPress Enter to return to the menu..."
        Read-Host | Out-Null
    }
} while ($true)