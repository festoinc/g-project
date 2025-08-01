/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { useCallback, useMemo, useEffect, useState } from 'react';
import { type PartListUnion } from '@google/genai';
import process from 'node:process';
import { UseHistoryManagerReturn } from './useHistoryManager.js';
import { useStateAndRef } from './useStateAndRef.js';
import { Config, GitService, Logger } from '@google/gemini-cli-core';
import { useSessionStats } from '../contexts/SessionContext.js';
import {
  Message,
  MessageType,
  HistoryItemWithoutId,
  HistoryItem,
  SlashCommandProcessorResult,
} from '../types.js';
import { LoadedSettings } from '../../config/settings.js';
import {
  type CommandContext,
  type SlashCommandActionReturn,
  type SlashCommand,
} from '../commands/types.js';
import { CommandService } from '../../services/CommandService.js';

// This interface is for the old, inline command definitions.
// It will be removed once all commands are migrated to the new system.
export interface LegacySlashCommand {
  name: string;
  altName?: string;
  description?: string;
  completion?: () => Promise<string[]>;
  action: (
    mainCommand: string,
    subCommand?: string,
    args?: string,
  ) =>
    | void
    | SlashCommandActionReturn
    | Promise<void | SlashCommandActionReturn>;
}

/**
 * Hook to define and process slash commands (e.g., /help, /clear).
 */
