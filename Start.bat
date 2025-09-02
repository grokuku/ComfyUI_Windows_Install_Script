@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: ComfyUI-Launcher Script
:: Version: 6.2 (Fix premature exit)
:: Author: Holaf + Gemini
:: ============================================================================
:: This script automates the setup and execution of ComfyUI.
:: ============================================================================

:: ============================================================================
:: --- Phase -1: System Detection ---
:: ============================================================================
echo [INFO] Detecting system hardware...

set "CPU_NAME=N/A"
set "GPU_NAME=N/A"
set "TOTAL_RAM_GB=N/A"
set "GPU_VRAM_GB=N/A"
set "SAGE_SUPPORT=false"
set "SAGE_STATUS=Disabled (No compatible NVIDIA GPU detected)"

:: --- CPU Detection (wmic) ---
echo|set /p="[INFO] CPU detection... "
set "start_time=%TIME%"
for /f "tokens=1,* delims==" %%a in ('wmic cpu get name /value 2^>nul') do (
    if "%%a"=="Name" set "CPU_NAME=%%b"
)
if defined CPU_NAME for /f "tokens=*" %%i in ("%CPU_NAME%") do set "CPU_NAME=%%i"
call :get_elapsed_time
echo Done (!elapsed_ms! ms)

:: --- RAM Detection (wmic + PowerShell for 64-bit calculation) ---
echo|set /p="[INFO] RAM detection... "
set "start_time=%TIME%"
set "ram_bytes="
for /f "tokens=1,* delims==" %%a in ('wmic computersystem get totalphysicalmemory /value 2^>nul') do (
    if "%%a"=="TotalPhysicalMemory" set "ram_bytes=%%b"
)
if defined ram_bytes (
    for /f "usebackq" %%i in (`powershell -Command "[math]::Round(!ram_bytes! / 1GB)"`) do (
        set "TOTAL_RAM_GB=%%i GB"
    )
)
call :get_elapsed_time
echo Done (!elapsed_ms! ms)

:: --- GPU Detection (nvidia-smi preferred, wmic as fallback) ---
echo|set /p="[INFO] GPU detection... "
set "start_time=%TIME%"
where nvidia-smi >nul 2>&1
if !errorlevel! equ 0 (
    :: Method 1: Use nvidia-smi for precise info, including Compute Capability
    for /f "usebackq tokens=1,2,3 delims=," %%a in (`"nvidia-smi --query-gpu=gpu_name,memory.total,compute_cap --format=csv,noheader,nounits"`) do (
        set "GPU_NAME=%%a"
        set "vram_mb=%%b"
        set "compute_cap=%%c"
        
        set /a "vram_gb=vram_mb / 1024"
        set "GPU_VRAM_GB=!vram_gb! GB"
        
        :: Check for SageAttention compatibility based on Compute Capability >= 8.0
        for /f "tokens=1 delims=." %%d in ("!compute_cap!") do set "compute_major=%%d"
        
        if !compute_major! geq 8 (
            set "SAGE_SUPPORT=true"
            set "SAGE_STATUS=Enabled (Compute Capability !compute_cap! >= 8.0)"
        ) else (
            set "SAGE_STATUS=Disabled (Compute Capability !compute_cap! < 8.0)"
        )
    )
) else (
    :: Method 2: Fallback to wmic for non-NVIDIA or driverless systems
    for /f "tokens=1,* delims==" %%a in ('wmic path win32_videocontroller get name,adapterram /value 2^>nul') do (
        if "%%a"=="AdapterRAM" (
            set "vram_bytes=%%b"
            if defined vram_bytes for /f "usebackq" %%i in (`powershell -Command "[math]::Round(!vram_bytes! / 1GB)"`) do (
                set "GPU_VRAM_GB=%%i GB"
            )
        )
        if "%%a"=="Name" set "GPU_NAME=%%b"
    )
)
if defined GPU_NAME for /f "tokens=*" %%i in ("%GPU_NAME%") do set "GPU_NAME=%%i"
call :get_elapsed_time
echo Done (!elapsed_ms! ms)
echo.


:: --- Configuration: Directory Structure ---
set "TOOLS_DIR=%~dp0tools"
set "COMFYUI_DIR=%~dp0comfyui"
set "CONDA_ENV_DIR=%~dp0conda_env"
set "PARAMS_FILE=%~dp0parameters.txt"
set "GIT_INSTALL_DIR=%~dp0tools\git"
set "CONDA_DIR=%~dp0tools\miniforge"
set "SAGE_ATTENTION_DIR=%TOOLS_DIR%\SageAttention"

