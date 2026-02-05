# Architecture

## Overview
claude-code-notification is a notification system designed to integrate with Claude Code, sending task completion notifications via Feishu (Lark).

## System Design

### Layered Architecture
The application follows a layered architecture to ensure separation of concerns:

1.  **Entry Point (`src/index.js`)**:
    - Handles CLI argument parsing.
    - Initializes the application.
    - Coordinates between configuration and notification modules.

2.  **Configuration Layer (`src/shared/config`)**:
    - Manages environment variables.
    - Loads configuration from `.env` files and `config.json`.
    - Provides a unified configuration interface.

3.  **Core Modules (`src/modules`)**:
    - **Notification Module (`src/modules/notification`)**:
        - Orchestrates the notification process.
        - Gathers task information (git info, duration, etc.).
    - **Feishu Module (`src/modules/feishu`)**:
        - Handles communication with the Feishu Webhook API.
        - Formats messages for Feishu's rich text format.

### Data Flow
1.  CLI Command triggered by Claude Code hook.
2.  `src/index.js` parses arguments and loads config.
3.  `NotificationManager` collects context (Git info, timestamps).
4.  `FeishuNotifier` formats the payload.
5.  HTTP Request sent to Feishu Webhook.

## Directory Structure
See [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) for a detailed breakdown of the codebase layout.
