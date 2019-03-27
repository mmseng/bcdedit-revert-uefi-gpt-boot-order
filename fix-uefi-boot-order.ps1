# This script looks for the first non-Windows Boot Manager entry in the UEFI/GPT boot order and moves it to the top
# For preventing newly installed Windows from hijacking the top boot order spot on my UEFI/GPT image testing VMs
# by mmseng
# https://github.com/mmseng/bcdedit-revert-uefi-gpt-boot-order

# Notes:
# - There's very little point in using this on regular production machines being deployed. Its main use is for machines being repeatedly imaged, or might be useful for lab machines.
# - AFAICT bcdedit provideds no way to pull the friendly names of the devices in the overall UEFI boot order list. Therefore, this script only moves the first entry it identifies in the list which is NOT "{bootmgr}" (a.k.a. "Windows Boot Manager"). It's up to the user to make sure the boot order will exist in a state where the desired result is achieved.
# - In my case, my test UEFI VMs initially have the boot order of 1) "EFI Network", 2) whatever else. When Windows is installed with GPT partitioning, it changes the boot order to 1) "Windows Boot Manager", 2) "EFI Network", 3) whatever else. In that state, this script can be used to change the boot order to 1) "EFI Network", 2) "Windows Boot Manager", 3) whatever else.
# - This functionality relies on the completely undocumented feature of bcdedit to modify the "{fwbootmgr}" GPT entry, which contains the overall list of UEFI boot devices.
# - AFAICT bcdedit is really only designed to edit Windows' own "{bootmgr}" entry which represents one of the "boot devices" in the overall UEFI list.
# - Here are some sources:
#   - https://www.cnet.com/forums/discussions/bugged-bcdedit-349276/
#   - https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcd-system-store-settings-for-uefi
#   - https://www.boyans.net/DownloadVisualBCD.html
#   - https://serverfault.com/questions/813695/how-do-i-stop-windows-10-install-from-modifying-bios-boot-settings
#   - https://serverfault.com/questions/714337/changing-uefi-boot-order-from-windows


# Read current boot order
echo "Reading current boot order..."
$bcdOutput = cmd /c bcdedit /enum "{fwbootmgr}"
echo $bcdOutput

# Kill as many of the stupid characters as possible
echo "Removing extraneous characters from boot order output..."
$bcdOutput = $bcdOutput -replace '\s+',''
$bcdOutput = $bcdOutput -replace '`t',''
$bcdOutput = $bcdOutput -replace '`n',''
$bcdOutput = $bcdOutput -replace '`r',''
$bcdOutput = $bcdOutput.trim()
$bcdOutput = $bcdOutput.trimEnd()
$bcdOutput = $bcdOutput.trimStart()
$bcdOutput = $bcdOutput -replace ' ',''
echo $bcdOutput

# Define a reliable regex to capture the UUIDs of non-Windows Boot Manager devices in the boot order list
# This is difficult because apparently Powershell interprets regex is a fairly non-standard way (.NET regex flavor)
# https://docs.microsoft.com/en-us/dotnet/standard/base-types/regular-expressions
# Even then, .NET regex testers I used didn't match the behavior of what I got out of various Powershell commands that accept regex strings
# However this seems to work, even though I can't replicate the results in any regex testers
$regex = [regex]'^{([\-a-z0-9]+)+}'
echo "Defined regex as: $regex"

# Save matches
echo "Save strings matching regex..."
$foundMatches = $bcdOutput -match $regex

# Grab first match
# If Windows Boot Manager (a.k.a. "{bootmgr}" was the first in the list, this should be the second
# Which means it was probably the first before Windows hijacked the first spot
# Which means it was probably my "EFI Network" boot device
$secondBootEntry = $foundMatches[0]
echo "First match: $secondBootEntry"

# Move it to the first spot
echo "Running this command:"
echo "cmd /c bcdedit $bcdParams /set `"{fwbootmgr}`" displayorder $secondBootEntry /addfirst"
cmd /c bcdedit $bcdParams /set "{fwbootmgr}" displayorder $secondBootEntry /addfirst
