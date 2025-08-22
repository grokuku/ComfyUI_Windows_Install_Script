@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: ComfyUI-Launcher Script
:: Version: 3.8 (Minimalist Menu)
:: Author: Holaf + Gemini
:: ============================================================================
:: This script automates the setup and execution of ComfyUI.
:: ============================================================================

:: --- Configuration: Directory Structure ---
set "TOOLS_DIR=%~dp0tools"
set "COMFYUI_DIR=%~dp0comfyui"
set "CONDA_ENV_DIR=%~dp0conda_env"
set "PARAMS_FILE=%~dp0parameters.txt"
set "GIT_INSTALL_DIR=%~dp0tools\git"
set "CONDA_DIR=%~dp0tools\miniforge"

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
    ) > "%PARAMS_FILE%"
    echo [SETUP] 'parameters.txt' created successfully.
    echo.
)

:main_menu
cls
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
echo ============================================================================
choice /c 1234 /n /m "Your choice: "
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
    
    echo [INSTALL] Creating Conda environment...
    cmd /c "call "%ACTIVATE_BAT%" && conda create -p "%CONDA_ENV_DIR%" -c conda-forge python=3.11 -y"
    
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

