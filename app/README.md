# Quotes Application

FastAPI application that serves random quotes from Azure SQL Database.

## Files

- `app.py` - FastAPI application with single endpoint `/`
- `requirements.txt` - Python dependencies
- `init-db.sql` - Database initialization script

## Deployment

The application is automatically deployed to the VM via cloud-init during infrastructure provisioning.

The app runs as a systemd service on port 8000 and is accessible through the Application Gateway.

