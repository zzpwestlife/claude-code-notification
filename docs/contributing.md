# Contributing to Claude Code Notification

We welcome contributions! Please follow these guidelines to ensure a smooth process.

## Development Setup

1.  **Clone the repo**:
    ```bash
    git clone https://github.com/yourusername/claude-code-notification.git
    cd claude-code-notification
    ```

2.  **Install dependencies**:
    ```bash
    npm install
    ```

3.  **Run in development mode**:
    ```bash
    npm start -- --message "Test Message"
    ```
    Or use the helper script:
    ```bash
    ./scripts/dev.sh --message "Test Message"
    ```

## Project Structure
We follow a functional directory structure:
- `src/`: Source code
- `tests/`: Test files
- `config/`: Configuration files
- `scripts/`: Helper scripts
- `docs/`: Documentation

## Coding Standards
- Use **ES6+** syntax.
- Follow **CommonJS** module system (currently used).
- Ensure code is formatted cleanly.

## Testing
Run integration tests before submitting a PR:
```bash
npm test
```
Or:
```bash
./scripts/test.sh
```

## Submitting Pull Requests
1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.
