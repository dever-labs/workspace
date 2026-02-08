# Contributing to Workspace

Thank you for your interest in contributing to Workspace! This project aims to provide containerized development environments that help developers work freely and efficiently.

## 🎯 Ways to Contribute

- **Report Bugs** - Found an issue? Let us know!
- **Suggest Features** - Have ideas for improvements? We'd love to hear them!
- **Improve Documentation** - Help make our docs clearer and more comprehensive
- **Submit Code** - Fix bugs, add features, or optimize existing code
- **Share Your Setup** - Show how you're using the workspace in your environment

## 🐛 Reporting Issues

When reporting issues, please include:

1. **Environment details:**
   - OS and version (Windows 11, Ubuntu 22.04, etc.)
   - Docker version (`docker --version`)
   - Docker Desktop or Docker Engine
   - GPU model (if using Sunshine/GPU features)

2. **Steps to reproduce:**
   - What commands did you run?
   - What configuration did you use?
   - What was expected vs. what happened?

3. **Logs:**
   ```bash
   docker compose logs
   docker logs devworkstation
   ```

4. **Configuration:**
   - Relevant `.env` settings
   - Which compose files you're using
   - Any customizations made

## 💡 Suggesting Features

Before suggesting a feature:

1. Check existing issues to avoid duplicates
2. Explain the use case - what problem does it solve?
3. Consider if it fits the project's scope
4. Think about backward compatibility

## 🔧 Development Setup

### Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Git
- Basic knowledge of Docker and containers
- For documentation: Markdown editor

### Getting Started

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then:
   git clone https://github.com/YOUR-USERNAME/workspace.git
   cd workspace
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make your changes**
   - Follow the existing code style
   - Test your changes thoroughly
   - Update documentation as needed

4. **Test locally**
   ```bash
   cd src/ubuntu
   docker compose down
   docker compose up -d --build
   
   # Test the changes
   # Connect via RDP, SSH, or Sunshine
   
   # Check logs
   docker compose logs -f
   ```

## 📝 Code Guidelines

### Dockerfile Changes

- Keep layers minimal and efficient
- Use specific package versions when stability is critical
- Clean up apt cache after installations
- Comment complex sections
- Test on clean Docker environment

### Compose Files

- `compose.yaml` - Base configuration (runs everywhere)
- `compose.override.yaml` - Local development only
- `compose.remote.yaml` - Remote VM deployment
- Keep environment variables documented in `.env.example`

### Scripts

- Use clear, descriptive variable names
- Add error handling
- Include usage examples in comments
- Test on both Windows PowerShell and Linux Bash (when applicable)

### Documentation

- Use clear, concise language
- Include code examples
- Add screenshots for UI-related features
- Update README.md if adding new features
- Keep documentation structure consistent

## 🧪 Testing

Before submitting:

1. **Build successfully:**
   ```bash
   docker compose build
   ```

2. **Start containers:**
   ```bash
   docker compose up -d
   ```

3. **Verify functionality:**
   - RDP connection works
   - Services start properly
   - No errors in logs
   - GPU features work (if applicable)

4. **Test different scenarios:**
   - Clean install
   - Upgrade from previous version
   - Different configurations

## 📤 Submitting Changes

### Pull Request Process

1. **Update documentation**
   - README.md for user-facing changes
   - Code comments for complex logic
   - CHANGELOG.md if applicable

2. **Commit messages**
   Follow conventional commits:
   ```
   feat: add X2Go support for better performance
   fix: resolve NVENC detection issue on Windows
   docs: update Sunshine setup guide
   chore: update dependencies
   ```

3. **Create pull request**
   - Use a clear, descriptive title
   - Reference related issues (#123)
   - Describe what changed and why
   - Include testing performed
   - Add screenshots/logs if relevant

4. **Code review**
   - Be open to feedback
   - Respond to comments
   - Make requested changes
   - Keep PR focused on one thing

### Pull Request Template

```markdown
## Description
Brief description of what this PR does.

## Motivation
Why is this change needed? What problem does it solve?

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing Performed
- [ ] Tested on Windows Docker Desktop
- [ ] Tested on Linux Docker Engine
- [ ] Tested GPU features (if applicable)
- [ ] Documentation updated
- [ ] No breaking changes

## Related Issues
Fixes #123
Related to #456

## Screenshots/Logs
(if applicable)
```

## 🏗️ Project Structure

```
workspace/
├── README.md              # Main documentation
├── LICENSE               # MIT License
├── CONTRIBUTING.md       # This file
└── src/
    └── ubuntu/           # Ubuntu dev workstation
        ├── Dockerfile            # Container image definition
        ├── compose.yaml          # Base configuration
        ├── compose.override.yaml # Local development
        ├── compose.remote.yaml   # Remote VM deployment
        ├── entrypoint.sh         # Container startup script
        ├── README.md             # Ubuntu workstation docs
        ├── SUNSHINE_SETUP.md     # Sunshine/Moonlight guide
        └── k8s/                  # Kubernetes manifests
```

## 🎨 Adding New Features

### Example: Adding a New Development Tool

1. **Update Dockerfile:**
   ```dockerfile
   RUN apt-get update && apt-get install -y \
       new-tool \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
   ```

2. **Document in README:**
   - Add to "Installed Tools" section
   - Update any relevant guides

3. **Test thoroughly:**
   - Build fresh image
   - Verify tool works
   - Check for conflicts

### Example: Adding a New Remote Access Method

1. **Install in Dockerfile**
2. **Add startup logic to entrypoint.sh**
3. **Add environment variable to .env.example**
4. **Document setup in README**
5. **Add troubleshooting section**

## 🔒 Security Considerations

- Never commit secrets or passwords
- Use environment variables for sensitive data
- Review security implications of new packages
- Test permission boundaries
- Document security requirements

## ❓ Questions?

- Open an issue for questions
- Check existing issues and discussions
- Review documentation thoroughly first

## 📜 Code of Conduct

Be respectful, constructive, and collaborative. This project aims to help developers, and we value contributions from everyone regardless of experience level.

## 🎓 Learning Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Sunshine Documentation](https://docs.lizardbyte.dev/projects/sunshine/)

## 🙏 Thank You!

Every contribution, no matter how small, helps make this project better. Thank you for taking the time to contribute!

---

**Ready to contribute?** Fork the repo, make your changes, and submit a PR. We're excited to see what you build! 🚀
