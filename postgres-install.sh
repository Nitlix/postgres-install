#!/bin/bash



#Reject if not root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check if PostgreSQL configuration exists
if [ -d "/etc/postgresql/" ]; then
    echo "PostgreSQL detected."
    
    # Prompt the user for action
    echo "Please choose an option:"
    echo "1) Display all databases"
    echo "2) Create a database"
    echo "3) Delete a database"
    echo "4) Enable TimescaleDB on a database"
    read -p "Enter your choice (1-3): " user_choice
    
    case $user_choice in
        1)
            echo "Displaying all databases..."
            sudo -u postgres psql -c "\l"
            ;;
        2)
            echo "Creating a new database..."
            read -p "Enter the name of the new database: " db_name
            sudo -u postgres createdb "$db_name"
            echo "Database '$db_name' created successfully."
            ;;
        3)
            echo "Deleting a database..."
            read -p "Enter the name of the database to delete (not template or postgres): " db_name
            sudo -u postgres dropdb "$db_name"
            echo "Database '$db_name' deleted successfully."
            ;;
        4)
            echo "Enabling TimescaleDB on a database..."
            read -p "Enter the name of the database to enable TimescaleDB on: " db_name
            sudo -S -u postgres psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
            echo "TimescaleDB enabled on database '$db_name'."
        *)
            echo "Invalid choice. Exiting..."
            exit 1
            ;;
    esac
else
    echo "Installing PostgreSQL..."
    
    # Update package lists and install PostgreSQL
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
    
    # Prompt the user to set a password for the 'postgres' user
    echo "Setting up 'postgres' user password..."
    sudo -S -u postgres psql -c "\password postgres"

    # Find the pg_hba.conf file and append the necessary line
    echo "Configuring PostgreSQL to allow connections from any IP address..."
    PG_HBA_CONF_FILE=$(find /etc/postgresql/ -name pg_hba.conf)
    if [[ -n "$PG_HBA_CONF_FILE" ]]; then
        echo "host all all 0.0.0.0/0 md5" | sudo tee -a "$PG_HBA_CONF_FILE" > /dev/null
        echo "Configuration to allow connections from any IP address added to pg_hba.conf."
    else
        echo "pg_hba.conf not found. Skipping configuration."
    fi
    
    # Add listen_addresses setting to postgresql.conf
    echo "Configuring PostgreSQL to listen on all addresses..."
    sudo sed -i '/^#listen_addresses =/ s/^/#/' /etc/postgresql/*/main/postgresql.conf
    echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf > /dev/null

    read -p "Do you want to install TimescaleDB? (Y/N): " timescaledb_choice
    if [ "$timescaledb_choice" == "Y" ] || [ "$timescaledb_choice" == "y" ]; then
        echo "Installing TimescaleDB..."
        echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list
        wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
        sudo apt update
        sudo apt install timescaledb-2-postgresql-16 postgresql-client-16 -y


        sudo timescaledb-tune --quiet --yes
        echo "TimescaleDB installed and tuned successfully."
    else
        echo "Skipping TimescaleDB installation."
    fi
    
    # Restart PostgreSQL service
    echo "Restarting and enabling PostgreSQL service..."
    sudo systemctl restart postgresql
    sudo systemctl enable postgresql
    echo "Postgres setup complete."
fi