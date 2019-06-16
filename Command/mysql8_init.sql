ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'TAKE0one';
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'TAKE0one';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
