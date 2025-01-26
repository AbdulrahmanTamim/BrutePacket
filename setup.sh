#!/bin/bash

echo "======================================================="
echo "Welcome to Brute Packet Setup!"
echo "Let's set up your account and install necessary tools."
echo "======================================================="
echo ""

# Prompt the user for credentials
echo -n "Enter your username: "
read username
echo -n "Enter your password: "
read -s password
echo -e "\nEnter your email: "
read email

# Hash the password using SHA-256
password_hash=$(echo -n "$password" | openssl dgst -sha256 | awk '{print $2}')

# Store credentials in MySQL database
echo "Storing user credentials in the database..."
mysql -u root -p <<EOF
CREATE DATABASE IF NOT EXISTS brutepacket_auth;
USE brutepacket_auth;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(64) NOT NULL,
    email VARCHAR(100) NOT NULL
);
INSERT INTO users (username, password_hash, email) VALUES ('$username', '$password_hash', '$email');
EOF

echo "User account created successfully!"

# Detect Linux distribution
echo "Detecting your Linux distribution..."

if command -v lsb_release > /dev/null; then
  distro=$(lsb_release -si)
else
  distro=$(cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d '"')
fi

echo "Detected Linux Distribution: $distro"

# Function to install necessary tools
install_tools() {
  if [[ "$distro" == "Ubuntu" || "$distro" == "Debian" ]]; then
    sudo apt update && sudo apt install -y curl git openssl systemd
  elif [[ "$distro" == "Fedora" ]]; then
    sudo dnf install -y curl git openssl systemd
  elif [[ "$distro" == "Arch" ]]; then
    sudo pacman -Syu --noconfirm curl git openssl systemd
  elif [[ "$distro" == "CentOS" ]]; then
    sudo yum install -y curl git openssl systemd
  else
    echo "Unsupported distribution: $distro"
    exit 1
  fi
}

# Install tools
echo "Installing necessary tools..."
install_tools

# Set up Rust backend as a systemd service
echo "Creating a systemd service to run the Brute Packet tool server..."

SERVICE_NAME="brutepacket.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# Compile the Rust backend
echo "Compiling the Rust backend..."
cd backend
cargo build --release
sudo cp target/release/brutepacket /usr/local/bin/brutepacket
cd ..

# Create systemd service file
echo "[Unit]
Description=Brute Packet Tool Server
After=network.target

[Service]
ExecStart=/usr/local/bin/brutepacket
WorkingDirectory=$(pwd)/backend
User=$USER
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_PATH > /dev/null

# Enable and start the service
echo "Enabling the service to start on boot..."
sudo systemctl daemon-reload
sudo systemctl enable brutepacket.service
sudo systemctl start brutepacket.service

echo "Setup complete! The Brute Packet tool server is now running in the background and will start automatically on boot."
echo "Your account details have been saved securely in the database."
echo "Ready to begin. You can now access the tool through your browser."