:: Set path to the git executable
set "GIT_EXE=%GIT_INSTALL_DIR%\cmd\git.exe"

:: Set main activation script path
set "ACTIVATE_BAT=%CONDA_DIR%\Scripts\activate.bat"

:: ============================================================================
:: --- Phase 0: Bootstrap - Ensure required tools are available ---
:: ============================================================================
echo.
echo [INFO] Checking for required tools (Git and Miniforge)...
mkdir "%TOOLS_DIR%" >nul 2>&1

:: Check for Git
if not exist "%GIT_EXE%" (
    echo [SETUP] Git not found. Downloading Portable Git...
    curl -L "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/PortableGit-2.45.2-64-bit.7z.exe" -o "%TOOLS_DIR%\PortableGit.exe"
    if !errorlevel! neq 0 ( echo [ERROR] Git download failed. & pause & exit /b 1 )
    echo [SETUP] Extracting Git...
    start /wait "" "%TOOLS_DIR%\PortableGit.exe" -o"%GIT_INSTALL_DIR%" -y
    del "%TOOLS_DIR%\PortableGit.exe"
    echo [SETUP] Git setup complete.
)

:: Check for Miniforge
if not exist "%CONDA_DIR%\Scripts\conda.exe" (
    echo [SETUP] Miniforge not found. Downloading...
    curl -L "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe" -o "%TOOLS_DIR%\Miniforge_Installer.exe"
    if !errorlevel! neq 0 ( echo [ERROR] Miniforge download failed. & pause & exit /b 1 )
    echo [SETUP] Installing Miniforge silently...
    start /wait "" "%TOOLS_DIR%\Miniforge_Installer.exe" /S /InstallationType=JustMe /RegisterPython=0 /D=%CONDA_DIR%
    del "%TOOLS_DIR%\Miniforge_Installer.exe"
    echo [SETUP] Miniforge setup complete.
)
echo [INFO] Tools check complete. Git and Miniforge are ready.
echo.


:: ============================================================================
:: --- Phase 1: Initial Setup & Main Menu ---
:: ============================================================================
if not exist "%PARAMS_FILE%" (
    echo [SETUP] First launch detected: Creating default 'parameters.txt' file...
    (
        echo # Web + Network
        echo --port 9000
        echo.
        echo # Directories
        echo.
        echo # Options
        echo --windows-standalone-build
    ) > "%PARAMS_FILE%"
    echo [SETUP] 'parameters.txt' created successfully.
    echo.
)

:main_menu
cls
echo ============================================================================
echo   System Information
echo ============================================================================
echo.
echo   CPU: !CPU_NAME!
echo   RAM: !TOTAL_RAM_GB!
echo   GPU: !GPU_NAME! (!GPU_VRAM_GB! VRAM)
echo.
echo   SageAttention Support: !SAGE_STATUS!
echo.
echo ============================================================================
echo   ComfyUI Portable Launcher
echo ============================================================================
echo.
echo   Please choose an option:
echo.
echo      [1] Run ComfyUI
echo      [2] Update + Run ComfyUI
echo      [3] Repair + Run ComfyUI
echo      [4] Open Interactive Terminal
echo.
echo      [5] Quit
echo.
echo ============================================================================
choice /c 12345 /n /m "Your choice: "
if errorlevel 5 goto :eof
if errorlevel 4 goto :action_terminal
if errorlevel 3 goto :action_repair
if errorlevel 2 goto :action_update
if errorlevel 1 goto :action_run
goto :main_menu


:: ============================================================================
:: --- Phase 2: Action Implementation ---
:: ============================================================================

:action_run
cls
echo ============================================================================
echo   [1] Run ComfyUI
echo ============================================================================
echo.
set "NEEDS_INSTALL=0"
if not exist "%CONDA_ENV_DIR%\conda-meta" ( set "NEEDS_INSTALL=1" )
goto :check_repositories

