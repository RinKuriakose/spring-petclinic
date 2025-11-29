# Complete CI/CD Pipeline Setup Guide for Spring PetClinic

**A step-by-step guide**

## What You'll Build

A complete DevOps pipeline with:

- Jenkins (CI/CD automation)
- SonarQube (Code quality analysis)
- OWASP ZAP (Security scanning)
- Prometheus (Metrics collection)
- Grafana (Monitoring dashboards)

## Prerequisites

### Required Software

1. **Docker Desktop**

   - Install and start Docker Desktop
   - Verify installation:
     ```bash
     docker --version
     docker compose version
     ```
   - You version returned

2. **Git**
   - Verify installation:
     ```bash
     git --version
     ```

## Step-by-Step Setup

### Step 1: Get the Code

Open your terminal run:

```bash
cd ~/Documents

git clone https://github.com/rosannadeng/spring-petclinic.git

cd spring-petclinic

# Verify you're in the right place
ls -la
```

---

### Step 2: Build Custom Docker Images

build two custom Docker images before starting services.

#### 2.1 Build Jenkins Image with Docker CLI and plugins

```bash
# Build Jenkins image from Dockerfile.jenkins
docker compose build jenkins
```

#### 2.2 Build Maven-Java25 Image

```bash
# Build Maven with Java 25 image
docker compose build maven-java25
```

#### 2.3 Verify Images Were Built

```bash
# Check that images were created
docker images | grep -E "jenkins|maven-java25"
```

---

### Step 3: Start All Services

```bash
# Start all services in detached mode (background)
docker compose up -d
```

**What this does:** Starts containers for Jenkins, SonarQube, PostgreSQL, Prometheus, and Grafana.

#### 3.1 Verify All Services Are Running

```bash
# Check running containers
docker compose ps
```

---

### Step 4: Configure SonarQube

#### 4.1 Access SonarQube Web Interface

1. Open your web browser
2. Go to: **http://localhost:9000**
3. Wait for SonarQube to fully start

#### 4.2 Initial Login

- **Username:** `admin`
- **Password:** `admin`
- Click **"Log in"**

#### 4.3 Change Password 

1. Enter:
   - **Old password:** `admin`
   - **New password:** (choose a strong password)
   - **Confirm password:** (same password)

#### 4.4 Generate Authentication Token

1. Click on your profile icon (top right corner, letter 'A')
2. Select **"My Account"**
3. Click on the **"Security"** tab
4. Under **"Generate Tokens"**:
   - **Name:** `jenkins`
   - **Type:** Select **"Global Analysis Token"**
   - **Expires in:** Select **"No expiration"**
5. Click **"Generate"**
6. **CRITICAL:** You'll see a token like `squ_xxxxxxxxx`
7. **Copy this tokeny**
8. Save it in a somewhere

---

### Step 5: Create Environment File with Token

#### 5.1 Create `.env` File

In your terminal, run:

```bash
# Make sure you're in the project directory
cd ~/Documents/spring-petclinic

# Create .env file with your token
cat > .env << 'EOF'
SONAR_AUTH_TOKEN=PASTE_YOUR_TOKEN_HERE
EOF
```
**Replace `PASTE_YOUR_TOKEN_HERE` with your actual token from Step 4.4**

Example:

```bash
cat > .env << 'EOF'
SONAR_AUTH_TOKEN=squ_1234567890abcdefghijklmnop
EOF
```

#### 5.2 Verify `.env` File

```bash
# Check the file was created
cat .env
# should be the same as you have
```

#### 5.3 Restart Services to Load Token

```bash
# Stop all services
docker compose down

# Start services again (they'll read the .env file)
docker compose up -d

```

#### 5.4 Verify Token Was Loaded

```bash
# Check if Jenkins has the environment variable
docker exec jenkins env | grep SONAR_AUTH_TOKEN

# You should see:
# SONAR_AUTH_TOKEN=squ_your_actual_token
```

---

### Step 6: Configure Jenkins

#### 6.1 Access Jenkins Web Interface

1. Open your web browser
2. Go to: **http://localhost:8082/jenkins**
3. You'll see "Unlock Jenkins" page

#### 6.2 Get Initial Admin Password

In your terminal, run:

```bash
# Get the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Expected output:** A long string like `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

1. Copy this password
2. Paste it into the Jenkins "Administrator password" 

#### 6.3 Install Plugins

1. Select **"Install suggested plugins"**

#### 6.4 Instance Configuration

1. **Jenkins URL:** Keep default `http://localhost:8082/jenkins/`
2. Click **"Save and Finish"**
3. Click **"Start using Jenkins"**

#### 6.5 Configure SonarQube Server in Jenkins

**Option A: Verify Automatic Configuration (Recommended)**

1. Go to **"Manage Jenkins"** (left sidebar)
2. Click **"Configure System"**
3. Scroll down to **"SonarQube servers"** section
4. You should see:
   - Name: `SonarQubeServer`
   - Server URL: `http://sonarqube:9000`
   - Server authentication token: `sonar-token`

If you see this, **skip to next**. If not, continue with Option B.

**Option B: Manual Configuration**

1. Go to **"Manage Jenkins"** → **"Configure System"**
2. Scroll to **"SonarQube servers"**
3. Click **"Add SonarQube"**
4. Fill in:
   - **Name:** `SonarQubeServer` 
   - **Server URL:** `http://sonarqube:9000`
   - **Server authentication token:** Click **"Add"** → **"Jenkins"**
