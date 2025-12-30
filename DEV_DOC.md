# Developer Documentation

## Table of Contents

- [Environment Setup](#environment-setup)
- [Project Architecture](#project-architecture)
- [Building and Launching](#building-and-launching)
- [Container Management](#container-management)
- [Volume Management](#volume-management)
- [Networking](#networking)
- [Security](#security)
- [Development Workflow](#development-workflow)
- [Debugging](#debugging)

## Environment Setup

### Prerequisites

Before setting up the project, ensure you have:

- **Operating System:** Linux (Debian/Ubuntu recommended) or compatible Unix-like OS
- **Docker Engine:** Version 20.10 or higher
- **Docker Compose:** Version 2.0 or higher
- **Make:** GNU Make utility
- **Git:** For version control
- **Text Editor:** Any code editor (VS Code, Vim, etc.)

### Verify Prerequisites

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Check Make version
make --version

# Verify Docker daemon is running
docker ps
```

### System Requirements

- Minimum 2GB RAM available
- At least 5GB free disk space
- Port 443 available (not used by other services)

### Initial Setup

1. **Clone the Repository**

```bash
git clone <repository-url>
cd inception
```

2. **Configure the Domain**

Add the domain to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
```

Add this line:
```
127.0.0.1    mmanaoui.42.fr
```

3. **Create Data Directories**

The Makefile will automatically create these, but you can do it manually:

```bash
mkdir -p /home/mmanaoui/data/mariadb
mkdir -p /home/mmanaoui/data/wordpress
```

Ensure proper permissions:

```bash
sudo chown -R $USER:$USER /home/mmanaoui/data
chmod -R 755 /home/mmanaoui/data
```

4. **Configure Secrets**

The `secrets/` directory contains sensitive credentials. Review and modify these files:

```bash
# WordPress admin password
echo "your_secure_admin_password" > secrets/admin_password.txt

# WordPress author password
echo "your_secure_author_password" > secrets/user_password.txt

# Database user password
echo "your_secure_db_password" > secrets/db_password.txt

# Database root password
echo "your_secure_root_password" > secrets/db_root_password.txt
```

**Important:** Ensure no trailing newlines or spaces in secret files.

5. **Review Environment Configuration**

Check `srcs/.env` for environment variables. While most settings are defined in `docker-compose.yml`, the `.env` file serves as documentation and backup.

## Project Architecture

### Directory Structure

```
inception/
├── Makefile                          # Build and management commands
├── secrets/                          # Docker secrets (passwords)
│   ├── admin_password.txt
│   ├── user_password.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                          # Environment variables reference
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB container image
        │   ├── conf/
        │   │   └── my.cnf            # MariaDB configuration
        │   └── tools/
        │       └── init.sh           # Database initialization script
        ├── wordpress/
        │   ├── Dockerfile            # WordPress container image
        │   └── tools/
        │       └── configure.sh      # WordPress setup script
        └── nginx/
            ├── Dockerfile            # Nginx container image
            ├── conf/
            │   └── nginx.conf        # Nginx configuration template
            └── tools/
                └── ssl_setup.sh      # SSL certificate generation
```

### Service Architecture

```
┌─────────────────────────────────────────┐
│           External Network              │
│              (Internet)                 │
└────────────────┬────────────────────────┘
                 │
                 │ HTTPS (443)
                 │
         ┌───────▼────────┐
         │     Nginx      │  ◄── SSL/TLS Termination
         │   (Alpine)     │
         └───────┬────────┘
                 │
                 │ FastCGI (9000)
                 │
         ┌───────▼────────┐
         │   WordPress    │  ◄── PHP-FPM Application
         │   (Alpine)     │
         └───────┬────────┘
                 │
                 │ MySQL Protocol (3306)
                 │
         ┌───────▼────────┐
         │    MariaDB     │  ◄── Database Server
         │   (Debian 11)  │
         └────────────────┘
```

### Data Flow

1. **Client Request:** Browser connects to `https://mmanaoui.42.fr:443`
2. **Nginx Processing:** 
   - Terminates SSL/TLS connection
   - Serves static files directly
   - Forwards PHP requests to WordPress
3. **WordPress Processing:**
   - Executes PHP code via PHP-FPM
   - Queries MariaDB for dynamic content
   - Returns rendered HTML
4. **Response:** Nginx sends encrypted response back to client

## Building and Launching

### Makefile Commands

The project uses a Makefile for simplified management:

```bash
# Complete setup (init + build + start)
make

# Individual steps
make init      # Create data directories
make build     # Build Docker images
make up        # Start containers (detached)
make viewUp    # Start containers (foreground with logs)

# Management
make restart   # Restart all containers
make down      # Stop containers
make downV     # Stop and remove volumes
make cleanV    # Remove all Docker volumes
```

### Manual Build Process

If you need to build without the Makefile:

```bash
# Create directories
mkdir -p /home/mmanaoui/data/{mariadb,wordpress}

# Build images
docker compose -f srcs/docker-compose.yml build --parallel

# Start services
docker compose -f srcs/docker-compose.yml up -d

# View logs
docker compose -f srcs/docker-compose.yml logs -f
```

### Build Options

Build with no cache (force rebuild):

```bash
docker compose -f srcs/docker-compose.yml build --no-cache
```

Build specific service:

```bash
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml build nginx
```

## Container Management

### Viewing Container Status

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container details
docker inspect mariadb
docker inspect wordpress
docker inspect nginx
```

### Container Logs

```bash
# All service logs
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# Last 100 lines
docker compose -f srcs/docker-compose.yml logs --tail=100
```

### Executing Commands in Containers

```bash
# MariaDB
docker exec -it mariadb bash
docker exec -it mariadb mysql -u root -p

# WordPress
docker exec -it wordpress sh
docker exec -it wordpress wp --info

# Nginx
docker exec -it nginx sh
docker exec -it nginx nginx -t  # Test configuration
```

### Container Resource Usage

```bash
# View resource consumption
docker stats

# Specific container
docker stats mariadb
```

### Restarting Services

```bash
# Restart all
docker compose -f srcs/docker-compose.yml restart

# Restart specific service
docker compose -f srcs/docker-compose.yml restart mariadb
```

## Volume Management

### Understanding Volumes

The project uses **bind mounts** (not Docker-managed volumes) for data persistence:

```yaml
volumes:
  mariadb_data:
    driver_opts:
      type: none
      o: bind
      device: /home/mmanaoui/data/mariadb
```

### Volume Locations

- **MariaDB Data:** `/home/mmanaoui/data/mariadb`
  - Contains: Database files, system tables, WordPress database
  
- **WordPress Data:** `/home/mmanaoui/data/wordpress`
  - Contains: WordPress core files, themes, plugins, uploads

### Inspecting Volumes

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data

# Check bind mount contents
ls -la /home/mmanaoui/data/mariadb
ls -la /home/mmanaoui/data/wordpress
```

### Backing Up Data

```bash
# Backup MariaDB
docker exec mariadb mysqldump -u root -p wordpress > backup-db.sql

# Backup WordPress files
tar -czf wordpress-backup.tar.gz /home/mmanaoui/data/wordpress/

# Combined backup script
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
docker exec mariadb mysqldump -u root -p$ROOT_PASS wordpress > "backup-db-$DATE.sql"
tar -czf "backup-wp-$DATE.tar.gz" /home/mmanaoui/data/wordpress/
```

### Restoring Data

```bash
# Restore database
docker exec -i mariadb mysql -u root -p wordpress < backup-db.sql

# Restore WordPress files
tar -xzf wordpress-backup.tar.gz -C /
```

### Cleaning Volumes

```bash
# Remove named volumes
make downV

# Remove all unused volumes
make cleanV

# Manual cleanup
docker volume rm inception_mariadb_data inception_wordpress_data

# Clean bind mount data
sudo rm -rf /home/mmanaoui/data/mariadb/*
sudo rm -rf /home/mmanaoui/data/wordpress/*
```

## Networking

### Network Configuration

The project uses a custom bridge network named `inception`:

```yaml
networks:
  inception:
    driver: bridge
```

### Network Inspection

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception

# View connected containers
docker network inspect inception | grep -A 10 Containers
```

### Internal Communication

Containers communicate using service names as hostnames:

- WordPress connects to MariaDB: `mariadb:3306`
- Nginx connects to WordPress: `wordpress:9000`

### Port Mapping

Only Nginx exposes ports to the host:

```yaml
ports:
  - "443:443"  # HTTPS only
```

MariaDB and WordPress use `expose` for internal-only access:

```yaml
expose:
  - "3306"  # MariaDB (internal)
  - "9000"  # WordPress PHP-FPM (internal)
```

### Testing Network Connectivity

```bash
# From host to nginx
curl -k https://mmanaoui.42.fr

# From WordPress to MariaDB
docker exec wordpress nc -zv mariadb 3306

# From Nginx to WordPress
docker exec nginx nc -zv wordpress 9000
```

## Security

### Docker Secrets

The project uses Docker Secrets for sensitive data:

```yaml
secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt
  db_password:
    file: ../secrets/db_password.txt
  admin_password:
    file: ../secrets/admin_password.txt
  user_password:
    file: ../secrets/user_password.txt
```

Secrets are mounted at `/run/secrets/` inside containers.

### SSL/TLS Configuration

Nginx generates a self-signed certificate on first run:

- **Certificate:** `/etc/nginx/ssl/nginx.crt`
- **Private Key:** `/etc/nginx/ssl/nginx.key`
- **Protocols:** TLSv1.2 and TLSv1.3

For production, replace with a valid certificate from Let's Encrypt.

### Security Best Practices

1. **Never commit secrets to Git:**
   ```bash
   # Add to .gitignore
   secrets/*.txt
   ```

2. **Use strong passwords:**
   - Minimum 12 characters
   - Mix uppercase, lowercase, numbers, symbols

3. **Restrict file permissions:**
   ```bash
   chmod 600 secrets/*.txt
   ```

4. **Regular updates:**
   ```bash
   docker compose pull
   docker compose up -d --build
   ```

5. **Monitor logs for suspicious activity:**
   ```bash
   docker compose logs -f | grep -i "error\|fail\|unauthorized"
   ```

## Development Workflow

### Making Changes

1. **Modify Configuration:**
   - Edit files in `srcs/requirements/`
   - Update `docker-compose.yml` if needed

2. **Rebuild Affected Service:**
   ```bash
   docker compose -f srcs/docker-compose.yml build --no-cache <service>
   ```

3. **Restart Service:**
   ```bash
   docker compose -f srcs/docker-compose.yml up -d <service>
   ```

4. **Test Changes:**
   ```bash
   docker compose -f srcs/docker-compose.yml logs -f <service>
   ```

### Adding New Services

1. Create service directory structure
2. Write Dockerfile
3. Add service to `docker-compose.yml`
4. Configure networking and volumes
5. Build and test

### Testing Configuration Changes

```bash
# Test Nginx configuration
docker exec nginx nginx -t

# Test MariaDB configuration
docker exec mariadb mysqld --help --verbose | grep my.cnf

# Test PHP configuration
docker exec wordpress php -i
```

## Debugging

### Common Issues

**Container won't start:**
```bash
# Check logs
docker compose -f srcs/docker-compose.yml logs <service>

# Check for port conflicts
sudo netstat -tlnp | grep <port>

# Verify configuration
docker compose -f srcs/docker-compose.yml config
```

**Database connection fails:**
```bash
# Test from WordPress container
docker exec wordpress nc -zv mariadb 3306

# Check MariaDB logs
docker compose -f srcs/docker-compose.yml logs mariadb

# Verify credentials
docker exec wordpress cat /run/secrets/db_password
```

**WordPress installation issues:**
```bash
# Check WordPress CLI
docker exec wordpress wp --info

# Verify database
docker exec mariadb mysql -u wordpress -p -e "SHOW DATABASES;"

# Check file permissions
docker exec wordpress ls -la /var/www/html
```

### Performance Profiling

```bash
# Container resource usage
docker stats

# Network throughput
docker exec nginx sh -c "cat /var/log/nginx/access.log | wc -l"

# Database performance
docker exec mariadb mysqladmin status -u root -p
```

### Advanced Debugging

```bash
# Enable verbose logging
docker compose -f srcs/docker-compose.yml --verbose up

# Inspect running processes
docker exec mariadb ps aux
docker exec wordpress ps aux

# Check disk usage
docker system df
docker system df -v
```

## Data Persistence

### Where Data is Stored

All persistent data is stored in bind-mounted directories:

- **Host Path:** `/home/mmanaoui/data/`
- **MariaDB:** `/home/mmanaoui/data/mariadb/` → `/var/lib/mysql` (in container)
- **WordPress:** `/home/mmanaoui/data/wordpress/` → `/var/www/html` (in container)

### Persistence Behavior

- Data persists when containers are stopped (`make down`)
- Data persists when containers are removed
- Data is removed only with `make downV` or manual deletion
- Data is accessible from the host filesystem

### Verifying Persistence

```bash
# Create test data
docker exec wordpress touch /var/www/html/test.txt

# Stop containers
make down

# Verify file exists on host
ls -la /home/mmanaoui/data/wordpress/test.txt

# Start containers
make up

# Verify file exists in container
docker exec wordpress ls -la /var/www/html/test.txt
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress Developer Documentation](https://developer.wordpress.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)