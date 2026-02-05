# Project Structure

```
claude-code-notification/
├── assets/                  # Static assets (images, fonts, icons, videos)
│   ├── fonts/
│   ├── icons/
│   ├── images/
│   └── videos/
├── config/                  # Configuration files
│   ├── .env.dev             # Development environment variables
│   ├── .env.prod            # Production environment variables
│   ├── .env.staging         # Staging environment variables
│   └── .env.example         # Example environment variables template
├── docs/                    # Documentation
│   ├── architecture.md      # System architecture overview
│   ├── contributing.md      # Contribution guidelines
│   ├── deployment.md        # Deployment and installation guide
│   └── modules/             # Module-specific documentation
├── scripts/                 # Utility scripts (cross-platform)
│   ├── build.sh             # Build script (placeholder)
│   ├── clean.sh             # Cleanup script
│   ├── dev.sh               # Development runner
│   ├── lint.sh              # Linting script
│   ├── setup.sh             # Project setup script
│   └── test.sh              # Test runner
├── src/                     # Source code
│   ├── index.js             # Application entry point
│   ├── modules/             # Functional modules
│   │   ├── feishu/          # Feishu integration module
│   │   │   └── client.js    # Feishu API client
│   │   └── notification/    # Notification logic
│   │   │   └── manager.js   # Notification manager
│   ├── scripts/             # Internal scripts
│   │   └── setup-wizard.js  # Interactive setup wizard
│   └── shared/              # Shared utilities and config
│       └── config/          # Configuration logic
│           └── env.js       # Environment variable loader
├── tests/                   # Tests
│   └── integration/         # Integration tests
│       └── quick-install.test.sh
├── CLAUDE.md                # Claude Code specific instructions
├── package.json             # Node.js project manifest
├── quick-install.sh         # One-click install script (macOS/Linux)
├── quick-install.bat        # One-click install script (Windows)
└── README.md                # Project README
```
