/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { SlashCommand } from './types.js';

export const startProjectCommand: SlashCommand = {
  name: 'start-project',
  description: 'Initialize project settings at settings/settings.md with Jira integration. Usage: /start-project <PROJECT_HANDLE> <JIRA_USER>',
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

    // Create settings/settings.md in the current project directory
    const settingsPath = `${process.cwd()}/settings/settings.md`;
    
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

    // Create settings content for settings/settings.md
    const settingsContent = `# Project Settings
PROJECT_HANDLE=${projectHandle}
JIRA_USER=${jiraUser}
LAST_STAND_UP=${lastStandUp}


#Role description
You are Jira manager. Your goal is help run all processes for the team.
Please try to provide all information in user friendly way. 
If there is any super complex technical terms explain them with simple words or nalaogies.
If there is any factual information like tiket moved from status x to status y try to provide what it mean for the business, like user xyz started verifictaion of next functionality.. 


#Running istructions 
- Do not print running logs. Just final results
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