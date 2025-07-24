/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { SlashCommand } from './types.js';
import { execSync } from 'child_process';

export const getToKnowMyProjectCommand: SlashCommand = {
  name: 'get-to-know-my-project',
  description: 'Get project information including time, statuses, and issue types. Usage: /get-to-know-my-project <PROJECT_HANDLE>',
  action: async (context, args) => {
    const projectHandle = args.trim();
    
    if (!projectHandle) {
      return { 
        type: 'message', 
        messageType: 'error', 
        content: 'Please provide a project handle. Usage: /get-to-know-my-project <PROJECT_HANDLE>\n\nExample: /get-to-know-my-project GP' 
      };
    }

    try {
      // Get server time
      const serverTime = execSync(
        `jira request -M GET "/rest/api/2/serverInfo" | jq -r '.serverTime'`,
        { encoding: 'utf-8' }
      ).trim();

      // Get project statuses
      let statuses: string[] = [];
      try {
        const statusesOutput = execSync(
          `jira request -M GET "/rest/api/2/project/${projectHandle}/statuses" | jq -r '.[].name' | sort | uniq`,
          { encoding: 'utf-8' }
        );
        statuses = statusesOutput.trim().split('\n').filter(Boolean);
      } catch (error) {
        // Project might not exist
        return {
          type: 'message',
          messageType: 'error',
          content: `Ooops seems to be project {${projectHandle}} do not exist`
        };
      }

      // Get issue types from project
      const issueTypesOutput = execSync(
        `jira list --query="project = ${projectHandle}" --template=json | jq -r '.issues[].fields.issuetype.name' | sort | uniq`,
        { encoding: 'utf-8' }
      );
      const issueTypes = issueTypesOutput.trim().split('\n').filter(Boolean);

      // Format output
      let output = `## Project Information: ${projectHandle}\n\n`;
      output += `### Time\n${serverTime}\n\n`;
      
      output += `### Potential Statuses\n`;
      if (statuses.length > 0) {
        statuses.forEach(status => {
          output += `- ${status}\n`;
        });
      } else {
        output += 'No statuses found\n';
      }
      output += '\n';
      
      output += `### Potential Issue Types\n`;
      if (issueTypes.length > 0) {
        issueTypes.forEach(type => {
          output += `- ${type}\n`;
        });
      } else {
        output += 'No issue types found\n';
      }

      return {
        type: 'message',
        messageType: 'info',
        content: output
      };
    } catch (error: any) {
      if (error.message && (error.message.includes('not found') || error.message.includes('404'))) {
        return {
          type: 'message',
          messageType: 'error',
          content: `Ooops seems to be project {${projectHandle}} do not exist`
        };
      }
      return {
        type: 'message',
        messageType: 'error',
        content: `Error getting project information: ${error.message || 'Unknown error'}`
      };
    }
  },
};