<img src="Banner.png" width="800">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/MatiDEV-PL/Clean-Windows/blob/main/LICENSE) 

# 📋 Overview
By default, almost everything should be removed. Available programs are shown in the file Available_Programs_Windows_X. Any changes made to the image are described in autounattend.xml. For an in-depth overview of what is Unattend Windows installation, you can check out this official Microsoft page: [Answer files](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs?view=windows-11). 

> [!CAUTION]
> Windows modified using autounattend.xml does not have a browser installed. You need to install one using the Browser_downloader.bat located on the desktop or through other methods, such as using the command prompt.

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
- Modifications and additions made in this project are licensed under the [GPLv3 License](https://github.com/MatiDEV-PL/Clean-Windows/blob/1.0/LICENSE)

# 🔍 Sources:
- [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall)
- [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge?tab=readme-ov-file)
- [EdgeRemover](https://github.com/he3als/EdgeRemover/tree/main)

# 🎁 If you like my work consider giving tip
[<img src="https://liberapay.com/assets/widgets/donate.svg" width="100">](https://liberapay.com/MatiDEV-PL/donate) 

<img src="https://github.com/MatiDEV-PL/Clean-Windows/blob/main/Donate.png" width="120">
