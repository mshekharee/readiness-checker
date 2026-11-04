# Pairing Round — Readiness Checker

Check your laptop before a DevOps pairing interview. The checker checks a container runtime (Docker-compatible engines such as Docker Desktop or Colima, and Podman), Git, system permissions, development tools, GitHub connectivity, and internet quality, then opens a local HTML report for webcam, microphone, screen-sharing tests, and PDF export. **No software installation or administrator access is required by the checker itself.**

## Run from GitHub (recommended)

**macOS / Linux — Terminal**

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/mshekharee/readiness-checker/main/install.sh && bash install.sh
```

**Windows — PowerShell**

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mshekharee/readiness-checker/main/install.ps1 -OutFile install.ps1; if ($?) { & .\install.ps1 }
```

These commands download the checker from GitHub, run diagnostics on your own computer, and open the report in your browser. **Review the scripts and verify the repository before running them.** Prefer a trusted release tag over `main` for fixed, reproducible versions. Do not bypass your organization's security controls.

## Run after downloading ZIP / cloning

Open Terminal or PowerShell in the extracted repository folder.

- **macOS / Linux:** `bash readiness.sh`
- **Windows PowerShell:** `.\readiness.ps1`

Enter the GitHub username in the **GitHub connectivity & account** check, then click **Verify account**. That button becomes **Re-test account** after a lookup. Run the webcam, microphone, and screen-sharing tests, then choose **Save as PDF / Print** to save the report. Speak during the microphone test; audio is analyzed locally and not recorded. To re-test diagnostics, rerun the command you used to start the checker. This regenerates `results.js` and opens the updated report.

## Notes

- Docker, Colima, or Podman must be installed and its engine running. Colima is checked through the Docker CLI and its `colima` context; it does not need to be the currently selected Docker context. No test container image is downloaded. Kubernetes is optional and excluded from the readiness score. If you plan to deploy to Kubernetes during the pairing, make sure the cluster is reachable through the active `kubectl` context. This can be a local cluster, such as Rancher Desktop, or a cloud-hosted cluster.
- GitHub supports both HTTPS and SSH. The SSH check authenticates your GitHub account with `ssh -T`; it does not target a repository or verify project-repository access. The bootstrap download remains HTTPS-based so it works without SSH configuration.
- The optional Internet quality check contacts Cloudflare and transfers up to 1 MB of test data down and 256 KB of synthetic data up. It reports suggested tiers: **Poor** means response exceeds 300 ms, download is below 5 Mbps, or upload is below 2 Mbps; **Good** meets all three targets; **Excellent** is response of 100 ms or less, 25 Mbps down, and 10 Mbps up. These are checker guidelines, not Google Meet minimums. A Poor result may affect call quality but does not necessarily prevent joining.
- GitHub verification checks HTTPS connectivity and whether the public account exists; it does not verify repository push access.
- Diagnostic results stay on your computer in `results.js` (`~/.pairing-readiness-checker` when using the bootstrap command). No report is uploaded; the Internet quality test contacts Cloudflare and sends synthetic test bytes.
- Browser security settings may restrict webcam or screen capture; unavailable tests show **Not verified**.
- Some managed computers restrict shell or PowerShell scripts. Do not disable security protections to run this checker.
