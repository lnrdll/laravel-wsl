# laravel-wsl

The script and instructions below will setup an environment for Laravel development on your Windows Systems for Linux.

**Shout-Out**: Some of the instructions here and the tasks for the bootstrap script were taken from this nice [tutorial](https://dev-squared.com/2018/05/15/getting-started-with-laravel-development-on-windows-subsystem-for-linux-with-vs-code-a-complete-guide/).

## Setup

### Enable WSL

Follow the instructions in this [documentation](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Once you get WSL enabled, go ahead and install Ubuntu.

### Bootstrap script

Once your WSL is up and running, download the bootstrap script and run it on your WSL. It will perform the following tasks:

1. Update Linux
2. Install PHP 7.3 and configure it
3. Install MariaDB
4. Install Redis
5. Install composer and valet
6. Install and configure vim
7. Configure xdebug

### Docroot

Create a docroot where your code will exist. Since the Windows filesystem can be access from the WSL `/mnt/`, create a directory shared between the two spaces and symlinked it for your home directory in WSL.

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

### VSCode and PHP

To get all the VS Code goodness to work with PHP on your Windows box, you need to download PHP and configure VS Code to use it.

1. Download PHP and explode the package somewhere on your Windows machine
2. Edit your VS Code settings and point the `php.validate.executablePath` and `php.executablePath` settings to the path of the `php.exe` you just exploded:
```
"php.validate.executablePath":"C:\\Users\\<username>\\php\\php.exe",
"php.executablePath":"C:\\Users\\<username>\\php\\php.exe"
```
3. Restart VS Code
4. Install some PHP packages on your VS Code:
   * PHP Intelephense
   * PHP IntelliSense
