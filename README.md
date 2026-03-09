# CI/CD Pipeline — GitHub Actions + Maven + Ansible → Windows

## How It Works
```
You push code to GitHub (main branch)
          ↓
GitHub Actions starts automatically (FREE Linux runner)
          ↓
Job 1: Maven builds WAR + runs tests
          ↓
Job 2: Ansible deploys to YOUR Windows PC via WinRM
          ↓
Job 3: Ansible deploys to AJITH's Windows PC via WinRM
          ↓
App live at http://YOUR_IP:8080/sample-webapp/
           http://AJITH_IP:8080/sample-webapp/
```

---

## Project Structure
```
github-actions-cicd/
├── .github/
│   └── workflows/
│       ├── cicd-pipeline.yml     ← Main pipeline (push to main)
│       └── test-only.yml         ← Test only (pull requests)
├── .gitignore
├── pom.xml
├── src/
│   ├── main/java/com/sample/app/HelloServlet.java
│   ├── main/webapp/index.html + WEB-INF/web.xml
│   ├── main/resources/application.properties
│   └── test/java/com/sample/app/HelloServletTest.java
└── ansible/
    ├── setup-winrm.ps1           ← Run on both Windows PCs first
    ├── ansible.cfg
    ├── inventory.ini             ← Template only, no real passwords
    ├── deploy.yml
    ├── group_vars/windows_servers.yml
    └── roles/
        ├── install-java/
        ├── install-tomcat/
        └── deploy-app/
            └── templates/        ← J2 templates
```

---

## STEP 1 — Run WinRM Setup on Both Windows PCs

On YOUR PC and AJITH's PC — open PowerShell as Administrator:
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File ".\ansible\setup-winrm.ps1"
```

Note the IP address shown at the end (not 169.254.x.x addresses).

---

## STEP 2 — Create GitHub Repository

```bash
# Create new repo on github.com, then:
git init
git add .
git commit -m "Initial CI/CD project"
git remote add origin https://github.com/YOUR_USERNAME/sample-webapp.git
git push -u origin main
```

---

## STEP 3 — Add GitHub Secrets (IMPORTANT!)

Go to your GitHub repo:
**Settings → Secrets and variables → Actions → New repository secret**

Add ALL of these secrets:

| Secret Name      | Value                          | Example           |
|------------------|--------------------------------|-------------------|
| YOUR_PC_IP       | Your Windows PC IP             | 172.30.28.8       |
| WINDOWS_USER     | Your Windows username          | Susanth           |
| WINDOWS_PASSWORD | Your Windows login password    | MyPassword@123    |
| AJITH_PC_IP      | Ajith's Windows PC IP          | 192.168.1.50      |
| AJITH_USER       | Ajith's Windows username       | Ajith             |
| AJITH_PASSWORD   | Ajith's Windows login password | AjithPass@123     |

⚠️ Secrets are NEVER shown in logs — GitHub hides them automatically.

---

## STEP 4 — Push Code to Trigger Pipeline

```bash
# Make any change to trigger the pipeline
git add .
git commit -m "Trigger deployment"
git push origin main
```

Then go to GitHub repo → **Actions tab** to watch it run live!

---

## STEP 5 — Watch Pipeline in GitHub

```
GitHub Repo → Actions tab

✅ Maven Build & Test         ~2 mins
✅ Deploy to Your Windows PC  ~5 mins
✅ Deploy to Ajith's PC       ~5 mins
```

---

## Pipeline Flow Diagram

```
git push → main branch
    │
    ▼
┌─────────────────────────────┐
│  JOB 1: build               │  ubuntu-latest runner
│  ✅ checkout code            │  Java 11 + Maven
│  ✅ mvn clean package        │
│  ✅ mvn test                 │
│  ✅ upload WAR artifact      │
└────────────┬────────────────┘
             │ if build passes
             ▼
┌─────────────────────────────┐
│  JOB 2: deploy-local        │  ubuntu-latest runner
│  ✅ download WAR             │  Ansible + pywinrm
│  ✅ install ansible          │
│  ✅ create inventory         │  ← IP from GitHub Secret
│  ✅ win_ping YOUR PC         │  ← WinRM connection test
│  ✅ ansible-playbook deploy  │  ← installs Java+Tomcat+WAR
│  ✅ verify HTTP 200          │
└────────────┬────────────────┘
             │ if local deploy passes
             ▼
┌─────────────────────────────┐
│  JOB 3: deploy-ajith        │  ubuntu-latest runner
│  ✅ download WAR             │  Ansible + pywinrm
│  ✅ install ansible          │
│  ✅ create inventory         │  ← IP from GitHub Secret
│  ✅ win_ping AJITH PC        │
│  ✅ ansible-playbook deploy  │
│  ✅ verify HTTP 200          │
└─────────────────────────────┘
```

---

## Verify After Deployment

Open in browser:
```
http://YOUR_PC_IP:8080/sample-webapp/
http://YOUR_PC_IP:8080/sample-webapp/hello
http://YOUR_PC_IP:8080/deploy-status.html

http://AJITH_PC_IP:8080/sample-webapp/
http://AJITH_PC_IP:8080/deploy-status.html
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| WinRM connection refused | Run setup-winrm.ps1 on target PC |
| `win_ping` fails | Check IP in GitHub Secrets is correct |
| Maven build fails | Check Java code compiles locally first |
| Tomcat not starting | Check `C:\Tomcat\logs\catalina.out` on Windows |
| Pipeline not triggering | Make sure you pushed to `main` branch |
| Secrets not working | Re-check secret names match exactly |
