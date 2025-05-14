#############
# Licencia  #
#############

# WindowsProfileRemover.ps1
#
# GPL 3.0
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# 2025 © masakk1

#############
# Variables #
#############

# Customizables
$Whitelist = @("GPT_Auditoria", "AdminGPT", "AdminHGA") # WHITELIST - solo para usuarios de dominio
$UsersFolder = "C:\Users\"

# Usuarios
$LocalUsers = Get-WmiObject Win32_UserAccount -Filter "LocalAccount='True'"
$AllUsers = Get-CimInstance -ClassName Win32_UserProfile


#############
# Funciones #
#############

function PrintUserExclusion() {
    param (
        [parameter(Mandatory = $true)]$User,
        [string]$Reason
    )
    Write-host $User.SID $User.LocalPath $Reason
}

function SurveyUsers() {
    # Vamos a mostrar usuarios en el foreach
    Write-Host "`n`n--------- Usuarios a quedar ---------`n"

    $UsersToRemove = @()
    foreach ($User in $AllUsers) {
        # En C:\Users\
	    If ($User.LocalPath -notlike "$UsersFolder*") {
            PrintUserExclusion -User $User -Reason "usuario fuera de $UsersFolder"; Continue
        }

        # No es local
        If ($User.SID -in $LocalUsers.SID ) {PrintUserExclusion -User $User -Reason "usuario es local"; Continue}
    
        # No está en la Whitelist
        $UserIsWhitelisted = $False
        ForEach ( $Username in $Whitelist ) {
            If ( $User.LocalPath -like "$UsersFolder$Username" ) {
                $UserIsWhitelisted = $True
                break
            }
        }

        If ($UserIsWhitelisted) {PrintUserExclusion -User $User -Reason "usuario en whitelist"; Continue}

        # No está cargado/en uso
        If ($User.Loaded) {PrintUserExclusion -User $User -Reason "usuario está cargado/en uso"; Continue}

        # Especial
        If ( $User.SID -eq "S-1-5-7" ) {PrintUserExclusion -User $User -Reason "usuario es anónimo"; Continue} # Anonymous login > https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        
        # Agregar usuario
        $UsersToRemove += $User
    }

    return $UsersToRemove
}

function DisplayUsersToRemove() {
    param (
        [parameter()]$UsersToRemove
    )
    Write-Host "`n`n--------- Usuarios a eliminar ---------"
    if ( $UsersToRemove -eq $null ) {
        Write-Host "`nNo hay usuarios a eliminar"

    } else {
        Split-Path -Path $UsersToRemove.Localpath -Leaf | Format-Wide -Property {$_} -Column 3 -Force

    }
}

function EliminarYReportarUsuarios() {
    param (
        [parameter(Mandatory=$true)]$UsersToRemove
    )

    # Mostrar información
    Write-Host "`n`n--------- Eliminando usuarios ---------"
    #TODO: Buscar alguna manera de reportar el tamaño de cada usuario
    Write-Host "Usuarios:" $UsersToRemove.Count

    # Recopilar información y borrar perfiles
    $i = 1
    $CustomReportList = @()
    foreach ($User in $UsersToRemove) {
        $Username = Split-Path -Path $User.Localpath -Leaf
        Write-Progress -Activity "Eliminando Perfiles" -Status "Eliminando $Username..." -PercentComplete $($i/($UsersToRemove.Count + 1) * 100)

        $User_TimeStarted = Get-Date
        Remove-CimInstance $User
        $User_TimeTaken = (Get-Date) - ($User_TimeStarted)

        $CustomReport = [PSCustomObject]@{
            SID           = $User.SID
            LocalPath     = $User.LocalPath
            num           = "$i/$($UsersToRemove.Count)"
            segundos      = $User_TimeTaken.TotalSeconds
        }

        $i++

        $CustomReportList += $CustomReport
    }

    Write-Progress -Activity "Eliminando Perfiles" -Status "Terminado de borrar perfiles" -Completed

    # Mostrat información 
    $CustomReportList | Format-Table -AutoSize

}


#############
# Principal #
#############

function Main(){
    $UsersToRemove = SurveyUsers{}

    DisplayUsersToRemove -UsersToRemove $UsersToRemove

    if ( $UsersToRemove -eq $null ) {
        Write-Host "`nNo hacemos nada."
        return
    }

    # Confirmar
    $answer = Read-Host 'Deseas ELIMINAR PERMANENTEMENTE estos Perfiles de Active Directory? (s/N)'

    # Aceptar s/S/y/Y
    if ($answer -eq "s" -or $answer -eq "S" -or $answer -eq "y" -or $answer -eq "Y") {
        EliminarYReportarUsuarios -UsersToRemove $UsersToRemove
    } else {
        Write-Host "No hacemos nada."
    }
}

Main{}

Write-Host 'Terminado. Presiona cualquier tecla para cerrar...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
