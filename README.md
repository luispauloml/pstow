# PStow
This is a utility for creating symbolic links for files inspired by
[GNU Stow](https://www.gnu.org/software/stow/) that works in Microsoft
PowerShell, hence, the name.

## License
This project was written and is licensed by Luis Paulo Morais Lima
under the MIT License. See [LICENSE](./LICENSE).

## Requirements

* Microsoft PowerShell version 5.1 or above.

* An administrator user account.

  Since Windows Vista, it is necessary to have [proper privileges to
  be able to create symbolic
  links](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc766301(v=ws.10)#create-symbolic-links).
  Therefore, you need to run PowerShell as administrator to use PStow.


## Instalation
Clone this repository and execute `Set-PStow.ps1` in PowerShell:

```
PS > git clone https://github.com/luispauloml/pstow.git
PS > cd .\pstow\
PS > . .\Set-PStow.ps1
```

# Usage
Try `Get-Help Set-PStow -detailed` or `Get-Help pstow -detailed` for
help.
	
## Example
If you already use `stow` in Linux, that means you already have
directories organized the right way.  The next step is to just go the
directory where the package is located and use `Set-PStow` or the
alias `pstow`.  However, unless otherwise told to do differently,
`stow` creates links in the parent directory of the current working
directory, while for PStow there is no default behaviour, and you need
to pass either the destination or a configuration file as a parameter.
If you want to use a configuration file, you can either set a JSON
file named `config.pstow` in current working directory or pass the
path to such a file.

As an example, suppose one wants to use PStow to setup symbolic links
for their configuration of GNU Emacs in Windows.  The first step is to
put all files and directories for which links will be created inside a
single directory whose tree will be replicated at `%APPDATA%`, which
is where GNU Emacs looks for configuration files in Windows.  The
folder will be `emacs` and has the following contents:

```
PS > tree /f /a
Folder PATH listing
Volume serial number is [redacted]
C:.
|
+---emacs
    \---.emacs.d
        |   init.el
        |
        \---lisp
                my-theme.el
```

All needed now is to run `Set-PStow` or `pstow` on `emacs`.
To see what is happening, pass `-Verbose`:

```
PS > pstow emacs $env:appdata -verbose
VERBOSE: found directory 'emacs'
VERBOSE: found directory C:\Users\<user>\AppData\Roaming
VERBOSE: '.emacs.d' is a directory and already exists at destination.
VERBOSE: 'lisp' is a directory and already exists at destination.
VERBOSE: 'my-theme.el' does not exists at destination. Symbolic link will be created.
VERBOSE: 'init.el' does not exists at destination. Symbolic link will be created.
```

## Notes
PStow only creates new symbolic links and does not remember previous
usage.  Therfore, if you want to remove a link created by PStow, you
will need to delete it manually.  However, if you want to overwrite an
already existing link or junction, just pass `-Force` to the command.
