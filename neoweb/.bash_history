ssh-keygen -t rsa -b 4096 -C "chvandendriessche@neomnia.net"
ls -ld /home/neoweb/.ssh
ls -l /home/neoweb/.ssh
ssh neoweb@148.113.46.144
ls -l ~/.ssh/*.pem
sudo i-
ls -l ~/.ssh/*.pem
sudo i-
sudo -i
sudo -u neoweb whoami
ls -l ~/.ssh/
ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/neoweb_key.pem
sudo systemctl status ssh
ssh-keygen -t rsa -b 4096 -C "chvandendriessche@neomnia.net"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chown neoweb:neoweb ~/.ssh
ssh-keygen -t rsa -b 4096 -C "chvandendriessche@neomnia.net"
su - neoweb
sudo apt update
sudo -i
tail -f log/production.log
sudo su - root
gem install foreman
RAILS_ENV=production foreman start -f Procfile -e .env
sudo -i
sudo su - root
whoami
sudo i-
sudo -i
cd var/backups
git pull origin main --rebase
git status
ps aux | grep git
CTRL + C
kill 99557
git reset
git add *.sh
git add *.tar.gz
git add *.sql
git status
git commit -m "Ajout de la sauvegarde automatique du VPS"
git push origin main
ls -t /var/backups | head -n1
/bin/bash /var/backups/backup_vps.sh
cd /var/backups
git init
git remote add origin git@github.com:neoweb2212/attol-project.git
git remote -v
git remote remove origin
git remote -v
git remote add origin git@github.com:neoweb2212/attol-project.git
git remote -v
LATEST_FILE=$(ls -t /var/backups | head -n1)
git add "$LATEST_FILE"
git commit -m "Sauvegarde automatique du VPS : $(date +%Y-%m-%d)"
git push origin main
git status
cat .gitignore
git add -f "$LATEST_FILE"
git commit -m "Force ajout de la sauvegarde automatique du VPS : $(date +%Y-%m-%d)"
git push origin main
ssh -T git@github.com
ssh-add -l
ssh-add ~/.ssh/id_rsa
nano ~/.ssh/config
ssh -T git@github.com
git push origin main
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
ssh-add -l
ssh-add ~/.ssh/id_rsa
ssh-add -l
ssh -T git@github.com
cat ~/.ssh/id_rsa.pub
ssh -T git@github.com
git remote -v
git remote set-url origin git@github.com:neoweb2212/attol-project.git
LATEST_FILE=$(ls -t /var/backups | head -n1)
git add "$LATEST_FILE"
git commit -m "Sauvegarde automatique du VPS : $(date +%Y-%m-%d)"
git push origin main
neoweb@vps-5462d7d7-vps-ovh-ca:/var/backups$ LATEST_FILE=$(ls -t /var/backups | head -n1)
git add "$LATEST_FILE"
git commit -m "Sauvegarde automatique du VPS : $(date +%Y-%m-%d)"
git push origin main
On branch main
nothing to commit, working tree clean
To github.com:neoweb2212/attol-project.git
error: failed to push some refs to 'github.com:neoweb2212/attol-project.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note 

sudo apt-get update
cd ~/.ssh
ls -l
cat ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
sudo nano /etc/ssh/sshd_config
ssh-copy-id -i ~/.ssh/id_rsa.pub neoweb@148.113.46.144
ssh neoweb@148.113.46.144
cd/var/backups
cd var/backups
git push origin main
git status
ls -l /opt/huginn/public/assets/
sudo chown -R huginn:huginn /opt/huginn/public/assets
sudo chmod -R 755 /opt/huginn/public/assets
sudo chown -R neoweb:neoweb /opt/huginn/public/assets
sudo chmod -R 755 /opt/huginn/public/assets
ps aux | grep huginn
sudo systemctl restart nginx
sudo netstat -tulnp | grep -E '80|443'
sudo systemctl restart apache2
cd /home/huginn/huginn
bundle exec rake assets:precompile RAILS_ENV=production
find / -type d -name "huginn" 2>/dev/null
ls -l /opt/huginn/public/assets
cd /opt/huginn
sudo -u huginn -H bash -c "bundle exec rake assets:precompile RAILS_ENV=production"
export RAILS_SERVE_STATIC_FILES=true
export RAILS_ENV=production
sudo chown -R huginn:huginn /opt/huginn/public/assets
sudo chmod -R 755 /opt/huginn/public/assets
getent passwd huginn
export RAILS_SERVE_STATIC_FILES=true
export RAILS_ENV=production
cd /opt/huginn
cp env.example .env.production
nano .env.production
sudo chown huginn:huginn /opt/huginn/.env.production
sudo chmod 600 /opt/huginn/.env.production
ls -l /opt/huginn/public/android-chrome-48x48.png
ls -l /opt/huginn/public/android-chrome-192x192.png
cd /opt/huginn
RAILS_ENV=production bundle exec rake assets:precompile*
sudo systemctl restart huginn
RAILS_ENV=production bundle exec rake assets:precompile
ps aux | grep huginn
tail -f /opt/huginn/log/production.log
git push --force origin main
cd /var/backups
git push --force origin main
git lfs track "*.tar.gz"
git add .gitattributes
git commit -m "Ajout du support Git LFS"
git push origin main
docker logs huginn
sudo -i
cd var/backups
ssh -T git@github.com
cat ~/.ssh/id_ed25519.pub
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
ssh-keygen -p -f ~/.ssh/id_ed25519
ssh -T git@gitub.com
ssh -T git@github.com
ls -lt /var/backups | head -n 5
bash var/backups/backup_vps.sh
bash /var/backups/backup_vps.sh
cd /var/backups  # Aller dans le dossier des sauvegardes
LATEST_FILE=$(ls -t | head -n1)  # Récupérer le dernier fichier créé
git add "$LATEST_FILE"  # Ajouter le fichier au dépôt Git
git commit -m "🔄 Sauvegarde automatique du VPS : $LATEST_FILE"
git push origin main  # Pousser sur GitHub
ssh -T git@github.com
ssh-keygen -p -f /home/neoweb/.ssh/id_rsa
sudo -i
ssh -T git@github.com
ssh-keygen -p -f /home/neoweb/.ssh/id_rsa
ssh -T git@github.com
eval "$(ssh-agent -s)"
ssh-add /home/neoweb/.ssh/id_rsa
cd /var/backups
LATEST_FILE=$(ls -t | head -n1)
git add "$LATEST_FILE"
git commit -m "🔄 Sauvegarde automatique du VPS : $LATEST_FILE"
git push origin main
git status
git pull origin main --rebase
sudo -i
cd opt/n8n
sudo apt update && sudo apt install git -y
git config --global user.name "neoweb2212"
git config --global user.email "chvandendriessche@neomnia.net"
ssh -T git@github.com
ls -al ~/.ssh
ssh-keygen -t ed25519 -C "chvandendriessche@neomnia.net"
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git remote add origin git@github.com:neoweb2212/attol-project.git
mkdir -p /home/neoweb/attol-project
cd /home/neoweb/attol-project
git init
git remote add origin git@github.com:neoweb2212/attol-project.git
git remote -v
echo "Test de connexion SSH avec GitHub" > test.txt
git add test.txt
git commit -m "Premier commit - Test connexion SSH"
git branch -M main
git push -u origin main
git pull --rebase origin main
git add .
git rebase --continue
git push -u origin main
sudo zip -r ~/attol-project/vps_backup_$(date +'%Y%m%d').zip /     -x "/proc/*" "/sys/*" "/dev/*" "/run/*" "/mnt/*" "/media/*" "/lost+found/*"
sudo -i
git --version
sudo apt update
sudo apt install git -y
cd /var/backups
git init
echo "*.log" >> .gitignore
echo "*.tmp" >> .gitignore
echo "cache/" >> .gitignore
git add .gitignore
git commit -m "Ajout du fichier .gitignore"
git add .
git commit -m "Sauvegarde initiale de /var/backups"
git remote add origin https://github.com/votre-utilisateur/backups-repo.git
git branch -M main
git push -u origin main
git remote set-url origin git@github.com:votre-utilisateur/backups-repo.git
git push -u origin main
git remote -v
git remote set-url origin git@github.com:VOTRE_UTILISATEUR/backups-repo.git
git remote set-url origin git@github.com:neoweb2212/backups-repo.git
ssh -T git@github.com
sudo nano /var/backups/backup_vps.sh
crontab -e
crontab -l
sudo -i
nginx -V
sudo -i
