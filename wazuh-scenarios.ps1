# wazuh-scenarios.ps1

$LogName = "Application"
$Source  = "Wazuh-Scenario-Lab"

# Ensure the source exists
if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
    New-EventLog -LogName $LogName -Source $Source
}

function Write-WazuhEvent {
    param(
        [int]$Id,
        [string]$Type,
        [string]$Message
    )
    Write-EventLog -LogName $LogName -Source $Source -EventId $Id -EntryType $Type -Message $Message
}

# -------- Scenarios --------

function Scenario1-DDoS {
    for ($i = 1; $i -le 50; $i++) {
        $src = "203.0.113.$i"
        $msg = "DDoS simulation: blocked TCP SYN to 192.0.2.10:80 from $src via firewall UFW."
        Write-WazuhEvent -Id 1001 -Type Warning -Message $msg
        Start-Sleep -Milliseconds 50
    }
}

function Scenario2-IronDoor {
    for ($i = 1; $i -le 3; $i++) {
        $msg = "IronDoor ACCESS_DENIED user_id=EMP332 badge=0xAB12 door=DataCenter-1 reason=INVALID_PIN attempt=$i"
        Write-WazuhEvent -Id 2001 -Type Warning -Message $msg
        Start-Sleep -Milliseconds 300
    }
    $msgOK = "IronDoor ACCESS_GRANTED user_id=EMP999 badge=0xCD34 door=DataCenter-1 reason=VALID_PIN"
    Write-WazuhEvent -Id 2002 -Type Information -Message $msgOK
}

function Scenario4-Phishing {
    $msg1 = "Phishing simulation: mail gateway blocked from=<support@micr0s0ft-secure.com> to=<user1@example.com> reason=phishing_signature_hit"
    Write-WazuhEvent -Id 3001 -Type Warning -Message $msg1

    $msg2 = "Phishing simulation: user1@example.com clicked suspicious URL http://malicious-login.example/phish"
    Write-WazuhEvent -Id 3002 -Type Error -Message $msg2
}

function Scenario5-Exfiltration {
    for ($i = 1; $i -le 10; $i++) {
        $msg = "Data exfiltration simulation: outbound 5MB transfer from 192.0.2.10 to 203.0.113.200:443 (#$i)"
        Write-WazuhEvent -Id 4001 -Type Warning -Message $msg
        Start-Sleep -Milliseconds 100
    }
    $msg2 = "Data exfiltration simulation: scp user=alice file=C:\Secret\plan.txt dest=203.0.113.150:/upload/plan.txt"
    Write-WazuhEvent -Id 4002 -Type Error -Message $msg2
}

function Scenario6-Ransomware {
    for ($i = 1; $i -le 50; $i++) {
        $msg = "Ransomware simulation: file rename C:\Share\docs\file$i.docx -> C:\Share\docs\file$i.docx.encrypted"
        Write-WazuhEvent -Id 5001 -Type Warning -Message $msg
        Start-Sleep -Milliseconds 40
    }
    $note = "Ransomware simulation: ransom note created C:\Share\README_RESTORE_FILES.txt"
    Write-WazuhEvent -Id 5002 -Type Error -Message $note
}

function Scenario7-Downtime {
    $msg1 = "Downtime simulation: nginx service crash on WEB01 status=1/FAILURE"
    $msg2 = "Downtime simulation: nginx service auto-restart on WEB01 restart_counter=3"
    $msg3 = "Downtime simulation: WEB01 recovered, service nginx running"

    Write-WazuhEvent -Id 6001 -Type Error -Message $msg1
    Write-WazuhEvent -Id 6002 -Type Information -Message $msg2
    Write-WazuhEvent -Id 6003 -Type Information -Message $msg3

    $msg4 = "Downtime simulation: HOST_DOWN name=web01.example.com ip=192.0.2.20 duration=300s reason=No heartbeat"
    Write-WazuhEvent -Id 6004 -Type Error -Message $msg4
    Start-Sleep -Seconds 1
    $msg5 = "Downtime simulation: HOST_RECOVERED name=web01.example.com ip=192.0.2.20"
    Write-WazuhEvent -Id 6005 -Type Information -Message $msg5
}

function Scenario8-Botnet {
    for ($i = 1; $i -le 20; $i++) {
        $msg = "Botnet simulation: outbound beacon from 192.0.2.30 to 198.51.100.200:8080 interval=60s (#$i)"
        Write-WazuhEvent -Id 7001 -Type Warning -Message $msg
        Start-Sleep -Milliseconds 60
    }
    $dns1 = "Botnet simulation: DNS query 192.0.2.30 -> abcdefghij.malware-c2.example"
    $dns2 = "Botnet simulation: DNS query 192.0.2.30 -> xyz1234.malware-c2.example"
    Write-WazuhEvent -Id 7002 -Type Information -Message $dns1
    Write-WazuhEvent -Id 7003 -Type Information -Message $dns2
}

function Scenario9-AUP {
    $proxy1 = "AUP simulation: proxy ACCESS_DENIED user=student1 url=http://gambling-example.com category=Gambling"
    $proxy2 = "AUP simulation: proxy ACCESS_DENIED user=student1 url=http://social-media.example/video123 category=StreamingMedia"
    $audit1 = "AUP simulation: unauthorized software install attempt 'winget install tor' by user=student1"

    Write-WazuhEvent -Id 8001 -Type Warning -Message $proxy1
    Write-WazuhEvent -Id 8002 -Type Warning -Message $proxy2
    Write-WazuhEvent -Id 8003 -Type Error   -Message $audit1
}

function Run-All {
    Scenario1-DDoS
    Scenario2-IronDoor
    Scenario4-Phishing
    Scenario5-Exfiltration
    Scenario6-Ransomware
    Scenario7-Downtime
    Scenario8-Botnet
    Scenario9-AUP
}

# -------- Menu UI --------

function Show-Menu {
    Clear-Host
    Write-Host "Please select one of the scenarios below to run:`n" -ForegroundColor Green
    Write-Host "Analyst Fundamentals Training" -ForegroundColor Magenta
    Write-Host " 1: DDoS Attack! Run Time: 30 Minutes"
    Write-Host " 2: IronDoor Unauthorized Physical Access Attempt. Run Time: 3 minutes"
    Write-Host " 4: Phishing E-mail Scenario. Run Time: 5 Minutes`n"
    Write-Host "Security Analysts Training" -ForegroundColor Magenta
    Write-Host " 5: Data Exfiltration"
    Write-Host " 6: Ransomware Attack"
    Write-Host " 7: Reducing Downtime"
    Write-Host " 8: BotNet Detection"
    Write-Host " 9: Comply with Acceptable Use Policy`n"
    Write-Host " A: Run ALL scenarios"
    Write-Host " Q: Quit`n"
}

do {
    Show-Menu
    $choice = Read-Host "Which scenario would you like to run?"
    switch ($choice.ToUpper()) {
        "1" { Scenario1-DDoS }
        "2" { Scenario2-IronDoor }
        "4" { Scenario4-Phishing }
        "5" { Scenario5-Exfiltration }
        "6" { Scenario6-Ransomware }
        "7" { Scenario7-Downtime }
        "8" { Scenario8-Botnet }
        "9" { Scenario9-AUP }
        "A" { Run-All }
        "Q" { Write-Host "Exiting."; break }
        Default { Write-Host "Invalid choice. Press Enter to continue..."; Read-Host | Out-Null }
    }
    if ($choice.ToUpper() -ne "Q") {
        Write-Host "`nScenario complete. Press Enter to return to the menu..."
        Read-Host | Out-Null
    }
} while ($true)

