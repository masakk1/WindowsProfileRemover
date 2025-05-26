#############
# License   #
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

# Localization
if (Test-Path -Path "$PSScriptRoot\localization\$($PSCulture).psd1") {
    $msgTable = Import-PowerShellDataFile "$PSScriptRoot\localization\$($PSCulture).psd1"
} else {
    $msgTable = Import-PowerShellDataFile "$PSScriptRoot\localization\en-US.psd1"
}

# Customise
$Whitelist = @("GPT_Auditoria", "AdminGPT", "AdminHGA", "Administrador", "Administrator") # WHITELIST
$UsersFolder = "C:\Users\"

# Users
$LocalUsers = Get-WmiObject Win32_UserAccount -Filter "LocalAccount='True'"
$AllUsers = Get-CimInstance -ClassName Win32_UserProfile


#############
# Functions #
#############

function PrintUserExclusion() {
    param (
        [parameter(Mandatory = $true)]$User,
        [string]$Reason
    )
    Write-host $User.SID $User.LocalPath "-" $Reason
}

function SurveyUsers() {
    # We'll be showing information in this function, state that:
    Write-Host "`n`n--------- $($msgTable.infoMsg6) ---------`n"

    $UsersToRemove = @()
    foreach ($User in $AllUsers) {
        # Check if it's in `C:\`
	    If ($User.LocalPath -notlike "$UsersFolder*") {
            PrintUserExclusion -User $User -Reason "$($msgTable.reasonNotInUserFolder) $UsersFolder"; Continue
        }

        # Check if it's local
        If ($User.SID -in $LocalUsers.SID ) {PrintUserExclusion -User $User -Reason $msgTable.reasonUserIsLocal; Continue}
    
        # Check the whitelist
        $UserIsWhitelisted = $False
        ForEach ( $Username in $Whitelist ) {
            If ( $User.LocalPath -like "$UsersFolder$Username" ) {
                $UserIsWhitelisted = $True
                break
            }
        }

        If ($UserIsWhitelisted) {PrintUserExclusion -User $User -Reason $msgTable.reasonUserInWhitelist; Continue}

        # Check if loaded
        If ($User.Loaded) {PrintUserExclusion -User $User -Reason $msgTable.reasonUserisLoaded; Continue}

        # Special - Anonymous login - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        If ( $User.SID -eq "S-1-5-7" ) {PrintUserExclusion -User $User -Reason $msgTable.reasonUserIsSpecial; Continue}
        
        $UsersToRemove += $User
    }

    return $UsersToRemove
}

function DisplayUsersToRemove() {
    param (
        [parameter()]$UsersToRemove
    )
    Write-Host "`n`n--------- $($msgTable.infoMsg5) ---------"
    if ( $UsersToRemove -eq $null ) {
        Write-Host "`n$($msgTable.errExitMsg1)`n"

    } else {
        Split-Path -Path $UsersToRemove.Localpath -Leaf | Format-Wide -Property {$_} -Column 3 -Force

    }
}

function RemoveAndReportUsers() {
    param (
        [parameter(Mandatory=$true)]$UsersToRemove
    )

    Write-Host "`n`n--------- $($msgTable.infoMsg4) ---------"
    #TODO: figure out how to report the storage taken by each user.
    Write-Host $msgTable.infoMsg1 $UsersToRemove.Count

    # Gather information and remove user CimInstance
    $i = 1
    $CustomReportList = @()

    foreach ($User in $UsersToRemove) {
        $Username = Split-Path -Path $User.Localpath -Leaf
        Write-Progress -Activity $msgTable.removingProfilesActivity -Status "$($msgTable.infoMsg2) $Username..." -PercentComplete $($i/($UsersToRemove.Count + 1) * 100)

        $User_TimeStarted = Get-Date
        Remove-CimInstance $User
        $User_TimeTaken = (Get-Date) - ($User_TimeStarted)

        $CustomReport = [PSCustomObject]@{
            SID           = $User.SID
            LocalPath     = $User.LocalPath
            num           = "$i/$($UsersToRemove.Count)"
            sec           = $User_TimeTaken.TotalSeconds
        }

        $i++

        $CustomReportList += $CustomReport
    }

    Write-Progress -Activity $msgTable.removingProfilesActivity -Completed -Status $msgTable.infoMsg3

    # Report 
    $CustomReportList | Format-Table -AutoSize

}


#############
# Main      #
#############

function Main(){
    $UsersToRemove = SurveyUsers{}

    DisplayUsersToRemove -UsersToRemove $UsersToRemove

    if ( $UsersToRemove -eq $null ) {
        Write-Host "`n$($msgTable.errMsg2)"
        return
    }

    # Confirm
    $answer = Read-Host $msgTable.questionMsg1

    # Accept all of s/S/y/Y
    if ($answer -eq "s" -or $answer -eq "S" -or $answer -eq "y" -or $answer -eq "Y") {
        RemoveAndReportUsers -UsersToRemove $UsersToRemove
    } else {
        Write-Host $msgTable.errExitMsg3
    }
}

Main{}

PAUSE
