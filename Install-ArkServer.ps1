#Requires -RunAsAdministrator

# Steam Variables
$SteamCmdUri = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
$SteamCmdDir = "C:\SteamCMD"
$SteamCmdExe = $SteamCmdDir + "\" + "steamcmd.exe"
$SteamCmdZip = $SteamCmdDir + "\" + "steamcmd.zip"

# Ark Install Variables
$ArkServerDir = "C:\ArkServer"
$ArkAppID     = "2430930"

# Server Run Variables
$ArkBatDir     = "$ArkServerDir\ShooterGame\Binaries\Win64\"
$ArkBatScript  = $ArkBatDir + "startserver.bat"
$ArkServerPort = "7777"
$ArkPeerPort   = "7778"
$ArkQueryPort  = "27015"
$ArkRconPort   = "27020"
$ArkPortArray  = @($ArkServerPort, $ArkPeerPort, $ArkQueryPort, $ArkRconPort)
$ArkNetOptions = @("Configure Local Ark Server", "Configure Network Ark Server")

# Prompt user to pick a local or networked server
Write-Host "Please select from the following network configuration:"
$i = 1
foreach ($NetOption in $ArkNetOptions) {
    Write-Host "$i. $NetOption" -ForegroundColor Yellow
    $i++
}
do {
    $NetOptCount = $($ArkNetOptions).Length
    $ArkNetInput = Read-Host "Enter the number of your choice"

    # Check if the input can be converted to an integer and within range
    if ($ArkNetInput -match '^\d+$') {
        if ([int]$ArkNetInput -ge 1 -and [int]$ArkNetInput -le [int]$NetOptCount) {
            $isValid = $true
        } else {
            Write-Host "INVALID INPUT: Please enter a valid selection." -ForegroundColor Red
            $isValid = $false
        }
    } else {
        Write-Host "INVALID INPUT: Please enter a valid selection." -ForegroundColor Red
        $isValid = $false
    }
} while (-not $isValid)

# Ark Server Name and Passwords
$ArkServerName      = Read-Host "Enter your Ark Server Session Name (join display name)"
$ArkSessionPassword = Read-Host "Enter your Ark Server Session Password (required to join)"
$ArkAdminPassword   = Read-Host "Enter your Ark Server Admin Password (required to administer)"

## Pick a Server Map and Validate
$Maps = [ordered]@{
    "The Island"     = "TheIsland_WP"
    "The Center"     = "TheCenter_WP"
    "Scorched Earth" = "ScorchedEarth_WP"
    "Ragnarok"       = "Ragnarok_WP"
    "Aberration"     = "Aberration_WP"
    "Extinction"     = "Extinction_WP"
}

# Prompt user to select a map
Write-Host "Please select a map from the following options:"
$i = 1
foreach ($Key in $Maps.Keys) {
    Write-Host "$i. $Key" -ForegroundColor Yellow
    $i++
}
do {
    $MapsCount = $($Maps.Keys).Length
    $MapInput = Read-Host "Enter the number of your choice"

    # Check if the input can be converted to an integer and within range
    if ($MapInput -match '^\d+$') {
        if ([int]$MapInput -ge 1 -and [int]$MapInput -le [int]$MapsCount) {
            $isValid = $true
        } else {
            Write-Host "INVALID INPUT: Please enter a valid selection." -ForegroundColor Red
            $isValid = $false
        }
    } else {
        Write-Host "INVALID INPUT: Please enter a valid selection." -ForegroundColor Red
        $isValid = $false
    }
} while (-not $isValid)

$SelectedKey = $Maps.Keys | Select-Object -Index ($MapInput -1)
$ArkMap      = $Maps[$SelectedKey]

## Pick Number of Max Players and Validate
do {
    $MaxPlayerInput = Read-Host "Enter the number of Max Players allowed on your Ark Server"

    # Check if the input can be converted to an integer
    if ($MaxPlayerInput -match '^\d+$') {
        # Convert the input to an integer
        $ArkMaxPlayers = [int]$MaxPlayerInput
        $isValid = $true
    } else {
        Write-Host "INVALID INPUT: Please enter NUMBERS only." -ForegroundColor Red
        $isValid = $false
    }
} while (-not $isValid)

