# Easy php-fpm upgrade

![easy_fpm_upgrade_demonstration](https://github.com/user-attachments/assets/71aaa3c3-178d-48c6-8288-0eddce116edf)

Simple script which look for current installed php modules and custom configs to migrate them into new version.


## Automated installation of a new version of php-fpm on Debian distributions

The script will ask you to specify the new version of PHP to install and the old version from which you want to transfer the configs.

Collects information about the currently installed modules, puts similar ones for the new version.

**Optional**: Transfers custom tuning configs from `/etc/php/*/fpm/pool.d/` - by masks: `x\y\z*www.conf`.

*In php-fpm, the settings are overwritten in alphabetical order of reading files. Default values in `www.conf` will be overlapped from files `x-www*.conf` `y-www*.conf` `z-www*.conf`.
For example: `x-www.override.conf`.*

To remind you about updating the tuning, the errors messages `server reached pm.max_children` will be displayed from `/var/log` folder, if exist.
Outputs a validation of the nginx\apache config and the enabled sites list.

After installation, you must **manually** switch the php version used `update-alternatives --config php` and change the socket to `/etc/nginx/conf.d/php-fpm.conf`.


## Transferring settings from `/etc/php/8.*/fpm/php.ini` to `/etc/php/8.*/fpm/pool.d/z-www.conf`

What for? To improve subsequent tuning, versions updating and custom settings control.

We take the required lines from `../fpm/php.ini`:

```
output_buffering = Off
opcache.interned_strings_buffer=10
```

and bring it to the:

```
php_admin_flag[output_buffering] = Off
php_admin_value[opcache.interned_strings_buffer] = 10
```

`php_admin_flag[]` - for boolean values.
`php_admin_value[]` - for string values.

and transfer these settings to `../fpm/pool.d/z-www.conf`
