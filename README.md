# Pairing Round — Readiness Checker

Check your laptop before a DevOps pairing interview. The checker checks Docker, Git, system permissions, development tools, GitHub connectivity, and internet quality, then opens a local HTML report for webcam, microphone, screen-sharing tests, and PDF export. **No software installation or administrator access is required by the checker itself.**

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

Enter the GitHub username in the **GitHub connectivity & account** check, then click **Verify account**. That button becomes **Re-test account** after a lookup. Run the webcam, microphone, and screen-sharing tests, then choose **Save as PDF / Print** to save the report. Speak during the microphone test; audio is analyzed locally and not recorded. To re-test local tools, run the script again and click **Refresh results** in the report.

## Notes

- Docker must be installed and its engine running; no test container image is downloaded. Kubernetes is optional and excluded from the final score.
- GitHub supports both HTTPS and SSH. The required SSH check confirms GitHub accepts your key, but it does not check whether you can push to your project repository. The bootstrap download remains HTTPS-based so it works without SSH configuration.
- The optional Internet quality check contacts Cloudflare and transfers up to 1 MB of test data down and 256 KB of synthetic data up. It reports response time and measured speeds; a low result is a review, not a readiness failure.
- GitHub verification checks HTTPS connectivity and whether the public account exists; it does not verify repository push access.
- Diagnostic results stay on your computer in `results.js` (`~/.pairing-readiness-checker` when using the bootstrap command). No report is uploaded; the Internet quality test contacts Cloudflare and sends synthetic test bytes.
- Browser security settings may restrict webcam or screen capture; unavailable tests show **Not verified**.
- Some managed computers restrict shell or PowerShell scripts. Do not disable security protections to run this checker.
