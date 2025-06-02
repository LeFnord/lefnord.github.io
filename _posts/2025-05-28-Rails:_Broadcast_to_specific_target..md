---
layout: post
title: 'Rails: Broadcast to specific target.'
excerpt: ''
date: 2025-05-28 23:42 +0200
modified: 2025-06-02 20:42 +0200
tags: [rails, turbo]
comments: false
share: false
author: LeFnord
---

If you are working with [Turbo](https://turbo.hotwired.dev) a while, there are comming the point you want to stream things only to a specific set users, say moderators. But how can this be acived without having the right `current_user` object. Cause the `current_user` on controller level isn't the same as user as it is for the target in the context of broadcast.

So say you have a chat room and only the owner of a message is allowed to delet its message.

```haml
-# app/views/messages/_room.html.haml

= turbo_stream_from dom_id(current_user)
= turbo_stream_from dom_id(room)
- room.messages.each do |message|
  = render partial: 'messages/message', locals: {message: message, owner: message.user == current_user}
```

Here we have two streams one for the current user, which is used to add the delete link, and the one for the chat room itself to add the newly create message.

The chat message partial looks like.

```haml
-# app/views/messages/_message.html.haml

= message.initials
= message.username
= I18n.l message.created_at, format: :short
= raw message.message

= turbo_frame_tag [dom_id(message), 'delete'] do
  - if owner
    = render partial: 'messages/delete', locals: {message: message}
```

Now then somebody sends a message we using in the model callback the message user to send also the delete link to the owner.

```rb
# app/models/message.rb

class Message < ApplicationRecord
  belongs_to :room, counter_cache: true
  belongs_to :user

  after_create_commit :create_broadcast

  def create_broadcast
    broadcast_append_to room,
                        partial: 'messages/message',
                        locals: {message: self, owner: false}

    broadcast_replace_to "user_#{user.id}",
                         target: "message_#{id}_delete",
                         partial: 'messages/delete',
                         locals: {message: self}
    end
  end
end
```

The trick is to send the delete broadcast to the user stream, with the delete target defined by the turbo frame above.

