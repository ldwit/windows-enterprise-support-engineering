# Windows Enterprise Support Engineering

Hands-on, reproducible labs for Windows enterprise support: boot and application troubleshooting, performance analysis, ETW tracing, PowerShell automation, Active Directory, WSL, and customer escalations.

Every project is a **step-by-step tutorial** you can follow in your own lab using only free Microsoft tools and evaluation images. Each one is also published as an article in the DEV Community series *Windows Support Engineering Lab*.

## Start here

1. Build the lab in **[Project 0](00-lab-environment/README.md)**.
2. Work through the projects in order. Each one starts from the `baseline` snapshot.

## Projects

| Project | Topic | Tools | Status |
|---|---|---|---|
| [Project 0](00-lab-environment/README.md) | Build a Free Windows Support Lab | Windows 11 Enterprise evaluation, VirtualBox / Hyper-V, winget, Sysinternals, Windows Performance Toolkit, WinDbg, PowerShell 7 | Complete |
| [Project 1](01-windows-troubleshooting/README.md) | Windows Startup and Application Troubleshooting | Event Viewer, Autoruns, Process Monitor, Reliability Monitor, msconfig | Not started |
| [Project 2](02-performance-analysis/README.md) | CPU and Memory Performance Analysis | Task Manager, Resource Monitor, Process Explorer, Performance Monitor, ProcDump, WinDbg | Not started |
| [Project 3](03-advanced-diagnostics/README.md) | Advanced Diagnostics with WPR and WPA | Windows Performance Recorder, Windows Performance Analyzer | Not started |
| [Project 4](04-powershell-automation/README.md) | PowerShell Support Diagnostics Collector | PowerShell 7, Pester | Not started |
| [Project 5](05-windows-server/README.md) | Active Directory, DNS, and Group Policy Troubleshooting | Windows Server 2025 evaluation, AD DS, DNS, nltest, dcdiag, gpresult | Not started |
| [Project 6](06-wsl-troubleshooting/README.md) | WSL 2 Troubleshooting | WSL 2, wsl.exe, .wslconfig, collect-wsl-logs.ps1 | Not started |
| [Project 7](07-connected-cache/README.md) | Microsoft Connected Cache Feasibility Brief | Delivery Optimization cmdlets, Event Viewer | Not started |
| [Project 8](08-escalation-capstone/README.md) | Enterprise Support Escalation Capstone | All tools from Projects 0–7 | Not started |

## Skills covered

| Skill | Projects |
|---|---|
| Windows startup troubleshooting | 1, 3 |
| Application troubleshooting | 1, 2, 3 |
| CPU and memory analysis | 2, 3 |
| Windows Performance Recorder / Analyzer | 3 |
| PowerShell and automation | 4 |
| Windows Server, AD DS, DNS, Group Policy | 5 |
| Windows Subsystem for Linux | 6 |
| Delivery Optimization / Connected Cache | 7 |
| Root cause analysis and technical writing | 0–8 |
| Engineering escalation and customer communication | 8 |

## Repository layout

```text
00-lab-environment/ … 08-escalation-capstone/
├── README.md     # the tutorial
├── rca.md        # root cause analysis
├── scripts/      # scripts to break, diagnose, and fix
└── evidence/     # screenshots and small log excerpts
interview-preparation/
templates/        # DEV Community article template
```

## Ground rules

- All scenarios are simulated in a personal lab. No employer systems, customer data, or license keys.
- Large trace, dump, and VM files are excluded by `.gitignore`. Share screenshots or small excerpts instead.

## License

Released under the [MIT License](LICENSE).
