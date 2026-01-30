# DokPloy Deployment Guide

This repository is configured to deploy with **DokPloy** using a **Dockerfile (recommended)**. The previous Nixpacks configuration is still included for compatibility.

## 🚀 Quick Deploy

### 1. Prerequisites
- A DokPloy instance running
- Docker and Docker Compose installed on the host (required for Supabase project management)
- SMTP credentials for email functionality

### 2. DokPloy Configuration

#### Step 1: Create New Application
1. In DokPloy, create a new application
2. Connect your Git repository
3. Select **Dockerfile** as the build provider

#### Step 2: Environment Variables
Configure the following environment variables in DokPloy:

**Required:**
```env
# Database
DATABASE_URL=file:/app/data/db.sqlite

# Authentication (IMPORTANT: Generate a secure random string)
NEXTAUTH_SECRET=<generate-a-secure-random-string>
NEXTAUTH_URL=https://your-domain.com

# SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Supabase Core Repository
SUPABASE_CORE_REPO_URL=git clone --depth 1 https://github.com/supabase/supabase

# Application
APP_NAME=SupaConsole Dashboard
APP_URL=https://your-domain.com
```

**Generating NEXTAUTH_SECRET:**
```bash
openssl rand -base64 32
```

#### Step 3: Persistent Storage
Configure a volume mount in DokPloy for persistent data:
- **Mount Path:** `/app/data`
- **Purpose:** SQLite database storage
- **Size:** 1-5 GB recommended

Optional volumes for Supabase projects:
- **Mount Path:** `/app/supabase-core`
- **Mount Path:** `/app/supabase-projects`

#### Step 4: Port Configuration
- **Container Port:** `3000`
- DokPloy will automatically proxy this to your domain

#### Step 5: Docker Socket Access
This application manages Docker containers for Supabase projects. You need to:

**Option A: Docker Socket Mount (Recommended for single-server deployments)**
- Mount `/var/run/docker.sock` from host to container
- In DokPloy advanced settings, add volume: `/var/run/docker.sock:/var/run/docker.sock`

**Option B: Docker-in-Docker (More isolated)**
- Use a privileged container
- This requires enabling privileged mode in DokPloy

⚠️ **Security Note:** Docker socket access gives the container significant host permissions. Only use in trusted environments.

### 3. Build Configuration

This repository includes a production-ready `Dockerfile` that:

- Installs system dependencies required by Prisma (OpenSSL)
- Installs Git and Curl (used by the app) and the Docker CLI + Compose plugin
- Generates the Prisma client and builds the Next.js app
- Runs `prisma db push` on container start (without destructive flags)
- Exposes port `3000`

If you prefer not to use the Dockerfile, you can still use the existing Nixpacks config.

**Build Command:**
```bash
npm ci && npx prisma generate && npm run build
```

**Start Command:**
```bash
npx prisma db push && npm start
```

**Environment Variables:** Same as DokPloy configuration above

### 4. Post-Deployment

After deployment:

1. **First Login:** Navigate to `/auth/register` to create your account
2. **Initialize Workspace:** Click "Initialize" on the dashboard to:
   - Clone the Supabase repository
   - Create project directories
3. **Start Creating Projects:** Use the "New Project" button

## 📋 Checklist

- [ ] DokPloy application created with Nixpacks
- [ ] All environment variables configured
- [ ] `NEXTAUTH_SECRET` generated securely
- [ ] Persistent volume for `/app/data` configured
- [ ] Docker socket mounted or Docker-in-Docker enabled
- [ ] SMTP credentials tested and working
- [ ] Domain/URL configured correctly
- [ ] Application deployed successfully
- [ ] First user registered at `/auth/register`
- [ ] Workspace initialized

## 🔧 Troubleshooting

### Database Issues
- Ensure `/app/data` volume is properly mounted
- Check `DATABASE_URL` points to persistent storage
- Verify write permissions on the volume

### Docker Container Management
- Confirm Docker socket is accessible in container
- Test with: `docker ps` inside the container
- Check DokPloy logs for Docker-related errors

### Build Failures
- Check if all dependencies are installing correctly
- Verify Node.js version compatibility
- Review Prisma generation logs

### SMTP Issues
- Test SMTP credentials before deployment
- For Gmail, use App Passwords, not regular passwords
- Check firewall rules for SMTP ports

## 🔄 Alternative: Railway/Render Configuration

If using other platforms, you can use these settings:

**Build Command:**
```bash
npm ci && npx prisma generate && npm run build
```

**Start Command:**
```bash
npx prisma db push --accept-data-loss && npm start
```

**Environment Variables:** Same as DokPloy configuration above

## 📚 Additional Resources

- [DokPloy Documentation](https://dokploy.com/docs)
- [Nixpacks Documentation](https://nixpacks.com/docs)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Prisma Production Best Practices](https://www.prisma.io/docs/guides/deployment/deployment-guides)
