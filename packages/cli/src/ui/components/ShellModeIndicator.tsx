/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Box, Text } from 'ink';
import { Colors } from '../colors.js';

export const ShellModeIndicator: React.FC = () => (
  <Box>
    <Text color={Colors.AccentYellow}>
      shell mode enabled
      <Text color={Colors.Gray}> (esc to disable)</Text>
    </Text>
  </Box>
);
