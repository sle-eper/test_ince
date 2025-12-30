# User Documentation

## Overview

This Inception project provides a complete web hosting infrastructure using Docker containers. The stack includes:

- **MariaDB** - Database server for storing WordPress data
- **WordPress** - Content management system with PHP-FPM
- **Nginx** - Web server handling HTTPS requests and serving as a reverse proxy

All services run in isolated Docker containers and communicate through a private network.

## Services Provided

### MariaDB Database
- Runs on port 3306 (internal network only)
- Stores all WordPress content (posts, pages, users, settings)
- Accessible only by WordPress container for security

### WordPress Application
- PHP-FPM running on port 9000 (internal network only)
- Powers the website and administration interface
- Handles all dynamic content generation

### Nginx Web Server
- Listens on port 443 (HTTPS only)
- Serves as the sole entry point to the infrastructure
- Provides SSL/TLS encryption for all connections
- Forwards PHP requests to WordPress container

## Starting and Stopping the Project

### Starting the Infrastructure

To start all services:

```bash
make
```

This command will:
1. Create necessary data directories
2. Build all Docker images
3. Start containers in detached mode

Alternative commands:
```bash
make build    # Only build images
make up       # Only start containers
make viewUp   # Start with logs visible
```

### Stopping the Infrastructure

To stop all services:

```bash
make down
```

To stop and remove volumes:

```bash
make downV
```

To restart services:

```bash
make restart
```

## Accessing the Website

### Website Access

Open your web browser and navigate to:

```
https://mmanaoui.42.fr
```

**Important:** Since this uses a self-signed SSL certificate, your browser will show a security warning. This is normal for development environments. You can safely proceed by:

1. Clicking "Advanced" or "Show Details"
2. Selecting "Proceed to mmanaoui.42.fr" or "Accept the Risk"

### Administration Panel

To access the WordPress admin dashboard:

```
https://mmanaoui.42.fr/wp-admin
```

Use the administrator credentials listed below.

## Credentials Management

### Default Credentials

#### WordPress Administrator
- **Username:** `wpowner`
- **Password:** Located in `secrets/admin_password.txt` (default: `12345`)
- **Email:** `wpowner@mmanaoui.42.fr`

#### WordPress Author User
- **Username:** `author`
- **Password:** Located in `secrets/user_password.txt` (default: `author_user_password`)
- **Email:** `author@mmanaoui.42.fr`

#### Database Credentials
- **Root Password:** Located in `secrets/db_root_password.txt` (default: `root_password_here`)
- **User Password:** Located in `secrets/db_password.txt` (default: `db_user_password`)

### Changing Credentials

**Important:** Change all default passwords before deploying to production!

To modify credentials:

1. Edit the appropriate file in the `secrets/` directory:
   - `secrets/admin_password.txt` - WordPress admin password
   - `secrets/user_password.txt` - WordPress author password
   - `secrets/db_password.txt` - Database user password
   - `secrets/db_root_password.txt` - Database root password

2. Rebuild and restart the containers:
   ```bash
   make down
   make
   ```

**Note:** The secrets files should contain only the password text with no extra whitespace or newlines.

### Security Best Practices

- Never commit real passwords to version control
- Use strong passwords (minimum 12 characters with mixed case, numbers, and symbols)
- Regularly rotate passwords, especially after team changes
- Restrict file permissions on secret files:
  ```bash
  chmod 600 secrets/*.txt
  ```

## Verifying Services

### Quick Health Check

Check if all containers are running:

```bash
docker ps
```

You should see three containers running:
- `mariadb`
- `wordpress`
- `nginx`

### Detailed Service Status

View container logs:

```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

### Testing Database Connectivity

Connect to MariaDB container:

```bash
docker exec -it mariadb mysql -u wordpress -p
```

Enter the password from `secrets/db_password.txt`, then verify the database:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
EXIT;
```

### Testing WordPress

1. Access the website at `https://mmanaoui.42.fr`
2. You should see the WordPress homepage
3. Try logging in at `https://mmanaoui.42.fr/wp-admin`

### Testing SSL Certificate

Check the certificate details:

```bash
openssl s_client -connect mmanaoui.42.fr:443 -showcerts
```

## Data Management

### Data Persistence

All persistent data is stored in:

```
/home/mmanaoui/data/
├── mariadb/    # Database files
└── wordpress/  # WordPress files and uploads
```

This data persists even when containers are stopped or removed (unless using `make downV`).

### Backup Recommendations

To backup your data:

```bash
# Backup WordPress files
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/mmanaoui/data/wordpress/

# Backup database
docker exec mariadb mysqldump -u root -p wordpress > wordpress-db-backup-$(date +%Y%m%d).sql
```

### Cleaning Up

To remove all data and start fresh:

```bash
make downV
sudo rm -rf /home/mmanaoui/data/*
make cleanV    # Remove all Docker volumes
```

**Warning:** This will permanently delete all your WordPress content and database!

## Troubleshooting

### Cannot Access Website

1. Check if containers are running: `docker ps`
2. Verify port 443 is not in use: `sudo netstat -tlnp | grep 443`
3. Check nginx logs: `docker compose -f srcs/docker-compose.yml logs nginx`

### Database Connection Errors

1. Verify MariaDB is running: `docker ps | grep mariadb`
2. Check database logs: `docker compose -f srcs/docker-compose.yml logs mariadb`
3. Ensure passwords in secrets files match the environment

### WordPress Installation Issues

1. Check WordPress logs: `docker compose -f srcs/docker-compose.yml logs wordpress`
2. Verify database connectivity from WordPress container:
   ```bash
   docker exec -it wordpress nc -zv mariadb 3306
   ```

### SSL Certificate Warnings

Self-signed certificates will always show warnings in browsers. For production use:

1. Obtain a valid certificate from Let's Encrypt or a Certificate Authority
2. Replace the certificate files in the nginx container
3. Update the nginx configuration accordingly

## Getting Help

If you encounter issues not covered in this documentation:

1. Check the developer documentation (DEV_DOC.md) for technical details
2. Review container logs for error messages
3. Verify all configuration files are correctly formatted
4. Ensure Docker and Docker Compose are up to date