# Inception

*This project has been created as part of the 42 curriculum by [mmanaoui].*

## Description

**Inception** is a system administration project that challenges students to set up a complete web infrastructure using Docker containers. The project involves containerizing and orchestrating multiple services—MariaDB, WordPress, and Nginx—in a secure, isolated environment following best practices for production deployments.

### Project Goal

The primary objective is to deepen understanding of:

- **Docker containerization** and multi-container applications
- **Service orchestration** using Docker Compose
- **Network isolation** and inter-container communication
- **Data persistence** and volume management
- **Security practices** including secrets management and SSL/TLS configuration
- **Infrastructure as Code** principles

### Brief Overview

The Inception infrastructure consists of three interconnected Docker containers:

1. **MariaDB Container** - Database server storing all WordPress data
2. **WordPress Container** - Content management system with PHP-FPM processing dynamic requests
3. **Nginx Container** - Reverse proxy and web server handling HTTPS traffic

All services communicate through a custom Docker network, with data persisting in bind-mounted volumes. The system exposes only port 443 (HTTPS) to the outside world, with internal services isolated from direct external access.

## Instructions

### Prerequisites

- Linux operating system (Debian/Ubuntu recommended)
- Docker Engine (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- GNU Make
- Root or sudo privileges
- Minimum 2GB RAM and 5GB disk space

### Installation

1. **Clone the repository:**

```bash
git clone <repository-url>
cd inception
```

2. **Configure the domain:**

Add the domain to your `/etc/hosts` file:

```bash
sudo sh -c 'echo "127.0.0.1    mmanaoui.42.fr" >> /etc/hosts'
```

3. **Set up secrets:**

The `secrets/` directory contains password files. For security, update these before deployment:

```bash
echo "your_admin_password" > secrets/admin_password.txt
echo "your_user_password" > secrets/user_password.txt
echo "your_db_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
```

4. **Build and launch:**

```bash
make
```

This command will:
- Create necessary data directories at `/home/mmanaoui/data/`
- Build all Docker images in parallel
- Start all services in detached mode

### Accessing the Application

Once the services are running:

- **Website:** https://mmanaoui.42.fr
- **Admin Panel:** https://mmanaoui.42.fr/wp-admin

**Note:** You'll receive a security warning due to the self-signed SSL certificate. This is expected for development environments.

### Default Credentials

- **Admin Username:** wpowner
- **Admin Password:** Check `secrets/admin_password.txt`
- **Author Username:** author
- **Author Password:** Check `secrets/user_password.txt`

### Managing the Infrastructure

```bash
make          # Build and start everything
make down     # Stop all containers
make downV    # Stop containers and remove volumes
make restart  # Restart all services
make cleanV   # Remove all Docker volumes
```

### Verification

Check if all containers are running:

```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, and `mariadb`.

## Project Description

### Docker in This Project

This project leverages **Docker** to create a reproducible, isolated web infrastructure. Each service (MariaDB, WordPress, Nginx) runs in its own container with minimal dependencies, providing:

- **Isolation:** Services run independently without interfering with the host system or each other
- **Reproducibility:** The infrastructure can be rebuilt identically on any Docker-capable system
- **Portability:** The entire stack can be moved between environments seamlessly
- **Resource Efficiency:** Containers share the host kernel, using fewer resources than traditional VMs

### Source Files Overview

#### `/srcs/docker-compose.yml`
The orchestration file defining all services, networks, volumes, and secrets. It coordinates the three containers and their dependencies.

#### `/srcs/requirements/mariadb/`
- **Dockerfile:** Builds MariaDB image from Debian 11
- **conf/my.cnf:** Custom MariaDB configuration optimizing performance and security
- **tools/init.sh:** Initialization script creating databases, users, and setting passwords

#### `/srcs/requirements/wordpress/`
- **Dockerfile:** Builds WordPress image from Alpine with PHP-FPM and WP-CLI
- **tools/configure.sh:** Setup script configuring WordPress and creating users

#### `/srcs/requirements/nginx/`
- **Dockerfile:** Builds Nginx image from Alpine with OpenSSL
- **conf/nginx.conf:** Nginx configuration template with SSL and FastCGI settings
- **tools/ssl_setup.sh:** Generates self-signed SSL certificates and starts Nginx

#### `/secrets/`
Contains sensitive credentials as plain text files, mounted into containers as Docker secrets.

### Design Choices

#### Service Separation
Each component (database, application, web server) runs in its own container, following the single-responsibility principle. This separation:
- Simplifies debugging and monitoring
- Allows independent scaling of services
- Enables zero-downtime updates of individual components
- Improves security through isolation

#### Base Image Selection
- **MariaDB:** Debian 11 for stability and comprehensive package support
- **WordPress & Nginx:** Alpine Linux for minimal image size and attack surface

#### Network Configuration
Uses a custom bridge network (`inception`) providing:
- DNS-based service discovery (services communicate via container names)
- Network isolation from other Docker networks
- Built-in load balancing between container instances

#### Volume Strategy
Employs bind mounts rather than Docker-managed volumes for direct host filesystem access, simplifying backup and recovery procedures.

## Technical Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Architecture** | Full OS with hypervisor | Shared kernel with isolated user space |
| **Boot Time** | Minutes | Seconds |
| **Disk Space** | GBs per VM | MBs per container |
| **Resource Overhead** | High (separate OS per VM) | Low (shared kernel) |
| **Isolation Level** | Complete hardware virtualization | Process-level isolation |
| **Performance** | Near-native to slower | Near-native |
| **Portability** | Heavy VM images | Lightweight container images |
| **Use Case** | Full OS isolation, legacy apps | Microservices, cloud-native apps |

**Why Docker for Inception:**
Docker provides sufficient isolation for this web stack while maintaining excellent performance and minimal resource consumption. The ability to version control the entire infrastructure as code and rapidly deploy consistent environments makes Docker ideal for development and testing workflows.

### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|----------------|----------------------|
| **Storage** | Encrypted in Docker's internal DB | Plain text in container config |
| **Access** | Mounted as files in `/run/secrets/` | Available as `$VAR` in process env |
| **Visibility** | Not visible in `docker inspect` | Visible in `docker inspect` |
| **Security** | Secure - encrypted at rest/transit | Insecure - easily exposed |
| **Rotation** | Can update without rebuilding | Requires container restart |
| **Logging** | Never appears in logs | May accidentally leak in logs |
| **Best For** | Passwords, API keys, certificates | Non-sensitive configuration |

**Why Secrets for Inception:**
Database passwords and WordPress credentials must be protected from accidental exposure. Docker secrets prevent these sensitive values from appearing in container definitions, environment dumps, or logs. The secrets are mounted as read-only files, accessible only to authorized containers.

### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|--------|----------------------|--------------|
| **Isolation** | Containers isolated from host | Container shares host network |
| **Port Mapping** | Explicit port publishing required | Direct access to all ports |
| **Service Discovery** | DNS-based by container name | Requires IP addresses |
| **Security** | Network-level isolation | No network isolation |
| **Performance** | Minimal overhead (~5%) | Zero network overhead |
| **Port Conflicts** | Containers can use same ports | Port conflicts with host |
| **NAT** | Docker provides NAT | No NAT (direct routing) |
| **Use Case** | Standard deployment | Performance-critical apps |

**Why Docker Network for Inception:**
The custom `inception` bridge network provides:
- **Security:** MariaDB and WordPress are completely inaccessible from outside the Docker network
- **Simplicity:** Services communicate using names (e.g., `mariadb:3306`) without hardcoded IPs
- **Flexibility:** Only Nginx exposes port 443, creating a single controlled entry point
- **Standard Practice:** Bridge networks are Docker's recommended approach for multi-container applications

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | User-managed paths |
| **Location** | Docker's storage directory | Any host path |
| **Portability** | Portable across systems | Path-dependent |
| **Permissions** | Docker handles automatically | Manual permission management |
| **Backup** | Requires Docker commands | Standard filesystem tools |
| **Performance** | Optimized by Docker | Native filesystem speed |
| **Sharing** | Difficult to access from host | Easy host access |
| **Best For** | Production databases, stateful apps | Development, host-dependent data |

**Why Bind Mounts for Inception:**
This project uses bind mounts (`/home/mmanaoui/data/`) because:
- **Accessibility:** Admins can directly access data for backup/inspection without Docker commands
- **Simplicity:** Standard Linux tools (`tar`, `rsync`, `cp`) work for backup/restore
- **Transparency:** Data location is explicit and predictable
- **Project Requirements:** The subject specifically requires data storage at `/home/mmanaoui/data/`
- **Development:** Easy to inspect WordPress files and database contents during development

The trade-off of reduced portability is acceptable since the project targets a specific environment with a known data directory structure.

## Resources

### Documentation References

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Networking Guide](https://docs.docker.com/network/)
- [Docker Secrets Management](https://docs.docker.com/engine/swarm/secrets/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [MariaDB Server Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Commands Reference](https://developer.wordpress.org/cli/commands/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx FastCGI Configuration](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

### Tutorials and Articles

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [WordPress Hardening Guide](https://wordpress.org/support/article/hardening-wordpress/)
- [Nginx Security Guide](https://www.acunetix.com/blog/web-security-zone/hardening-nginx/)

### 42 School Resources

- [Inception Subject PDF](https://cdn.intra.42.fr/pdf/pdf/xxxxx/en.subject.pdf)
- 42 Intranet forums and peer discussions
- Previous cohort project examples and evaluations

## AI Usage Disclosure

### Tasks Where AI Was Used

Artificial Intelligence (specifically Claude AI) was utilized for the following aspects of this project:

1. **Documentation Writing:**
   - Generating comprehensive user and developer documentation
   - Creating README with technical comparisons and explanations
   - Structuring documentation for clarity and completeness

2. **Configuration Optimization:**
   - Reviewing Dockerfile best practices
   - Suggesting MariaDB configuration optimizations
   - Nginx SSL/TLS configuration recommendations

3. **Debugging Assistance:**
   - Interpreting Docker error messages
   - Troubleshooting network connectivity issues
   - Identifying permission-related problems

4. **Code Review:**
   - Shell script syntax verification
   - Docker Compose YAML validation
   - Security best practice implementation

### Parts Created With AI

- **Complete Documentation:** USER_DOC.md, DEV_DOC.md, and this README.md were generated with AI assistance
- **Configuration Comments:** Inline documentation in configuration files explaining settings
- **Script Error Handling:** Improved error handling logic in shell scripts

### Parts Created Without AI

- **Core Architecture:** Service structure and inter-container communication design
- **Dockerfiles:** Container build instructions and package selections
- **docker-compose.yml:** Service definitions, networking, and volume configuration
- **Shell Scripts:** Initialization and configuration script logic
- **Nginx Configuration:** Web server and reverse proxy setup
- **SSL Implementation:** Certificate generation and HTTPS configuration
- **Database Schema:** MariaDB initialization and user management
- **WordPress Setup:** WP-CLI commands and site configuration
- **Security Implementation:** Docker secrets setup and credential management

### Development Approach

The project followed an iterative development process:

1. **Research Phase:** Studied Docker, WordPress, MariaDB, and Nginx documentation independently
2. **Implementation Phase:** Built each service container individually, testing thoroughly
3. **Integration Phase:** Connected services and resolved networking/permission issues through debugging
4. **Documentation Phase:** Used AI to create comprehensive, professional documentation based on the working implementation
5. **Review Phase:** Manually verified all documentation against actual project behavior

AI served as a documentation assistant and technical advisor, but the core infrastructure design, implementation, and problem-solving were completed through hands-on development and debugging.

## Project Features

### Security Features

- ✅ HTTPS-only access (TLSv1.2/TLSv1.3)
- ✅ Docker secrets for credential management
- ✅ Network isolation (no direct database access from outside)
- ✅ Non-root processes in containers
- ✅ Minimal container images (Alpine/Debian slim)
- ✅ No hardcoded passwords in code

### Reliability Features

- ✅ Automatic container restart policies
- ✅ Data persistence across container restarts
- ✅ Health checks and dependency management
- ✅ Proper error handling in initialization scripts

### Operational Features

- ✅ Simple Makefile interface
- ✅ Centralized logging
- ✅ Easy backup and restore procedures
- ✅ Clear separation of configuration and secrets

## Additional Information

### System Architecture Diagram

```
Internet
   │
   │ HTTPS (443)
   ▼
┌──────────────────┐
│      Nginx       │  Port 443 → Serves static files
│   (Alpine 3.18)  │            → Proxies PHP to WordPress
└────────┬─────────┘
         │ FastCGI (9000)
         ▼
┌──────────────────┐
│    WordPress     │  Port 9000 → Executes PHP
│   (Alpine 3.18)  │            → Queries database
└────────┬─────────┘
         │ MySQL (3306)
         ▼
┌──────────────────┐
│     MariaDB      │  Port 3306 → Stores data
│   (Debian 11)    │            → Internal only
└──────────────────┘

All containers connected via "inception" bridge network
Data persisted to /home/mmanaoui/data/{mariadb,wordpress}
```

### File Tree

```
inception/
├── Makefile                    # Build automation
├── README.md                   # This file
├── USER_DOC.md                 # End-user documentation
├── DEV_DOC.md                  # Developer documentation
├── secrets/                    # Credentials (not in Git)
│   ├── admin_password.txt
│   ├── user_password.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                    # Environment reference
    ├── docker-compose.yml      # Orchestration config
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── my.cnf
        │   └── tools/
        │       └── init.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        │       └── configure.sh
        └── nginx/
            ├── Dockerfile
            ├── conf/
            │   └── nginx.conf
            └── tools/
                └── ssl_setup.sh
```

## License

This project is part of the 42 School curriculum and follows the school's academic policies.

## Author

**mmanaoui** - 42 Student

For questions or issues, please refer to the documentation files or contact the author through 42's internal messaging system.