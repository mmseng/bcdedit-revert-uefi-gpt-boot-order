# bcdedit-revert-uefi-gpt-boot-order
This powershell script modifies the UEFI/GPT boot order by finding the first non-Windows entry and moving it to the top of the order.

When using UEFI+GPT, the Windows installation (since Windows 7?) creates its own boot device entry ("Windows Boot Manager", a.k.a. "{bootmgr}") in the UEFI/GPT boot order list and, obnoxiously, takes the liberty of moving said entry to the top of the list. Under most circumstances, this is fine, and probably desirable. However for systems used for repeated deployment testing, or systems which you want a different bootloader to take priority (such as dual-boot systems, or computer lab systems that can be remotely re-imaged), this is a show stopper. So I needed a way to do this programmatically.

This script makes use of the arcane and undocumented {fwbootmgr} identifier implemented by bcdedit to find the first non-Windows boot device entry in the UEFI/GPT boot order list and move it to the top of the list. 

Notes:
- There's very little point in using this on regular production machines being deployed. Its main use is for machines being repeatedly imaged, or might be useful for lab machines.
- AFAICT bcdedit provides no way to pull the friendly names of the devices in the overall UEFI boot order list. Therefore, this script simply identifies the first entry in the list which is NOT "{bootmgr}" (a.k.a. "Windows Boot Manager"), and moves it to the top of the list.
    - It's up to the user to make sure the boot order exists in a state before the script is run, such that the desired result is achieved.
    - In my case:
        - My test UEFI VMs initially have the boot order of
             - 1 - "EFI Network"
             - 2 - whatever else
        - When Windows is installed with GPT partitioning, it changes the boot order to
            - 1 - "Windows Boot Manager"
            - 2 - "EFI Network"
            - 3 - whatever else
         - In that state, this script can be used to change the boot order to
            - 1 - "EFI Network"
            - 2 - "Windows Boot Manager"
            - 3 - whatever else
- This functionality relies on the completely undocumented feature of bcdedit to modify the "{fwbootmgr}" GPT entry, which contains the overall list of UEFI boot devices.
    - AFAICT bcdedit is really only designed to edit Windows' own "{bootmgr}" entry which represents one of the "boot devices" in the overall UEFI list.

Here are some sources I used in my research:
- https://www.cnet.com/forums/discussions/bugged-bcdedit-349276/
- https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcd-system-store-settings-for-uefi
- https://www.boyans.net/DownloadVisualBCD.html
- https://serverfault.com/questions/813695/how-do-i-stop-windows-10-install-from-modifying-bios-boot-settings
- https://serverfault.com/questions/714337/changing-uefi-boot-order-from-windows
