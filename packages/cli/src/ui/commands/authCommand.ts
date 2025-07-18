/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { OpenDialogActionReturn, SlashCommand } from './types.js';

export const authCommand: SlashCommand = {
  name: 'auth',
  description: 'change the auth method',
  action: (_context, _args): OpenDialogActionReturn => ({
    type: 'dialog',
    dialog: 'auth',
  }),
};
