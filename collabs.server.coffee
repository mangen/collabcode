# TODO:
# 1) Figure out a way to disable the ACE editor.
# 2) Discover a mechanism for real-time communication b/w server and client
# -  - It seems zappa has some bugs with the socket.io implementation.
# 3) List users in the current channel.
# 4) Implement locking mechanism for users


@include = ->
  enable 'serve now'
  enable 'serve socket.io'

  get '/collabs': ->
    redirect '/'

  get '/collabs/:id': ->
    console.log "[TRACE] retrieve id #{@id}"

    ace_modes = [
      {name: 'text'}
      {name: 'javascript', src: 'mode-javascript.js'}
      {name: 'coffeescript', src: 'mode-coffee.js'}
      {name: 'csharp', src: 'mode-csharp.js'}
      {name: 'c', src: 'mode-c_cpp.js'}
      {name: 'html', src: 'mode-html.js'}
      {name: 'python', src: 'mode-python.js'}
      {name: 'ruby', src: 'mode-ruby.js'}
    ]

    code = @id
    collab_docs.get @id, (err, updated_doc) ->
      console.log "[TRACE] callback from findOne: #{err} and #{updated_doc}"
      if err?
        lines = [err,]
      else if updated_doc?
        code = updated_doc.code
        lines = updated_doc.lines
      else
        lines = [
          'Start coding here!',
          'Select your language highlighting preference up top.',
          '',
          'Only one person can edit at a time.',
          'Click the lock symbol to the right lock editing to you.'
        ]

      render 'collab', {code, ace_modes, lines}

  release_lock = ->
    console.log '[TRACE] releasing the edit lock enabling anyone to edit file.'
    # TODO: update db with info on the user lock mapping.
    emit 'lock_released'
  
  at connection: ->
    console.log "CONNECTION"
    emit 'test_hook'

  at disconnect: ->
    socket.get 'username', (err, name) ->
      console.log "#{name} disconnected."
      #TODO: Remove lock if it exists for that user.

  at join_room_handler: ->
    console.log "user <#{@username}> joining room #{@code}."
    socket.set 'username', @username
    socket.set 'code', @code
    socket.join @code

  at get_users_handler: ->
    console.log "retrieving the current users in the room."
    #TODO: return the users for the room @code.

  at collab_updated_handler: ->
    console.log "[TRACE] updating collab with code #{@code} with lines: #{@lines}"
    collab_docs.set @code, @lines, (err, updated_doc) ->
      socket.broadcast.to(updated_doc.code).emit 'collab_updated', code: updated_doc.code, lines: updated_doc.lines

  at request_lock_handler: ->
    socket.get 'username', (err, name) ->
      if err?
        console.log "[ERROR] #{err}"
      else
        console.log "[TRACE] attempting to assign edit lock to user <#{name}>"
        #TODO: 1) check that no one already has lock. 2) map lock to this user. 3) emit 'lock_granted' call.
  
  at release_lock_handler: ->
    release_lock()


