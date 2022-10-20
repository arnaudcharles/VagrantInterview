#Variables
$ExecutionPolicyChanges = $false
function Get-CheckandSet() {
    $ActualExPo = Get-ExecutionPolicy
    if ($ActualExPo -eq 'RemoteSigned') { $CheckMark = "Ok" } else { $CheckMark = "" }
    Write-Host "Checking first your PowerShell Execution Policy... is " $ActualExPo $CheckMark
    if ($ActualExPo -ne 'RemoteSigned') { 
        $FixEcPo = Read-Host -Prompt "It look like that your policies are not define to run this script, do you want to set them ? (y/n)"
        if ($FixEcPo -eq 'y') {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned 
            Write-Host "Done"
            Write-Host "A final step is now enabled to set back your execution policy."
            $ExecutionPolicyChanges = $true
        }
        else { Exit }
    }
}
function Get-Prerequisite() {
    $ChocolateyInstalled = choco -v
    if (-not($ChocolateyInstalled)) {
        Write-Output "Chocolatey is not installed, fixing it..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Done"
    }
    else {
        Write-Output "Chocolatey $ChocolateyInstalled is already installed"
    }
}
function Get-RevertChanges() {
    if ($ExecutionPolicyChanges -eq $true) {
        Write-Host "Reverting now your execution policy..."
        Set-ExecutionPolicy -ExecutionPolicy Restricted 
        Write-Host "Done"
    }
}
function Get-Software() {
    choco feature enable -n allowGlobalConfirmation
    choco.exe install virtualbox --version 6.1.40 --force
    choco.exe install vagrant -y
}
function Set-Vagrant() {
    $Value = @"
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.provision "shell",
    inline: "sudo apt update -y && sudo apt install docker.io -y"
end
"@
    
    New-Item -Path . -Name "Vagrantfile" -ItemType "file" -Value $Value | Out-Null
    $Validation = vagrant.exe validate
    if ($Validation -eq 'Vagrantfile validated successfully.') { 
        Write-Host "The creation of the dev environment is started, it will take a few minute to be up and running..."
        vagrant.exe up > ./vagrant_run.log }
    else { Write-Host "There is an issue on making the Vagrantfile, please reach out direclty to your interviewer" }
}
function Get-Information() {
    Write-Host "You will now be connected to your Docker-Dev environment through Vagrant (Hashicorp)"
    Write-Host "If there is any mistake done during the interview meaning that you need to start over, just run : CTRL+D to disconnect SSH followed by ‣ vagrant destroy then ‣ vagrant up to rebuild the dev-env."
    Write-Host "The Docker documentation is available and will now be opened."
    $Uri = "https://docs.docker.com/"
    Start-Process $Uri
    vagrant.exe ssh
}

Get-CheckandSet
Get-Prerequisite 
Get-Software
Set-Vagrant
Get-Information
Get-RevertChanges