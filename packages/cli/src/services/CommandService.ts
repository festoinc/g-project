/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { Config } from '@google/gemini-cli-core';
import { SlashCommand } from '../ui/commands/types.js';
import { clearCommand } from '../ui/commands/clearCommand.js';
import { authCommand } from '../ui/commands/authCommand.js';
import { themeCommand } from '../ui/commands/themeCommand.js';
import { statsCommand } from '../ui/commands/statsCommand.js';
import { compressCommand } from '../ui/commands/compressCommand.js';
import { quitCommand } from '../ui/commands/quitCommand.js';
import { toolsCommand } from '../ui/commands/toolsCommand.js';
import { screenTasksCommand } from '../ui/commands/screenTasksCommand.js';
import { existsSync } from 'fs';
import { join } from 'path';
import { readdirSync } from 'fs';

const loadBuiltInCommands = async (
  _config: Config | null,
): Promise<SlashCommand[]> => {
  const commands: (SlashCommand | null)[] = [
    authCommand,
    clearCommand,
    compressCommand,
    quitCommand,
    statsCommand,
    themeCommand,
    toolsCommand,
  ];

  // Only add screenTasksCommand if validation files exist
  const settingsPath = join(process.cwd(), 'settings');
  if (existsSync(settingsPath)) {
    try {
      const files = readdirSync(settingsPath);
      const hasValidationFiles = files.some(file => file.endsWith('_validation.json'));
      if (hasValidationFiles) {
        commands.push(screenTasksCommand);
      }
    } catch (error) {
      // Ignore errors reading directory
    }
  }

  return commands.filter(
    (command): command is SlashCommand => command !== null,
  );
};

export class CommandService {
  private commands: SlashCommand[] = [];

  constructor(
    private config: Config | null,
    private commandLoader: (
      config: Config | null,
    ) => Promise<SlashCommand[]> = loadBuiltInCommands,
  ) {
    // The constructor can be used for dependency injection in the future.
  }

  async loadCommands(): Promise<void> {
    // For now, we only load the built-in commands.
    // File-based and remote commands will be added later.
    this.commands = await this.commandLoader(this.config);
  }

  getCommands(): SlashCommand[] {
    return this.commands;
  }
}