# $ArkBatScript Variables
$StartupScript = $null
$StartupScript = @"
@echo off
echo -----------------------
echo   Updating Ark Server
echo -----------------------
start /WAIT $($SteamCmdExe) +force_install_dir $($ArkServerDir) +login anonymous +app_update $($ArkAppID) validate +quit
echo:
echo -----------------------
echo     Update Complete    
echo -----------------------
echo:
echo -----------------------
echo   Starting Ark Server
echo -----------------------
start $($ArkServerDir)\ShooterGame\Binaries\Win64\ArkAscendedServer.exe $($ArkMap)?listen?SessionName="$($ArkServerName)"?ServerPassword="$($ArkSessionPassword)"?ServerAdminPassword="$($ArkAdminPassword)"?Port=$($ArkServerPort)?QueryPort=$($ArkQueryPort)?PeerPort=$($ArkPeerPort)?ReconPort=$($ArkRconPort)?MaxPlayers=$($ArkMaxPlayers) -NoBattlEye -log -server
"@

# Create the directory if it doesn't exist
if (-not (Test-Path $SteamCmdDir)) {
    New-Item -Path $SteamCmdDir -ItemType Directory | Out-Null
    Write-Host "DONE: SteamCMD directory ($($SteamCmdDir)) created." -ForegroundColor Green
} else {
    Write-Host "INFO: SteamCMD directory ($($SteamCmdDir)) already exists." -ForegroundColor Yellow
}

# Check if SteamCMD is already installed
if (Test-Path $SteamCmdExe) {
    Write-Host "INFO: SteamCMD is already exists at $SteamCmdExe." -ForegroundColor Yellow
} else {
    # If it doesn't exist, download and extract SteamCMD
    Write-Host "Downloading and unpacking SteamCMD..."
    try {
        Invoke-WebRequest -Uri $SteamCmdUri -OutFile $SteamCmdZip
        Expand-Archive -Path $SteamCmdZip -DestinationPath $SteamCmdDir -Force
        Write-Host "Cleaning up downloaded files..."
        Remove-Item -Path $SteamCmdZip
        Write-Host "DONE: SteamCMD extracted to $SteamCmdExe." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Encountered problem downloading and installing SteamCMD." -ForegroundColor Red
        Break
    }
}

# Check if the Ark Server path already exists
if (Test-Path $ArkServerDir) {
    Write-Host "INFO: Ark Server directory already exists at $($ArkServerDir)." -ForegroundColor Yellow
} else {
    # If it doesn't exist, create the directory and install the Ark server
    New-Item -Path $ArkServerDir -ItemType Directory | Out-Null
    Write-Host "DONE: Ark Server directory ($($ArkServerDir)) created." -ForegroundColor Green
}

# Install or update Ark server
Write-Host "Installing or updating Ark Server..."
try {
    & $SteamCmdExe "+force_install_dir $($ArkServerDir)" "+login anonymous" "+app_update $($ArkAppID) validate" "+quit"
} catch {
    Write-Host "ERROR: Unable to launch $SteamCmdExe." -ForegroundColor Red
    Break
}

# Create Ark Server Startup Script
if (-not (Test-Path $ArkBatDir)) {
    Write-Host "ERROR: Ark Server did not install correctly from SteamCMD. Check logs or try again." -ForegroundColor Red
    Break
}

# Function to create $ArkBatScript based on $StartupScript heredoc generated above
function Create-ArkBatScript {
    try {
        $StartupScript | Set-Content -Path $ArkBatScript -Force -Encoding Ascii
        Write-Host "DONE: Ark Server start up script created at $ArkBatScript." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Unable to create Ark Server startup script at $ArkBatScript." -ForegroundColor Red
        Break
    }
}

