# UV Pip Best Practices Menu Script

$requirementsFile = "requirements.txt"
$envName = ".venv"
$envPath = "$PSScriptRoot\$envName"
function Install-UV {
    # 检查是否在虚拟环境中
    if (-not (Test-Path "$envPath\Scripts\activate")) {
        Write-Host "请先创建并激活虚拟环境！" -ForegroundColor Red
        return
    }

    # 检查是否已激活虚拟环境
    if (-not ($env:VIRTUAL_ENV)) {
        Write-Host "请先激活虚拟环境！使用选项8来激活环境。" -ForegroundColor Red
        return
    }

    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "UV已安装在当前虚拟环境中。" -ForegroundColor Cyan
        $currentVersion = (uv --version).Trim()
        Write-Host "当前版本: $currentVersion" -ForegroundColor Cyan        
        
        $updateChoice = Read-Host "是否要更新UV到最新版本？(Y/N)"
        if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
            Write-Host "正在更新UV..." -ForegroundColor Cyan
            uv pip install --upgrade uv
            Write-Host "UV已更新完成。" -ForegroundColor Green
            $restartChoice = Read-Host "是否要重启脚本以应用更改？(Y/N)"
            if ($restartChoice -eq "Y" -or $restartChoice -eq "y") {
                Write-Host "正在重启脚本..." -ForegroundColor Yellow
                Start-Process powershell -ArgumentList "-NoExit", "-File", "'$($MyInvocation.MyCommand.Path)'"
                exit
            }
        } else {
            Write-Host "已跳过更新。" -ForegroundColor Cyan
        }
    } else {
        Write-Host "正在安装UV..." -ForegroundColor Cyan
        uv pip install uv
        Write-Host "UV已安装完成。" -ForegroundColor Green
        $restartChoice = Read-Host "是否要重启脚本以应用更改？(Y/N)"
        if ($restartChoice -eq "Y" -or $restartChoice -eq "y") {
            Write-Host "正在重启脚本..." -ForegroundColor Yellow
            Start-Process powershell -ArgumentList "-NoExit", "-File", "'$($MyInvocation.MyCommand.Path)'"
            exit
        }
    }
}
function Create-VirtualEnvironment {
    Write-Host "Preparing to create virtual environment..." -ForegroundColor Cyan

    # 检查并删除旧的虚拟环境
    if (Test-Path $envPath) {
        Write-Host "Found existing virtual environment, removing..." -ForegroundColor Yellow
        try {
            # 确保没有进程在使用虚拟环境
            $pythonProcesses = Get-Process python -ErrorAction SilentlyContinue
            if ($pythonProcesses) {
                Write-Host "Stopping Python processes..." -ForegroundColor Yellow
                $pythonProcesses | ForEach-Object { $_.Kill() }
                Start-Sleep -Seconds 2  # 等待进程完全终止
            }
            
            # 删除旧的虚拟环境
            Remove-Item -Path $envPath -Recurse -Force
            Write-Host "Old virtual environment removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove old virtual environment: $_" -ForegroundColor Red
            return
        }
    }

    # 创建新的虚拟环境
    Write-Host "Creating new virtual environment..." -ForegroundColor Cyan
    try {
        python -m venv $envPath
        if (-not $?) { throw "Failed to create virtual environment" }
        Write-Host "Virtual environment created successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create virtual environment: $_" -ForegroundColor Red
        return
    }

    # 激活环境并安装包
    Write-Host "Installing/Updating pip and uv in the new environment..." -ForegroundColor Cyan
    try {
        Wait-ActivateEnvironment
        python -m pip install --upgrade pip
        pip install uv
        if (Get-Command uv -ErrorAction SilentlyContinue) {
            Write-Host "UV installed successfully in $envName." -ForegroundColor Green
            Write-Host "Activate the environment with: $envName\Scripts\activate"
        } else {
            throw "UV installation verification failed"
        }
    } catch {
        Write-Host "Failed to setup virtual environment: $_" -ForegroundColor Red
        return
    }
}

