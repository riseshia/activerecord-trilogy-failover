-- Admin user with SUPER privilege (can SET GLOBAL read_only)
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;

-- App user WITHOUT SUPER (will get error 1290 on writes when read_only=1)
CREATE USER 'app'@'%' IDENTIFIED BY 'app';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX ON failover_test.* TO 'app'@'%';

FLUSH PRIVILEGES;
