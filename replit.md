# PDF Compressor - CLI Tool

## Overview
A command-line tool for compressing PDF files using the [ilovepdf API](https://www.iloveapi.com/docs/api-reference). This tool was originally designed as a Docker container and has been adapted to run directly in the Replit environment.

## Purpose
Compress PDF files to reduce their size while maintaining quality. The compressed files are saved with a `.min.pdf` extension.

## Current State
- **Type**: Command-line tool (not a web application)
- **Status**: Ready for use (requires API token)
- **Dependencies**: bash, curl, jq, file, openssl (all installed)

## Recent Changes
- **2024-12-07**: Adapted Docker-based tool to Replit environment
  - Fixed bash script compatibility (removed hardcoded paths like `/usr/bin/curl`)
  - Updated file path handling (removed `/data/` volume mount requirement)
  - Fixed all LSP warnings in bash scripts
  - Installed required system dependencies via Nix

## Project Architecture

### Key Files
- **compress.sh**: Main compression script that orchestrates the PDF compression workflow
- **create_jwt_token.sh**: Generates JWT authentication tokens for the ilovepdf API
- **test/**: Directory containing sample PDF files for testing
- **file1.pdf**: Sample PDF file in root directory

### How It Works
1. Validates the input PDF file
2. Creates a JWT token using your API credentials
3. Initiates a compression task with ilovepdf API
4. Uploads the PDF file
5. Processes the compression
6. Downloads the compressed file (saved as `filename.min.pdf`)

### API Information
- Uses the free tier of ilovepdf API (250 calls per month)
- Requires an API token from [ilovepdf](https://www.iloveapi.com)

## Usage

### Prerequisites
Set your ilovepdf API token as an environment variable:
```bash
export API_ILOVEPDF_TOKEN="your_token_here"
```

Or add it to Replit Secrets with the key `API_ILOVEPDF_TOKEN`.

### Basic Usage
```bash
./compress.sh path/to/your/file.pdf
```

### Example
```bash
./compress.sh file1.pdf
```

This will create `file1.min.pdf` with the compressed version.

### Features
- Automatically skips files that have already been compressed (`.min.pdf` extension)
- Validates PDF format before processing
- Shows compression ratio after completion
- Handles errors gracefully

## Environment Variables

### Required
- **API_ILOVEPDF_TOKEN**: Your ilovepdf API token (request from user via Replit Secrets)

### Optional
- **OUTPUT_DIR**: Directory where compressed files are saved
  - **Docker**: Set to `/data` (mounted volume) - automatically set in Dockerfile
  - **Replit**: Leave unset - files are saved in the same directory as the input file

## User Preferences
None documented yet.

## Notes
- The script is in French (comments and messages are in French)
- Files with `.min.pdf` extension won't be compressed again
- Original Docker setup used `/data` volume mounts, now works with direct file paths