export const useSlashCommandProcessor = (
  config: Config | null,
  settings: LoadedSettings,
  history: HistoryItem[],
  addItem: UseHistoryManagerReturn['addItem'],
  clearItems: UseHistoryManagerReturn['clearItems'],
  loadHistory: UseHistoryManagerReturn['loadHistory'],
  refreshStatic: () => void,
  setShowHelp: React.Dispatch<React.SetStateAction<boolean>>,
  onDebugMessage: (message: string) => void,
  openThemeDialog: () => void,
  openAuthDialog: () => void,
  openEditorDialog: () => void,
  setQuittingMessages: (message: HistoryItem[]) => void,
) => {
  const session = useSessionStats();
  const [commands, setCommands] = useState<SlashCommand[]>([]);
  const gitService = useMemo(() => {
    if (!config?.getProjectRoot()) {
      return;
    }
    return new GitService(config.getProjectRoot());
  }, [config]);

  const logger = useMemo(() => {
    const l = new Logger(config?.getSessionId() || '');
    // The logger's initialize is async, but we can create the instance
    // synchronously. Commands that use it will await its initialization.
    return l;
  }, [config]);

  const [pendingCompressionItemRef, setPendingCompressionItem] =
    useStateAndRef<HistoryItemWithoutId | null>(null);

  const pendingHistoryItems = useMemo(() => {
    const items: HistoryItemWithoutId[] = [];
    if (pendingCompressionItemRef.current != null) {
      items.push(pendingCompressionItemRef.current);
    }
    return items;
  }, [pendingCompressionItemRef]);

  const addMessage = useCallback(
    (message: Message) => {
      // Convert Message to HistoryItemWithoutId
      let historyItemContent: HistoryItemWithoutId;
      if (message.type === MessageType.ABOUT) {
        historyItemContent = {
          type: 'about',
          cliVersion: message.cliVersion,
          osVersion: message.osVersion,
          sandboxEnv: message.sandboxEnv,
          modelVersion: message.modelVersion,
          selectedAuthType: message.selectedAuthType,
          gcpProject: message.gcpProject,
        };
      } else if (message.type === MessageType.STATS) {
        historyItemContent = {
          type: 'stats',
          duration: message.duration,
        };
      } else if (message.type === MessageType.MODEL_STATS) {
        historyItemContent = {
          type: 'model_stats',
        };
      } else if (message.type === MessageType.TOOL_STATS) {
        historyItemContent = {
          type: 'tool_stats',
        };
      } else if (message.type === MessageType.QUIT) {
        historyItemContent = {
          type: 'quit',
          duration: message.duration,
        };
      } else if (message.type === MessageType.COMPRESSION) {
        historyItemContent = {
          type: 'compression',
          compression: message.compression,
        };
      } else {
        historyItemContent = {
          type: message.type,
          text: message.content,
        };
      }
      addItem(historyItemContent, message.timestamp.getTime());
    },
    [addItem],
  );

  const commandContext = useMemo(
    (): CommandContext => ({
      services: {
        config,
        settings,
        git: gitService,
        logger,
      },
      ui: {
        addItem,
        clear: () => {
          clearItems();
          console.clear();
          refreshStatic();
        },
        setDebugMessage: onDebugMessage,
        pendingItem: pendingCompressionItemRef.current,
        setPendingItem: setPendingCompressionItem,
      },
      session: {
        stats: session.stats,
      },
    }),
    [
      config,
      settings,
      gitService,
      logger,
      addItem,
      clearItems,
      refreshStatic,
      session.stats,
      onDebugMessage,
      pendingCompressionItemRef,
      setPendingCompressionItem,
    ],
  );

  const commandService = useMemo(() => new CommandService(config), [config]);

  useEffect(() => {
    const load = async () => {
      await commandService.loadCommands();
      setCommands(commandService.getCommands());
    };

    load();
  }, [commandService]);

  // Define legacy commands
  // This list contains all commands that have NOT YET been migrated to the
  // new system. As commands are migrated, they are removed from this list.
  const legacyCommands: LegacySlashCommand[] = useMemo(() => {
    const commands: LegacySlashCommand[] = [
      // `/help` and `/clear` have been migrated and REMOVED from this list.
      // `/corgi` and `/restore` have been REMOVED from this list.
    ];

    return commands;
  }, []);

  const handleSlashCommand = useCallback(
    async (
      rawQuery: PartListUnion,
    ): Promise<SlashCommandProcessorResult | false> => {
      if (typeof rawQuery !== 'string') {
        return false;
      }

      const trimmed = rawQuery.trim();
      if (!trimmed.startsWith('/') && !trimmed.startsWith('?')) {
        return false;
      }

      const userMessageTimestamp = Date.now();
      if (trimmed !== '/quit' && trimmed !== '/exit') {
        addItem(
          { type: MessageType.USER, text: trimmed },
          userMessageTimestamp,
        );
      }

      const parts = trimmed.substring(1).trim().split(/\s+/);
      const commandPath = parts.filter((p) => p); // The parts of the command, e.g., ['memory', 'add']

      // --- Start of New Tree Traversal Logic ---

      let currentCommands = commands;
      let commandToExecute: SlashCommand | undefined;
      let pathIndex = 0;

      for (const part of commandPath) {
        const foundCommand = currentCommands.find(
          (cmd) => cmd.name === part || cmd.altName === part,
        );

        if (foundCommand) {
          commandToExecute = foundCommand;
          pathIndex++;
          if (foundCommand.subCommands) {
            currentCommands = foundCommand.subCommands;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      if (commandToExecute) {
        const args = parts.slice(pathIndex).join(' ');

        if (commandToExecute.action) {
          const result = await commandToExecute.action(commandContext, args);

          if (result) {
            switch (result.type) {
              case 'tool':
                return {
                  type: 'schedule_tool',
                  toolName: result.toolName,
                  toolArgs: result.toolArgs,
                };
              case 'message':
                addItem(
                  {
                    type:
                      result.messageType === 'error'
                        ? MessageType.ERROR
                        : MessageType.INFO,
                    text: result.content,
                  },
                  Date.now(),
                );
                return { type: 'handled' };
              case 'dialog':
                switch (result.dialog) {
                  case 'auth':
                    openAuthDialog();
                    return { type: 'handled' };
                  case 'theme':
                    openThemeDialog();
                    return { type: 'handled' };
                  case 'editor':
                    openEditorDialog();
                    return { type: 'handled' };
                  default: {
                    const unhandled: never = result.dialog;
                    throw new Error(
                      `Unhandled slash command result: ${unhandled}`,
                    );
                  }
                }
              case 'load_history': {
                await config
                  ?.getGeminiClient()
                  ?.setHistory(result.clientHistory);
                commandContext.ui.clear();
                result.history.forEach((item, index) => {
                  commandContext.ui.addItem(item, index);
                });
                return { type: 'handled' };
              }
              case 'quit':
                setQuittingMessages(result.messages);
                setTimeout(() => {
                  process.exit(0);
                }, 100);
                return { type: 'handled' };
              default: {
                const unhandled: never = result;
                throw new Error(`Unhandled slash command result: ${unhandled}`);
              }
            }
          }

          return { type: 'handled' };
        } else if (commandToExecute.subCommands) {
          const helpText = `Command '/${commandToExecute.name}' requires a subcommand. Available:\n${commandToExecute.subCommands
            .map((sc) => `  - ${sc.name}: ${sc.description || ''}`)
            .join('\n')}`;
          addMessage({
            type: MessageType.INFO,
            content: helpText,
            timestamp: new Date(),
          });
          return { type: 'handled' };
        }
      }

      // --- End of New Tree Traversal Logic ---

      // --- Legacy Fallback Logic (for commands not yet migrated) ---

      const mainCommand = parts[0];
      const subCommand = parts[1];
      const legacyArgs = parts.slice(2).join(' ');

      for (const cmd of legacyCommands) {
        if (mainCommand === cmd.name || mainCommand === cmd.altName) {
          const actionResult = await cmd.action(
            mainCommand,
            subCommand,
            legacyArgs,
          );

          if (actionResult?.type === 'tool') {
            return {
              type: 'schedule_tool',
              toolName: actionResult.toolName,
              toolArgs: actionResult.toolArgs,
            };
          }
          if (actionResult?.type === 'message') {
            addItem(
              {
                type:
                  actionResult.messageType === 'error'
                    ? MessageType.ERROR
                    : MessageType.INFO,
                text: actionResult.content,
              },
              Date.now(),
            );
          }
          return { type: 'handled' };
        }
      }

      addMessage({
        type: MessageType.ERROR,
        content: `Unknown command: ${trimmed}`,
        timestamp: new Date(),
      });
      return { type: 'handled' };
    },
    [
      config,
      addItem,
      setShowHelp,
      openAuthDialog,
      commands,
      legacyCommands,
      commandContext,
      addMessage,
      openThemeDialog,
      openEditorDialog,
      setQuittingMessages,
    ],
  );

  const allCommands = useMemo(() => {
    // Adapt legacy commands to the new SlashCommand interface
    const adaptedLegacyCommands: SlashCommand[] = legacyCommands.map(
      (legacyCmd) => ({
        name: legacyCmd.name,
        altName: legacyCmd.altName,
        description: legacyCmd.description,
        action: async (_context: CommandContext, args: string) => {
          const parts = args.split(/\s+/);
          const subCommand = parts[0] || undefined;
          const restOfArgs = parts.slice(1).join(' ') || undefined;

          return legacyCmd.action(legacyCmd.name, subCommand, restOfArgs);
        },
        completion: legacyCmd.completion
          ? async (_context: CommandContext, _partialArg: string) =>
              legacyCmd.completion!()
          : undefined,
      }),
    );

    const newCommandNames = new Set(commands.map((c) => c.name));
    const filteredAdaptedLegacy = adaptedLegacyCommands.filter(
      (c) => !newCommandNames.has(c.name),
    );

    return [...commands, ...filteredAdaptedLegacy];
  }, [commands, legacyCommands]);

  return {
    handleSlashCommand,
    slashCommands: allCommands,
    pendingHistoryItems,
    commandContext,
  };
};
