# This program is used to decrypt/encrypt MIUI temperature control configuration files

### Clean up
-Delete the files in the `origin` `decrypted` `encrypted` directory

### Decrypt temperature control
-Put the original temperature control configuration file under `origin`
-Run `d.sh`, the decrypted file will be output to the `decrypted` directory

### Encrypted temperature control
-After modifying the decrypted temperature control configuration file in `decrypted`
-Run `e.sh`, the encrypted file will be output under `encrypted`

### Note
-Some temperature control configuration files of MIUI are not encrypted
-When performing decryption operations, these files will be skipped, please pay attention!
