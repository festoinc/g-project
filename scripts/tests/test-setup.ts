/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { vi } from 'vitest';

vi.mock('fs', () => ({
  ...vi.importActual('fs'),
  appendFileSync: vi.fn(),
}));
