# Laravel Herd Worker Manager

A PowerShell script to manage Laravel queue workers on Windows 11, tailored for Laravel Herd users. Handles starting, stopping, and logging of workers.

## Features
  - **Start Multiple Workers**: Launch up to 32 queue workers with individual log files.
  - **Stop Workers**: Terminate running workers and clean up associated files.
  - **Log Management**: Redirects worker output to log files (`worker_1.log`, `worker_2.log`, etc.).
  - **Git Integration**: Automatically adds `worker_*.log` and `worker_pids.txt` to `.gitignore`.

## Requirements
  - **Operating System**: Windows 11
  - **Laravel Herd**: Installed and configured, with the `php` command available in your PATH
  - **PowerShell**: Version 5.1 or later (included with Windows 11)

## Installation

1. **Download the Script**:
  - Clone this repository: `git clone https://github.com/your-username/laravel-worker-manager-windows.git`
  - Or download `worker_manager.ps1` directly from the repository and place it in your Laravel project directory.

2. **Verify Setup**:
  - Ensure your Laravel project is set up with Laravel Herd.
  - Confirm that running `php` in PowerShell returns the PHP executable path (Herd should handle this).

## Usage

1. **Navigate to Your Project**:
  - Open PowerShell and change to your Laravel project directory (where `artisan` is located): `cd C:\path\to\your\laravel\project`

2. **Run the Script**:
  - Execute the script: `.\worker_manager.ps1`

3. **Follow the Prompts**:
  - **If Workers Are Running**:
  - If `worker_pids.txt` exists or PHP processes are detected, it shows how many workers are active.
  - You’ll be asked: `Do you want to stop all workers and delete logs? (y/n)`
    - `y`: Stops all workers, deletes `worker_pids.txt` and log files.
    - `n`: Exits without changes.
  - **If No Workers Are Running**:
  - If no `worker_pids.txt` exists and no workers are detected, it asks: `Do you want to start some? (y/n)`
    - `y`: Prompts for the number of workers (1-32), then starts them.
    - `n`: Exits without starting workers.

4. **Starting Workers**:
  - Workers run `php artisan queue:work`, with output logged to `worker_1.log`, `worker_2.log`, etc.
  - Process IDs are saved to `worker_pids.txt`.

5. **Stopping Workers**:
  - Terminates processes listed in `worker_pids.txt` and any additional `php artisan queue:work` processes.
  - Deletes log files and `worker_pids.txt`.

## Configuration
  - **Automatic `.gitignore` Updates**: The script adds `worker_*.log` and `worker_pids.txt` to your project’s `.gitignore` if they’re not already present.
  - **Customization**: Edit `worker_manager.ps1` to adjust the maximum worker limit (default: 32) or log file names.

## Troubleshooting
  - **"Script can't find php.exe"**:
  - Ensure Laravel Herd is installed and `php` is in your PATH. Test by running `php -v` in PowerShell.
  - **Permission Errors**:
  - Run PowerShell as an administrator if you encounter issues deleting files.
  - **Workers Not Starting**:
  - Check `worker_*.log` files for errors.
  - Verify your Laravel queue configuration (e.g., `config/queue.php`).

## Contributing
Contributions are welcome! Please:
  - Report bugs or suggest features via GitHub Issues.
  - Submit improvements through Pull Requests.

## License
This project is licensed under the [MIT License](LICENSE).