:action_update
cls
echo ============================================================================
echo   [2] Update + Run ComfyUI
echo ============================================================================
echo.
echo [UPDATE] Updating ComfyUI repository only...
"%GIT_EXE%" -C "%COMFYUI_DIR%" fetch
if !errorlevel! neq 0 ( echo [ERROR] Git fetch failed for ComfyUI. & pause & goto :main_menu )
"%GIT_EXE%" -C "%COMFYUI_DIR%" reset --hard @{u}
if !errorlevel! neq 0 ( echo [ERROR] Git reset failed for ComfyUI. & pause & goto :main_menu )

echo.
echo [UPDATE] ComfyUI repository updated. Re-checking dependencies...
set "NEEDS_DEP_UPDATE=1"
goto :install_dependencies

:action_repair
cls
echo ============================================================================
echo   [3] Repair + Run ComfyUI
echo ============================================================================
echo.
echo [REPAIR] This will delete and reinstall the entire Python environment.
choice /c YN /m "Are you sure you want to continue? (Y/N): "
if errorlevel 2 goto :main_menu

echo [REPAIR] Deleting Conda environment directory...
cd /d "%~dp0"
rmdir /s /q "%CONDA_ENV_DIR%"
if !errorlevel! neq 0 ( echo [ERROR] Could not delete the conda_env directory. & pause & goto :main_menu )
echo [REPAIR] Environment deleted.
set "NEEDS_INSTALL=1"
goto :check_repositories

:action_terminal
cls
echo ============================================================================
echo   [4] Open Interactive Terminal
echo ============================================================================
echo.

:: --- Check if the environment exists before trying to activate it ---
if not exist "%CONDA_ENV_DIR%\conda-meta" (
    echo [ERROR] The Conda environment has not been created yet.
    echo [ERROR] Please run option [1] or [3] at least once before using the terminal.
    echo.
    pause
    goto :main_menu
)

echo [INFO] Opening a new terminal with the Conda environment activated...
echo [INFO] You can close this window; the new terminal will remain open.
echo.

:: The /k switch keeps the new cmd window open after the command finishes.
:: We manually set the prompt with a hardcoded name for reliability.
start "ComfyUI Interactive Terminal" cmd /k "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && prompt (conda_env) $P$G"

goto :main_menu


:: ============================================================================
:: --- Phase 3: Dependency Management and Execution ---
:: ============================================================================

:check_repositories
:: --- Check and clone ComfyUI repository ---
if not exist "%COMFYUI_DIR%\.git" (
    echo [SETUP] ComfyUI repository not found. Cloning...
    "%GIT_EXE%" clone https://github.com/comfyanonymous/ComfyUI.git "%COMFYUI_DIR%"
    if !errorlevel! neq 0 ( echo [ERROR] Failed to clone ComfyUI. & pause & exit /b 1 )
) else (
    if "%NEEDS_INSTALL%" == "0" ( echo [INFO] ComfyUI repository found. )
)

:: --- Check and clone ComfyUI-Manager ---
mkdir "%COMFYUI_DIR%\custom_nodes" >nul 2>&1
if not exist "%COMFYUI_DIR%\custom_nodes\ComfyUI-Manager\.git" (
    echo [SETUP] ComfyUI-Manager not found. Cloning...
    "%GIT_EXE%" clone https://github.com/ltdrdata/ComfyUI-Manager.git "%COMFYUI_DIR%\custom_nodes\ComfyUI-Manager"
    if !errorlevel! neq 0 ( echo [ERROR] Failed to clone ComfyUI-Manager. & pause & exit /b 1 )
) else (
    if "%NEEDS_INSTALL%" == "0" ( echo [INFO] ComfyUI-Manager found. )
)
goto :install_dependencies


:install_dependencies
if "%NEEDS_INSTALL%" == "1" (
    echo.
    echo [INSTALL] First time setup or Repair: Creating environment and installing all dependencies.
    echo [INSTALL] This will take a very long time. Please be patient.
    echo.
    set "NEEDS_DEP_UPDATE=1"
    
    echo [INSTALL] Creating Conda environment with Python 3.12...
    cmd /c "call "%ACTIVATE_BAT%" && conda create -p "%CONDA_ENV_DIR%" -c conda-forge python=3.12 -y"
    
    :: Robust check for success, as conda create can have a strange errorlevel.
    if not exist "%CONDA_ENV_DIR%\conda-meta" ( 
        echo [ERROR] Failed to create Conda environment directory. Check logs above.
        pause
        exit /b 1
    )
    echo [INSTALL] Conda environment created successfully.
)

