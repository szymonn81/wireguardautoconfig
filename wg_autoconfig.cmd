@echo off
:: WireGuard AutoConfig v4.5
:: Szymon Nowak szymonn841@gmail.com 27.02.2026
::
:: ----- Instructions to start --------
::
:: Change all occurrences in the text "10.68.45." in this file to your own e.g. "10.78.65." We only change the first 3 parts of the IP address, remember to avoid single "0: eg. "10.0.65." in the address, eg. "10.0.65."= bad address , and remember the dot at the end
:: Change all occurrences of "wgserver.domain.pl" in this file to your own hostname where the Wireguard server will run, you can also replace the name with your public IP address (WAN)
:: On the router, forward UDP port 41820 to the Windows machine where you will install the Wireguard server.
:: Install WIreguard (https://www.wireguard.com/install/)
:: Copy this script to this directory
:: Run CMD as Administrator and run command "cd c:\Program Files\WireGuard"
:: Run script wg_autoconfig_4.3.cmd makeconfig
:: From WireGuard_ConfigDATA\Server_config\ copy your wg_server.conf to "c:\Program Files\WireGuard"
:: Run command "c:\Program Files\Wireguard\wireguard.exe" /installtunnelservice "c:\Program Files\Wireguard\wg_server.conf"
:: Run command netstat -ant | find ":41820" If you see UDP 0.0.0.0:41820 *:* it means the server is running
:: Clients configurations are in the directory WireGuard_ConfigDATA\Clients_config you just need to import it on other machines to access the VPN server

echo %1 | find "makeconfig" >nul && goto makeconfig: || echo nothing >nul
echo %1 | find "addclient" >nul && goto addclient: || echo nothing >nul
echo.
echo Run wg_autoconfig.cmd makeconfig (for create new configuration) or wg_autoconfig.cmd addclient (for add new client to to an existing configuration)
echo.
pause
exit

:makeconfig
reg add HKLM\Software\WireGuard /v DangerousScriptExecution /t REG_DWORD /d 1 /f
:: Create a configuration directory
set WG_CONFIG_DIR=WireGuard_ConfigDATA
dir /B | find "WireGuard_ConfigDATA" >nul && set WG_CONFIG_DIR=WireGuard_ConfigDATA_%DATE%_%RANDOM%%RANDOM%%RANDOM%|| echo nothing >nul
mkdir %WG_CONFIG_DIR%
mkdir %WG_CONFIG_DIR%\Clients_config
mkdir %WG_CONFIG_DIR%\Server_config

:: Specifying parameters for the server config file
set SERVER_IP=10.68.45.1/24 
set SERVER_PORT=41820
set SERVER_WAN_ADDRESS=wgserver.domena.pl:41820

:: Running commands on the server requires importing the ScriptExecution.reg registry
set POSTUP_SERVER=PostUp = powershell.exe -command "Get-NetAdapter wg_server | Set-DnsClient -RegisterThisConnectionsAddress $false ; Set-NetIPInterface -InterfaceAlias wg_server -InterfaceMetric 5000 ; Set-NetIPInterface -interfaceAlias wg_server -Forwarding Enabled"

:: Specifying IP addressing for VPN clients
set CLIENT_IP_PREFIX=10.68.45.
set CLIENT_IP_MASK_SERVER_SITE=/32

:: Routing Options
::Access from Cient to WG Server machine only (default)
set CLIENT_ROUTING=10.68.45.1/32

:: Access from Cient to all WG CLients and WG Server machine 
::set CLIENT_ROUTING=10.68.45.0/24

:: Access from Cient to all WG CLients, WG Server machine and local network
::set CLIENT_ROUTING=10.68.45.0/24, 192.168.1.0/24

set CLIENT_PORT=51820
set CLIENT_IP_MASK_CLIENT_SITE=/32

:: Specifying the windows domain server IP (optional)
set DNS_SERVER=192.168.1.241, windowsdomian.local

:: Optional launch action after startup and disconnection of the VPN tunnel on the client side
:: Example using the hostsedit tool which adds static entries to a file C:\windows\system32\drivers\etc\hosts
:: set POSTUP=PostUp = cmd /C "hostsedit /a 192.168.1.15 somecomputer1 & hostsedit /a 192.168.1.30 somecomputer2"
:: set POSTDOWN=PostDown = cmd /C "hostsedit /r somecomputer1 & hostsedit /r somecomputer1"

:: server file generation
wg genkey > %WG_CONFIG_DIR%\server_privatekey
wg pubkey < %WG_CONFIG_DIR%\server_privatekey > %WG_CONFIG_DIR%\server_publickey
set /p server_privatekey=<%WG_CONFIG_DIR%\server_privatekey
set /p server_publickey=<%WG_CONFIG_DIR%\server_publickey
echo [Interface] > %WG_CONFIG_DIR%\Server_config\wg_server.conf
echo Address = %SERVER_IP% >> %WG_CONFIG_DIR%\Server_config\wg_server.conf
echo ListenPort = %SERVER_PORT% >> %WG_CONFIG_DIR%\Server_config\wg_server.conf
echo PrivateKey = %server_privatekey% >> %WG_CONFIG_DIR%\Server_config\wg_server.conf
echo %POSTUP_SERVER%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf

:: client file generation
:: How many client configurations to create - default 20 (countdown from 2 to 21)
for /L %%A in (2,1,21) do (
wg genkey > %WG_CONFIG_DIR%\client_privatekey_%%A
set /p client_privatekey_%%A=<%WG_CONFIG_DIR%\client_privatekey_%%A
wg genpsk > %WG_CONFIG_DIR%\client_PresharedKey_%%A
set /p client_PresharedKey_%%A=<%WG_CONFIG_DIR%\client_PresharedKey_%%A
type %WG_CONFIG_DIR%\client_privatekey_%%A | wg pubkey > %WG_CONFIG_DIR%\client_publickey_%%A
set /p client_publickey_%%A=<%WG_CONFIG_DIR%\client_publickey_%%A
echo [Peer]>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
call echo PublicKey = %%client_publickey_%%A%%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
echo AllowedIPs = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_SERVER_SITE%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
echo [Interface]>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
call echo PrivateKey = %%client_privatekey_%%A%%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
:: echo ListenPort = %CLIENT_PORT%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo Address = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_CLIENT_SITE%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
:: echo DNS = %DNS_SERVER%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
:: echo %POSTUP%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
:: echo %POSTDOWN%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo [Peer]>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo PublicKey = %server_publickey%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo AllowedIPs = %CLIENT_ROUTING%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo Endpoint = %SERVER_WAN_ADDRESS%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf)
)
echo.
echo The New configuration has been created in the directory %WG_CONFIG_DIR%
echo.
echo To install WGServer copy wg_server.conf to c:\Program Files\Wireguard\ and run command :
echo "c:\Program Files\Wireguard\wireguard.exe" /installtunnelservice "c:\Program Files\Wireguard\wg_server.conf"
echo.
echo To uninstall run command:  "c:\Program Files\Wireguard\wireguard.exe" /uninstalltunnelservice wg_server
echo.
echo if you want to access the local network you need to install NAT support (run first command, reboot and second) 
echo Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All 
echo New-NetNat -Name "WireguardNAT" -InternalIPInterfaceAddressPrefix "10.68.45.0/24"
pause
exit

