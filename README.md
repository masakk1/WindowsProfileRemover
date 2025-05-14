# WindowsProfileRemover
## English
This script is used to **remove Windows Profiles** in bulk, using the following criteria:

1. must be in $UsersFolder              (by default, C:\Users\)
2. must not be local / must be from AD  (comparing $LocalUsers and $AllUsers)
3. must not be in the whitelist         (which is configurable)
4. must not be loaded or in use
5. must not be anonymous                (special user)

It will show which users is going to remove, and which are to keep. Users to remove are displayed in columns.

### Customise
Change the `$Whitelist` or `$UsersFolder` in the **Variables** section.

If you don't like the criteria, change them in the function `SurveyUsers()` - they are all labeled.

## Spanish/Español
Este script **borra Perfiles de Windows** en masa, usando los siguientes criterios:

1. está en $UsersFolder      (por defecto, C:\Users\)
2. no es local / es de AD    (comparando $LocalUsers y $AllUsers)
3. no está en la whitelist   (la cual es configurable)
4. no está en uso
5. no es anónimo             (usuario especial)

Mostrará qué usuarios va a borrar, y cuales a quedar. Usuarios a borrar se muestran en columnas.

### Customizar
Cambia la `$Whitelist` o el `$UsersFolder` en la sección **Variables**.

Si no estás de acuerdo, o quieres cambiar los criterios, cámbialos en la función `SurveyUsers()` - tienen comentarios.ç

# License/Licencia
WindowsProfileRemover.ps1

GPL 3.0

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

2025 © masakk1
