# Winston The Wifi Hound

Winston is an advanced WiFi security toolkit that combines the power of aircrack-ng with a user-friendly interface. It's designed to help security professionals and researchers test and analyze wireless network security.

## Features

- Interactive terminal interface with command history and tab completion
- Color-coded output for better readability
- Adjustable verbosity levels
- Network scanning and monitoring
- Handshake capture and analysis
- Password cracking capabilities
- Secure password management
- User authentication system

## Prerequisites

Before running Winston The Wifi Hound, ensure you have the following installed:
- aircrack-ng suite
- screen
- iwconfig (usually comes with wireless-tools)

On Debian/Ubuntu/Raspberry Pi OS, you can install these with:
```bash
sudo apt-get update
sudo apt-get install aircrack-ng screen wireless-tools
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/WinstonTheWifiHound.git
cd WinstonTheWifiHound
```

2. Install dependencies:
```bash
sudo apt-get update
sudo apt-get install aircrack-ng screen
```

3. Set up the required directories:
```bash
sudo mkdir -p /winston/kenel
```

4. Make the scripts executable:
```bash
chmod +x Wifi_Hound_Script.sh
chmod +x capture.sh
chmod +x deauth.sh
chmod +x password_manager.sh
```

## Usage

### Starting Winston

Run the main script:
```bash
sudo ./Wifi_Hound_Script.sh
```

### Terminal Interface

Winston provides an interactive terminal interface with the following features:

#### Command History
- Use up/down arrows to navigate through command history
- View recent commands with the `history` command
- History is persisted between sessions

#### Tab Completion
- Press TAB to see available commands
- Press TAB after a command to see available options
- Available completions:
  - Interface names for `monitor` command
  - Network names for `capture` and `deauth` commands
  - Wordlist files for `wordlist` command
  - Verbosity levels for `verbose` command

#### Verbosity Levels
Use the `verbose` command to adjust output detail:
- `verbose 0`: Quiet mode (minimal output)
- `verbose 1`: Normal mode (default)
- `verbose 2`: Verbose mode (detailed output)
- `verbose 3`: Debug mode (all output)

#### Color Coding
- RED: Errors and warnings
- GREEN: Success messages
- YELLOW: Warnings and important notices
- BLUE: Information messages
- MAGENTA: Headers and command help
- CYAN: Debug messages
- BOLD: Command names and important text

### Available Commands

- `help [command]` - Show help message (optional: specific command)
- `scan [all|target]` - Scan for networks (all or specific target)
- `interfaces` - List available wireless interfaces
- `monitor <interface>` - Put interface in monitor mode
- `capture <network>` - Start capturing packets for a network
- `deauth <network>` - Start deauthentication attack
- `handshakes` - List captured handshakes
- `crack <handshake>` - Attempt to crack a handshake
- `wordlist <file>` - Set custom wordlist file
- `status` - Show current operation status
- `history` - Show command history
- `verbose [level]` - Set verbosity level (0-3)
- `clear` - Clear the screen
- `exit` - Exit Winston

### Getting Help

- Type `help` to see all available commands
- Type `help <command>` for detailed help on a specific command
- Use `verbose 2` or `verbose 3` for more detailed output
- Check the status with `status` command

## Security Features

- User authentication system
- Secure password storage
- Process cleanup on exit
- Screen session management
- Error handling and logging

## File Structure

- `Wifi_Hound_Script.sh` - Main script
- `capture.sh` - Handshake capture script
- `deauth.sh` - Deauthentication script
- `password_manager.sh` - Password management script
- `/winston/kenel/` - Working directory for temporary files
- `/winston/<username>/` - User-specific directories

## Troubleshooting

1. If you encounter permission issues:
   ```bash
   sudo chmod +x *.sh
   ```

2. If screen sessions aren't working:
   ```bash
   sudo apt-get install screen
   ```

3. If aircrack-ng isn't working:
   ```bash
   sudo apt-get install aircrack-ng
   ```

4. For verbose debugging:
   ```bash
   verbose 3
   ```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This tool is for educational and security research purposes only. Always obtain proper authorization before testing any network security.

## Best Practices
1. Always test on your own networks first
2. Keep your wordlist updated
3. Regularly check for captured handshakes
4. Maintain proper security of stored data
5. Document your testing activities
6. Follow local laws and regulations
7. Respect network privacy
