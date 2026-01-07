# Professional Git Workflow Guide

This document explains how a professional software development team sets up and uses Git.

## 1. The Repository Setup

In a professional setting, there is usually a "Remote" repository (hosted on GitHub, GitLab, Bitbucket, etc.) that acts as the **Single Source of Truth**.

### Initial Setup (Completed)
The project repository is initialized, and `.gitignore` is configured.

### Ongoing Development
Since the project is active:
1.  **Pull Latest**: Always start by pulling the latest changes from `main`.
2.  **Create Feature Branch**: Creates separate branches for new features (e.g., `feature/web-support`).
3.  **Commit Often**: Save work with clear messages.
4.  **Merge**: Merge back to `main` when the feature is complete and tested.

## 2. The Development Flow

Teams rarely work directly on the `main` (or `master`) branch. Instead, they use **Feature Branches**.

### The Flow:
1.  **Update Local**: `git checkout main` -> `git pull` (Get latest changes).
2.  **Create Branch**: `git checkout -b feature/add-login-screen` (Create a safe space to work).
3.  **Work & Commit**: Make changes and save small snapshots (`git commit -m "Added login button UI"`).
4.  **Push**: Send your branch to the cloud.
5.  **Pull Request (PR)**: Ask the team to review your code before merging it into `main`.

## 3. Forking vs. Branching

You mentioned **Forking**. Here is the difference:

*   **Branching**: You are a member of the team. You have permission to write to the main repository. You create branches directly there.
*   **Forking**: You are an outside contributor (open source) or want a completely separate copy. You make a "Fork" (your own copy on GitHub), work there, and send a PR across repositories.

*For this project, since you are the owner, we will simulate the **Team Workflow (Branching)** as it's the standard for professional teams working on their own product.*

## 4. Setting up Virtual Environment (Python)

Professional teams ensure everyone uses the same dependency versions.
1.  Create `venv`: `python3 -m venv venv` (Isolated sandbox).
2.  Activate: `source venv/bin/activate`.
3.  Install: `pip install -r requirements.txt`.
4.  Freeze: `pip freeze > requirements.txt` (Save list of used libraries).

---

**Next Steps for Us:**
1.  We will initialize git.
2.  We will setup the `.gitignore`.
3.  We will create the `venv`.