# Check if $ArkBatScript already exists
if (Test-Path $ArkBatScript) {
    # Determine what to do if script already exists
    do {
        # Prompt user for decision
        Write-Host "INFO: $ArkBatScript already exists." -ForegroundColor Yellow
        $BatInput = Read-Host "Would you like to replace? (Y/N)"

        # Check if the input is Y/N
        if ($BatInput -match "y|n") {
            # Replace existing $ArkBatScript
            if ($BatInput -eq 'Y' -or $BatInput -eq 'y') {
                Write-Host "Replacing $ArkBatScript..."
                $isValid = $true
                Create-ArkBatScript
            # Leave existing $ArkBatScript
            } else {
                Write-Host "Skipping $ArkBatScript creation..."
                $isValid = $true
            }
        # User input invalid response
        } else {
            Write-Host "INVALID INPUT: Please enter Y or N." -ForegroundColor Red
            $isValid = $false
        }
    # Close while loop
    } while (-not $isValid)
# Script does not exist, so create one
} else {
    Create-ArkBatScript
}

# Function to open all Inbound and Outbound Ark Server Ports in Windows Firewall
function Set-ArkServerPorts {
    $ArkPortArrayTxt = $ArkPortArray -join ", "
    # Set inbound TCP ports using $ArkPortArray
    try {
        New-NetFirewallRule `
            -DisplayName "Ark Server - Inbound TCP" `
            -Description "Open Inbound TCP Ports ($($ArkPortArrayTxt)) for Ark: Survival Ascended Server." `
            -Direction Inbound `
            -LocalPort $ArkPortArray `
            -Protocol TCP `
            -Action Allow

        Write-Host "INFO: Opened Inbound TCP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Unable to open Inbound TCP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Red
    }
    # Set inbound UDP ports using $ArkPortArray
    try {
        New-NetFirewallRule `
            -DisplayName "Ark Server - Inbound UDP" `
            -Description "Open Inbound UDP Ports ($($ArkPortArray)) for Ark: Survival Ascended Server." `
            -Direction Inbound `
            -LocalPort $ArkPortArray `
            -Protocol UDP `
            -Action Allow

        Write-Host "INFO: Opened Inbound UDP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Unable to open Inbound UDP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Red
    }
    # Set outbound TCP ports using $ArkPortArray
    try {
        New-NetFirewallRule `
            -DisplayName "Ark Server - Outbound TCP" `
            -Description "Open Outbound TCP Ports ($($ArkPortArrayTxt)) for Ark: Survival Ascended Server." `
            -Direction Outbound `
            -LocalPort $ArkPortArray `
            -Protocol TCP `
            -Action Allow

        Write-Host "INFO: Opened Outbound TCP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Unable to open Outbound TCP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Red
    }
    # Set outbound UDP ports using $ArkPortArray
    try {
        New-NetFirewallRule `
            -DisplayName "Ark Server - Outbound UDP" `
            -Description "Open Outbound UDP Ports ($($ArkPortArrayTxt)) for Ark: Survival Ascended Server." `
            -Direction Outbound `
            -LocalPort $ArkPortArray `
            -Protocol UDP `
            -Action Allow
        
        Write-Host "INFO: Opened Outbound UDP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Unable to open Outbound UDP Ports ($($ArkPortArrayTxt)) for Ark Server." -ForegroundColor Red
    }
}

# If user selected "networked server", open firewall ports
if ($ArkNetInput -gt 1 ) {
    # If firewall ports already exist for Ark Server
    if (Get-NetFirewallRule -DisplayName "Ark Server*" -ErrorAction SilentlyContinue) {
        # Determine what to do if network ports already exists
        do {
            # Prompt user for decision
            Write-Host "INFO: Ark Server Port configuration already exists in Windows Firewall." -ForegroundColor Yellow
            $NetOverride = Read-Host "Would you like to replace? (Y/N)"

            # Check if the input is Y/N
            if ($NetOverride -match "y|n") {
                # Replace existing Port configuration
                if ($NetOverride -eq 'Y' -or $NetOverride -eq 'y') {
                    Write-Host "Replacing Windows Firewall configuration..."
                    $isValid = $true
                    Remove-NetFirewallRule -DisplayName "Ark Server*"
                    Set-ArkServerPorts
                # Leave existing Port configuration
                } else {
                    Write-Host "INFO: Skipping Windows Firewall configuration..." -ForegroundColor Yellow
                    $isValid = $true
                }
            # User input invalid response
            } else {
                Write-Host "INVALID INPUT: Please enter Y or N." -ForegroundColor Red
                $isValid = $false
            }
        # Close while loop
        } while (-not $isValid)
    # Setup new firewall ports
    } else {
        Set-ArkServerPorts
    }
# Do not configure firewall ports
} else {
    Write-Host "INFO: Ark Server is configured for local access only." -ForegroundColor Yellow
}