function Install-Packages {
    if (-not ($env:VIRTUAL_ENV)) {
        Wait-ActivateEnvironment
    }
    $packages = Read-Host "Enter package names separated by spaces"
    if ([string]::IsNullOrWhiteSpace($packages)) {
        Write-Host "No packages specified."
        return
    }
    uv pip install $packages
    Write-Host "Packages installed successfully."
}

function Install-RequirementsTxt {
    if (-not ($env:VIRTUAL_ENV)) {
        Wait-ActivateEnvironment
    }
    if (Test-Path $requirementsFile) {
        uv pip install -r $requirementsFile
        Write-Host "Packages installed successfully."
    } else {
        Write-Host "Error: $requirementsFile not found."
    }
}

function Generate-RequirementsTxt {
    if (-not ($env:VIRTUAL_ENV)) {
        Wait-ActivateEnvironment
    }
    uv pip freeze > $requirementsFile
    Write-Host "$requirementsFile generated successfully."
}

function List-Packages {
    if (-not ($env:VIRTUAL_ENV)) {
        Wait-ActivateEnvironment
    }
    uv pip list
}
function Wait-ActivateEnvironment {
    # 等待虚拟环境激活完成
    if (-not ($env:VIRTUAL_ENV)) {
        $activateScriptPath = "$envPath\Scripts\activate.ps1"
        if (Test-Path $activateScriptPath) {
            Write-Host "Activating virtual environment using: $activateScriptPath" -ForegroundColor Cyan
            try {
                . $activateScriptPath
                Write-Host "Virtual environment activated." -ForegroundColor Green
            } catch {
                Write-Host "Failed to activate virtual environment using dot-sourcing: $_" -ForegroundColor Red
                throw "Failed to activate virtual environment"
            }
        } else {
            Write-Host "Error: Activation script not found at $activateScriptPath" -ForegroundColor Red
            throw "Activation script not found"
        }
    }
}
function Activate-VirtualEnvironment {
    if (Test-Path $envPath) {
        Write-Host "Starting interactive virtual environment session..." -ForegroundColor Green
        Write-Host "Type 'exit' to leave the virtual environment session" -ForegroundColor Green
        PowerShell -NoExit -Command "& '$envPath\Scripts\activate.ps1'; Set-Location '$PSScriptRoot'"
    } else {
        Write-Host "Error: Virtual environment not found. Please create it first." -ForegroundColor Red
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "================ UV Pip Best Practices Menu ================="
    Write-Host "1: Create($envName)"
    Write-Host "2: Create($envName) && Install requirements.txt"
    Write-Host "3: Activate($envName)"
    Write-Host "4: ($envName)Install packages by user input"
    Write-Host "5: ($envName)Install packages from requirements.txt"
    Write-Host "6: ($envName)Generate requirements.txt"
    Write-Host "7: ($envName)List installed packages"
    Write-Host "8: Install UV globally"
    Write-Host "9: Update pip globally"
    Write-Host "0: Exit"
    Write-Host "==========================================================="
}

# Main menu loop
do {
    Show-Menu
    $selection = Read-Host "Please select an option"    
    switch ($selection) {
        '1' {
            Create-VirtualEnvironment
        }
        '2' {
            Create-VirtualEnvironment
            Install-RequirementsTxt
        }
        '3' {
            Activate-VirtualEnvironment
        }
        '4' {
            Install-Packages
        }
        '5' {
            Install-RequirementsTxt
        }
        '6' {
            Generate-RequirementsTxt
        }
        '7' {
            List-Packages
        }
        '8' {
            # 如果在虚拟环境中，先退出
            if ($env:VIRTUAL_ENV) {
                deactivate
                Write-Host "已退出虚拟环境以进行全局安装..." -ForegroundColor Yellow
            }
            powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
        }   
        '9' {
            # 如果在虚拟环境中，先退出
            if ($env:VIRTUAL_ENV) {
                deactivate
                Write-Host "已退出虚拟环境以进行全局安装..." -ForegroundColor Yellow
            }
            python -m pip install --upgrade pip
        }      
        '0' {
            exit
        }
    }
    Pause
} until ($selection -eq '0')

