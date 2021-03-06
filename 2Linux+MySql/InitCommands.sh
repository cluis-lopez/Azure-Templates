# The admin username you've crated when deploying the VM in Azure
USER=<your username>

# Formatear el disco de datos a fstab. Crear el filesystem, montar y a�adir a fstab.
# Data disk mounted on /mysql_data/data1

sudo bash autodisk.sh

# Initialize package list in the newly installed machine

sudo apt-get update -y

# Install mysql
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password <your mysql password here>'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password <your mysql password here>'

sudo apt-get install mysql-server -y
sudo apt-get install mysql-client -y

# Stop the instance
sudo systemctl stop mysql

# Install JAVA SDK
sudo apt-get install default-jdk -y

# Create a dir under your HOME to pull github
mkdir /home/$USER/CSAP
cd CSAP
git init
git pull https://github.com/cluis-lopez/CSAP.git
