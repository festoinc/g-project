/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import { SlashCommand } from './types.js';

export const startProjectCommand: SlashCommand = {
  name: 'start-project',
  description: 'Initialize project settings at /settings/settings.md with Jira integration. Usage: /start-project <PROJECT_HANDLE> <JIRA_USER>',
  action: async (context, args) => {
    const argsArray = args.trim().split(/\s+/);
    
    if (argsArray.length < 2) {
      return { 
        type: 'message', 
        messageType: 'error', 
        content: 'Usage: /start-project <PROJECT_HANDLE> <JIRA_USER>\n\nExample: /start-project AT john.doe@company.com' 
      };
    }

    const [projectHandle, jiraUser] = argsArray;

    // Create /settings/settings.md
    const settingsPath = '/settings/settings.md';
    
    // Generate LAST_STAND_UP (current time - 24h) in format: 16-Jul-2025 19:24:16
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const day = yesterday.getDate().toString().padStart(2, '0');
    const month = monthNames[yesterday.getMonth()];
    const year = yesterday.getFullYear();
    const hours = yesterday.getHours().toString().padStart(2, '0');
    const minutes = yesterday.getMinutes().toString().padStart(2, '0');
    const seconds = yesterday.getSeconds().toString().padStart(2, '0');
    
    const lastStandUp = `${day}-${month}-${year} ${hours}:${minutes}:${seconds}`;

    // Create settings content for /settings/settings.md
    const settingsContent = `# Project Settings

PROJECT_HANDLE=${projectHandle}
JIRA_USER=${jiraUser}
LAST_STAND_UP=${lastStandUp}
`;

    // Use the write_file tool to create the settings file
    return {
      type: 'tool',
      toolName: 'write_file',
      toolArgs: {
        file_path: settingsPath,
        content: settingsContent
      }
    };
  },
};