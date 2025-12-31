import fs from 'fs';
import { exec } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

// Helper for ESM equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 1. Load Environment Variables (Simple Parser)
function loadEnv() {
    try {
        const envPath = path.resolve(__dirname, '.env');
        const envContent = fs.readFileSync(envPath, 'utf8');
        const env = {};
        envContent.split('\n').forEach(line => {
            const parts = line.split('=');
            if (parts.length >= 2) {
                const key = parts[0].trim();
                const value = parts.slice(1).join('=').trim();
                env[key] = value;
            }
        });
        return env;
    } catch (e) {
        console.error("Error loading .env file:", e.message);
        return {};
    }
}

const envFromFile = loadEnv();
const env = { ...process.env, ...envFromFile };
const assetsPath = env['FRONTEND_ASSETS_PATH'];

if (!assetsPath) {
    console.error("Error: FRONTEND_ASSETS_PATH not set in .env");
    process.exit(1);
}

if (!fs.existsSync(assetsPath)) {
    console.error(`Error: Assets path does not exist: ${assetsPath}`);
    process.exit(1);
}

console.log(`Watching for changes in: ${assetsPath}`);

let debounceTimer;

// 2. Watch Directory (Recursive)
fs.watch(assetsPath, { recursive: true }, (eventType, filename) => {
    if (filename) {
        // Debounce: Wait 1 second after last change
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            console.log(`\nSyncing assets... (Triggered by ${filename})`);
            runSync();
        }, 1000);
    }
});

function runSync() {
    exec('php artisan notes:sync-assets', (error, stdout, stderr) => {
        if (error) {
            console.error(`Sync Error: ${error.message}`);
            return;
        }
        if (stdout) console.log(stdout.trim());
        if (stderr) console.error(stderr.trim());
        console.log("--- Sync Complete ---\n");
    });
}
