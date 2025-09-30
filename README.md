<img src="Banner.png" width="800">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/MatiDEV-PL/Clean-Windows/blob/main/LICENSE) 

# 📋 Overview
Clean Windows provides a comprehensive Windows installation automation solution that removes bloatware, enhances privacy, and optimizes performance by default. Using a customized autounattend.xml answer file, it bypasses Windows setup requirements, removes bloatware, disables telemetry, and applies extensive system optimizations automatically during installation

The autounattend.xml file is Microsoft's official method for automating Windows installations without user interaction. All modifications are transparently documented in autounattend.xml, which handles everything from bypassing TPM requirements to configuring privacy settings and removing unwanted software. For detailed information about Windows unattended installations, see Microsoft's official [Answer files](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs?view=windows-11) documentation.

> [!CAUTION]
> Windows modified using autounattend.xml does not have a browser installed. You need to install one using the Browser_downloader.bat located on the desktop or through other methods, such as using the command prompt.

# 🔑Key Features
### 🚀 Installation & Setup Optimization
- Bypasses TPM, Secure Boot, CPU, RAM, storage, and disk requirements
- Forces Windows Setup to show all available editions
- Hides EULA, OEM registration, Microsoft account creation, and wireless setup pages
- Sets network location to "Work" and prevents forced Microsoft account creation
- Disables network adapters during setup to prevent automatic updates

### 🛡️ Privacy & Telemetry Configuration
- Disables all Windows telemetry and data collection services
- Removes diagnostic tracking and feedback collection
- Disables advertising ID and targeted advertisements
- Blocks Microsoft account sync and cloud content delivery
- Disables location services and GPS tracking
- Removes activity history and timeline features
- Blocks input personalization and typing data collection

### 🗑️ Bloatware & App Removal
- Removes over 40 pre-installed Microsoft Store apps like Teams, Xbox apps, Edge
- Removes Windows components like Internet Explorer, WordPad

### ⚡ Performance Optimizations
- Enables Ultimate Performance power plan
- Optimizes memory management and virtual memory settings
- Increases network performance with IRP stack size modifications
- Prioritizes multimedia applications and gaming performance
- Sets over 200 Windows services to Manual or Disabled startup
- Disables unnecessary background processes and scheduled tasks

### 🔧 System Configuration
- Enables long file paths (up to 32,767 characters)
- Disables hibernation and fast startup features
- Configures taskbar alignment and removes unnecessary UI elements
- Disables Windows Spotlight and consumer features
- Defers feature and quality updates for 365 days
- Limits updates to security-only installations
- Disables automatic driver downloads and installations
- Blocks Windows 11 upgrades beyond current version

### 🛠️ Advanced Features
- Includes browser downloader utility for desktop deployment
- Disables Windows Defender sample submission
- Configures firewall and network security settings
- Removes remote access capabilities
- Disables Windows Error Reporting

### 📱 Windows 11 Specific Tweaks
- Removes Copilot AI assistant integration
- Disables Recall feature and widgets
- Configures Start menu and taskbar behavior

# 🔔 What's Needed:
* Brain
* [Windows 10](https://www.microsoft.com/software-download/windows10) or [Windows 11](https://www.microsoft.com/software-download/windows11) ISO (64/32-bit)
* Software like [AnyBurn](https://www.anyburn.com/download.php) to add autounattend.xml to ISO
* Optionally, access to the internet (without it, Edge might appear on the desktop during Windows 10 setup)


# 🚨 Removing Edge
If Edge is still present for any reason (thanks, Microsoft), run the following command in PowerShell.
  ```powershell
  iex "&{$(irm https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1)} -UninstallEdge -RemoveEdgeData"
  ```

# 🎓 Tutorials:
[How to add autounattend.xml to Windows iso file](https://youtu.be/qKIFijGB-Ig)

[Installation of Windows 11 24H2 using autounattend.xml](https://youtu.be/5jFbvl3571U)

# 🖼️ Screenshots:

<img src="https://github.com/MatiDEV-PL/Clean-Windows/blob/main/Photo_10.png" width="600">
<img src="https://github.com/MatiDEV-PL/Clean-Windows/blob/main/Photo_11.png" width="600">

# 📜 License

- The original code from [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall) is licensed under the [MIT License](https://github.com/MatiDEV-PL/Clean-Windows/blob/main/MIT%20LICENSE)
- Modifications and additions made in this project are licensed under the [GPLv3 License](https://github.com/MatiDEV-PL/Clean-Windows/blob/main/LICENSE)

# 🔍 Sources:
- [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall)
- [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge?tab=readme-ov-file)
- [EdgeRemover](https://github.com/he3als/EdgeRemover/tree/main)

# 🎁 If you like my work consider giving tip
[<img src="https://liberapay.com/assets/widgets/donate.svg" width="100">](https://liberapay.com/MatiDEV-PL/donate) 

<img src="https://github.com/MatiDEV-PL/Clean-Windows/blob/main/Donate.png" width="120">