if "%NEEDS_DEP_UPDATE%" == "1" (
    echo.
    echo [INSTALL] Installing/Verifying main dependencies...

    echo "[INSTALL] Uninstalling any pre-existing PyTorch (to ensure clean CUDA install)..."
    cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip uninstall -y torch torchvision torchaudio"

    echo [INSTALL] Installing NVIDIA CUDA Toolkit components via Conda...
    cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && conda install -c "nvidia/label/cuda-12.8.0" cudatoolkit -y"
    if !errorlevel! neq 0 ( echo [ERROR] Failed to install CUDA Toolkit. & pause & exit /b 1 )

    echo [INSTALL] Installing PyTorch with CUDA 12.8 support...
    cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128"
    if !errorlevel! neq 0 ( echo [ERROR] Failed to install PyTorch with CUDA. & pause & exit /b 1 )
    
    echo [INSTALL] Installing Triton for Windows...
    cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip install triton-windows"
    if !errorlevel! neq 0 ( echo [ERROR] Failed to install Triton. & pause & exit /b 1 )
    
    if "%SAGE_SUPPORT%" == "true" (
        echo [INSTALL] Preparing SageAttention...
        if not exist "%SAGE_ATTENTION_DIR%\.git" (
            echo [INSTALL] Cloning SageAttention repository...
            "%GIT_EXE%" clone https://github.com/thu-ml/SageAttention.git "%SAGE_ATTENTION_DIR%"
            if !errorlevel! neq 0 ( echo [ERROR] Failed to clone SageAttention. & pause & exit /b 1 )
        )
        echo [INSTALL] Installing SageAttention...
        cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip install "%SAGE_ATTENTION_DIR%""
        if !errorlevel! neq 0 ( echo [WARNING] Failed to install SageAttention. This might not be critical. & pause )
    )
        
    echo [INSTALL] Installing ComfyUI main requirements...
    cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip install -r "%COMFYUI_DIR%\requirements.txt""
    if !errorlevel! neq 0 ( echo [ERROR] Failed to install ComfyUI requirements. & pause & exit /b 1 )

    echo [INSTALL] Checking for custom node requirements...
    for /d %%d in ("%COMFYUI_DIR%\custom_nodes\*") do (
        if exist "%%d\requirements.txt" (
            echo [INSTALL] Installing dependencies for %%~nxd...
            cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python -m pip install -r "%%d\requirements.txt""
            if !errorlevel! neq 0 ( echo [ERROR] Failed to install dependencies for %%~nxd. & pause & exit /b 1 )
        )
    )
    echo [INSTALL] All dependencies are up to date.
) else (
    echo [INFO] Environment and dependencies are already installed. Skipping to launch.
)
goto :launch_comfyui


:launch_comfyui
echo.
echo ============================================================================
echo   Launching ComfyUI
echo ============================================================================
echo.

:: --- Build launch arguments from parameters.txt ---
set "LAUNCH_ARGS="
for /f "usebackq tokens=*" %%i in ("%PARAMS_FILE%") do (
    set "line=%%i"
    if defined line (
        echo !line! | findstr /b /c:"#" >nul || (
            for /f "tokens=* delims= " %%a in ("!line!") do set "param=%%a"
            set "LAUNCH_ARGS=!LAUNCH_ARGS! !param!"
        )
    )
)
echo [INFO] Starting ComfyUI with arguments:!LAUNCH_ARGS!
echo.

:: --- Execute using the proven activation logic ---
cd /d "%COMFYUI_DIR%"
cmd /c "call "%ACTIVATE_BAT%" && conda activate "%CONDA_ENV_DIR%" && python main.py!LAUNCH_ARGS!"

echo.
echo ComfyUI has been closed.
pause
goto :eof

:: ============================================================================
:: --- Utility Functions ---
:: ============================================================================

:get_elapsed_time
:: Calculates the time difference between %start_time% and the current time.
:: Result is stored in %elapsed_ms%.
set "end_time=%TIME%"
for /f "tokens=1-4 delims=:," %%a in ("%start_time%") do set /a "start_ms=(1%%a*360000)+(1%%b*6000)+(1%%c*100)+1%%d-36006100"
for /f "tokens=1-4 delims=:," %%a in ("%end_time%") do set /a "end_ms=(1%%a*360000)+(1%%b*6000)+(1%%c*100)+1%%d-36006100"
set /a "elapsed_ms=end_ms-start_ms"
goto :eof