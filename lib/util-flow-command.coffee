path = require 'path'
{BufferedProcess} = require 'atom'

run = ({onMessage, onComplete, onFailure, args, cwd}) ->
  options = if cwd then { cwd: cwd } else {}

  stdout = (onMessage, line) ->
    line.split('\n').filter((l)->0 != l.length).map onMessage

  proc = new BufferedProcess
    command: '/Users/lukeh/Downloads/flow/flow'
    args: args
    options: options
    stdout: (data) ->
      console.debug data
      onMessage data
    stderr: (data) ->
      console.debug data
    exit: -> onComplete?()

  # on error hack (from http://discuss.atom.io/t/catching-exceptions-when-using-bufferedprocess/6407)
  proc.process.on 'error', (node_error) ->
    # TODO this error should be in output view log tab
    console.error "Flow utility not found at '/Users/lukeh/Downloads/flow/flow'"
    onFailure?()

  proc

module.exports =

  startServer: ->
    editor = atom.workspace.activePaneItem
    filename = editor.getPath()
    dir = path.dirname filename
    process = run
      args: [ 'server', '--lib', 'lib' ]
      cwd: dir
      onMessage: (output) ->
    process

  check: ({fileName, onResult, onComplete, onFailure, onDone})->
    dir = path.dirname fileName
    if !@servers then @servers = {}
    if !@servers[dir] then @servers[dir] = @startServer()
    process = run
      args: [ '--json' ]
      cwd: dir
      onMessage: (output) ->
        result = JSON.parse output
        onResult result

  typeAtPos: ({fileName, bufferPt, onResult, onComplete, onFailure, onDone}) ->
    process = run
      args: ['type-at-pos', fileName, bufferPt.row + 1, bufferPt.column + 1, '--json']
      cwd: path.dirname fileName
      onMessage: (output) ->
        result = JSON.parse output
        onResult result