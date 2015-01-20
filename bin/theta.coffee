#!/usr/bin/env coffee

fs   = require 'fs'
path = require 'path'

optparse = require 'optparse'

Theta = require path.resolve("#{__dirname}/../")
theta = new Theta

config = {}

parser = new optparse.OptionParser [
  ['-h', '--help', 'show help']
  ['--capture [FILENAME]', 'take a picture']
  ['--list', 'list pictures']
  ['--id [Object ID]', 'specify picture by ID']
  ['--save [FILENAME]', 'save picture']
  ['--delete [Object ID]', 'delete a picture']
  ['--battery', 'check battery level']
]

parser.on 'help', ->
  package_json = require "#{__dirname}/../package.json"
  parser.banner = """
  theta v#{package_json.version} - #{package_json.homepage}

  Usage:
    % theta --capture
    % theta --capture out.jpg
    % theta --list
    % theta --id [object_id] --save out.jpg
    % theta --delete [object_id]
    % DEBUG=* theta --capture  # print all debug messages
  """
  console.log parser.toString()
  return process.exit 0

savePicture = (object_id, filename) ->
  theta.getPicture object_id, (err, picture) ->
    if err
      console.error err
      return process.exit 1
    fs.writeFile filename, picture, (err) ->
      console.log "picture (ID:#{object_id}) saved => #{filename}"
      theta.disconnect()

parser.on 'capture', (opt, filename) ->
  theta.connect()
  theta.once 'connect', ->
    theta.capture (err) ->
      if err
        console.error err
        return process.exit 1
      console.log 'capture success'
      unless filename
        return theta.disconnect()

  theta.once 'objectAdded', (object_id) ->
    savePicture object_id, filename

parser.on 'list', ->
  theta.connect()
  theta.once 'connect', ->
    theta.listPictures (err, object_ids) ->
      console.log "Object IDs: #{JSON.stringify(object_ids)}"
      console.log "#{object_ids.length} pictures"
      theta.disconnect()

parser.on 'id', (opt, object_id) ->
  config.object_id = object_id

parser.on 'save', (opt, filename) ->
  unless typeof config.object_id is 'string'
    console.error '"--id=[object_id]" option required'
    return process.exit 1
  theta.connect()
  theta.once 'connect', ->
    savePicture config.object_id, filename

parser.on 'delete', (opt, object_id) ->
  theta.connect()
  theta.once 'connect', ->
    theta.deletePicture object_id, (err) ->
      if err
        console.error err
        return process.exit 1
      console.log "delete #{object_id} success"
      theta.disconnect()

parser.on 'battery', ->
  theta.connect()
  theta.once 'connect', ->
    theta.getBatteryLevel (err, res) ->
      if err
        console.error err
        return process.exit 1
      console.log "BatteryLevel: #{res.dataPacket.toString()}"
      theta.disconnect()

if process.argv.length < 3
  parser.on_switches.help.call()

parser.parse process.argv
