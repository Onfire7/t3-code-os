# T3 Code OS

A sandboxed, headless T3 Code server packaged as a container for a Maître server. Desktop and other devices connect to it as a remote environment; agents run inside it with full freedom, isolated from the host.

## Language

**Remote Environment**:
A headless T3 Code server that client devices (desktop app, browser) pair with and drive; threads, worktrees and agents execute there, not on the client.
_Avoid_: Instance, backend, host

**Sandbox**:
The container boundary that lets agents act with full permissions without reaching the host's filesystem or credentials.
_Avoid_: VM, jail

**Workspace**:
The folder where projects are cloned and worked on: a Space folder dedicated to this Remote Environment, chosen by the user and reachable from outside for copying files in and out. Nothing else of the host is visible to the Sandbox.
_Avoid_: Projects dir, code volume

**Provider**:
An agent CLI (Claude Code, Codex) that T3 Code drives to do work inside the Remote Environment.
_Avoid_: Model, backend, agent

**Provider Login**:
The persisted credential a Provider uses to authenticate, established once inside the Remote Environment.
_Avoid_: API key, auth

**Pairing**:
The one-time exchange that authorises a client device to use the Remote Environment.
_Avoid_: Login, linking

**Account Link**:
The persistent tie between the Remote Environment and the user's T3 account (via T3 Connect), which lets the user's devices find and reach it without a direct network route.
_Avoid_: Pairing, connection

**Channel**:
The release train (stable, preview, nightly) the Remote Environment follows when T3 Code updates itself.
_Avoid_: Version, track
