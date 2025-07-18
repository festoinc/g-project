/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Text } from 'ink';
import { Colors } from '../colors.js';
import { type MCPServerConfig } from '@google/gemini-cli-core';

interface ContextSummaryDisplayProps {
  geminiMdFileCount: number; // Now represents settings file count
  contextFileNames: string[];
  mcpServers?: Record<string, MCPServerConfig>;
  showToolDescriptions?: boolean;
}

export const ContextSummaryDisplay: React.FC<ContextSummaryDisplayProps> = ({
  geminiMdFileCount,
  contextFileNames,
  mcpServers,
  showToolDescriptions,
}) => {
  const mcpServerCount = Object.keys(mcpServers || {}).length;

  if (geminiMdFileCount === 0 && mcpServerCount === 0) {
    return <Text> </Text>; // Render an empty space to reserve height
  }

  const settingsText = (() => {
    if (geminiMdFileCount === 0) {
      return '';
    }
    return 'Settings are loaded!';
  })();

  const mcpText =
    mcpServerCount > 0
      ? `${mcpServerCount} MCP server${mcpServerCount > 1 ? 's' : ''}`
      : '';

  let summaryText = '';
  if (settingsText) {
    summaryText += settingsText;
  }
  if (settingsText && mcpText) {
    summaryText += ' Using ';
  }
  if (mcpText) {
    summaryText += mcpText;
    // Add ctrl+t hint when MCP servers are available
    if (mcpServers && Object.keys(mcpServers).length > 0) {
      if (showToolDescriptions) {
        summaryText += ' (ctrl+t to toggle)';
      } else {
        summaryText += ' (ctrl+t to view)';
      }
    }
  }

  return <Text color={Colors.Gray}>{summaryText}</Text>;
};
