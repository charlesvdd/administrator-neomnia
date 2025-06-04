### Execution of `gitexe.sh`

- To run the script as root, you should execute:
- ```bash
- sudo curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/gitexe.sh | bash
- ```
- Or alternatively, in two steps:
- ```bash
- curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/gitexe.sh -o gitexe.sh
- sudo bash gitexe.sh
- ```

Now, `gitexe.sh` will self-evaluate and restart itself as root if necessary. Therefore, you can simply do:
```bash
curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/gitexe.sh | bash
```
Without any other options; the script detects that it is not running as root and automatically restarts with `sudo` for you.
