# Project 0: Build a Free Windows Support Lab

> **Status:** Not started

Build a disposable Windows 11 evaluation VM in VirtualBox (or Hyper-V), install the free Microsoft diagnostics toolset, and save a clean `baseline` snapshot.

**Tools:** Windows 11 Enterprise evaluation, VirtualBox / Hyper-V, winget, Sysinternals, Windows Performance Toolkit, WinDbg, PowerShell 7
**Estimated time:** _TBD_

## What you'll learn

- _TBD_

## Prerequisites

- The host requirements in [Setup and prerequisites](#setup-and-prerequisites) below.

## Setup and prerequisites

Everything in this repo is free and public.

### Hardware

| | Minimum | Recommended |
|---|---|---|
| CPU | 64-bit x86 with virtualization (Intel VT-x / AMD-V) turned on in BIOS/UEFI | 4+ cores |
| RAM | 8 GB (run one VM at a time) | 16 GB (Windows 11 + Windows Server together) |
| Disk | 100 GB free | 150 GB SSD |

Apple Silicon Macs (M1–M4) can't run the x86 evaluation images. Use the optional Azure path or a separate x86 PC.

### Hypervisor (pick one)

| Option | Host OS | Notes |
|---|---|---|
| **VirtualBox** (used in this repo) | Windows, Linux, Intel Mac | Free and cross-platform. |
| **Hyper-V** | Windows 10/11 Pro, Enterprise, Education | Built in. Recommended for Project 6 (WSL) because nested virtualization is reliable. |

### Operating systems (Microsoft Evaluation Center, free registration)

| Image | Evaluation length | Used in |
|---|---|---|
| Windows 11 Enterprise evaluation | 90 days | Projects 0–4, 6, 7 |
| Windows Server 2025 evaluation | 180 days | Project 5 |

### Tools (free)

Sysinternals Suite, Windows Performance Toolkit (from the Windows ADK), WinDbg, PowerShell 7, Pester, Git.

### Things that could cost money

| Step | Risk | How to stay at $0 |
|---|---|---|
| Optional Azure VMs | Charges after free credit or trial ends; sign-up needs a credit card | Set a $1 budget alert, deallocate VMs, delete the resource group |
| Microsoft Connected Cache production setup | Needs eligible enterprise or ISP infrastructure | Project 7 is a written brief only |
| Windows licenses | Evaluations expire | Rebuild from the ISO; never commit a license key |

## Scenario

_The simulated customer report, written the way the support ticket would read._

## Step 1: Reproduce the problem

_Exact commands or scripts (in `scripts/`) that put the lab into the broken state._

```powershell
# command here
```

## Step 2: Diagnose

_For each step: the command or click path, a screenshot from `evidence/`, **what you should see**, and **what it tells you**._

## Fix and verify

_Steps to resolve the issue and confirm it worked._

## Root cause and prevention

_Short summary. Full write-up in [rca.md](rca.md)._

## Troubleshooting this lab

| Symptom | Likely cause | What to do |
|---|---|---|
| | | |

## Clean up

Restore the VM to the `baseline` snapshot.

## Further reading

- _Microsoft Learn links for each tool_
