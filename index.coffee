# secrets.coffee
fs = require 'fs'
yael = require 'yael'

PASSWORD = null
plaintext_file = null
encrypted_file = null

main = (options) ->
  cache = options.cache ?= true
  if cache
    PASSWORD       ?= options.password
    plaintext_file ?= options.plaintext_file
    encrypted_file ?= options.encrypted_file || options.plaintext_file + '.yael'
  else
    PASSWORD        = options.password
    plaintext_file  = options.plaintext_file
    encrypted_file  = options.encrypted_file || options.plaintext_file + '.yael'

  # When no plaintext file exists, load from encrypted file.
  if not fs.existsSync plaintext_file
    console.log "Reading secrets from #{encrypted_file}."
    plaintext = main.readEncrypted()
    return plaintext
  # Otherwise, load our settings from the plaintext file.
  console.log "Reading secrets from #{plaintext_file}."
  orig_plaintext = fs.readFileSync(plaintext_file).toString()

  # If a password is present, save an encrypted copy
  if PASSWORD?
    # If encrypted copy doesn't exist yet, save one.
    if not fs.existsSync encrypted_file
      console.log "Saving #{encrypted_file} because it doesn't exist."
      main.saveEncrypted()
    # If encrypted copy does exist, save only if the plaintext is different.
    else
      plaintext = main.readEncrypted()
      if plaintext != orig_plaintext
        # Updated the encrypted file
        console.log "Updating #{encrypted_file} because it has changed."
        main.saveEncrypted()
      else
        console.log "Not updating #{encrypted_file} because nothing has changed."
  # Here ends the reading.
  return orig_plaintext

main.readEncrypted = ->
  # We need secrets! Can we obtain them?
  if not fs.existsSync encrypted_file
    throw Error "Cannot find #{plaintext_file} or #{encrypted_file}"
  if not PASSWORD?
    throw Error "No encryption password was set."
  # Yes we can. Let's decrypt them.
  cipherbuffer = fs.readFileSync encrypted_file
  cipherObject = new yael.CipherObject cipherbuffer
  plaintext = yael.decryptSync PASSWORD, cipherObject
  return plaintext.toString()

main.saveEncrypted = ->
  if not fs.existsSync plaintext_file
    throw Error "Cannot find #{plaintext_file}"
  if not PASSWORD?
    throw Error "No encryption password was set."
  # We have secrets! Load 'em
  plaintext = fs.readFileSync plaintext_file
  # Let's encrypt them and save them.
  cipherObject = yael.encryptSync PASSWORD, plaintext
  cipherbuffer = cipherObject.toBuffer()
  fs.writeFileSync encrypted_file, cipherbuffer

module.exports = main
