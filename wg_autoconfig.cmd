@echo off
:: WireGuard AutoConfig v1.3
:: Szymon Nowak MicroCreative 2022 

echo %1 | find "makeconfig" >nul && goto makeconfig: || echo nothing >nul
echo %1 | find "addclient" >nul && goto addclient: || echo nothing >nul
echo.
echo Run wg_autoconfig.cmd makeconfig (for create new configuration) or wg_autoconfig.cmd addclient (for add new client to to an existing configuration)
echo.
pause
exit

:makeconfig
set WG_CONFIG_DIR=WireGuard_ConfigDATA
dir /B | find "WireGuard_ConfigDATA" >nul && set WG_CONFIG_DIR=WireGuard_ConfigDATA_%DATE%_%RANDOM%%RANDOM%%RANDOM%|| echo nothing >nul
mkdir %WG_CONFIG_DIR%
set SERVER_IP=10.55.35.1/24 
set SERVER_PORT=41820
set SERVER_WAN_ADDRESS=vpn.examplehost.com:41820
set CLIENT_IP_PREFIX=10.55.35.
set CLIENT_IP_MASK_SERVER_SITE=/32
set CLIENT_ROUTING=10.55.35.0/24, ::/1, 8000::/1
set CLIENT_PORT=51820
set CLIENT_IP_MASK_CLIENT_SITE=/24
wg genkey > %WG_CONFIG_DIR%\server_privatekey
wg pubkey < %WG_CONFIG_DIR%\server_privatekey > %WG_CONFIG_DIR%\server_publickey
set /p server_privatekey=<%WG_CONFIG_DIR%\server_privatekey
set /p server_publickey=<%WG_CONFIG_DIR%\server_publickey
echo [Interface] > %WG_CONFIG_DIR%\wg_server.conf
echo Address = %SERVER_IP% >> %WG_CONFIG_DIR%\wg_server.conf
echo ListenPort = %SERVER_PORT% >> %WG_CONFIG_DIR%\wg_server.conf
echo PrivateKey = %server_privatekey% >> %WG_CONFIG_DIR%\wg_server.conf

:: How many client configurations to create - default 4 (countdown from 2 to 5)
for /L %%A in (2,1,5) do (
wg genkey > %WG_CONFIG_DIR%\client_privatekey_%%A
set /p client_privatekey_%%A=<%WG_CONFIG_DIR%\client_privatekey_%%A
wg genpsk > %WG_CONFIG_DIR%\client_PresharedKey_%%A
set /p client_PresharedKey_%%A=<%WG_CONFIG_DIR%\client_PresharedKey_%%A
type %WG_CONFIG_DIR%\client_privatekey_%%A | wg pubkey > %WG_CONFIG_DIR%\client_publickey_%%A
set /p client_publickey_%%A=<%WG_CONFIG_DIR%\client_publickey_%%A
echo [Peer]>>%WG_CONFIG_DIR%\wg_server.conf
call echo PublicKey = %%client_publickey_%%A%%>>%WG_CONFIG_DIR%\wg_server.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\wg_server.conf
echo AllowedIPs = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_SERVER_SITE%>>%WG_CONFIG_DIR%\wg_server.conf
echo [Interface]>>%WG_CONFIG_DIR%\client%%A.conf
call echo PrivateKey = %%client_privatekey_%%A%%>>%WG_CONFIG_DIR%\client%%A.conf
echo ListenPort = %CLIENT_PORT%>>%WG_CONFIG_DIR%\client%%A.conf
echo Address = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_CLIENT_SITE%>>%WG_CONFIG_DIR%\client%%A.conf
echo [Peer]>>%WG_CONFIG_DIR%\client%%A.conf
echo PublicKey = %server_publickey%>>%WG_CONFIG_DIR%\client%%A.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\client%%A.conf
echo AllowedIPs = %CLIENT_ROUTING%>>%WG_CONFIG_DIR%\client%%A.conf
echo Endpoint = %SERVER_WAN_ADDRESS%>>%WG_CONFIG_DIR%\client%%A.conf)
)
echo The New configuration has been created in the directory %WG_CONFIG_DIR%
echo wireguard /installtunnelservice "c:\Program Files\Wireguard\myconfname.conf
echo wireguard /uninstalltunnelservice myconfname
pause
exit

:addclient
:: catalog where is server config exampel WireGuard_ConfigDATA
set WG_CONFIG_DIR=WireGuard_ConfigDATA
dir /B | find "WireGuard_ConfigDATA" >nul && goto makeclient: || goto missingdata:
exit

:makeclient
set SERVER_IP=10.55.35.1/24 
set SERVER_PORT=41820
set SERVER_WAN_ADDRESS=95.182.27.204:41820
set CLIENT_IP_PREFIX=10.55.35.
set CLIENT_IP_MASK_SERVER_SITE=/32
set CLIENT_ROUTING=10.55.35.0/24, ::/1, 8000::/1
set CLIENT_PORT=51820
set CLIENT_IP_MASK_CLIENT_SITE=/24
set /p server_privatekey=<%WG_CONFIG_DIR%\server_privatekey
set /p server_publickey=<%WG_CONFIG_DIR%\server_publickey

:: How many new client configurations to create - default 4 (countdown from 6 to 10)
for /L %%A in (6,1,10) do (
wg genkey > %WG_CONFIG_DIR%\client_privatekey_%%A
set /p client_privatekey_%%A=<%WG_CONFIG_DIR%\client_privatekey_%%A
wg genpsk > %WG_CONFIG_DIR%\client_PresharedKey_%%A
set /p client_PresharedKey_%%A=<%WG_CONFIG_DIR%\client_PresharedKey_%%A
type %WG_CONFIG_DIR%\client_privatekey_%%A | wg pubkey > %WG_CONFIG_DIR%\client_publickey_%%A
set /p client_publickey_%%A=<%WG_CONFIG_DIR%\client_publickey_%%A
echo [Peer]>>%WG_CONFIG_DIR%\wg_server.conf
call echo PublicKey = %%client_publickey_%%A%%>>%WG_CONFIG_DIR%\wg_server.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\wg_server.conf
echo AllowedIPs = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_SERVER_SITE%>>%WG_CONFIG_DIR%\wg_server.conf
echo [Interface]>>%WG_CONFIG_DIR%\client%%A.conf
call echo PrivateKey = %%client_privatekey_%%A%%>>%WG_CONFIG_DIR%\client%%A.conf
echo ListenPort = %CLIENT_PORT%>>%WG_CONFIG_DIR%\client%%A.conf
echo Address = %CLIENT_IP_PREFIX%%%A%CLIENT_IP_MASK_CLIENT_SITE%>>%WG_CONFIG_DIR%\client%%A.conf
echo [Peer]>>%WG_CONFIG_DIR%\client%%A.conf
echo PublicKey = %server_publickey%>>%WG_CONFIG_DIR%\client%%A.conf
call echo PresharedKey = %%client_PresharedKey_%%A%%>>%WG_CONFIG_DIR%\client%%A.conf
echo AllowedIPs = %CLIENT_ROUTING%>>%WG_CONFIG_DIR%\client%%A.conf
echo Endpoint = %SERVER_WAN_ADDRESS%>>%WG_CONFIG_DIR%\client%%A.conf)
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
