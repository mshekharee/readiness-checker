# Pairing Round — System Readiness Checker

Check your laptop before the DevOps pairing interview. **No installation required.** The script checks local tools and opens an HTML report for printing or saving as PDF.

## Run after downloading or cloning

Open Terminal / PowerShell **inside this folder**, then run:

**macOS / Linux**
```bash
bash readiness.sh
```

**Windows (PowerShell)**
```powershell
powershell -NoProfile -File .\readiness.ps1
```

In the opened report, add candidate details, verify your GitHub username, test webcam and screen sharing, then select **Save as PDF / Print**. To re-check local tools after fixing an issue, rerun the same script and refresh the report.

## Get the files from GitHub

After this repository is published, replace `OWNER/REPO` with the real GitHub repository path. Candidates can choose **Code → Download ZIP**, or clone:

```bash
git clone https://github.com/OWNER/REPO.git
cd REPO
bash readiness.sh
```

**macOS / Linux: download the repository using curl (Git not required)**
```bash
curl -fL https://github.com/OWNER/REPO/archive/refs/heads/main.zip -o readiness.zip
unzip readiness.zip
cd REPO-main
bash readiness.sh
```

**Windows:** use **Code → Download ZIP**, extract it, open PowerShell in the folder and run the Windows command above.

## Notes

- Docker CLI and engine are checked; no `hello-world` image is downloaded. Kubernetes is optional and excluded from the readiness score.
- The GitHub check confirms a public account exists, not that it can push code.
- Diagnostics stay on this computer in `results.js`; no diagnostic data is uploaded. The GitHub username lookup contacts GitHub's public API.
- Browsers may restrict camera or screen sharing from local HTML files. The report marks such tests *Not verified*; do not bypass security controls.
- Scripts can be restricted by corporate device policies. Review the scripts before running; **do not disable security settings** to execute them.
