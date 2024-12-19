@ECHO OFF
cls

set /p computador=Digite o nome ou IP do computador: 

REM Obtém informações sobre a placa-mãe
wmic /node:"%computador%" baseboard get product,Manufacturer,version,serialnumber

pause