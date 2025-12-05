import { existsSync, mkdirSync, copyFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

const publicDir = 'public';

// Create public directory if it doesn't exist
if (!existsSync(publicDir)) {
  mkdirSync(publicDir, { recursive: true });
}

// Copy files and directories
const files = readdirSync('.');
files.forEach(file => {
  if (file === 'public' || file === 'node_modules' || file === '.git' || file === 'build.js') {
    return;
  }
  
  const stat = statSync(file);
  if (stat.isFile()) {
    copyFileSync(file, join(publicDir, file));
  } else if (stat.isDirectory()) {
    // Use execSync for cross-platform directory copying
    try {
      if (process.platform === 'win32') {
        execSync(`xcopy /E /I /Y "${file}" "${join(publicDir, file)}"`, { stdio: 'ignore' });
      } else {
        execSync(`cp -r "${file}" "${join(publicDir, file)}"`, { stdio: 'ignore' });
      }
    } catch (error) {
      console.error(`Error copying ${file}:`, error.message);
    }
  }
});

console.log('Build complete! Files copied to public directory.');

