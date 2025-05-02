# Winston The Wifi Hound

A user-friendly interface for aircrack-ng that makes wireless network auditing accessible to beginners.

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

1. Clone this repository:
```bash
git clone https://github.com/yourusername/WinstonTheWifiHound.git
cd WinstonTheWifiHound
```

2. Make all scripts executable:
```bash
chmod +x *.sh
```

3. Run the setup script:
```bash
sudo ./Wifi_Hound_Setup.sh
```
This will:
- Create your user account
- Set up necessary directories
- Create a default wordlist
- Configure permissions

## Usage

### Starting the Program
```bash
sudo ./Wifi_Hound_Script.sh
```

### Main Features
1. **Network Scanning**
   - Scan all networks in range
   - Target specific networks
   - View available networks and their details

2. **Password Management**
   - View stored passwords:
     ```bash
     sudo ./password_manager.sh list
     ```
   - Search for specific networks:
     ```bash
     sudo ./password_manager.sh search <network_name>
     ```

### Common Use Cases

1. **Scanning All Networks**
   ```bash
   sudo ./Wifi_Hound_Script.sh
   # Select option 1 when prompted for scanning mode
   ```

2. **Targeting a Specific Network**
   ```bash
   sudo ./Wifi_Hound_Script.sh
   # Select option 2 when prompted
   # Enter the network name (SSID)
   ```

3. **Checking Captured Handshakes**
   ```bash
   sudo ./password_manager.sh list
   # Look for entries with "PENDING" status
   ```

4. **Searching for Previous Captures**
   ```bash
   sudo ./password_manager.sh search "NetworkName"
   ```

### Customizing the Wordlist

The default wordlist is located at `/winston/kenel/wordlist.txt`. You can customize it in several ways:

1. **Add Custom Passwords**
   ```bash
   sudo nano /winston/kenel/wordlist.txt
   # Add your passwords, one per line
   ```

2. **Use a Larger Wordlist**
   ```bash
   # Download a larger wordlist (example)
   sudo wget https://github.com/danielmiessler/SecLists/raw/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt -O /winston/kenel/wordlist.txt
   ```

3. **Create a Targeted Wordlist**
   ```bash
   # Combine multiple wordlists
   sudo cat wordlist1.txt wordlist2.txt > /winston/kenel/wordlist.txt
   ```

### How It Works
1. The program will ask for your username and password
2. Select your wireless interface
3. Choose scanning mode (all networks or specific network)
4. Select target network from the list
5. The program will:
   - Start capturing packets
   - Monitor for connected devices
   - Attempt to capture handshakes
   - Store successful captures

## Security Notes
- All operations require sudo privileges
- Passwords are stored securely using SHA-256 hashing
- Captured handshakes are stored in `/winston/kenel/handshakes/`
- User data is stored in `/winston/username/`

## Troubleshooting

### Common Issues and Solutions

1. **Script Permission Issues**
   ```bash
   # Fix permissions for all scripts
   sudo chmod +x *.sh
   # Fix ownership
   sudo chown -R $USER:$USER .
   ```

2. **Wireless Interface Problems**
   ```bash
   # Check available interfaces
   iwconfig
   # Check if interface supports monitor mode
   sudo iw list | grep -A 5 "Supported interface modes"
   # Put interface in monitor mode manually if needed
   sudo airmon-ng start <interface>
   ```

3. **Screen Session Issues**
   ```bash
   # List all screen sessions
   screen -ls
   # Kill a specific screen session
   screen -X -S <session_id> quit
   # Kill all screen sessions
   pkill screen
   ```

4. **Directory Permission Issues**
   ```bash
   # Fix permissions for Winston directories
   sudo chmod -R 700 /winston
   sudo chown -R $USER:$USER /winston
   ```

5. **Process Management**
   ```bash
   # Check for running aircrack processes
   ps aux | grep aircrack
   # Kill interfering processes
   sudo airmon-ng check kill
   ```

### Error Messages and Solutions

1. **"Cannot execute: required file not found"**
   - Ensure you're in the correct directory
   - Check if scripts are executable
   - Verify file permissions

2. **"No wireless interfaces found"**
   - Check if wireless card is recognized
   - Verify driver installation
   - Try different USB port (if using USB adapter)

3. **"Permission denied"**
   - Run commands with sudo
   - Check file permissions
   - Verify user ownership

4. **"Screen session not found"**
   - Restart the main script
   - Manually kill existing screen sessions
   - Check screen installation

## Legal Disclaimer
This tool is for educational and authorized security testing purposes only. Always:
- Obtain proper authorization before testing any network
- Respect privacy and data protection laws
- Use responsibly and ethically

## Best Practices
1. Always test on your own networks first
2. Keep your wordlist updated
3. Regularly check for captured handshakes
4. Maintain proper security of stored data
5. Document your testing activities
6. Follow local laws and regulations
7. Respect network privacy
