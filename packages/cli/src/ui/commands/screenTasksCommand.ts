/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { SlashCommand } from './types.js';
import { execSync } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import chalk from 'chalk';

interface ValidationRules {
  [status: string]: string[];
}

interface TaskValidationResult {
  taskId: string;
  taskSummary: string;
  validations: {
    [rule: string]: {
      passed: boolean;
      message: string;
    };
  };
}

export const screenTasksCommand: SlashCommand = {
  name: 'screen-tasks',
  description: 'Validate Jira tasks based on project validation rules. Usage: /screen-tasks <PROJECT_HANDLE>',
  action: async (context, args) => {
    const projectHandle = args.trim();
    
    if (!projectHandle) {
      return { 
        type: 'message', 
        messageType: 'error', 
        content: 'Usage: /screen-tasks <PROJECT_HANDLE>\n\nExample: /screen-tasks GP' 
      };
    }

    // Check if validation file exists
    const validationFilePath = join(process.cwd(), 'settings', `${projectHandle}_validation.json`);
    
    if (!existsSync(validationFilePath)) {
      return {
        type: 'message',
        messageType: 'error',
        content: 'Please create validation rules for this project'
      };
    }

    let validationRules: ValidationRules;
    try {
      const fileContent = readFileSync(validationFilePath, 'utf-8');
      validationRules = JSON.parse(fileContent);
    } catch (error) {
      return {
        type: 'message',
        messageType: 'error',
        content: `Error reading validation file: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }

    const results: { [status: string]: TaskValidationResult[] } = {};

    // Process each status in the validation rules
    for (const [status, rules] of Object.entries(validationRules)) {
      const query = `project = ${projectHandle} AND status WAS '${status}' AND status NOT IN ('${status}', 'Done')`;
      
      try {
        // Get tasks that transitioned from this status
        const listOutput = execSync(`jira list --query="${query}"`, { encoding: 'utf-8' }).trim();
        
        if (!listOutput) {
          continue; // No tasks found for this status
        }

        const taskLines = listOutput.split('\n').filter(line => line.trim());
        const taskResults: TaskValidationResult[] = [];

        for (const taskLine of taskLines) {
          const match = taskLine.match(/^([\w-]+):\s+(.+)$/);
          if (!match) continue;

          const [, taskId, taskSummary] = match;
          const validations: TaskValidationResult['validations'] = {};

          // Get task details in JSON format
          const taskJson = JSON.parse(
            execSync(`jira view ${taskId} --template=json`, { encoding: 'utf-8' })
          );

          // Run each validation rule
          for (const rule of rules) {
            validations[rule] = await validateRule(rule, taskId, taskJson);
          }

          taskResults.push({
            taskId,
            taskSummary,
            validations
          });
        }

        if (taskResults.length > 0) {
          results[status] = taskResults;
        }
      } catch (error) {
        console.error(`Error processing status ${status}: ${error}`);
      }
    }

    // Generate output table
    return {
      type: 'message',
      messageType: 'info',
      content: generateResultTable(results, validationRules)
    };
  },
};

async function validateRule(rule: string, taskId: string, taskJson: any): Promise<{ passed: boolean; message: string }> {
  switch (rule) {
    case 'comment_count_at_least_one': {
      const commentCount = taskJson.fields?.comment?.comments?.length || 0;
      return {
        passed: commentCount > 0,
        message: commentCount > 0 ? `${commentCount} comments` : 'No comments'
      };
    }

    case 'description_not_empty': {
      const description = taskJson.fields?.description;
      const hasDescription = description !== null && description !== undefined && description.trim() !== '';
      return {
        passed: hasDescription,
        message: hasDescription ? 'Has description' : 'Empty'
      };
    }

    case 'original_estimate_not_empty': {
      const originalEstimate = taskJson.fields?.timetracking?.originalEstimate;
      const hasEstimate = originalEstimate !== null && originalEstimate !== undefined;
      return {
        passed: hasEstimate,
        message: hasEstimate ? originalEstimate : 'Not set'
      };
    }

    case 'worklog_not_empty': {
      try {
        const worklogOutput = execSync(`jira worklog list ${taskId}`, { encoding: 'utf-8' }).trim();
        const hasWorklog = worklogOutput.length > 0;
        
        if (hasWorklog) {
          // Count worklogs
          const worklogCount = worklogOutput.split('\n').filter(line => line.startsWith('- #')).length;
          return {
            passed: true,
            message: `${worklogCount} entries`
          };
        }
        
        return {
          passed: false,
          message: 'No entries'
        };
      } catch (error) {
        return {
          passed: false,
          message: 'Error checking'
        };
      }
    }

    default:
      return {
        passed: false,
        message: 'Unknown rule'
      };
  }
}

function generateResultTable(results: { [status: string]: TaskValidationResult[] }, validationRules: ValidationRules): string {
  if (Object.keys(results).length === 0) {
    return 'No tasks found for validation';
  }

  let output = '';
  
  for (const [status, taskResults] of Object.entries(results)) {
    output += chalk.bold.underline(`\nStatus: ${status}\n`);
    
    // Create table header
    const rules = validationRules[status];
    const columnWidths: { [key: string]: number } = {
      taskId: 10,
      ...Object.fromEntries(rules.map(rule => [rule, Math.max(rule.length + 2, 20)]))
    };

    // Header row
    output += '┌' + '─'.repeat(columnWidths.taskId) + '┬';
    output += rules.map(rule => '─'.repeat(columnWidths[rule])).join('┬') + '┐\n';
    
    output += '│' + ' Task ID'.padEnd(columnWidths.taskId) + '│';
    output += rules.map(rule => ` ${rule}`.padEnd(columnWidths[rule])).join('│') + '│\n';
    
    output += '├' + '─'.repeat(columnWidths.taskId) + '┼';
    output += rules.map(rule => '─'.repeat(columnWidths[rule])).join('┼') + '┤\n';

    // Data rows
    for (const task of taskResults) {
      output += '│' + ` ${task.taskId}`.padEnd(columnWidths.taskId) + '│';
      
      for (const rule of rules) {
        const validation = task.validations[rule];
        const icon = validation.passed ? chalk.green('✓') : chalk.red('✗');
        const message = validation.passed ? chalk.green(validation.message) : chalk.red(validation.message);
        const content = ` ${icon} ${message}`;
        
        // Truncate if too long
        const maxLength = columnWidths[rule] - 2;
        const displayContent = content.length > maxLength ? content.substring(0, maxLength - 3) + '...' : content;
        output += displayContent.padEnd(columnWidths[rule]) + '│';
      }
      
      output += '\n';
    }

    // Bottom border
    output += '└' + '─'.repeat(columnWidths.taskId) + '┴';
    output += rules.map(rule => '─'.repeat(columnWidths[rule])).join('┴') + '┘\n';
  }

  // Summary
  const totalTasks = Object.values(results).reduce((sum, tasks) => sum + tasks.length, 0);
  let failedValidations = 0;
  let passedValidations = 0;

  for (const taskResults of Object.values(results)) {
    for (const task of taskResults) {
      for (const validation of Object.values(task.validations)) {
        if (validation.passed) {
          passedValidations++;
        } else {
          failedValidations++;
        }
      }
    }
  }

  output += `\n${chalk.bold('Summary:')} ${totalTasks} tasks validated`;
  output += ` | ${chalk.green(`✓ ${passedValidations} passed`)}`;
  output += ` | ${chalk.red(`✗ ${failedValidations} failed`)}`;

  return output;
}