System Access Restoration Tool (SART) v1.0
Professional Edition - Documentation
================================================================================

LEGAL DISCLAIMER AND USAGE NOTICE:
This software is provided for educational and authorized administrative recovery 
purposes only. It demonstrates technical capabilities regarding Windows 
accessibility features and file system permissions.

1. Authorization: Do not use this tool on systems you do not own or have 
   explicit, written permission to administer. Unauthorized access to computer 
   systems is illegal in many jurisdictions.
   
2. Liability: The author(s) and provider(s) of this script assume no liability 
   for data loss, system instability, or legal consequences arising from the 
   misuse of this tool.

3. Compatibility: This tool modifies system files. While backup mechanisms are 
   included, proceed at your own risk.

================================================================================

1. Purpose
----------
SART enables authorized administrators to regain access to a locked Windows 
system where passwords have been lost. It utilizes the "Accessibility Tool 
Replacement" method (replacing sethc.exe or utilman.exe with cmd.exe) to 
generate a temporary administrative account.

2. Workflow Overview
--------------------
The recovery process involves three distinct phases:

[Phase 1] Deployment (SART.bat)
- Run from an external environment (Windows PE) or a secondary Windows installation.
- Mounts the target system's registry and modifies file permissions.
- Backs up the original accessibility tools (sethc.exe/utilman.exe).
- Replaces them with the command interpreter (cmd.exe).

[Phase 2] Access Recovery
- Boot the target system normally.
- At the logon screen, trigger the accessibility shortcut:
  > Press SHIFT 5 times (for Sticky Keys/sethc.exe)
  > Or press Win+U (for Utility Manager/utilman.exe)
- A command prompt will appear with SYSTEM privileges.
- Type "ADDUSER" to create the recovery account.
  > Username: temp_admin
  > Password: Password12!

[Phase 3] Cleanup & Restoration (CLEAN.bat)
- Log in using the `temp_admin` credentials.
- Open a Command Prompt as Administrator.
- Run "CLEAN" to initiate the restoration process.
- The script will:
  > Restore the original sethc.exe/utilman.exe files.
  > Remove the `temp_admin` account.
  > Schedule the deletion of the temporary user profile.
  > Re-enable User Account Control (UAC) if it was disabled.

3. Requirements
---------------
Ensure the following utilities are present in the '3rdparty' folder or system PATH:
- attrib.exe, cacls.exe, reg.exe (Standard Windows components)
- taskkill.exe (or wkill.exe/pskill.exe)
- takeown.exe (or subinacl.exe)
- startx.exe (Required for background cleanup)
- movefile.exe (Required for profile deletion)

4. Troubleshooting
------------------
- "Sticky Keys" Disabled: If the target has disabled Sticky Keys, use Method II 
  in the main menu (Service Creation) or the utilman.exe replacement option.
- Windows 7/10/11: Sometimes the command prompt window may not render text 
  correctly at the logon screen. The commands will still execute. Blindly typing 
  "ADDUSER" usually works.
- Residual Files: If automatic cleanup fails, manually delete the 'temp_admin' 
  user profile folder after the final reboot.

================================================================================
End of Document