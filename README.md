# Toggle-WSL
A PowerShell 5 script to automate toggling WSL and Hyper-V related virtualization features on Windows 10 Pro.

## Usage
```
powershell .\toggle-wsl.ps1
```
You can make the script easily accessible by creating a shortcut: right click on your desktop -> New -> Shortcut, type `powershell <full-path-to-script>\toggle-wsl.ps1` in the Path field. You can now launch the script by double clicking on the shortcut.

If you have the new Windows Terminal installed you can instead type `wt powershell <full-path-to-script>\toggle-wsl.ps1` in the Path field.

The script expects to find at least one enabled feature. It will not work if all features are already disabled, as there is no saved state to restore! Keep reading to figure out why.

## Why
A reply to this [stackoverflow thread](https://superuser.com/questions/1208850/why-cant-virtualbox-or-vmware-run-with-hyper-v-enabled-on-windows-10) explains why this script exists:

> VirtualBox and VMware Workstation (and VMware Player) are "level 2 hypervisors". Hyper-V and VMware ESXi are "level 1 hypervisors".  
The main difference is that a level 2 hypervisor is an application running inside an existing OS, while a level 1 hypervisor is the OS itself.  
This means that when you enable Hyper-V, your Windows 10 "host" becomes a virtual machine. A special one, but nonetheless a virtual machine.  
So your question would more aptly be: "Why don't VirtualBox and VMware Workstation work inside a Hyper-V virtual machine?" One can answer because as a VM, the Intel VT-X instruction are no longer accessible from your virtual machine, only the host has access to it.

## How it works
The script is meant to be an easy tool to toggle between Hyper-V/Windows Subsystem for Linux and other virtualization software (VMware, VirtualBox, etc...)

The script looks for enabled Windows optional features known to cause problems with other virtualization software. It saves their state to a `.json` file, then proceeds to disable them and reboot the system. At this point you can use VMware/VirtualBox/others.  
When you want to restore features to the precedent state, re-run the script. The script will read the `.json` file, re-enabling only those features that were previously enabled, and then reboot the system.  
NOTE: if WSL is to be enabled, two reboots are required for it to work properly. The script will detect this and will do it for you.

## List of supported features
- Hyper-V
- Windows Hypervisor Platform
- Virtual Machine Platform
- Windows Subsystem for Linux
- Windows Sandbox

Feedback is welcome! If you find any other feature you believe should be disabled but the script does not, please open an issue and I'll gladly add it to the list.