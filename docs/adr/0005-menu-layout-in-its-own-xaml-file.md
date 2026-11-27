---
id: adr-0005
title: "ADR 0005: Menu layout in its own XAML file"
kind: adr
summary: The dashboard markup lives in ui/MainWindow.xaml instead of a here-string inside the menu script.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [QuietWindows-Menu.ps1, ui/MainWindow.xaml, tests/test-xaml.ps1]
adr_status: accepted
date: 2026-09-04
---

This ADR records the 1.0.4 change that moved the menu's layout out of PowerShell.

## Context

The menu's XAML sat inside `QuietWindows-Menu.ps1` as a long here-string, so changing a
label meant digging through the host script.

## Decision

Keep every page and button in `ui/MainWindow.xaml`; the menu loads it with
`Get-Content -Raw` and `XamlReader`.

## Consequences

- Layout and labels can be edited without touching behaviour.
- The `ui/` folder must ship next to the menu; the menu shows a message if it is missing.
- `tests/test-xaml.ps1` guards the split and checks every looked-up name exists.
