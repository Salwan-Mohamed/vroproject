# VProfile Microservices Kubernetes Deployment

## Project Overview

VProfile is a multi-tier web application deployed on Kubernetes, leveraging microservices architecture. The project demonstrates a robust, scalable, and containerized application using modern DevOps practices.

## Architecture

The application consists of the following microservices:
- Nginx (Web Server)
- Tomcat (Application Server)
- MySQL (Database)
- RabbitMQ (Message Broker)
- Memcached (Caching Layer)

## Prerequisites

- Kubernetes Cluster
- kubectl
- Docker
- OpenEBS (for local persistent storage)
- MetalLB (for LoadBalancer support)

## Project Structure

```
├── app/                # Tomcat Application Server
├── db/                 # MySQL Database Configuration
├── k8s/                # Kubernetes Deployment Files
├── mc/                 # Memcached Configuration
├── rmq/                # RabbitMQ Configuration
├── web/                # Nginx Web Server Configuration
```

## Deployment Components

### 1. Namespace
- Creates `vproproject` namespace for all resources

### 2. Secrets
- Manages sensitive information for:
  - Database credentials
  - RabbitMQ credentials

### 3. ConfigMaps
- Stores configuration for:
  - Application properties
  - Nginx configuration
  - RabbitMQ configuration

### 4. Storage
- Uses OpenEBS for persistent storage
- Provisions PersistentVolumeClaims for MySQL and RabbitMQ

### 5. Services
- Defines services for each microservice
- Includes internal and load-balanced services

### 6. Deployments/StatefulSets
- Tomcat Application: Horizontal Pod Autoscaler configured
- Nginx Web Server
- RabbitMQ
- MySQL

### 7. Ingress
- Configured for routing external traffic

## Deployment Steps

1. Create Namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

2. Apply Secrets
```bash
kubectl apply -f k8s/secrets.yaml
```

3. Apply ConfigMaps
```bash
kubectl apply -f k8s/configmap.yaml
```

4. Setup Storage
```bash
kubectl apply -f k8s/storage.yaml
```

5. Deploy Services
```bash
kubectl apply -f k8s/
```

## Key Features

- Multi-tier application architecture
- Kubernetes native deployment
- Secret management
- Dynamic scaling
- Health checks and probes
- Persistent storage
- Load balancing

## Monitoring and Scaling

- HorizontalPodAutoscaler configured for Tomcat application
- Scales based on CPU and memory utilization
- Minimum 3, maximum 10 replicas

## Security Considerations

- Secrets stored in base64 encoded format
- Resource limits and requests defined
- Network isolation through namespace
- Health checks for service reliability

## Customization

Modify the following files to customize the deployment:
- `k8s/secrets.yaml`: Update credentials
- `k8s/configmap.yaml`: Adjust configuration parameters
- Individual Dockerfiles for service-specific customizations

## Troubleshooting

1. Check pod status:
```bash
kubectl get pods -n vproproject
```

2. View logs:
```bash
kubectl logs <pod-name> -n vproproject
```

3. Describe resources:
```bash
kubectl describe <resource-type> <resource-name> -n vproproject
```

## Tools and Versions

- Kubernetes: Compatible with v1.20+
- Docker Images:
  - Tomcat: 9.0-jdk11
  - MySQL (MariaDB): 10.5
  - Nginx: 1.22
  - RabbitMQ: 3.8 with management plugin
  - Memcached: 1.6

## Maintainer

Salwan Saied

## License

[Specify License - e.g., MIT, Apache 2.0]

## Contributing

Contributions are welcome! Please submit pull requests or open issues on the project repository.
