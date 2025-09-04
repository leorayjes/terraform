resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "main-db-subnet-group"
  }
}
resource "aws_db_instance" "main" {
  identifier             = "hackathon-database"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  
  db_name  = "hackathon"
  username = "admin"
  password = "password123"
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  publicly_accessible = true
  
  storage_encrypted = false
  
  backup_retention_period = 0
  backup_window          = "00:00-01:00"
  
  maintenance_window = "sun:01:00-sun:02:00"
  
  auto_minor_version_upgrade = false
  
  deletion_protection = false
  
  skip_final_snapshot = true
  
  monitoring_interval = 0
  
  enabled_cloudwatch_logs_exports = []

  tags = {
    Name = "hackathon-database"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.public.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "hackathon-redis"
  description                = "Redis cluster for hackathon"
  
  node_type                  = "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = 2
  
  at_rest_encryption_enabled = false
  
  transit_encryption_enabled = false
  
  auth_token = ""
  
  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.database.id]
  
  snapshot_retention_limit = 0
  
  tags = {
    Name = "hackathon-redis"
  }
}

resource "aws_docdb_subnet_group" "docdb" {
  name       = "docdb-subnet-group"
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "docdb-subnet-group"
  }
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "hackathon-docdb"
  engine                  = "docdb"
  master_username         = "admin"
  master_password         = "password123"
  db_subnet_group_name    = aws_docdb_subnet_group.docdb.name
  vpc_security_group_ids  = [aws_security_group.database.id]
  
  storage_encrypted = false
  
  backup_retention_period = 1
  preferred_backup_window = "07:00-09:00"
  
  skip_final_snapshot = true
  
  tags = {
    Name = "hackathon-docdb"
  }
}