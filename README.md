# Some Scripts
Some useful scripts I wrote to do things for me

## Index
- `ssh.sh`: Sets up SSH into lab machine from local machine for students of the Department of Computer Science at Imperial College London.
	- Running:
	```sh
	curl https://raw.githubusercontent.com/Gum-Joe/some-tools/master/ssh.sh -o ./ssh.sh
	chmod +x ./ssh.sh
	./ssh.sh <username>
	```
	- Tested on Ubuntu (inc. WSL) & also Git Bash, should work on macOS (but untested on macOS)
	- After setup just:
	```sh
	ssh anylab # to land you in any lab machine
	ssh vscodelab # use vscodelab target for vscode remote dev (anylab will not work)
	```
s
## Contributing
Contributions are always welcome! Just fork, adjust & open a PR!
