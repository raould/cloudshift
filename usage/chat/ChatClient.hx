
import cloudshift.Core;
import cloudshift.Channel;
using cloudshift.Mixin;

import ChatUi;
import ChatTypes;

class ChatClient {

  var _chanClient:ChannelClient;
  var _room:Chan<Dynamic>;
  
  public static function main() {
    new ChatClient();
  }
  
  public function new() {
    ChatUi.init(login,logout);
  }

  function login(nick:String) {
    Channel.client()
      .start(nick)
      .outcome(function(client) {
          _chanClient = client;
          trace("starting room");
          startRoom(nick,client);
        },function(reason) {
          trace(reason);
        });
  }
 
  public function
  startRoom(nick:String,client:ChannelClient) {
    client.channel("/chat/room")
      .outcome(function(room) {
          _room = room;
          ChatUi.status("authorized in room");
          ChatUi.setChat(function(msg) {
              trace("should be sending "+msg);
              room.fill(Chat(nick,msg));
            });
          room.drain(function(mt:MsgTypes) {
              switch(mt) {
              case Chat(nick,msg):
                ChatUi.msg(nick,msg);
                case System(smt):
                  ChatUi.systemMsg(smt);
              }
            });
        },function(reason) {
          ChatUi.status("you're not authorised" +reason);
        });
  }

  
  function logout() {
    _chanClient.logout();
    _chanClient.unsub(_room);
    ChatUi.reset();
  }
}