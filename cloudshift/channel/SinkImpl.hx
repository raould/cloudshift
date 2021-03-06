
package cloudshift.channel;

import cloudshift.Core;
import cloudshift.Channel;
import cloudshift.channel.Flow;
import cloudshift.core.ObservableImpl;
using cloudshift.Mixin;

using cloudshift.Channel;

class SinkImpl implements Sink {
  public var part_:Part_<Conduit,String,Sink,SinkEvent>;
  
  var _chans:Hash<Chan<Dynamic>>;  
  var _conduit:Conduit;
  var _myfill:Dynamic->String->Dynamic->Void;
  
  public function new() {
    part_ = Core.part(this);
  }

  public function start_(c:Conduit,?oc:Outcome<String,Sink>) {

    if (oc == null)
      oc = Core.outcome();

    _chans = new Hash();
    _conduit = c;

    addConduit(c);
    
    stop_(function(d) {
        var soc = Core.outcome();
        _conduit.stop().outcome(function(c) {
            _conduit = null;
          _chans = null;
          soc.resolve(Right(""));
        });

        return soc;
      });
    
    oc.resolve(Right(untyped this));
    return oc;
  }

  public function addConduit(c:Conduit) {

    // the sink observes the conduit ...
    
    var removeConduitOb = c.observe(function(f) {
        switch(f) {
        case Incoming(pkt,sessID,cb):
          var
            pID = pkt.chanID(),
            pip = _chans.get(pID),
            op = pkt.operation();

          if (pip == null)
            pip = chan(pID);

        switch(op) {
          case "s": // subscribe
            reqSub(sessID,pip,cb);
          case "u": // unsubscribe
            reqUnsub(sessID,pip,cb);
          case "m": // send a message
            reqMsg(pip,pkt);
            cb(Right(""));
          }
        case ConduitNoConnection(sessID),ConduitSessionExpire(sessID):
          notify(ConnectionClose(sessID));
        }
      });

    /*
    trace("adding conduit sink observer");
    var removeSinkOb = observe(function(s) {
          switch(s) {
          case Outgoing(sessID,pkt,chan,meta):
          trace("should be pumping, sess is:"+sessID);
          c.pump(sessID,pkt,chan,meta);
          default:
          }  
      });
      
    _conduitCleaners.push(function() {
        removeSinkOb();
        removeConduitOb();
      });
    */
  }

  public function
  chan<T>(pID):Chan<T> {
    var ch = _chans.get(pID) ;
    if (ch == null) {
      trace("Creating new channel:"+pID);
      ch = new ChanImpl<T>(pID);
      _chans.set(pID,ch);
      if (_myfill != null) {
        ch._fill = _myfill;
      }
    }
    return cast ch;
  }

  public function
  removeChan<T>(p:Chan<T>) {
    _chans.remove(p.pid());
  }
  
  public function
  chanFromId(pID:String):Option<Chan<Dynamic>> {
    return _chans.getOption(pID);
  }

  function reqSub(sessID:String,chan:Chan<Dynamic>,cb:Either<String,String>->Void) {
    throw "SinkImp:reqSub, should be overridden";
  }

  function reqUnsub(sessID,chan:Chan<Dynamic>,cb:Either<String,String>->Void) {
    throw "SinkImp:reqUnsub, should be overridden";
  }

  function removeAllSubs(sessID:String) {
    throw "SinkImp:removeAllSubs, should be overridden";
  }

  function reqMsg(chan:Chan<Dynamic>,pkt:Pkt<Dynamic>) {
    chan._defaultFill(pkt,"",null);
  }

  public function direct<T>(sessID:String):Chan<T> {
    return chan(Core.CSROOT+"direct/"+sessID);
  }
  
  public function
  authorize<T>(chan:Chan<T>):Outcome<String,Chan<T>> {
    var oc = Core.outcome();
    _conduit.authorize(chan.pid())
      .deliver(function(conduitAuthorized) {
          switch(conduitAuthorized) {
          case Right(_):
            oc.resolve(Right(chan));
          case Left(msg):
            oc.resolve(Left(msg));
          }
        });
    return oc;
  }

}
  