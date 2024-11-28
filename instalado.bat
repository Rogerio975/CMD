@echo off
REM Script para instalação remota de programas em ambiente de Active Directory
REM Senha será digitada sem exibição

REM Solicitar informações do usuário
set /p computador=Digite o nome ou IP do computador: 
set /p usuario=Digite o nome de usuário do AD (formato DOMINIO\usuario): 

REM Solicitar senha ocultamente usando PowerShell
for /f "delims=" %%P in ('powershell -Command "Read-Host -AsSecureString | ConvertFrom-SecureString"') do set senha_encriptada=%%P

REM Diretório compartilhado onde os instaladores estão localizados
set install_dir=\\servidor\compartilhamento\instaladores

REM Lista de programas e argumentos de instalação silenciosa
set programas=(
    "Chrome_installer.exe /silent /install"
    "NotepadPlusPlus_installer.exe /S"
    "JavaRuntime_installer.exe /s"
)

REM Arquivo de log para registrar os resultados
set log_file=%~dp0instalacao_log.txt

REM Testar a conectividade com o computador remoto
echo Testando conectividade com %computador%...
ping -n 1 %computador% >nul
if %errorlevel% neq 0 (
    echo Erro: Não foi possível alcançar o computador %computador%. Verifique a conectividade. >> %log_file%
    echo Verifique se o computador está ligado e acessível pela rede.
    pause
    exit /b
)

REM Mapeamento do compartilhamento de rede no computador remoto
echo Mapeando compartilhamento de rede...
for /f "delims=" %%P in ('powershell -Command "[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString -String %senha_encriptada% -AsPlainText -Force)))"') do set senha=%%P
net use \\%computador%\C$ %senha% /user:%usuario% /persistent:no
if %errorlevel% neq 0 (
    echo Erro ao mapear o compartilhamento de rede no computador remoto! >> %log_file%
    echo Verifique as credenciais e permissões. >> %log_file%
    pause
    exit /b
)

REM Copiar instaladores para o computador remoto
echo Copiando instaladores para o computador remoto...
for %%P in %programas% do (
    copy "%install_dir%\%%~P" \\%computador%\C$\Temp\ >nul
    if %errorlevel% neq 0 (
        echo Erro ao copiar %%~P para o computador remoto! >> %log_file%
        exit /b
    )
)

REM Instalar os programas no computador remoto
echo Instalando programas remotamente...
for %%P in %programas% do (
    psexec \\%computador% -u %usuario% -p %senha% "C:\Temp\%%~P"
    if %errorlevel% neq 0 (
        echo Erro ao instalar %%~P no computador remoto! >> %log_file%
    ) else (
        echo %%~P instalado com sucesso em %computador%. >> %log_file%
    )
)

REM Limpar arquivos temporários no computador remoto
echo Limpando arquivos temporários...
psexec \\%computador% -u %usuario% -p %senha% "cmd /c del /q C:\Temp\*"

REM Remover o mapeamento de rede
net use \\%computador%\C$ /delete /y

echo.
echo ===============================
echo Instalação concluída
echo Logs disponíveis em %log_file%
echo ===============================
pause
exit