# GitHub Repository Setup Guide

Quick guide to publish this AVD demo environment on GitHub.

## 1. Create GitHub Repository

### Option A: Via GitHub Website

1. Go to https://github.com/new
2. Repository name: `avd-demo` (or your preferred name)
3. Description: "Cost-optimized Azure Virtual Desktop demo environment with Azure AD join and SSO"
4. Visibility: Public (or Private)
5. **DON'T** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

### Option B: Via GitHub CLI

```bash
# Install GitHub CLI if needed: https://cli.github.com

# Login
gh auth login

# Create repository
gh repo create avd-demo --public --description "Cost-optimized Azure Virtual Desktop demo environment"
```

## 2. Initialize Local Repository

From the `avd-demo-repo` folder:

```bash
# Initialize git
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Complete AVD demo environment"

# Add remote (replace YOUR-USERNAME)
git remote add origin https://github.com/YOUR-USERNAME/avd-demo.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 3. Configure Repository Settings

### Enable Discussions
1. Go to repository → Settings → General
2. Scroll to "Features"
3. Check "Discussions"
4. Save changes

### Add Topics
1. Go to repository main page
2. Click the gear icon next to "About"
3. Add topics:
   - `azure`
   - `azure-virtual-desktop`
   - `avd`
   - `bicep`
   - `infrastructure-as-code`
   - `azure-ad`
   - `demo`
   - `cost-optimization`

### Create Branch Protection (Optional)
1. Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Include administrators

## 4. Update README

Replace `YOUR-USERNAME` in README.md:

```bash
# Find and replace
sed -i 's/YOUR-USERNAME/actual-username/g' README.md

# Commit the change
git add README.md
git commit -m "Update GitHub username in README"
git push
```

## 5. Enable GitHub Actions

Actions should be enabled by default. Verify:

1. Go to repository → Actions
2. You should see "Validate Bicep Templates" workflow
3. It will run automatically on pushes to `main`

## 6. Create Releases (Optional)

For version tracking:

```bash
# Tag the initial release
git tag -a v1.0.0 -m "Initial release: Complete AVD demo environment"
git push origin v1.0.0
```

Then on GitHub:
1. Go to Releases → Draft a new release
2. Choose tag: v1.0.0
3. Title: "v1.0.0 - Initial Release"
4. Description:
   ```markdown
   Initial release of the AVD demo environment.
   
   Features:
   - Azure AD join with SSO
   - Cost-optimized with B-series VMs
   - Start VM on Connect
   - Complete documentation
   - Automated deployment scripts
   ```
5. Publish release

## 7. Add Badges (Optional)

Add to top of README.md:

```markdown
[![Validate Bicep](https://github.com/YOUR-USERNAME/avd-demo/actions/workflows/validate.yml/badge.svg)](https://github.com/YOUR-USERNAME/avd-demo/actions/workflows/validate.yml)
[![GitHub](https://img.shields.io/github/license/YOUR-USERNAME/avd-demo)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/YOUR-USERNAME/avd-demo)](https://github.com/YOUR-USERNAME/avd-demo/stargazers)
```

## 8. Create Deploy to Azure Button (Optional)

The template already has the button, but you need to:

1. Convert Bicep to ARM JSON:
   ```bash
   az bicep build --file bicep/main.bicep --outfile azuredeploy.json
   ```

2. Commit the JSON file:
   ```bash
   git add azuredeploy.json
   git commit -m "Add ARM template for Deploy to Azure button"
   git push
   ```

3. The button in README will now work!

## 9. Promote Your Repository

### Share on Social Media
- LinkedIn
- Twitter
- Dev.to
- Reddit (r/Azure, r/sysadmin)

### Submit to Awesome Lists
- [Awesome Azure](https://github.com/kristofferandreasen/awesome-azure)
- [Awesome Bicep](https://github.com/ElYusubov/AWESOME-Azure-Bicep)

### Write a Blog Post
Document your journey creating this project

## 10. Maintain the Repository

### Regular Updates
- Update Bicep API versions
- Update documentation
- Add new features based on feedback
- Respond to issues

### Good First Issues
Label some issues as "good first issue" for new contributors

### Community Management
- Respond to issues promptly
- Review pull requests
- Thank contributors
- Update CHANGELOG for each release

## Repository Structure Checklist

✅ README.md with badges and clear instructions  
✅ LICENSE file  
✅ .gitignore file  
✅ CONTRIBUTING.md  
✅ Complete Bicep templates  
✅ Deployment scripts (PowerShell + Bash)  
✅ Comprehensive documentation  
✅ GitHub Actions workflow  
✅ Examples and troubleshooting  

## Example Commit Message Format

```
feat: Add auto-scaling support
fix: Resolve SSO configuration issue
docs: Update troubleshooting guide
chore: Update Bicep API versions
```

## Your Repository is Ready! 🎉

You now have a professional, well-documented GitHub repository that others can use to deploy AVD environments.

**Next Steps:**
1. Star your own repository (it counts! 😄)
2. Share it with the community
3. Wait for feedback and contributions
4. Keep improving!

---

**Questions?** Create a GitHub Discussion in your repository.
