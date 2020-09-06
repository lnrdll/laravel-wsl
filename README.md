# laravel-wsl

Bootstrap script to configure a Laravel **development** environment on Windows Systems for Linux. For WSL2 setup, checkout the [laravel-wsl2](https://github.com/rlunardelli/laravel-wsl) repository.

**Shout-Out**: Some of the instructions here and the tasks for the bootstrap script were taken from this nice [tutorial](https://dev-squared.com/2018/05/15/getting-started-with-laravel-development-on-windows-subsystem-for-linux-with-vs-code-a-complete-guide/).

## Setup

### Enable WSL

Follow the instructions in this [documentation](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Once you get WSL enabled, go ahead and install Debian.

### Bootstrap script

Once your WSL is up and running, download the bootstrap script and run it on your WSL. It will perform the following tasks:

1. Update Linux
2. Install and configure PHP 7.3
3. Install MariaDB
4. Install Redis
5. Install composer and valet
6. Install and configure vim
7. Configure xdebug

**Note**: The boostrap script was tested only on a Debian WSL.

### Docroot

Create a docroot where your code will exist. Since the Windows filesystem can be accessed from the WSL `/mnt/`, create a directory shared between the two spaces and symlinked it from your home directory in WSL.

```
ln -s /mnt/c/Users/<username>/<code_directory> ~/code
```

Run `valet` from within this new directory:

```
valet park
```

### DNS

Download and install [Acrylic DNS Proxy](http://mayakron.altervista.org/wikibase/show.php?id=AcrylicHome) on your Windows machine so you can wildcard domains for local development.

From the Acrylic folder in the start menu, click on "**Edit Acrylic Hosts file**". Add the following line to the bottom:

```
127.0.0.1   *.test
```

Change your network adapter DNS settings to point to 127.0.0.1. You can follow the instructions [here](https://www.windowscentral.com/how-change-your-pcs-dns-settings-windows-10).

**Note**: Now any requests to `<whatever>.test` will be routed to the appropriate named Valet folder.

### Init Laravel

In WSL, navigate to the your code directory and the run the following:

```
composer create-project --prefer-dist laravel/laravel blog
```

Composer will create a `blog` folder will all the boilerplate. You should be able to access it at: ``http://blog.test``.

### VS Code

#### PHP

To get all the VS Code goodness to work with PHP on your Windows box, you need to download the extension [Remote WSL](https://code.visualstudio.com/remote-tutorials/wsl/run-in-wsl). VS Code will add itself to your `%PATH%`, so from the WSL console you can type `code .` to open VS Code on that folder. If for some reason, VS Code is not in your path, you can modify your `~/.bashrc` and add VS Code to your path. By default, VS Code is installed under `C:\users\{username}\AppData\Local\Programs\Microsoft VS Code`.

Add this line to your path:

```
export PATH=$PATH:/mnt/c/Users/{username}/AppData/Local/Programs/Microsoft VS Code/bin"
```

#### Extensions

1. [advanced-new-file](https://marketplace.visualstudio.com/items?itemName=patbenatar.advanced-new-file)
2. [Better Align](https://marketplace.visualstudio.com/items?itemName=wwm.better-align)
3. [Better PHPUnit](https://marketplace.visualstudio.com/items?itemName=calebporzio.better-phpunit)
4. [Bracket Pair Colorizer](https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer)
5. [File Utils](https://marketplace.visualstudio.com/items?itemName=sleistner.vscode-fileutils)
6. [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)
7. [Path Intellisense](https://marketplace.visualstudio.com/items?itemName=christian-kohler.path-intellisense)
8. [PHP Debug](https://marketplace.visualstudio.com/items?itemName=felixfbecker.php-debug)
9. [PHP Intelephense](https://marketplace.visualstudio.com/items?itemName=bmewburn.vscode-intelephense-client)
10. [PHP Getters & Setters](https://marketplace.visualstudio.com/items?itemName=phproberto.vscode-php-getters-setters)
11. [PHP import checker](https://marketplace.visualstudio.com/items?itemName=marabesi.php-import-checker)
12. [PHP Mess Detector](https://marketplace.visualstudio.com/items?itemName=ecodes.vscode-phpmd)
13. [phpfmt - PHP formatter](https://marketplace.visualstudio.com/items?itemName=kokororin.vscode-phpfmt)
14. [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
15. [Polacode](https://marketplace.visualstudio.com/items?itemName=pnp.polacode)
16. [Settings Sync](https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync)

#### Terminal

In case you need to configure VS Code Shell to use the WSL environment, you'll have to update the user's profile settings.

* `File -> Preferences -> Settings`

Then, you'll change/add the following property:

```
"terminal.integrated.shell.windows": "C:\\Windows\\Sysnative\\bash.exe"
```

## License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details
