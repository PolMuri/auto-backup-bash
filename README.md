# auto-backup-bash
 Bash script that automates the backup process for a MySQL database

It performs the following tasks:

-Database Backup: Dumps a specific table from the database, compresses the backup using gzip, and stores it locally.
-Remote Directory Management: Creates a directory on a remote server via sftp if it doesn't already exist.
-Old Backup Cleanup: Connects to the remote server, lists backup files, and deletes older backups based on defined retention policies.
-File Upload: Uploads the latest backup file to the remote server using sftp.
-Report Generation: Logs all actions to a report file, detailing success or failure for each step.
-Email Notification: Sends the generated report via email to a specified recipient.

The script ensures directory creation, error handling (to some extent), and uses SSH keys for secure remote access.
