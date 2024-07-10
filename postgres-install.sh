#!/bin/bash



# Check if PostgreSQL configuration exists
if [ -d "/etc/postgresql/" ]; then
    echo "PostgreSQL detected."
    
    # Prompt the user for action
    echo "Please choose an option:"
    echo "1) Display all databases"
    echo "2) Create a database"
    echo "3) Delete a database"
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
    
    # Add listen_addresses setting to postgresql.conf
    echo "Configuring PostgreSQL to listen on all addresses..."
    sudo sed -i '/^#listen_addresses =/ s/^/#/' /etc/postgresql/*/main/postgresql.conf
    echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf > /dev/null
    
    # Restart PostgreSQL service
    echo "Restarting and enabling PostgreSQL service..."
    sudo systemctl restart postgresql
    sudo systemctl enable postgresql
    echo "Postgres setup complete."
fi