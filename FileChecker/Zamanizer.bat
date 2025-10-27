@echo off
setlocal enabledelayedexpansion

rem Create a folder to store files by extension (outside the current directory to avoid infinite loop)
set "targetFolder=Sorted_Files"
if not exist "%targetFolder%" mkdir "%targetFolder%"

rem Define folder for files without extensions
set "noExtFolder=Unknown"

rem For each file in the folder and all subfolders
for /r %%a in (*) do (
    rem Check if the file has an extension
    if "%%~xa"=="" (
        rem If the file has no extension, move it to the "Unknown" folder
        if not exist "%targetFolder%\%noExtFolder%" mkdir "%targetFolder%\%noExtFolder%"
        
        rem Set the destination path for files without extensions
        set "destFile=%targetFolder%\%noExtFolder%\%%~na"
    ) else (
        rem If the file has an extension, check if the extension folder exists under the target folder, if not, it is created
        if not exist "%targetFolder%\%%~xa" mkdir "%targetFolder%\%%~xa"

        rem Set the destination path using base name and extension
        set "destFile=%targetFolder%\%%~xa\%%~na%%~xa"
    )

    rem Initialize the counter
    set "counter=1"

    rem If the destination file already exists, generate a unique name with a counter
    if exist "!destFile!" (
        rem Loop until we find a filename that doesn't exist
        :find_unique_name
        if "%%~xa"=="" (
            set "destFile=%targetFolder%\%noExtFolder%\%%~na_!counter!"
        ) else (
            set "destFile=%targetFolder%\%%~xa\%%~na_!counter!%%~xa"
        )
        set /a counter+=1
        if exist "!destFile!" goto find_unique_name
    )

    rem Move the file to the unique destination
    move "%%a" "!destFile!"
)
