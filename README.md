mattermost for Docker
=====================

Docker container for [Mattermost](http://www.mattermost.org).

Still experimental, Mattermost itself is considered beta.

## Requirements

You will need a MySQL or MariaDB database server, and configure a database DSN for Mattermost to use.
Of course you can use a Docker container for that.

All you need to do is create a database and grant a user:

```
CREATE DATABASE mattermost;
GRANT ALL ON mattermost.* TO mattermost@'172.17.%' IDENTIFIED BY 'password';
```

## Usage

Example usage with a linked mariadb container:

```
docker run -it --rm \
  --link mariadb:mysql \
  -e DATABASE_DSN="mattermost:password@tcp(mysql:3306)/mattermost?charset=utf8mb4,utf8" \
  -v /data/docker/mattermost/data:/data \
  -p 8102:8080 \
  lazyfrosch/mattermost
```

The Docker [entrypoint](entrypoint.sh) will copy a [default config](config.default.json) file to `/data/config.json`.

The entrypoint will also:
 * update database DSN if necessary
 * fill salt and encryption hashes with random generated data (only once)

Feel free to change `/data/config.json`, but be **careful**.

All local filesystem data will be stored in `/data/storage`, while the logs get written to `/data/logs`.

After the entrypoint is done, mattermost itself will run under a non-privileged user `mattermost`. See [mattermost](mattermost) script, which is the default CMD.

## License

    Copyright (c) 2015 Markus Frosch <markus@lazyfrosch.de>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
