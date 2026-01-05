# Pre-Commit Hook Setup

This project includes a pre-commit hook that automatically runs code formatting and analysis before each commit.

## What the Hook Does

The pre-commit hook performs the following checks:
1. **Code Formatting** - Runs `dart format` to ensure code is properly formatted
2. **Code Analysis** - Runs `flutter analyze` to check for errors and warnings
3. **Tests** (optional) - Can be enabled to run tests before committing

## Installation

### On Windows (PowerShell/Git Bash)

```powershell
# From the project root directory
copy pre-commit .git\hooks\pre-commit
```

Or using Git Bash:
```bash
cp pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### On macOS/Linux

```bash
# From the project root directory
cp pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Enabling Tests in Pre-Commit

By default, the tests are commented out to speed up commits. To enable them:

1. Open `.git/hooks/pre-commit` in a text editor
2. Uncomment the test section (remove the `#` at the start of lines 26-31)
3. Save the file

## Bypassing the Hook

If you need to bypass the pre-commit hook for a specific commit:

```bash
git commit --no-verify -m "your commit message"
```

**Note:** Only bypass the hook when absolutely necessary, as it helps maintain code quality.

## Troubleshooting

### Hook not running
- Make sure the hook file is executable: `chmod +x .git/hooks/pre-commit`
- Verify the file is in the correct location: `.git/hooks/pre-commit`

### Permission errors on Windows
- Run Git Bash as administrator when copying the hook file
- Or manually copy the `pre-commit` file to `.git\hooks\` using File Explorer

### Format/analyze failures
- Run `dart format frontend` to format all code
- Run `cd frontend && flutter analyze` to see analysis issues
- Fix all issues before attempting to commit again
