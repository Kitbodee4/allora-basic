# Allora Chain Setup Script


This repository contains a setup script to install and configure Allora chain and workers. It includes steps to add a new user, install dependencies, set up Docker, and configure Allora chain.

## Prerequisites

- Ubuntu (or a Debian-based Linux distribution)
- User with sudo privileges

## How to Use

1. **Clone the repository:**

    ```sh
    git clone https://github.com/Kitbodee4/allora-basic.git
    cd allora-basic
    ```

2. **Make the script executable:**

    ```sh
    chmod +x setup.sh
    ```

3. **Run the script:**

    ```sh
    ./setup.sh
    ```

4. **Follow the prompts:**
   - Enter the new username.   #root
   - Enter the `HEAD_ID` (you can get this by running `cat head-data/keys/identity` after the head keys are created).
   - Enter the `WALLET_SEED_PHRASE`.

## Script Details

The script performs the following steps:

1. **System Update and Upgrade:**
    - Updates and upgrades the system packages.

2. **Install Required Packages:**
    - Installs necessary dependencies such as `curl`, `git`, `docker`, `docker-compose`, and more.

3. **Add a New User:**
    - Prompts for a new username and adds the user to the system with sudo and docker group permissions.

4. **Install Python3 and Pip:**
    - Installs Python3 and pip.

5. **Install Docker:**
    - Installs Docker and Docker Compose, then adds the new user to the Docker group.

6. **Install Go:**
    - Installs Go programming language.

7. **Install Allorad:**
    - Clones the Allora repository, builds the Allora chain, and sets up the wallet.

8. **Setup Workers:**
    - Clones the basic coin prediction node repository, creates directories for workers, sets permissions, and generates keys for head and workers.

9. **Create Docker Compose Configuration:**
    - Prompts for `HEAD_ID` and `WALLET_SEED_PHRASE`, then generates a `docker-compose.yml` file with the provided information.

10. **Run Docker Compose:**
    - Builds and starts the Docker containers for the inference service, updater, head, and workers.

## Contributing

Please feel free to submit issues, fork the repository, and send pull requests!

