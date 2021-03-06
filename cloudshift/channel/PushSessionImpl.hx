
package cloudshift.channel;

import cloudshift.Http;
import cloudshift.channel.Flow;
import cloudshift.channel.MessageQImpl;

using cloudshift.Mixin;

class PushSessionImpl implements ConduitSession {
  public var lastConnection(default,default):Float;
  public var sessID(default,default):String;
  
  var mq:MessageQ;
  var subs:Hash<Void->Void>;
  
  public function new(sessID:String) {
    this.sessID = sessID;
    mq = new MessageQImpl(sessID);
    subs = new Hash();
  }

  public function
  subscriptions():Hash<Void->Void> {
    return subs;
  }

  public inline function
  append(pkt:Dynamic) {
    mq.append(pkt);
  }

  public function
  flusher(flush:MessageQ->Bool) {
    mq.setFlusher(flush);
  }

  public function
  shutDown() {
    mq = null;
    trace("removed all subs for "+sessID);
    subs.values().foreach(function(f) f());
    subs = null;
  }

}