#!/usr/bin/env node

/**
 * @license
 * Copyright 2025 G-PROJECT Contributors
 * SPDX-License-Identifier: Apache-2.0
 */

import { existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '..');
const bundlePath = join(projectRoot, 'bundle', 'gemini.js');

// Check if bundle exists, if not try to build it
if (!existsSync(bundlePath)) {
  console.log('Bundle not found, building...');
  try {
    // Build the bundle
    const buildProcess = spawn('npm', ['run', 'bundle'], {
      cwd: projectRoot,
      stdio: 'inherit'
    });
    
    buildProcess.on('exit', (code) => {
      if (code === 0) {
        // Bundle built successfully, now run it
        import(bundlePath).catch(console.error);
      } else {
        console.error('Failed to build bundle');
        process.exit(1);
      }
    });
  } catch (error) {
    console.error('Error building bundle:', error);
    process.exit(1);
  }
} else {
  // Bundle exists, run it directly
  import(bundlePath).catch(console.error);
}