5. In the popup:
   - **Kind:** Select **"Secret text"**
   - **Scope:** Global
   - **Secret:** Paste your SonarQube token from Step 4.4
   - **ID:** `sonar-token`
   - **Description:** `SonarQube Authentication Token`
   - Click **"Add"**
6. Select `sonar-token` from the dropdown
7. Click **"Save"** at the bottom

#### 6.6 Verify Tools Configuration

1. Go to **"Manage Jenkins"** → **"Global Tool Configuration"**
2. Verify you see:
   - **Maven installations:** `Maven 3.9.5`
   - **JDK installations:** `JDK 25`

These are auto-configured by `jenkins.yaml`.

---

### Step 7: Create Jenkins Pipeline

#### 7.1 Create New Pipeline Job

1. From Jenkins homepage, click **"New Item"** 
2. Enter item name: `spring-petclinic-pipeline`
3. Select **"Pipeline"**
4. Click **"OK"**

#### 7.2 Configure Pipeline Source

Scroll down to the **"Pipeline"** section:

1. **Definition:** Select **"Pipeline script from SCM"**
2. **SCM:** Select **"Git"**
3. **Repository URL:** Enter your repository URL
   - Example: `https://github.com/rosannadeng/spring-petclinic.git`
4. **Credentials:** Leave as **"- none -"** (for public repos)
5. **Branch Specifier:** `*/main` 
6. **Script Path:** `Jenkinsfile`
7. Click **"Save"**

---

### Step 8: Run Your First Build

#### 8.1 Trigger Build

1. Click **"Build Now"** (left sidebar)
2. You'll see a build appear in **"Build History"**
3. Click on the build number (e.g., **#1**)

#### 8.2 Watch Build Progress

**Option A: Classic View**

- Click on the build number
- Click **"Console Output"** to see real-time logs

**Option B: Blue Ocean (Recommended)**

- Click **"Open Blue Ocean"** (left sidebar)
- You'll see a visual pipeline with stages

#### 8.3 Build Stages

The pipeline will execute these stages (takes 15-20 minutes on first run):

1. **Checkout** - Downloads code from Git
2. **Build (Java 25)** - Compiles the application
3. **Test (Java 25)** - Runs unit tests
4. **SonarQube Analysis** - Analyzes code quality
5. **Quality Gate** - Waits for SonarQube results
6. **Checkstyle** - Checks code style
7. **Package** - Creates JAR file
8. **Archive** - Saves artifacts
9. **OWASP ZAP Scan** - Security scanning
10. **Publish ZAP Report** - Publishes security report

#### 8.4 Monitor Build

```bash
# In another terminal, watch Jenkins logs
docker logs -f jenkins

# Watch SonarQube logs
docker logs -f sonarqube
```

---

### Step 9: View Results

#### 9.1 View SonarQube Analysis

1. Go to **http://localhost:9000**
2. Click on **"spring-petclinic"** project
3. View:
   - **Bugs:** Code issues that could cause errors
   - **Vulnerabilities:** Security issues
   - **Code Smells:** Maintainability issues
   - **Coverage:** Test coverage percentage
   - **Duplications:** Duplicate code

#### 9.2 View OWASP ZAP Security Report

1. In Jenkins, click on your job
2. Click **"OWASP ZAP Security Report"** (left sidebar)

#### 9.4 View Test Results

1. In Jenkins build page
2. Click **"Test Result"** (left sidebar)
3. See:
   - Total tests
   - Passed tests
   - Failed tests
   - Test duration

#### 9.5 View Code Coverage

1. In Jenkins build page
2. Click **"Coverage Report"** (left sidebar)
3. See JaCoCo coverage report with line/branch coverage

---

**Symptoms:** Jenkins container keeps restarting

**Solution:**

## Understanding the Pipeline

### What Each Stage Does

1. **Checkout**

   - Downloads code from Git repository

2. **Build (Java 25)**

   - Compiles Java source code
   - Downloads Maven dependencies (slow on first run)

3. **Test (Java 25)**

   - Runs JUnit tests
   - Generates test reports

4. **SonarQube Analysis**

   - Analyzes code quality
   - Finds bugs, vulnerabilities, code smells
   - Calculates test coverage

5. **Quality Gate**

   - Waits for SonarQube to finish processing
   - Checks if code meets quality standards
   - Fails build if quality gate fails

6. **Checkstyle**

   - Checks code formatting and style
   - Generates warnings for style violations

7. **Package**

   - Creates executable JAR file

8. **Archive**

   - Saves JAR file as Jenkins artifact

9. **OWASP ZAP Scan**

   - Starts application in Docker
   - Scans for security vulnerabilities
   - Tests for common web vulnerabilities (XSS, SQL injection, etc.)

10. **Publish ZAP Report**
    - Makes security report available in Jenkins

### Total Build Time

- **First build:** 15-20 minutes (downloading dependencies)
- **Subsequent builds:** 5-10 minutes

---

## Additional Resources

### Access URLs

- **Jenkins:** http://localhost:8082/jenkins
- **SonarQube:** http://localhost:9000
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000
- **Application (when running):** http://localhost:8080

### Default Credentials

| Service   | Username     | Password                      |
| --------- | ------------ | ----------------------------- |
| SonarQube | admin        | admin (change on first login) |
| Grafana   | admin        | admin                         |
| Jenkins   | (you create) | (you create)                  |

### Documentation

- Jenkins: https://www.jenkins.io/doc/
- SonarQube: https://docs.sonarqube.org/
- OWASP ZAP: https://www.zaproxy.org/docs/
- Docker Compose: https://docs.docker.com/compose/