# ASCII Art - Installation Complete
$SplashScreen = @"

░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀█░▀█▀░▀█▀░█▀█░█▀█░░░█▀▀░█▀█░█▄█░█▀█░█░░░█▀▀░▀█▀░█▀▀
░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀█░░█░░░█░░█░█░█░█░░░█░░░█░█░█░█░█▀▀░█░░░█▀▀░░█░░█▀▀
░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀░░▀░░▀▀▀                                     
                                 
                                 
                                       ▓▒▒▒▒▒              
                                       ▓▒▒▒▒▒▒             
                                      ▓▒▒▒▒▒▒░░            
                                     ▒▒▒▒▓▓▒░░░░           
                                    ▓▓▓▓▓█ ▓▒░░░░          
                                   ▓▓▓▓▓█   ▓▒▒▒░▒         
                                  ▒▒▒▒▓█   ▓▒█▒▒▒░░        
                                ▓▒▒▒▒▒▒▒▒▒▒▒▒▒█▓▒▒▒▒▒      
                               ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓ █▒▒░▒▒▒     
                             ▓▓▓▒▒▒▓█████▓▓▓▓▓  █▓▒▒▒▒▒    
                           ▓▓▓▓▓▓▒▒█             █▓▒▒▒░░░  
                           ▓▓▒▒▒▓▓▓               █▒▒░░░░▒ 
                           ▓▓▓▓▓▓▓▓█             ▓▓▒▒▒▒▒▒▒▒
       
                                                                                                  
                                    ░█▀█░█▀▄░█░█
                                    ░█▀█░█▀▄░█▀▄
                                    ░▀░▀░▀░▀░▀░▀     
                                                                                                                            
        ░█▀▀░█░█░█▀▄░█░█░▀█▀░█░█░█▀█░█░░░░░█▀█░█▀▀░█▀▀░█▀▀░█▀█░█▀▄░█▀▀░█▀▄
        ░▀▀█░█░█░█▀▄░▀▄▀░░█░░▀▄▀░█▀█░█░░░░░█▀█░▀▀█░█░░░█▀▀░█░█░█░█░█▀▀░█░█
        ░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░░▀░░▀░▀░▀▀▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀▀░
"@                                

# Server information and user instructions
$FinishMessage = @"

Your Ark Server installation completed successfully.

Use the following information to manage and access your server:
        SteamCMD Install Directory   = $($SteamCmdDir)
        SteamCMD Executable          = $($SteamCmdExe)
        SteamCMD Ark App ID          = $($ArkAppID)
        Ark Server Install Directory = $($ArkServerDir)
        Ark Server Session Name      = $($ArkServerName)
        Ark Server Session Password  = $($ArkSessionPassword)
        Ark Server Map               = $($SelectedKey)
        Ark Server Max Players       = $($ArkMaxPlayers)
        Ark Server Admin Password    = $($ArkAdminPassword)
        Ark Server Server Port       = $($ArkServerPort)
        Ark Server Peer Port         = $($ArkPeerPort)
        Ark Server Query Port        = $($ArkQueryPort)
        Ark Server RCON Port         = $($ArkRconPort)
        Ark Server Start Script      = $($ArkBatScript)

To launch your Ark Server use the following command:
        $ArkBatScript

"@

# Write output of installation
Write-Host "$SplashScreen" -ForegroundColor Gray
sleep 4
Write-Host "$FinishMessage" -ForegroundColor Green