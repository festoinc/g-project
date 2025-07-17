/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import { vi, describe, it, expect, beforeEach, type Mocked } from 'vitest';
import { CommandService } from './CommandService.js';
import { type Config } from '@google/gemini-cli-core';
import { type SlashCommand } from '../ui/commands/types.js';
import { clearCommand } from '../ui/commands/clearCommand.js';
import { authCommand } from '../ui/commands/authCommand.js';
import { themeCommand } from '../ui/commands/themeCommand.js';
import { statsCommand } from '../ui/commands/statsCommand.js';
import { compressCommand } from '../ui/commands/compressCommand.js';
import { quitCommand } from '../ui/commands/quitCommand.js';

// Mock the command modules to isolate the service from the command implementations.
vi.mock('../ui/commands/clearCommand.js', () => ({
  clearCommand: { name: 'clear', description: 'Mock Clear' },
}));
vi.mock('../ui/commands/authCommand.js', () => ({
  authCommand: { name: 'auth', description: 'Mock Auth' },
}));
vi.mock('../ui/commands/themeCommand.js', () => ({
  themeCommand: { name: 'theme', description: 'Mock Theme' },
}));
vi.mock('../ui/commands/statsCommand.js', () => ({
  statsCommand: { name: 'stats', description: 'Mock Stats' },
}));
vi.mock('../ui/commands/compressCommand.js', () => ({
  compressCommand: { name: 'compress', description: 'Mock Compress' },
}));
vi.mock('../ui/commands/quitCommand.js', () => ({
  quitCommand: { name: 'quit', description: 'Mock Quit' },
}));

describe('CommandService', () => {
  const subCommandLen = 6;
  let mockConfig: Mocked<Config>;

  beforeEach(() => {
    mockConfig = {
      getIdeMode: vi.fn(),
    } as unknown as Mocked<Config>;
  });

  describe('when using default production loader', () => {
    let commandService: CommandService;

    beforeEach(() => {
      commandService = new CommandService(mockConfig);
    });

    it('should initialize with an empty command tree', () => {
      const tree = commandService.getCommands();
      expect(tree).toBeInstanceOf(Array);
      expect(tree.length).toBe(0);
    });

    describe('loadCommands', () => {
      it('should load the built-in commands into the command tree', async () => {
        // Pre-condition check
        expect(commandService.getCommands().length).toBe(0);

        // Action
        await commandService.loadCommands();
        const tree = commandService.getCommands();

        // Post-condition assertions
        expect(tree.length).toBe(subCommandLen);

        const commandNames = tree.map((cmd) => cmd.name);
        expect(commandNames).toContain('auth');
        expect(commandNames).toContain('clear');
        expect(commandNames).toContain('theme');
        expect(commandNames).toContain('stats');
        expect(commandNames).toContain('compress');
        expect(commandNames).toContain('quit');
      });


      it('should overwrite any existing commands when called again', async () => {
        // Load once
        await commandService.loadCommands();
        expect(commandService.getCommands().length).toBe(subCommandLen);

        // Load again
        await commandService.loadCommands();
        const tree = commandService.getCommands();

        // Should not append, but overwrite
        expect(tree.length).toBe(subCommandLen);
      });
    });

    describe('getCommandTree', () => {
      it('should return the current command tree', async () => {
        const initialTree = commandService.getCommands();
        expect(initialTree).toEqual([]);

        await commandService.loadCommands();

        const loadedTree = commandService.getCommands();
        expect(loadedTree.length).toBe(subCommandLen);
        expect(loadedTree).toEqual([
          authCommand,
          clearCommand,
          compressCommand,
          quitCommand,
          statsCommand,
          themeCommand,
        ]);
      });
    });
  });

  describe('when initialized with an injected loader function', () => {
    it('should use the provided loader instead of the built-in one', async () => {
      // Arrange: Create a set of mock commands.
      const mockCommands: SlashCommand[] = [
        { name: 'injected-test-1', description: 'injected 1' },
        { name: 'injected-test-2', description: 'injected 2' },
      ];

      // Arrange: Create a mock loader FUNCTION that resolves with our mock commands.
      const mockLoader = vi.fn().mockResolvedValue(mockCommands);

      // Act: Instantiate the service WITH the injected loader function.
      const commandService = new CommandService(mockConfig, mockLoader);
      await commandService.loadCommands();
      const tree = commandService.getCommands();

      // Assert: The tree should contain ONLY our injected commands.
      expect(mockLoader).toHaveBeenCalled(); // Verify our mock loader was actually called.
      expect(tree.length).toBe(2);
      expect(tree).toEqual(mockCommands);

      const commandNames = tree.map((cmd) => cmd.name);
      expect(commandNames).not.toContain('auth'); // Verify it didn't load production commands.
    });
  });
});