:addclient
:: catalog where is server config exampel WireGuard_ConfigDATA
set WG_CONFIG_DIR=WireGuard_ConfigDATA
dir /B | find "WireGuard_ConfigDATA" >nul && goto makeclient: || goto missingdata:
exit


:: adding new configs over 21 (21-51)
:makeclient
set SERVER_IP=10.68.45.1/24 
set SERVER_PORT=41820
set SERVER_WAN_ADDRESS=wgserver.domena.pl:41820
set CLIENT_IP_PREFIX=10.68.45.
set CLIENT_IP_MASK_SERVER_SITE=/32
set CLIENT_ROUTING=10.68.45.1/32, ::/1, 8000::/1
::set CLIENT_ROUTING=10.68.45.0/24, ::/1, 8000::/1
::set CLIENT_ROUTING=10.68.45.0/24, 192.168.1.0/24, ::/1, 8000::/1
set CLIENT_PORT=51820
set DNS_SERVER=192.168.1.241, windowsdomian.local
set CLIENT_IP_MASK_CLIENT_SITE=/32
set POSTUP=PostUp = cmd /C "hostsedit /a 192.168.1.15 somecomputername1 & hostsedit /a 192.168.1.30 somecomputername1"
set POSTDOWN=PostDown = cmd /C "hostsedit /r somecomputername1 & hostsedit /r somecomputername2"
set /p server_privatekey=<%WG_CONFIG_DIR%\server_privatekey
set /p server_publickey=<%WG_CONFIG_DIR%\server_publickey

:: How many new client configurations add to exist config - default next 10 cleints (countdown from 22 to 51)
for /L %%A in (22,1,51) do (
wg genkey > %WG_CONFIG_DIR%\client_privatekey_%%A
set /p client_privatekey_%%A=<%WG_CONFIG_DIR%\client_privatekey_%%A
wg genpsk > %WG_CONFIG_DIR%\client_PresharedKey_%%A
set /p client_PresharedKey_%%A=<%WG_CONFIG_DIR%\client_PresharedKey_%%A
type %WG_CONFIG_DIR%\client_privatekey_%%A | wg pubkey > %WG_CONFIG_DIR%\client_publickey_%%A
set /p client_publickey_%%A=<%WG_CONFIG_DIR%\client_publickey_%%A
set /p client_publickey_%%A=<%WG_CONFIG_DIR%\client_publickey_%%A
echo [Peer]>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
call echo PublicKey = %%client_publickey_%%A%%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
echo AllowedIPs = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_SERVER_SITE%>>%WG_CONFIG_DIR%\Server_config\wg_server.conf
echo [Interface]>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
call echo PrivateKey = %%client_privatekey_%%A%%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
:: echo ListenPort = %CLIENT_PORT%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo Address = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_CLIENT_SITE%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
::echo DNS = %DNS_SERVER%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
::echo %POSTUP%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
::echo %POSTDOWN%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo [Peer]>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo PublicKey = %server_publickey%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo AllowedIPs = %CLIENT_ROUTING%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf
echo Endpoint = %SERVER_WAN_ADDRESS%>>%WG_CONFIG_DIR%\Clients_config\client%%A.conf)
)
echo.
echo New clients config has been added in the directory %WG_CONFIG_DIR%
echo.
pause
exit

:missingdata
echo.
echo WireGuard_ConfigDATA catalog not exist
echo.
pause
exit

